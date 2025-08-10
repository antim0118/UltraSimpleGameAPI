local gamesList = File.GetDirectories('Games');

local DEFAULT_ICON = 'Images/ICON0.png';

---@alias UIGameCategoryNames "Classic" | "Parody" | "Unknown"
---@type UIGameCategoryNames[]
local DEFAULT_CATEGORIES = {
    'Classic',
    'Parody',
    'Unknown'
};

---@param gamePath string
---@return UIGameMeta
local getMetaByGame = function(gamePath)
    local metaPath = table.concat({ 'Games', gamePath, 'meta.lua' }, '/');
    if (not File.exists(metaPath)) then return {}; end;
    ---@type UIGameMeta
    local meta = dofile(metaPath);
    return meta or {};
end;

---@param gamePath string
---@return string
local getIconByGame = function(gamePath)
    local path = table.concat({ 'Games', gamePath, 'icon.png' }, '/');
    if (not File.exists(path)) then return DEFAULT_ICON; end;
    return path;
end;

---@type UIGameCategory[]
local gameCategories = (function()
    ---@type UIGameCategory[]
    local tb = {};

    for i, categoryName in ipairs(DEFAULT_CATEGORIES) do
        ---@type UIGameCategory
        local category = { name = categoryName, games = {} };
        table.insert(tb, category);
    end;

    for i, gamePath in ipairs(gamesList) do
        local meta = getMetaByGame(gamePath);
        local gameName = meta.altName or gamePath;
        if (meta.author) then
            gameName = gameName .. string.format(' (by %s)', meta.author);
        end;
        ---@type UIGame
        local game = { path = gamePath, name = gameName, icon = getIconByGame(gamePath) };

        local categoryName = meta.category or 'Unknown';

        --find category by name
        ---@type UIGameCategory | nil
        local category = nil;
        for i, cat in ipairs(tb) do
            if (cat.name == categoryName) then
                category = cat;
                break;
            end;
        end;

        if (not category) then
            error(string.format("Unknown category found: %s", tostring(categoryName)));
        end;

        table.insert(category.games, game);
    end;
    return tb;
end)();

return {
    getGameCategories = function() return gameCategories; end
};
