-- Codex ignores Rex's legacy Shift+Enter encoding through Mosh. Explicit CSI-u
-- preserves the modifier without relying on keyboard-protocol negotiation.
-- Match Mosh's default title prefix so local and SSH panes keep native handling.
rex.bind("shift+enter", function()
    local terminal = "com.superlogical.terminal"
    local title = rex.block.call(terminal, "title", {})
    if not title or not title.title:match("^%[mosh%]") then
        return false
    end
    local result = rex.block.call(terminal, "write", { data = "\27[13;2u" })
    return result ~= nil
end)
