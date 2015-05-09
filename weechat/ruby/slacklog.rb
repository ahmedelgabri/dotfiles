# Copyright (c) 2014 Pat Brisbin <pbrisbin@gmail.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
# Fetch Slack chat history when opening a buffer.
#
# Required settings:
#
# - plugins.var.ruby.slacklog.servers "foo,bar"
# - plugins.var.ruby.slacklog.foo.api_token "foo-api-token"
# - plugins.var.ruby.slacklog.bar.api_token "bar-api-token"
#
###
require "cgi"
require "json"
require "net/https"
require "uri"

SCRIPT_NAME = "slacklog"
SCRIPT_AUTHOR = "Pat Brisbin <pbrisbin@gmail.com>"
SCRIPT_VERSION = "0.1"
SCRIPT_LICENSE = "MIT"
SCRIPT_DESCRIPTION = "Slack backlog"
SCRIPT_FILE = File.join(ENV["HOME"], ".weechat", "ruby", "#{SCRIPT_NAME}.rb")

NAMESPACE = "plugins.var.ruby.#{SCRIPT_NAME}"
API_TOKENS = {}

class SlackAPI
  BASE_URL = "https://slack.com/api"

  def initialize(token)
    @token = token
  end

  def backlog(name, count = nil)
    name = name.sub(/^#/, "")
    members = rpc("users.list").fetch("members")

    history(name, count).reverse.flat_map do |message|
      user = message.key?("user") &&
        members.detect { |u| u["id"] == message["user"] }

      format_message_lines(user, message["text"], members)
    end
  end

  private

  def history(name, count = nil)
    channels = rpc("channels.list").fetch("channels")

    if channel = channels.detect { |c| c["name"] == name }
      return rpc("channels.history", history_params(channel, count)).fetch("messages")
    end

    groups = rpc("groups.list").fetch("groups")

    if group = groups.detect { |g| g["name"] == name }
      return rpc("groups.history", history_params(group, count)).fetch("messages")
    end

    []
  end

  def history_params(room, count)
    params = { channel: room["id"] }

    if count
      params[:count] = count
    end

    params
  end

  def format_message_lines(user, body, members)
    return [] unless user

    body.lines.map do |line|
      fixed = fix_join_parts(fix_usernames(line.chomp, members))

      "#{user["name"]}\t#{CGI.unescapeHTML(fixed)}"
    end
  end

  def fix_join_parts(line)
    line.gsub(/<@.*?\|(.*?)>/, '\1')
  end

  def fix_usernames(line, members)
    line.gsub(/<@(.*?)>/) do |match|
      if user = members.detect { |u| u["id"] == $1 }
        user["name"]
      else
        match
      end
    end
  end

  def rpc(method, arguments = {})
    params = parameterize({ token: @token }.merge(arguments))
    uri = URI.parse("#{BASE_URL}/#{method}?#{params}")
    response = Net::HTTP.start(uri.host, use_ssl: true) do |http|
      http.get(uri.request_uri)
    end

    JSON.parse(response.body).tap do |result|
      result["ok"] or raise "API Error: #{result.inspect}"
    end
  rescue JSON::ParserError
    raise "API Error: unable to parse HTTP response"
  end

  def parameterize(query)
    query.map { |k,v| "#{escape(k)}=#{escape(v)}" }.join("&")
  end

  def escape(value)
    URI.escape(value.to_s)
  end
end

def output_history(buffer_id)
  server, name = Weechat.buffer_get_string(buffer_id, "name").split('.')

  if token = API_TOKENS[server]
    count = Weechat.config_get_plugin("count")
    run_script = "ruby '#{SCRIPT_FILE}' fetch '#{token}' '#{name}' #{count}"
    Weechat.hook_process(run_script, 0, "on_process_complete", buffer_id)
  end

  Weechat::WEECHAT_RC_OK
end

def on_slacklog(_, buffer_id, args)
  if /^add (?<server>[^ ]*) (?<token>[^ ]*)$/ =~ args
    server_list = Weechat.config_get_plugin("servers")
    Weechat.config_set_plugin("servers", "#{server_list},#{server}")
    Weechat.config_set_plugin("#{server}.api_token", token)

    read_tokens
  elsif /^remove (?<server>[^ ]*)$/ =~ args
    server_list = Weechat.config_get_plugin("servers")
    server_list = server_list.split(',').reject { |s| s == server }.join(',')
    Weechat.config_set_plugin("servers", server_list)
    Weechat.config_unset_plugin("#{server}.api_token")

    read_tokens
  else
    output_history(buffer_id)
  end
end

def on_join(_, signal, data)
  server = signal.split(",").first
  nick = Weechat.info_get("irc_nick", server)
  joined_nick = Weechat.info_get("irc_nick_from_host", data)

  if joined_nick != nick
    # Not our own JOIN event
    return Weechat::WEECHAT_RC_OK
  end

  channel = data.sub(/.*JOIN (.*)$/, '\1')
  buffer_id = Weechat.info_get("irc_buffer", "#{server},#{channel}")

  output_history(buffer_id)
end

def on_process_complete(buffer_id, _, rc, out, err)
  if rc.to_i == 0
    fg = Weechat.config_color(Weechat.config_get("logger.color.backlog_line"))
    color = Weechat.color("#{fg},default}")

    out.lines do |line|
      nick, text = line.strip.split("\t")
      Weechat.print(buffer_id, "%s%s\t%s%s" % [color, nick, color, text])
    end
  end

  if rc.to_i > 0
    err.lines do |line|
      Weechat.print("", "slacklog error: #{line.strip}")
    end
  end

  Weechat::WEECHAT_RC_OK
end

def read_tokens(*)
  server_list = Weechat.config_get_plugin("servers")
  server_list.split(",").map(&:strip).each do |server|
    api_token = Weechat.config_get_plugin("#{server}.api_token")
    if api_token.start_with?('${sec.data.')
      api_token = Weechat.string_eval_expression(api_token, {}, {}, {})
    end
    API_TOKENS[server] = api_token
  end

  Weechat::WEECHAT_RC_OK
end

def weechat_init
  Weechat.register(
    SCRIPT_NAME,
    SCRIPT_AUTHOR,
    SCRIPT_VERSION,
    SCRIPT_LICENSE,
    SCRIPT_DESCRIPTION,
    "", ""
  )

  Weechat.hook_config("#{NAMESPACE}.*", "read_tokens", "")
  Weechat.hook_signal("*,irc_in2_join", "on_join", "")

  Weechat.hook_command(
    "slacklog",
    "manage servers, or print history in current buffer",
    "[add server api-token | remove server |]",
    "", "", "on_slacklog", ""
  )

  read_tokens
end

if ARGV.shift == "fetch"
  token, room_name, count = ARGV

  slack_api = SlackAPI.new(token)
  slack_api.backlog(room_name, count).each { |line| puts line }
end
