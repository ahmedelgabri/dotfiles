-- vim:ft=lua:tw=0

local EMAIL_ENV_SUFFIX = "_EMAIL"
local EMAIL_ALIASES_ENV_SUFFIX = "_EMAIL_ALIASES"

local accounts = {
  Personal = {
    account_name = "Personal",
    switch_account = "Work",
    color = "blue",
    required = true
  },
  Work = {
    account_name = "Work",
    switch_account = "Personal",
    color = "red"
  }
}

function init_accounts()
  switch_account("Personal")

  for _, acc in pairs(accounts) do
    if acc.switch_account ~= nill then
      local switch_to = acc.switch_account.."/"..acc.switch_account
      local switch_to_env = os.getenv(string.upper(acc.switch_account) .. EMAIL_ENV_SUFFIX)
      local first_char = string.lower(string.sub(acc.switch_account, 1, 1))

      mutt.enter("folder-hook +"..acc.account_name.."/* 'lua switch_account(\""..acc.account_name.."\")'")
      if switch_to_env ~= nil then
        mutt.enter('macro index,pager g' ..first_char.. ' "<change-folder>=' ..switch_to.. '<enter>" "Switch account to ' ..acc.switch_account.. '"')
      end
    end
  end
end

-- Create a string form a map
-- https://stackoverflow.com/a/1407187/213124
function listvalues(s)
  local t = {}
  for k,v in pairs(s) do
    t[#t+1] = tostring(v)
  end
  return "'"..table.concat(t,"' '").."'"
end

function _switch_account(opt)
  local notmuch_path = opt.account_name.."/**"
  local prefix = opt.account_name.."/"..opt.account_name
  local folder_prefix = "+"..prefix
  local email_env = string.upper(opt.account_name) .. EMAIL_ENV_SUFFIX
  local alternate_env = string.upper(opt.account_name) .. EMAIL_ALIASES_ENV_SUFFIX
  local email = os.getenv(email_env)
  local alternates = os.getenv(alternate_env)

  if email == nil then
    if opt.required then
      print('You need to set $' .. email_env)
      os.exit(1)
    end
  else
    mutt.enter('macro index,pager gs "<change-folder>=' ..prefix.. '.Starred<enter>" "go to Starred"')
    mutt.enter('macro index,pager gt "<change-folder>=' ..prefix.. '.Sent<enter>" "go to Sent"')
    mutt.enter('macro index,pager gd "<change-folder>=' ..prefix.. '.Drafts<enter>" "go to Drafts"')
    mutt.enter('macro browser gs "<exit><change-folder>=' ..prefix.. '.Starred<enter>" "go to Starred"')
    mutt.enter('macro browser gt "<exit><change-folder>=' ..prefix.. '.Sent<enter>" "go to Sent"')
    mutt.enter('macro browser gd "<exit><change-folder>=' ..prefix.. '.Drafts<enter>" "go to Drafts"')
    mutt.enter('macro index,pager / "<vfolder-from-query>path:' ..notmuch_path.. ' " "Searching ' ..opt.account_name.. 'mailbox with notmuch integration in neomutt"')

    mutt.enter("unmailboxes *")
    if alternates ~= nil then
      mutt.enter("alternates "..listvalues({ alternates }))
    end

    mutt.set("sendmail", opt.sendmail or "/usr/local/bin/msmtp -a "..string.lower(opt.account_name))
    mutt.set("from", email)
    mutt.set("spoolfile", opt.inbox or folder_prefix)
    mutt.set("postponed", opt.drafts or folder_prefix..".Drafts")
    mutt.set("mbox", opt.record or folder_prefix..".Archive")
    mutt.set("trash", opt.trash or folder_prefix..".Trash")
    mutt.set("header_cache", opt.header_cache or os.getenv('HOME').."/.mutt/cache/headers/"..string.lower(opt.account_name).."/")
    mutt.set("message_cachedir", opt.message_cachedir or os.getenv('HOME').."/.mutt/cache/messages/"..string.lower(opt.account_name).."/")

    mutt.call("mailboxes",
      folder_prefix,
      folder_prefix..".Starred",
      folder_prefix..".Sent",
      folder_prefix..".Drafts",
      folder_prefix..".Archive",
      folder_prefix..".Trash",
      folder_prefix..".Spam",
      -- [TODO]: This is awful, fix this!
      "`tree ~/.mail -d -I \"cur|new|tmp|certs|.notmuch|Inbox|\\[Gmail\\]\" -a -f -i | sed -n -E -e \"s|^"..os.getenv('HOME').."/.mail/?||\" -e \"/^("..opt.account_name..")$/d\" -e \"/^("..opt.account_name..")/{p;}\" | sed -E -e 's/(.*)/+\"\\1\"/' | grep -v \"\\/\\.\" | tr '\\n' ' '`"
      )

    mutt.enter("macro index SI '<shell-escape>mbsync "..string.lower(opt.account_name).."-download<enter>' 'sync inbox'")
    mutt.enter("macro index,pager y '<save-message>="..prefix..".Archive<enter>' 'Archive conversation'")
    mutt.enter("macro index,pager Y '<tag-thread><save-message>="..prefix..".Archive<enter>' 'Archive conversation'")

    mutt.enter("color status "..opt.color.." default")
    mutt.enter("color sidebar_highlight black "..opt.color)
    mutt.enter("color sidebar_indicator "..opt.color.." color0")
  end
end

-- Switch Mutt accounts
function switch_account(name)
  _switch_account(accounts[name])
end

init_accounts()


-- =======================================================================
-- = [TODO]: Enable gpg in neomutt
-- =======================================================================

-- https://github.com/sadsfae/misc-dotfiles/blob/5d10342013b7620e85eadb659c8295c243f49dec/muttrc-gpg.txt
-- set pgp_autosign=yes
-- set pgp_replyencrypt=yes
-- set pgp_replysign=yes
-- set pgp_replysignencrypted=yes
-- set pgp_timeout=600
-- set pgp_sign_as=XXXXXXXX
-- # decode application/pgp
-- set pgp_decode_command="/usr/local/bin/gpg  --charset utf-8   %?p?--passphrase-fd 0? --no-verbose --quiet  --batch  --output - %f"

-- # verify a pgp/mime signature
-- set pgp_verify_command="/usr/local/bin/gpg   --no-verbose --quiet  --batch  --output - --verify %s %f"

-- # decrypt a pgp/mime attachment
-- set pgp_decrypt_command="/usr/local/bin/gpg --status-fd=2  --passphrase-fd 0 --no-verbose --quiet  --batch  --output - %f"

-- # create a pgp/mime signed attachment
-- # set pgp_sign_command="/usr/bin/gpg-2comp --comment '' --no-verbose --batch  --output - --passphrase-fd 0 --armor --detach-sign --textmode %?a?-u %a? %f"
-- set pgp_sign_command="/usr/local/bin/gpg    --no-verbose --batch --quiet   --output - --passphrase-fd 0 --armor --detach-sign --textmode %?a?-u %a? %f"

-- # create a application/pgp signed (old-style) message
-- # set pgp_clearsign_command="/usr/bin/gpg-2comp --comment ''  --no-verbose --batch  --output - --passphrase-fd 0 --armor --textmode --clearsign %?a?-u %a? %f"
-- set pgp_clearsign_command="/usr/local/bin/gpg   --charset utf-8 --no-verbose --batch --quiet   --output - --passphrase-fd 0 --armor --textmode --clearsign %?a?-u %a? %f"
