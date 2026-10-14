-- Deliberately run with -u NONE --noplugin; never source interactive init.
local root, mode, output = unpack(arg)
local config = root .. '/editors/nvim'
vim.opt.rtp:prepend(config)
local requirements = dofile(config .. '/lua/config/requirements.lua')
local result = { version = 1, errors = {} }
local function fail(message)
  table.insert(result.errors, tostring(message))
end
local function main()
  if vim.fn.has 'nvim-0.12' == 0 then
    error 'Neovim 0.12 or newer is required'
  end
  if mode == 'manifest' then
    result.plugins = { ['lazy.nvim'] = 'folke/lazy.nvim' }
    result.builds = {}
    local function add(spec)
      if type(spec) == 'string' then
        spec = { spec }
      end
      local repo = spec[1]
      if type(repo) == 'string' then
        local name = spec.name or repo:match '([^/]+)$'
        result.plugins[name] = repo
        if type(spec.build) == 'string' then
          result.builds[name] = spec.build
        end
      end
      for _, dependency in ipairs(spec.dependencies or {}) do
        add(dependency)
      end
    end
    for _, path in ipairs(vim.fn.glob(config .. '/lua/plugins/*.lua', false, true)) do
      for _, spec in ipairs(dofile(path)) do
        add(spec)
      end
    end
    return
  end
  local data = vim.fn.stdpath 'data'
  for _, path in ipairs(vim.fn.glob(data .. '/lazy/*', false, true)) do
    vim.opt.rtp:append(path)
  end
  vim.env.PATH = data .. '/mason/bin:' .. vim.env.PATH
  local missing = {}
  for _, parser in ipairs(requirements.parsers) do
    local ok = pcall(vim.treesitter.language.add, parser)
    if not ok then
      table.insert(missing, parser)
    end
  end
  if mode == 'apply' and #missing > 0 then
    require('nvim-treesitter').install(missing):wait(300000)
  end
  for _, parser in ipairs(requirements.parsers) do
    local ok, err = pcall(vim.treesitter.language.add, parser)
    if not ok then
      fail('parser ' .. parser .. ': ' .. tostring(err))
    end
  end
  local missing_tools = {}
  for package, executable in pairs(requirements.tools) do
    if vim.fn.executable(executable) == 0 then
      missing_tools[package] = executable
    end
  end
  if mode == 'apply' and next(missing_tools) then
    require('mason').setup { PATH = 'skip' }
    local registry = require 'mason-registry'
    local refreshed = false
    registry.refresh(function() refreshed = true end)
    assert(vim.wait(300000, function() return refreshed end, 100), 'Mason registry refresh timed out')
    for package, _ in pairs(missing_tools) do
      local item = registry.get_package(package)
      if not item:is_installed() then
        item:install()
        assert(vim.wait(300000, function() return not item:is_installing() end, 100), package .. ' install timed out')
      end
    end
  end
  for package, executable in pairs(missing_tools) do
    if vim.fn.executable(executable) == 0 then
      fail('missing editor tool: ' .. package .. ' (' .. executable .. ')')
    end
  end
  if vim.fn.executable 'rustfmt' == 0 then
    fail 'missing system tool: rustfmt (install through the host toolchain)'
  end
end
local ok, err = pcall(main)
if not ok then fail(err) end
result.healthy = #result.errors == 0
vim.fn.writefile({ vim.json.encode(result) }, output)
