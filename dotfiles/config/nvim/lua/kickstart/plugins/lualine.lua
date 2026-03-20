require('lualine').setup({
  options = {
    theme = 'tokyonight',
    component_separators = { left = '', right = '' },
    section_separators = { left = '', right = '' },
    globalstatus = true,
  },
  sections = {
    lualine_a = { 'mode' },
    lualine_b = { 'branch' },
    lualine_c = {
      {
        'diagnostics',
        symbols = {
          error = 'E',
          warn = 'W',
          info = 'I',
          hint = 'H',
        },
      },
      { 'filetype', icon_only = true, separator = '', padding = { left = 1, right = 0 } },
      { 'filename', path = 1, symbols = { modified = '  ', readonly = '', unnamed = '' } },
    },
    lualine_x = {
      {
        function()
          return require('lazy.status').updates()
        end,
        cond = function()
          return require('lazy.status').has_updates()
        end,
        color = { fg = '#ff9e64' },
      },
      {
        'diff',
        symbols = {
          added = 'A',
          modified = 'M',
          removed = 'R',
        },
      },
    },
    lualine_y = {
      { 'progress', separator = ' ', padding = { left = 1, right = 0 } },
      { 'location', padding = { left = 0, right = 1 } },
    },
    lualine_z = {
      function()
        return ' ' .. os.date('%R')
      end,
    },
  },
  extensions = { 'neo-tree', 'lazy' },
})
