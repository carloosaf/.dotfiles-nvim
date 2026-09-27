-- Run from this config's root: nvim --headless '+luafile tests/smoke.lua'
-- Plugins, Mason tools, and Tree-sitter parsers must already be installed.
local function check()
  -- mini.files silently clears netrw's FileExplorer group before netrw loads.
  if vim.v.errmsg == 'E216: No such group or event: FileExplorer *' then vim.v.errmsg = '' end
  assert(vim.v.errmsg == '', 'Startup error: ' .. vim.v.errmsg)
  for _, file in ipairs(vim.fn.glob(vim.fn.stdpath 'config' .. '/**/*.lua', false, true)) do
    assert(loadfile(file))
  end

  assert(vim.g.mapleader == ' ')
  assert(vim.lsp.is_enabled 'lua_ls')
  assert(vim.lsp.is_enabled 'gleam')
  assert(vim.lsp.config.lua_ls.capabilities.textDocument.completion.completionItem.snippetSupport)
  assert(vim.fn.exists ':Trouble' == 2)
  assert(vim.fn.exists ':SupermavenStart' == 0)
  assert(vim.fn.exists ':VimtexCompile' == 0)
  assert(require('telescope').extensions.fzf, 'Telescope native fzf failed to load')

  for _, key in ipairs { 'H', 'L', 'D', ' .', ' sf', ' sg', '  ', ' f', ' xx', ' xX', ' cs', ' cl', ' xL', ' xQ' } do
    assert(vim.fn.maparg(key, 'n') ~= '', 'Missing shortcut: ' .. key)
  end

  -- Delete a buffer displayed in two splits and retain both windows.
  vim.cmd.enew()
  local deleted = vim.api.nvim_get_current_buf()
  vim.cmd.vsplit()
  local window_count = #vim.api.nvim_list_wins()
  vim.fn.maparg('D', 'n', false, true).callback()
  assert(not vim.bo[deleted].buflisted, 'Buffer was not deleted')
  assert(#vim.api.nvim_list_wins() == window_count, 'Buffer deletion closed a split')

  -- Reject the confirmation and verify modified text is still available.
  vim.cmd.enew()
  local dirty = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_lines(dirty, 0, -1, false, { 'unsaved work' })
  local confirm = vim.fn.confirm
  local prompted = false
  vim.fn.confirm = function()
    prompted = true
    return 1
  end
  local ok, err = pcall(vim.fn.maparg('D', 'n', false, true).callback)
  vim.fn.confirm = confirm
  assert(ok, err)
  assert(prompted and vim.bo[dirty].buflisted and vim.bo[dirty].modified, 'Unsaved buffer was not protected')
  vim.bo[dirty].modified = false

  -- Exercise actual external formatters with malformed spacing.
  for _, fixture in ipairs {
    { 'lua', 'local x={1,2}', 'local x = { 1, 2 }' },
    { 'python', 'x=[1,2]', 'x = [1, 2]' },
    { 'javascript', 'const x={a:1}', 'const x = { a: 1 };' },
    { 'typescript', 'const x:number=1', 'const x: number = 1;' },
  } do
    vim.cmd.enew()
    local extension = ({ lua = 'lua', python = 'py', javascript = 'js', typescript = 'ts' })[fixture[1]]
    vim.api.nvim_buf_set_name(0, vim.fn.tempname() .. '.' .. extension)
    vim.bo.filetype = fixture[1]
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { fixture[2] })
    local format_error
    require('conform').format({ async = false, timeout_ms = 10000 }, function(err) format_error = err end)
    assert(not format_error, tostring(format_error))
    assert(vim.api.nvim_buf_get_lines(0, 0, 1, false)[1] == fixture[3], 'Formatting failed for ' .. fixture[1])
    vim.bo.modified = false
  end

  vim.cmd.enew()
  vim.api.nvim_buf_set_name(0, vim.fn.tempname() .. '.lua')
  vim.bo.filetype = 'lua'
  assert(vim.wait(30000, function() return #vim.lsp.get_clients { bufnr = 0, name = 'lua_ls' } > 0 end), 'LuaLS did not attach')
  for _, key in ipairs { 'gd', 'gr', 'gI', 'gD', ' D', ' ds', ' ws', ' rn', ' ca', 'grd', 'grr', 'grn' } do
    assert(vim.fn.maparg(key, 'n') ~= '', 'Missing LSP shortcut: ' .. key)
  end

  -- Expand and navigate a real snippet using the preserved completion mappings.
  local ls = require 'luasnip'
  ls.snip_expand(ls.snippet('', { ls.insert_node(1, 'first'), ls.text_node ' ', ls.insert_node(2, 'second') }))
  local keymap = require('blink.cmp.config').keymap
  assert(keymap['<C-l>'][1](), 'Ctrl-l did not advance the snippet')
  assert(require('blink.cmp').snippet_backward(), 'Ctrl-h snippet action failed')
  vim.bo.modified = false

  vim.cmd.enew()
  vim.bo.filetype = 'markdown'
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { '#Title' })
  require('lint').try_lint()
  assert(vim.wait(10000, function() return #vim.diagnostic.get(0) > 0 end), 'Markdown linter returned no diagnostics')
  vim.bo.modified = false

  for _, language in ipairs { 'bash', 'c', 'diff', 'html', 'lua', 'luadoc', 'markdown', 'markdown_inline', 'query', 'vim', 'vimdoc' } do
    assert(vim.treesitter.language.add(language), 'Missing parser: ' .. language)
  end
  -- LuaSnip probes the optional vim-repeat plugin with a protected call.
  if vim.v.errmsg == 'E117: Unknown function: repeat#set' then vim.v.errmsg = '' end
  assert(vim.v.errmsg == '', 'Runtime error: ' .. vim.v.errmsg)
  print 'PASS: startup, preserved shortcuts, safe buffer deletion, LuaLS, formatters, snippets, Markdown lint, and parsers'
end

local ok, err = xpcall(check, debug.traceback)
if not ok then
  io.stderr:write(err .. '\n')
  vim.cmd 'cquit 1'
else
  vim.cmd 'qa!'
end
