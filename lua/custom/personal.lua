-- Personal additions to the current Kickstart base.
-- mini.nvim is already installed by init.lua.
require('mini.files').setup {}
require('mini.pairs').setup {}
require('mini.tabline').setup {}
require('mini.bufremove').setup {}

vim.keymap.set('n', '<leader>.', function() MiniFiles.open() end, { desc = 'Open file explorer' })
vim.keymap.set('n', '<S-l>', '<cmd>bnext<CR>', { desc = 'Next buffer' })
vim.keymap.set('n', '<S-h>', '<cmd>bprevious<CR>', { desc = 'Previous buffer' })
-- Keep the split layout and ask before deleting a modified buffer.
vim.keymap.set('n', '<S-d>', function() MiniBufremove.delete() end, { desc = 'Delete current buffer' })

-- Keep the familiar LSP mappings alongside current Kickstart's gr* mappings.
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('personal-lsp-keymaps', { clear = true }),
  callback = function(event)
    local builtin = require 'telescope.builtin'
    local map = function(keys, action, desc, mode) vim.keymap.set(mode or 'n', keys, action, { buffer = event.buf, desc = 'LSP: ' .. desc }) end
    map('gd', builtin.lsp_definitions, 'Goto definition')
    -- The mapping timeout lets both gr and the newer gr* keys remain usable.
    map('gr', builtin.lsp_references, 'Goto references')
    map('gI', builtin.lsp_implementations, 'Goto implementation')
    map('gD', vim.lsp.buf.declaration, 'Goto declaration')
    map('<leader>D', builtin.lsp_type_definitions, 'Type definition')
    map('<leader>ds', builtin.lsp_document_symbols, 'Document symbols')
    map('<leader>ws', builtin.lsp_dynamic_workspace_symbols, 'Workspace symbols')
    map('<leader>rn', vim.lsp.buf.rename, 'Rename')
    map('<leader>ca', vim.lsp.buf.code_action, 'Code action', { 'n', 'x' })
  end,
})

vim.pack.add { 'https://github.com/folke/trouble.nvim' }
require('trouble').setup {}
for _, mapping in ipairs {
  { '<leader>xx', 'diagnostics toggle', 'Diagnostics' },
  { '<leader>xX', 'diagnostics toggle filter.buf=0', 'Buffer diagnostics' },
  { '<leader>cs', 'symbols toggle focus=false', 'Symbols' },
  { '<leader>cl', 'lsp toggle focus=false win.position=right', 'LSP definitions and references' },
  { '<leader>xL', 'loclist toggle', 'Location list' },
  { '<leader>xQ', 'qflist toggle', 'Quickfix list' },
} do
  vim.keymap.set('n', mapping[1], '<cmd>Trouble ' .. mapping[2] .. '<CR>', { desc = mapping[3] .. ' (Trouble)' })
end
require('which-key').add {
  { '<leader>c', group = '[C]ode', mode = { 'n', 'x' } },
  { '<leader>d', group = '[D]ocument' },
  { '<leader>r', group = '[R]ename' },
  { '<leader>w', group = '[W]orkspace' },
  { '<leader>x', group = 'Trouble' },
}

-- The previous lint module was not loaded. Make Markdown linting active.
vim.pack.add { 'https://github.com/mfussenegger/nvim-lint' }
local lint = require 'lint'
lint.linters_by_ft = { markdown = { 'markdownlint' } }
vim.api.nvim_create_autocmd({ 'BufReadPost', 'BufWritePost', 'InsertLeave' }, {
  group = vim.api.nvim_create_augroup('personal-lint', { clear = true }),
  callback = function()
    if vim.bo.modifiable and vim.bo.buftype == '' and vim.bo.filetype == 'markdown' and vim.fn.executable 'markdownlint' == 1 then lint.try_lint() end
  end,
})
