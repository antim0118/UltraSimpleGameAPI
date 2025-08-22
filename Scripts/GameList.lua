local gamesList = File.GetDirectories('Games');

local DEFAULT_ICON = 'Images/ICON0.png';

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

---@param groupBy "category"|"author"|"createdWithAI"
---@return UIGameGroup[]
local getGroupedGamesBy = function(groupBy)
    ---@type table<string, UIGame[]>
    local groups = {};

    ---@param groupValue string
    ---@param game UIGame
    local appendGame = function(groupValue, game)
        --find group by name
        if (not groups[groupValue]) then
            groups[groupValue] = {};
        end;
        table.insert(groups[groupValue], game);
    end;

    for i, gamePath in ipairs(gamesList) do
        local meta = getMetaByGame(gamePath);
        local gameName = meta.altName or gamePath;
        if (meta.author) then
            gameName = gameName .. string.format(' (by %s)', meta.author);
        end;

        ---@type UIGame
        local game = { path = gamePath, name = gameName, icon = getIconByGame(gamePath) };
        local groupValue = meta[groupBy] or 'Unknown';

        if (type(groupValue) == "boolean" and groupValue) then
            groupValue = groupBy;
        end;

        appendGame(groupValue, game);
    end;

    ---@type UIGameGroup[]
    local tb = {};

    for groupValue, games in pairs(groups) do
        tb[#tb + 1] = { name = groupValue, games = games };
    end;

    table.sort(tb, function(a, b)
        local an, bn = a.name:upper(), b.name:upper();
        if (a.name == "Unknown") then return false; end;
        return an < bn;
    end);

    return tb;
end;

return {
    getGroupedGamesBy = getGroupedGamesBy
};
