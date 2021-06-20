local snap = require "snap"
local M = {}

function M.setup()
  snap.register.map(
    {"n"},
    {"<Leader><Leader>"},
    function()
      local fd_args = vim.split(os.getenv("FZF_DEFAULT_COMMAND"), " ")
      -- Mutate the table & remove the first item, that's the fd command
      table.remove(fd_args, 1)

      snap.run(
        {
          prompt = "",
          producer = snap.get "consumer.fzf"(
            snap.get "consumer.try"(
              -- snap.get "producer.git.file",
              snap.get "producer.fd.file".args(fd_args)
            )
          ),
          select = snap.get "select.file".select,
          multiselect = snap.get "select.file".multiselect,
          views = {snap.get "preview.file"}
        }
      )
    end
  )

  snap.register.map(
    {"n"},
    {"<Leader>h"},
    function()
      snap.run {
        prompt = "?",
        producer = snap.get "consumer.fzf"(snap.get "producer.vim.help"),
        select = snap.get "select.help".select,
        views = {snap.get "preview.help"}
      }
    end
  )

  snap.register.map(
    {"n"},
    {"<localleader>f"},
    function()
      snap.run {
        producer = snap.get "producer.ripgrep.vimgrep",
        steps = {
          {
            consumer = snap.get "consumer.fzf",
            config = {prompt = "FZF>"}
          }
        },
        select = snap.get "select.file".select,
        multiselect = snap.get "select.file".multiselect,
        views = {snap.get "preview.file"}
      }
    end
  )

  snap.register.map(
    {"n"},
    {"<localleader>sn"},
    function()
      snap.run {
        producer = snap.get "consumer.fzf"(
          snap.get "consumer.combine"(
            snap.get "producer.ripgrep.file".args({}, os.getenv("NOTES_DIR"))
          )
        ),
        select = snap.get "select.vimgrep".select,
        multiselect = snap.get "select.vimgrep".multiselect,
        views = {snap.get "preview.file"}
      }
    end
  )
  -- snap.register.map(
  --   {"n"},
  --   {"<Leader>ff"},
  --   function()
  --     snap.run(
  --       {
  --         prompt = "Grep",
  --         producer = snap.get "consumer.limit"(10000, snap.get "producer.ripgrep.vimgrep"),
  --         select = snap.get "select.vimgrep".select,
  --         multiselect = snap.get "select.vimgrep".multiselect,
  --         views = {snap.get "preview.vimgrep"}
  --       }
  --     )
  --   end
  -- )

  snap.register.map(
    {"n"},
    {"<Leader>b"},
    function()
      snap.run(
        {
          prompt = "Buffers",
          producer = snap.get "consumer.fzf"(snap.get "producer.vim.buffer"),
          select = snap.get "select.file".select,
          multiselect = snap.get "select.file".multiselect,
          views = {snap.get "preview.file"}
        }
      )
    end
  )

  snap.register.map(
    {"n"},
    {"<Leader>fo"},
    function()
      snap.run(
        {
          prompt = "Oldfiles",
          producer = snap.get "consumer.fzf"(snap.get "producer.vim.oldfile"),
          select = snap.get "select.file".select,
          multiselect = snap.get "select.file".multiselect,
          views = {snap.get "preview.file"}
        }
      )
    end
  )

  -- snap.register.map(
  --   {"n"},
  --   {"<Leader>fb"},
  --   function()
  --     snap.run(
  --       {
  --         prompt = "Grep",
  --         producer = snap.get "consumer.limit"(10000, snap.get "producer.ripgrep.vimgrep"),
  --         select = snap.get "select.vimgrep".select,
  --         multiselect = snap.get "select.vimgrep".multiselect,
  --         initial_filter = vim.fn.expand("<cword>")
  --       }
  --     )
  --   end
  -- )
end

return M
