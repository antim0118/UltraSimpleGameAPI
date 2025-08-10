local USGAPI = require('Scripts.USGAPI');
local GameList = require('Scripts.GameList');

local sf = string.format;
local min, max = math.min, math.max;

local gray = Color.new(128, 128, 128);
local fontName = "Fonts/luaFont.pgf";

local selectedCategory, selectedGame = 1, 1;

---@param path string путь до папки с игрой
local startGame = function(path)
    -- USGAPI.playSound("Sounds/startGame.wav");
    USGAPI.unloadAll();
    dofile(table.concat({ 'Games', path, 'script.lua' }, '/'));
    USGAPI.unloadAll();
end;

local update = function()
    local gameCategories = GameList.getGameCategories();
    if (buttons.pressed(buttons.up)) then selectedGame = max(1, selectedGame - 1); end;
    if (buttons.pressed(buttons.down)) then selectedGame = min(#gameCategories, selectedGame + 1); end;

    if (buttons.pressed(buttons.cross)) then
        startGame(gameCategories[selectedGame].gameName);
    end;

    GameList.processGameCategories(selectedGame);
end;

local _xmb_x1, _xmb_x2 = 0, 10;
local drawXMB = function()
    USGAPI.drawTexture("Images/xmb_bg480.png", 0, 0, 0, 255, Color.new(43, 92, 255));

    _xmb_x1 = _xmb_x1 + 0.8;
    if (_xmb_x1 > 480) then _xmb_x1 = 0; end;
    _xmb_x2 = _xmb_x2 + 0.75;
    if (_xmb_x2 > 480) then _xmb_x2 = 0; end;

    USGAPI.drawTexture("Images/xmb_wave.png", _xmb_x1, 144, 0, 255, Color.new(43, 92, 255));
    USGAPI.drawTexture("Images/xmb_wave.png", _xmb_x1 - 480, 144, 0, 255, Color.new(43, 92, 255));
    USGAPI.drawTexture("Images/xmb_wave.png", _xmb_x2, 144, 0, 255, Color.new(43, 92, 255));
    USGAPI.drawTexture("Images/xmb_wave.png", _xmb_x2 - 480, 144, 0, 255, Color.new(43, 92, 255));

    -- USGAPI.drawText(System.getBatteryPercent());
end;

local drawGames = function()
    local gameCategories = GameList.getGameCategories();
    for categoryName, category in pairs(gameCategories) do
        -- local x = 10;
        -- local y = 100 + 16 * i - selectedGame * 5;
        -- if (i == selectedGame) then
        --     USGAPI.drawText(fontName, x, y, '> ' .. drawInfo.gameName .. ' <', nil, drawInfo.scale);
        -- else
        --     USGAPI.drawText(fontName, x, y, drawInfo.gameName, gray, drawInfo.scale);
        -- end;
    end;
end;

return {
    update = update,
    drawXMB = drawXMB,
    drawGames = drawGames
};
