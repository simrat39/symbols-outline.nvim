local vim = vim

local D = {}

-- needs plenary
local reload = require('plenary.reload').reload_module

function D.R(name)
    reload(name)
    return require(name)
end

function D.setup_commands()
    vim.cmd("command! " .. "DSymbolsOutline " ..
                ":lua require'symbols-outline'.R('symbols-outline').toggle_outline()")
end

return D
