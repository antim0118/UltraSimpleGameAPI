local USGAPI = require("Scripts.USGAPI");
local gamePath = USGAPI.getGamePath();

--#region SHORTINGS
local held, pressed = buttons.held, buttons.pressed;
local min, max = math.min, math.max;
local fillRect = screen.filledRect;
local random, floor = math.random, math.floor;
--#endregion

local LOCATIONS_LIST = {
    RUINS16 = "room_ruins16",
    SANS_CORRIDOR = "room_sanscorridor",
    TUNDRA8 = "room_tundra8",

    BASEMENT1_FINAL = "room_basement1_final",
    TRUELAB_COOLER = "room_truelab_cooler",
    TUNDRA_ICEEXIT = "room_tundra_iceexit"
};

local LOCATION = LOCATIONS_LIST[table.keys(LOCATIONS_LIST)[floor(random() * 6 + 1)]];

--#region VARIABLES
local ROOM_WIDTH, ROOM_HEIGHT = 0, 0;
local x, y = 0, 0;

local borderUseAlpha = false;
local borderColors = {
    [false] = Color.new(0, 0, 0),
    [true] = Color.new(33, 33, 33, 128)
};
--#endregion

local onStart = function()
    local drawLoader = require("Scripts.DrawLoader");
    ---@param tile { bgName: string, x: number, y: number, w: number, h: number, xo: number, yo: number, depth: number }
    local function processTile(tile)
        local bgName = tile.bgName;
        local yo = tile.yo;

        if (bgName == "bg_tundratiles") then
            if (yo < 340) then
                bgName = bgName .. "1";
            elseif (yo < 660) then
                bgName = bgName .. "2";
                yo = yo - 340;
            else
                bgName = bgName .. "3";
                yo = yo - 660;
            end;
        end;

        local path = string.format("%s%s.png", gamePath, bgName);
        USGAPI.addTile(path, tile.xo, yo, tile.w, tile.h, tile.x, tile.y);
    end;

    local loadTiles = function(filePath)
        local file, err = io.open(filePath, "r");
        if not file then
            print("[loadTiles] Failed to open file: " .. tostring(filePath) .. " => " .. tostring(err));
            return;
        end;

        local current = 0;
        for line in file:lines() do
            if (current % 10 == 0) then
                drawLoader("Loading tiles...", current, 1479);
            end;
            current = current + 1;

            local w = string.match(line, "<width>(%d+)</width>");
            if w then ROOM_WIDTH = tonumber(w) --[[@as number]]; end;
            local h = string.match(line, "<height>(%d+)</height>");
            if h then ROOM_HEIGHT = tonumber(h) --[[@as number]]; end;

            if string.find(line, "<tile") then
                local attrs = {};
                for key, value in string.gmatch(line, "(%w+)%s*=%s*\"([^\"]*)\"") do
                    attrs[key] = value;
                end;

                if attrs.bgName then
                    local keys = { "x", "y", "w", "h", "xo", "yo", "depth" };
                    for i = 1, #keys do
                        local k = keys[i];
                        if attrs[k] ~= nil then
                            attrs[k] = tonumber(attrs[k]);
                        end;
                    end;

                    processTile(attrs);
                end;
            end;
        end;

        file:close();
    end;

    loadTiles(gamePath .. LOCATION .. '.room.xml');
    drawLoader("Optimizing...", 1, 1);
    USGAPI.optimizeTiles(32, 80, 16);
end;

onStart();

while true do
    USGAPI.startFrame();

    if (held(buttons.right)) then
        x = x + 2;
    elseif (held(buttons.left)) then
        x = x - 2;
    end;
    if (held(buttons.down)) then
        y = y + 2;
    elseif (held(buttons.up)) then
        y = y - 2;
    end;

    if (pressed(buttons.cross)) then
        borderUseAlpha = not borderUseAlpha;
    end;

    x = max(-80, min(ROOM_WIDTH - 480 + 80, x));
    y = max(-16, min(ROOM_HEIGHT - 272 + 16, y));

    USGAPI.setCameraPos(x, y);
    USGAPI.drawTiles();

    --border 320x240
    local borderColor = borderColors[borderUseAlpha];
    fillRect(0, 0, 80, 272, borderColor);
    fillRect(400, 0, 80, 272, borderColor);
    fillRect(0, 0, 480, 16, borderColor);
    fillRect(0, 256, 480, 16, borderColor);

    LUA.print(10, 10, string.format("Tiles: %d\nX - toggle border", USGAPI.getTilesCount()));

    if (buttons.pressed(buttons.start)) then break; end;
end;
