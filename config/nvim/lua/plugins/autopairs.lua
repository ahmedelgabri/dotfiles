return {
	'https://github.com/windwp/nvim-autopairs',
	event = 'InsertEnter',
	config = function()
		local npairs = require 'nvim-autopairs'
		local Rule = require 'nvim-autopairs.rule'
		local conds = require 'nvim-autopairs.conds'
		local ts_conds = require 'nvim-autopairs.ts-conds'
		local log = require 'nvim-autopairs._log'
		local utils = require 'nvim-autopairs.utils'

		npairs.setup {}

		-- Autoclosing angle-brackets.
		-- https://github.com/windwp/nvim-autopairs/wiki/Custom-rules#auto-pair--for-generics-but-not-as-greater-thanless-than-operators
		npairs.add_rule(Rule('<', '>', {
			-- Avoid conflicts with nvim-ts-autotag.
			'-html',
			'-javascript.jsx',
			'-javascriptreact',
			'-typescript.tsx',
			'-typescriptreact',
		}):with_pair(conds.before_regex('%a+:?:?$', 3)):with_move(function(opts)
			return opts.char == '>'
		end))

		-- When typing space equals for assignment in Nix, add the final semicolon to the line
		-- https://github.com/windwp/nvim-autopairs/wiki/Custom-rules#when-typing-space-equals-for-assignment-in-nix-add-the-final-semicolon-to-the-line
		-- Note that when the cursor is at the end of a comment line,
		-- treesitter thinks we are in attrset_expression
		-- because the cursor is "after" the comment, even though it is on the same line.
		local is_not_ts_node_comment_one_back = function()
			return function(info)
				log.debug 'not_in_ts_node_comment_one_back'

				local p = vim.api.nvim_win_get_cursor(0)
				-- Subtract one to account for 1-based row indexing in nvim_win_get_cursor
				-- Also subtract one from the position of the column to see if we are at the end of a comment.
				local pos_adjusted = { p[1] - 1, p[2] - 1 }

				vim.treesitter.get_parser():parse()
				local target = vim.treesitter.get_node {
					pos = pos_adjusted,
					ignore_injections = false,
				}
				log.debug(target:type())
				if
					target ~= nil and utils.is_in_table({ 'comment' }, target:type())
				then
					return false
				end

				local rest_of_line = info.line:sub(info.col)
				return rest_of_line:match '^%s*$' ~= nil
			end
		end

		npairs.add_rule(
			Rule('= ', ';', 'nix')
				:with_pair(is_not_ts_node_comment_one_back())
				:set_end_pair_length(1)
		)
	end,
}
