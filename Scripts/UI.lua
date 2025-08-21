local USGAPI = require('Scripts.USGAPI');
local GameList = require('Scripts.GameList');

--#region shortcut variables
local sf = string.format;
local min, max, abs, lerpWithClamp = math.min, math.max, math.abs, math.lerpWithClamp;

local drawTexture, drawText = USGAPI.drawTexture, USGAPI.drawText;
--#endregion

local TITLE = "USGAPI v" .. USGAPI.getAPIVersion();

local gray = Color.new(128, 128, 128, 128);
local black = Color.new(0, 0, 0, 128);
local fontName = "Fonts/luaFont.pgf";
local isEmulator = USGAPI.isEmulator();

local CATEGORIES_X_GAP = 250;
local GAMES_Y_GAP = 88;

local selectedCategory, selectedGame = 1, 1;
local selectedCategoryX, selectedGameY = CATEGORIES_X_GAP, GAMES_Y_GAP;
local gameWhiteBgSinner = 0;

local gameCategories = GameList.getGameCategories();

---@param path string путь до папки с игрой
local startGame = function(path)
    -- USGAPI.playSound("Sounds/startGame.wav");
    USGAPI.unloadAll();
    dofile(table.concat({ 'Games', path, 'script.lua' }, '/'));
    USGAPI.unloadAll();
    System.GC();
    USGAPI.setCameraPos(0, 0);
end;

local buttonsPressed, buttonsHeld = buttons.pressed, buttons.held;
local holdTimer = 0;
local update = function()
    local upHeld, downHeld = buttonsHeld(16), buttonsHeld(64);
    if (upHeld) then       --up
        holdTimer = holdTimer + 1;
    elseif (downHeld) then --down
        holdTimer = holdTimer + 1;
    else
        holdTimer = 0;
    end;

    if (buttonsPressed(16) or (upHeld and holdTimer > 30)) then       --up
        selectedGame = max(1, selectedGame - 1);
    elseif (buttonsPressed(64) or (downHeld and holdTimer > 30)) then --down
        selectedGame = min(#gameCategories[selectedCategory].games, selectedGame + 1);
    end;

    if (holdTimer > 30) then
        holdTimer = 27;
    end;

    if (buttonsPressed(32)) then --right
        selectedCategory = min(#gameCategories, selectedCategory + 1);
        selectedGame = 1;
        selectedGameY = GAMES_Y_GAP;
    elseif (buttonsPressed(128)) then --left
        selectedCategory = max(1, selectedCategory - 1);
        selectedGame = 1;
        selectedGameY = GAMES_Y_GAP;
    end;

    --horizontal move: category
    local targetCategoryX = selectedCategory * CATEGORIES_X_GAP;
    if (selectedCategoryX ~= targetCategoryX) then
        selectedCategoryX = lerpWithClamp(selectedCategoryX, targetCategoryX, 0.15);
    end;

    --vertival move: game
    local targetGameY = selectedGame * GAMES_Y_GAP;
    if (selectedGameY ~= targetGameY) then
        selectedGameY = lerpWithClamp(selectedGameY, targetGameY, 0.3);
    end;

    -- white bg
    gameWhiteBgSinner = gameWhiteBgSinner + 6;
    if (gameWhiteBgSinner > 255 * 2) then gameWhiteBgSinner = 0; end;

    if (buttonsPressed(16384)) then --cross
        startGame(gameCategories[selectedCategory].games[selectedGame].path);
    end;
end;

local _xmb_x1, _xmb_x2 = 0, 10;
local _xmb_color = Color.new(43, 92, 255);
local drawXMB = function()
    drawTexture("Images/xmb_bg480.png", 0, 0, 0, 255, _xmb_color);

    _xmb_x1 = _xmb_x1 + 0.8;
    if (_xmb_x1 > 480) then _xmb_x1 = 0; end;
    _xmb_x2 = _xmb_x2 + 0.75;
    if (_xmb_x2 > 480) then _xmb_x2 = 0; end;

    drawTexture("Images/xmb_wave.png", _xmb_x1, 121, 0, 255, _xmb_color);
    drawTexture("Images/xmb_wave.png", _xmb_x1 - 480, 121, 0, 255, _xmb_color);
    drawTexture("Images/xmb_wave.png", _xmb_x2, 121, 0, 255, _xmb_color);
    drawTexture("Images/xmb_wave.png", _xmb_x2 - 480, 121, 0, 255, _xmb_color);

    drawText(fontName, 6, 6, TITLE, black);
    drawText(fontName, 4, 4, TITLE);
    -- drawText("Fonts/arial.ttf", 10, 10, tostring(System.getBatteryPercent()));
end;

local drawGames = function()
    -- LUA.print(10, 10,
    --     string.format("cat:%.2f  game:%.2f\nsinner:%d", selectedCategoryX, selectedGame, abs(gameWhiteBgSinner - 255)));
    for ci, category in ipairs(gameCategories) do
        local cx, cy = 20 + ci * CATEGORIES_X_GAP - selectedCategoryX, 60;
        if (ci == selectedCategory) then
            for gi, game in ipairs(category.games) do
                local gx = 20 + ci * CATEGORIES_X_GAP - selectedCategoryX;
                local gy = 100 + gi * GAMES_Y_GAP - selectedGameY;

                if (gi == selectedGame) then
                    -- drawTexture("Images/xmb_game_black.png", gx - 11, gy - 11);
                    drawTexture("Images/xmb_game_white.png", gx - 11, gy - 11, 0,
                        abs(255 - gameWhiteBgSinner));
                    drawTexture(game.icon, gx, gy);
                    if (isEmulator) then
                        drawText(fontName, gx + 157, gy + 36, game.name, black);
                    end;
                    drawText(fontName, gx + 155, gy + 34, game.name);
                else
                    drawTexture(game.icon, gx, gy, 0, 69);
                    drawText(fontName, gx + 155, gy + 34, game.name, gray);
                end;
            end;
            if (isEmulator) then
                drawText(fontName, cx + 3, cy + 3, category.name, black, 1.5);
            end;
            drawText(fontName, cx, cy, category.name, nil, 1.5);
        else
            if (isEmulator) then
                drawText(fontName, cx + 2, cy + 2, category.name, black);
            end;
            drawText(fontName, cx, cy, category.name, gray);
        end;

        -- local x = 10;
        -- local y = 100 + 16 * i - selectedGame * 5;
        -- if (i == selectedGame) then
        --     drawText(fontName, x, y, '> ' .. drawInfo.gameName .. ' <', nil, drawInfo.scale);
        -- else
        --     drawText(fontName, x, y, drawInfo.gameName, gray, drawInfo.scale);
        -- end;
    end;
end;

return {
    update = update,
    drawXMB = drawXMB,
    drawGames = drawGames
};
