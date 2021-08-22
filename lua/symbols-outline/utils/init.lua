local M = {}

--- @param  f function
--- @param  delay number
--- @return function
function M.debounce(f, delay)
    local timer = vim.loop.new_timer()

    return function (...)
        local args = { ... }

        timer:start(delay, 0, vim.schedule_wrap(function ()
            timer:stop()
            f(unpack(args))
        end))
    end
end

return M
