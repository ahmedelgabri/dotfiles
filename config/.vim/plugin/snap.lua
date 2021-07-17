local has_snap = pcall(require, 'snap')

if not has_snap then
  return
end

local snap = require 'snap'
local config = snap.config
local notes = require '_.notes'
local M = {}

local fd_args = vim.split(vim.env.FZF_DEFAULT_COMMAND, ' ')
-- Mutate the table & remove the first item, that's the fd command
table.remove(fd_args, 1)

local custom_mappings = {
  ['view-toggle-hide'] = { '?' },
}

local defaults = {
  reverse = true,
  prompt = '',
  suffix = '',
  -- consumer = "fzy",
  mappings = custom_mappings,
  preview_min_width = 80,
}

local function file(opts)
  local options = vim.tbl_extend('force', defaults, opts or {})

  return config.file:with(options)
end

local vimgrep = config.vimgrep:with(vim.tbl_extend('force', defaults, {
  prompt = ' /',
  -- filter_with = "cword",
  limit = 50000,
}))

local notes_producer = snap.get 'consumer.limit'(50000, function(request)
  return snap.get 'producer.ripgrep.general'(request, {
    absolute = true,
    args = {
      '--line-buffered',
      '-M',
      '100',
      '--vimgrep',
      request.filter,
    },
    cwd = snap.sync(notes.get_dir),
  })
end)

function M.setup()
  snap.maps {
    {
      '<leader><leader>',
      file() {
        args = fd_args,
        try = {
          -- "git.file",
          'fd.file',
        },
      },
      { command = 'files' },
    },
    { '<leader>fg', file() { producer = 'git.file' }, { command = 'git.files' } },
    {
      '<leader>b',
      file { preview = false } { producer = 'vim.buffer' },
      { command = 'buffers' },
    },
    { '<leader>ff', vimgrep {}, { command = 'grep' } },
    {
      '<leader>fo',
      file { preview = false } { producer = 'vim.oldfile' },
      { command = 'oldfiles' },
    },
    {
      '<localleader>c',
      file() {
        combine = { 'vim.buffer', 'vim.oldfile' },
      },
    },
  }

  snap.register.map({ 'n' }, { '<leader>h' }, function()
    snap.run {
      reverse = true,
      prompt = '?',
      producer = snap.get 'consumer.fzf'(snap.get 'producer.vim.help'),
      select = snap.get('select.help').select,
      views = { snap.get 'preview.help' },
      mappings = custom_mappings,
    }
  end)

  snap.register.map({ 'n' }, { '<localleader>f' }, function()
    snap.run {
      producer = notes_producer,
      steps = {
        {
          consumer = snap.get 'consumer.fzf',
          config = { prompt = 'FZF>' },
          -- consumer = snap.get "consumer.fzy",
          -- config = {prompt = "FZY>"}
        },
      },
      select = snap.get('select.file').select,
      multiselect = snap.get('select.file').multiselect,
      views = { snap.get 'preview.file' },
      mappings = custom_mappings,
    }
  end)

  snap.register.map({ 'n' }, { '<localleader>sn' }, function()
    snap.run {
      prompt = 'notes:',
      reverse = true,
      producer = notes_producer,
      select = snap.get('select.vimgrep').select,
      multiselect = snap.get('select.vimgrep').multiselect,
      views = { snap.get 'preview.vimgrep' },
      -- initial_filter = vim.fn.expand("<cword>"),
      mappings = custom_mappings,
    }
  end)
end

-- M.setup()

if not has_snap then
  return
end

local snap = require 'snap'
local config = snap.config
local notes = require '_.notes'
local M = {}

local fd_args = vim.split(vim.env.FZF_DEFAULT_COMMAND, ' ')
-- Mutate the table & remove the first item, that's the fd command
table.remove(fd_args, 1)

local custom_mappings = {
  ['view-toggle-hide'] = { '?' },
}

local defaults = {
  reverse = true,
  prompt = '',
  suffix = '',
  -- consumer = "fzy",
  mappings = custom_mappings,
  preview_min_width = 80,
}

local function file(opts)
  local options = vim.tbl_extend('force', defaults, opts or {})

  return config.file:with(options)
end

local vimgrep = config.vimgrep:with(vim.tbl_extend('force', defaults, {
  prompt = ' /',
  -- filter_with = "cword",
  limit = 50000,
}))

local notes_producer = snap.get 'consumer.limit'(50000, function(request)
  return snap.get 'producer.ripgrep.general'(request, {
    absolute = true,
    args = {
      '--line-buffered',
      '-M',
      '100',
      '--vimgrep',
      request.filter,
    },
    cwd = snap.sync(notes.get_dir),
  })
end)

function M.setup()
  snap.maps {
    {
      '<leader><leader>',
      file() {
        args = fd_args,
        try = {
          -- "git.file",
          'fd.file',
        },
      },
      { command = 'files' },
    },
    { '<leader>fg', file() { producer = 'git.file' }, { command = 'git.files' } },
    {
      '<leader>b',
      file { preview = false } { producer = 'vim.buffer' },
      { command = 'buffers' },
    },
    { '<leader>ff', vimgrep {}, { command = 'grep' } },
    {
      '<leader>fo',
      file { preview = false } { producer = 'vim.oldfile' },
      { command = 'oldfiles' },
    },
    {
      '<localleader>c',
      file() {
        combine = { 'vim.buffer', 'vim.oldfile' },
      },
    },
  }

  snap.register.map({ 'n' }, { '<leader>h' }, function()
    snap.run {
      reverse = true,
      prompt = '?',
      producer = snap.get 'consumer.fzf'(snap.get 'producer.vim.help'),
      select = snap.get('select.help').select,
      views = { snap.get 'preview.help' },
      mappings = custom_mappings,
    }
  end)

  snap.register.map({ 'n' }, { '<localleader>f' }, function()
    snap.run {
      producer = notes_producer,
      steps = {
        {
          consumer = snap.get 'consumer.fzf',
          config = { prompt = 'FZF>' },
          -- consumer = snap.get "consumer.fzy",
          -- config = {prompt = "FZY>"}
        },
      },
      select = snap.get('select.file').select,
      multiselect = snap.get('select.file').multiselect,
      views = { snap.get 'preview.file' },
      mappings = custom_mappings,
    }
  end)

  snap.register.map({ 'n' }, { '<localleader>sn' }, function()
    snap.run {
      prompt = 'notes:',
      reverse = true,
      producer = notes_producer,
      select = snap.get('select.vimgrep').select,
      multiselect = snap.get('select.vimgrep').multiselect,
      views = { snap.get 'preview.vimgrep' },
      -- initial_filter = vim.fn.expand("<cword>"),
      mappings = custom_mappings,
    }
  end)
end

M.setup()
