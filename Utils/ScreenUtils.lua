---@param x number
---@param y number
---@param len? number
function screen.drawCross(x, y, len)
    local color = Color.new(255, 255, 0)
    len = len or 4
    screen.drawLine(x - 1, y, x - 1 - len, y, color)
    screen.drawLine(x + 1, y, x + 1 + len, y, color)
    screen.drawLine(x, y - 1, x, y - 1 - len, color)
    screen.drawLine(x, y + 1, x, y + 1 + len, color)
end
