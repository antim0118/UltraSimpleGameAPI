local white = Color.new(255, 255, 255);
local black = Color.new(0, 0, 0);
local gray = Color.new(128, 128, 128);

local mrad, mcos, msin = math.rad, math.cos, math.sin;

local function rotateX(x, y, z, angle)
    local rad = mrad(angle);
    local cosa = mcos(rad);
    local sina = msin(rad);
    return x, y * cosa - z * sina, y * sina + z * cosa;
end;

local function rotateY(x, y, z, angle)
    local rad = mrad(angle);
    local cosa = mcos(rad);
    local sina = msin(rad);
    return x * cosa + z * sina, y, -x * sina + z * cosa;
end;

local function rotateZ(x, y, z, angle)
    local rad = mrad(angle);
    local cosa = mcos(rad);
    local sina = msin(rad);
    return x * cosa - y * sina, x * sina + y * cosa, z;
end;

local vertices = {
    { -1, -1, -1 }, { 1, -1, -1 }, { 1, 1, -1 }, { -1, 1, -1 },
    { -1, -1, 1 }, { 1, -1, 1 }, { 1, 1, 1 }, { -1, 1, 1 }
};

local edges = {
    { 1, 2 }, { 2, 3 }, { 3, 4 }, { 4, 1 },
    { 5, 6 }, { 6, 7 }, { 7, 8 }, { 8, 5 },
    { 1, 5 }, { 2, 6 }, { 3, 7 }, { 4, 8 }
};

local ipairs = ipairs;
local unpack = unpack;
local insert = table.insert;
local drawLine = screen.drawLine;
local deg = math.deg;
local function DrawCube(rX, rY, rZ, scale)
    local transformed = {};

    for i = 1, 8 do
        local v = vertices[i];

        local x, y, z = unpack(v);
        x, y, z = rotateX(x, y, z, rX);
        x, y, z = rotateY(x, y, z, rY);
        x, y, z = rotateZ(x, y, z, rZ);
        insert(transformed, { x * 50 - 186, y * 50 - 130 });
    end;
    local r = (msin(deg(rX / 500)) + 1) * 128;
    local g = (msin(deg(rY / 500)) + 1) * 128;
    local b = (msin(deg(rZ / 500)) + 1) * 128;
    local black = Color.new(r, g, b);

    for i = 1, 12 do
        local edge = edges[i];

        local start = transformed[edge[1]];
        local endp = transformed[edge[2]];
        drawLine(start[1] * scale + 380, start[2] * scale + 200,
            endp[1] * scale + 380, endp[2] * scale + 200,
            black);
    end;
end;

local x, y, z = math.random() * 23, math.random() * 23, math.random() * 23;

---@param text string
---@param current number
---@param total number
local function drawLoader(text, current, total)
    --19717ms -> 9847ms
    screen.clear(white);

    screen.filledRect(20, 200, 440, 40, gray);
    screen.filledRect(25, 205, current / total * 430, 30, black);

    screen.filledRect(20, 180, 440, 14, gray);

    x = x + 0.5;
    y = y + 2.3;
    z = z + 0.11;

    for i = 1, 6 do
        DrawCube(x - i, y - i, z - i, 0.75);
    end;

    LUA.print(20, 180, text);

    screen.filledRect(0, 0, 60, 14, gray);
    LUA.print(0, 0, string.format("%.2fMb", LUA.getRAM() / 1024 / 1024));

    screen.flip();
end;

return drawLoader;
