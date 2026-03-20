local opt = vim.opt
local g = vim.g
local map = vim.keymap.set

opt.expandtab = true
opt.shiftwidth = 2
opt.smartindent = true
opt.tabstop = 2
opt.softtabstop = 2
opt.number = true
opt.relativenumber = true
opt.cursorline = true
opt.splitright = true
opt.splitbelow = true
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = true
opt.wrap = false
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.termguicolors = true

g.mapleader = ' '

map({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })

map('n', '<leader>w', ':w<CR>', { desc = 'Write buffer' })
map('n', '<leader>q', ':q<CR>', { desc = 'Quit' })
map('n', '<leader>h', ':nohlsearch<CR>', { desc = 'Clear search highlight' })

map('n', '<leader>s', ':%s//<Left>', { desc = 'Find and replace' })

map('n', '<leader>d', '"_d', { desc = 'Delete without yanking' })
map('n', '<leader>D', '"_D', { desc = 'Delete to end without yanking' })
map({ 'n', 'v' }, '<leader>y', '"+y', { desc = 'Yank to clipboard' })
map({ 'n', 'v' }, '<leader>p', '"+p', { desc = 'Paste from clipboard' })

map('n', '<leader>pv', vim.cmd.Ex, { desc = 'Netrw file explorer' })

map('n', '<leader>tt', ':tabnew<CR>', { desc = 'New tab' })
map('n', '<leader>to', ':tabonly<CR>', { desc = 'Close other tabs' })
map('n', '<leader>tc', ':tabclose<CR>', { desc = 'Close tab' })
map('n', '<leader>tn', ':tabnext<CR>', { desc = 'Next tab' })
map('n', '<leader>tp', ':tabprevious<CR>', { desc = 'Previous tab' })

map('n', '<leader>sv', ':vsplit<CR>', { desc = 'Vertical split' })
map('n', '<leader>sh', ':split<CR>', { desc = 'Horizontal split' })

map('n', '<C-h>', '<C-w>h', { desc = 'Move to left window' })
map('n', '<C-j>', '<C-w>j', { desc = 'Move to below window' })
map('n', '<C-k>', '<C-w>k', { desc = 'Move to above window' })
map('n', '<C-l>', '<C-w>l', { desc = 'Move to right window' })

map('n', '<leader>j', 'J', { desc = 'Join lines' })
map('n', '<leader>k', ':move -2<CR>', { desc = 'Move line up' })
map('n', '<leader>l', ':move +1<CR>', { desc = 'Move line down' })

map('n', 'n', 'nzzzv', { desc = 'Next search with center' })
map('n', 'N', 'Nzzzv', { desc = 'Previous search with center' })

map({ 'i', 'v' }, 'kj', '<Esc>', { desc = 'Escape to normal mode' })
