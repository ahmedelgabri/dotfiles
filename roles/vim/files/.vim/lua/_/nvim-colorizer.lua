local has_colorizer, colorizer = pcall(require, "colorizer")

if not has_colorizer then
  return
end

-- https://github.com/norcalli/nvim-colorizer.lua/issues/4#issuecomment-543682160
colorizer.setup(
  {
    "*",
    "!vim"
  },
  {
    css = true
  }
)
