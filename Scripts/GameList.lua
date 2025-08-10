local gamesList = File.GetDirectories('Games');

local min, max, lerp = math.min, math.max, math.lerp;

local DEFAULT_ICON = Image.load('Images/ICON0.png');

---@param gamePath string
---@return UIGameMeta
local getMetaByGame = function(gamePath)
    local metaPath = table.concat({ 'Games', gamePath, 'meta.lua' }, '/');
    if (not File.exists(metaPath)) then return {}; end;
    ---@type UIGameMeta
    local meta = dofile(metaPath);
    return meta or {};
end;

---@type table<string, UIGame[]>
local gameCategories = (function()
    ---@type table<string, UIGame[]>
    local tb = {};
    for i, gamePath in ipairs(gamesList) do
        local meta = getMetaByGame(gamePath);
        ---@type UIGame
        local game = { path = gamePath, name = meta.altName or gamePath, icon = DEFAULT_ICON };

        local categoryName = meta.category or 'Unknown';

        if (not tb[categoryName]) then
            tb[categoryName] = {};
        end;

        table.insert(tb[categoryName], game);
    end;
    return tb;
end)();

---@param selectedGame number
local processGameCategories = function(selectedGame)
    for i, category in pairs(gameCategories) do
        -- local scale = category.scale;
        -- if (i == selectedGame) then
        --     scale = min(1, lerp(scale, 1.05, 0.2));
        -- else
        --     scale = max(0.75, lerp(scale, 0.7, 0.2));
        -- end;
        -- category.scale = scale;
    end;
end;

return {
    processGameCategories = processGameCategories,
    getGameCategories = function() return gameCategories; end
};
