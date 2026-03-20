require('mason').setup()

local lspconfig = require('lspconfig')

local on_attach = function(_, bufnr)
  local bufmap = function(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
  end

  bufmap('n', 'gd', vim.lsp.buf.definition, 'Go to definition')
  bufmap('n', 'gD', vim.lsp.buf.declaration, 'Go to declaration')
  bufmap('n', 'gi', vim.lsp.buf.implementation, 'Go to implementation')
  bufmap('n', 'gr', require('telescope.builtin').lsp_references, 'Go to references')
  bufmap('n', '<leader>rn', vim.lsp.buf.rename, 'Rename')
  bufmap('n', '<leader>ca', vim.lsp.buf.code_action, 'Code action')
  bufmap('n', 'K', vim.lsp.buf.hover, 'Hover')
end

require('mason-lspconfig').setup({
  ensure_installed = {
    'lua_ls',
    'rust_analyzer',
    'tsserver',
    'gopls',
    'pyright',
    'bashls',
    'jsonls',
    'yamlls',
  },
  handlers = {
    function(server_name)
      lspconfig[server_name].setup({
        on_attach = on_attach,
      })
    end,
    lua_ls = function()
      lspconfig.lua_ls.setup({
        on_attach = on_attach,
        settings = {
          Lua = {
            runtime = {
              version = 'LuaJIT',
            },
            diagnostics = {
              globals = { 'vim' },
            },
            workspace = {
              library = vim.api.nvim_get_runtime_file('', true),
              checkThirdParty = false,
            },
            telemetry = {
              enable = false,
            },
          },
        },
      })
    end,
  },
})
