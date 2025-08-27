--[[

    ___ USGAPI v1.1.0 by antim ___
    _________ 12.08.2025 _________
    https://github.com/antim0118
    https://t.me/atgamedev

]] --

if (_USGAPI_CACHE) then return _USGAPI_CACHE; end;

--#region CONSTANTS
local API_VERSION = "1.1.0";

local FONT_DEFAULT_SIZE = 16;
--#endregion

--#region SHORTINGS
local sf = string.format;
local floor = math.floor;
local icontains = table.icontains;
local lower, sub = string.lower, string.sub;
local type = type;
--#endregion

local _drawCalls = 0;

local _white = Color.new(255, 255, 255);

--#region Buttons
local _buttonsRead = buttons.read;

--#endregion

--#region Screen
local _screenClear = screen.clear;
local _screenFlip = screen.flip;

---@param color? ColorInstance
local startFrame = function(color)
    LUA.print(180, 2, sf("FPS: %d / %.2fMb", LUA.getFPS(), LUA.getRAM() / 1024 / 1024));
    _screenFlip();
    if (color) then
        _screenClear(color);
    else
        _screenClear();
    end;
    _buttonsRead();
    _drawCalls = 0;
end;
--#endregion

--#region Camera
local cameraX, cameraY = 0, 0;
local setCameraPos = function(x, y)
    cameraX, cameraY = x, y;
end;

---@return integer cameraX, integer cameraY
local getCameraPos = function()
    return cameraX, cameraY;
end;
--#endregion

--#region Rendering (draw)
local _texDrawEasy, _texDraw = Image.draweasy, Image.draw;
local _texLoad = Image.load;

---@alias USGAPITexture { data: ImageInstance, w: number, h: number, size: number }

---@type table<string, USGAPITexture>
local _drawTextureCache = {};

---@param texturePath string Path to texture
---@return USGAPITexture
local loadTexture = function(texturePath)
    local data = _texLoad(texturePath);
    local w, h = Image.W(data), Image.H(data);
    ---@type USGAPITexture
    local tex = {
        data = data,
        w = w,
        h = h,
        size = w * h * 4
    };
    _drawTextureCache[texturePath] = tex;
    return tex;
end;

---@param texturePath string Path to texture
---@param x number
---@param y number
---@param angle? number Rotation (0-360)
---@param alpha? number Alpha (0-255)
---@param color? ColorInstance
local drawTexture = function(texturePath, x, y, angle, alpha, color)
    local tex = _drawTextureCache[texturePath];
    if (not tex) then tex = loadTexture(texturePath); end;

    x, y = x - cameraX, y - cameraY;

    --dont render outside of screen
    local w, h = tex.w, tex.h;
    if (not angle or angle == 0) then
        if (x + w < 0 or x > 480
                or y + h < 0 or y > 272) then
            return;
        end;
    else
        local ww, hh = w * 3 / 2, h * 3 / 2;
        if (x + ww < 0 or x - ww > 480
                or y + hh < 0 or y - hh > 272) then
            return;
        end;
    end;

    if (not angle and not alpha) then
        _texDrawEasy(tex.data, x, y, color);
    else
        angle = angle or 0;
        alpha = alpha or 255;
        _texDrawEasy(tex.data, x, y, color, angle, alpha);
    end;

    _drawCalls = _drawCalls + 1;
end;

---@param texturePath string Path to texture
---@param x number
---@param y number
---@param w number
---@param h number
---@param angle? number Rotation (0-360)
---@param alpha? number Alpha (0-255)
---@param color? ColorInstance
local drawTextureSized = function(texturePath, x, y, w, h, angle, alpha, color)
    local tex = _drawTextureCache[texturePath];
    if (not tex) then tex = loadTexture(texturePath); end;

    x, y = x - cameraX, y - cameraY;

    --dont render outside of screen
    if (not angle or angle == 0) then
        if (x + w < 0 or x > 480
                or y + h < 0 or y > 272) then
            return;
        end;
    else
        local ww, hh = w * 3 / 2, h * 3 / 2;
        if (x + ww < 0 or x - ww > 480
                or y + hh < 0 or y - hh > 272) then
            return;
        end;
    end;

    if (not angle and not alpha) then
        _texDraw(tex.data, x, y, w, h, color);
    else
        angle = angle or 0;
        alpha = alpha or 255;
        _texDraw(tex.data, x, y, w, h, color, 0, 0, tex.w, tex.h, angle, alpha);
    end;
    _drawCalls = _drawCalls + 1;
end;

---@param texturePath string Path to texture
---@param x number
---@param y number
---@param angle? number Rotation (0-360)
---@param alpha? number Alpha (0-255)
---@param color? ColorInstance
local drawUITexture = function(texturePath, x, y, angle, alpha, color)
    local tex = _drawTextureCache[texturePath];
    if (not tex) then tex = loadTexture(texturePath); end;

    angle = angle or 0;
    alpha = alpha or 255;

    _texDrawEasy(tex.data, x, y, color, angle, alpha);
    _drawCalls = _drawCalls + 1;
end;

local _drawLine = screen.drawLine;
local _drawCircle = screen.drawCircle;
local _fillRect = screen.filledRect;

---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
---@param color ColorInstance
---@param useCameraPos? boolean
local drawLine = function(x1, y1, x2, y2, color, useCameraPos)
    if (useCameraPos) then
        x1, y1 = x1 - cameraX, y1 - cameraY;
        x2, y2 = x2 - cameraX, y2 - cameraY;
    end;
    _drawLine(x1, y1, x2, y2, color);
    _drawCalls = _drawCalls + 1;
end;

---@param x number
---@param y number
---@param radius number
---@param color ColorInstance
---@---@param useCameraPos? boolean
local drawCircle = function(x, y, radius, color, useCameraPos)
    if (useCameraPos) then
        x, y = x - cameraX, y - cameraY;
    end;
    _drawCircle(x, y, radius, color);
    _drawCalls = _drawCalls + 1;
end;

---@param x number
---@param y number
---@param width number
---@param height number
---@param color ColorInstance
---@param useCameraPos? boolean
local drawRect = function(x, y, width, height, color, useCameraPos)
    local x2, y2 = x + width, y + height;
    if (useCameraPos) then
        x, y = x - cameraX, y - cameraY;
        x2, y2 = x2 - cameraX, y2 - cameraY;
    end;
    _drawLine(x, y, x2, y, color);
    _drawLine(x, y, x, y2, color);
    _drawLine(x2, y2, x2, y, color);
    _drawLine(x2, y2, x, y2, color);
    _drawCalls = _drawCalls + 4;
end;

---отрисовка прямоугольника
---@param x number положение на оси x
---@param y number положение на оси y
---@param width number ширина прямоугольника
---@param height number высота прямоугольника
---@param color ColorInstance цвет прямоугольника
---@param useCameraPos? boolean
local fillRect = function(x, y, width, height, color, useCameraPos)
    if (useCameraPos) then
        x, y = x - cameraX, y - cameraY;
    end;
    _fillRect(x, y, width, height, color);
    _drawCalls = _drawCalls + 1;
end;
--#endregion

--#region Tiles

---@alias USGAPITile { tex:ImageInstance, srcX:integer, srcY:integer, srcW: integer, srcH: integer, x: integer, y: integer, w: integer, h: integer }
---@alias USGAPITileChunks table<integer, table<integer, USGAPITile[]>> [cameraX/gap][cameraY/gap][]

---@type USGAPITile[]
local _drawTileCache = {};
local _drawTileCacheCount = 0;

---@type USGAPITileChunks [cameraX/gap][cameraY/gap][]
local _drawTileCacheChunks = {};
local _drawTileCacheChunksGap = 1;

---@param texturePath string
---@param srcX integer
---@param srcY integer
---@param srcW integer
---@param srcH integer
---@param targetX integer
---@param targetY integer
---@param targetW? integer
---@param targetH? integer
local addTile = function(texturePath, srcX, srcY, srcW, srcH, targetX, targetY, targetW, targetH)
    local tex = _drawTextureCache[texturePath];
    if (not tex) then tex = loadTexture(texturePath); end;

    ---@type USGAPITile
    local newTile = {
        tex = tex.data,
        srcX = srcX,
        srcY = srcY,
        srcW = srcW,
        srcH = srcH,
        x = targetX,
        y = targetY,
        w = targetW or srcW,
        h = targetH or srcH
    };

    -- check if it was already added
    for i = 1, _drawTileCacheCount do
        local tile = _drawTileCache[i];
        if (tile.tex == tex
                and tile.srcX == srcX and tile.srcY == srcY
                and tile.srcW == srcW and tile.srcH == srcH
                and tile.x == targetX and tile.y == targetY
                and tile.w == newTile.w and tile.h == newTile.h) then
            return;
        end;
    end;

    _drawTileCache[#_drawTileCache + 1] = newTile;
    _drawTileCacheCount = #_drawTileCache;
end;

---@param gap? integer [default = 128]
---@param leftRightMargin? integer [default = 0]
---@param topBottomMargin? integer [default = 0]
---@return USGAPITileChunks chunks [cameraX/gap][cameraY/gap][]
local optimizeTiles = function(gap, leftRightMargin, topBottomMargin)
    gap = gap or 128;
    leftRightMargin = leftRightMargin or 0;
    topBottomMargin = topBottomMargin or 0;

    ---@type USGAPITileChunks [cameraX/gap][cameraY/gap][]
    local chunks = {};

    for i = 1, _drawTileCacheCount do
        local tile = _drawTileCache[i];
        local x, y, w, h = tile.x, tile.y, tile.w, tile.h;

        local leftChunk = floor((x - 480 + leftRightMargin) / gap);
        local rightChunk = floor((x + w - leftRightMargin) / gap);
        local topChunk = floor((y - 272 + topBottomMargin) / gap);
        local bottomChunk = floor((y + h - topBottomMargin) / gap);

        for xc = leftChunk, rightChunk do
            if (not chunks[xc]) then
                chunks[xc] = {};
            end;
            local xChunk = chunks[xc];

            for yc = topChunk, bottomChunk do
                if (not xChunk[yc]) then
                    xChunk[yc] = {};
                end;
                local xyChunk = xChunk[yc];

                xyChunk[#xyChunk + 1] = tile;
            end;
        end;
    end;

    _drawTileCacheChunks = chunks;
    _drawTileCacheChunksGap = gap;

    collectgarbage();
    return chunks;
end;


local drawTiles = function()
    local chunkX = _drawTileCacheChunks[floor(cameraX / _drawTileCacheChunksGap)];
    if (not chunkX) then return; end;
    local chunk = chunkX[floor(cameraY / _drawTileCacheChunksGap)];
    if (not chunk) then return; end;

    for i = 1, #chunk do
        local tile = chunk[i];
        local x, y = tile.x - cameraX, tile.y - cameraY;
        if (x < 480 and y < 272) then
            local w, h = tile.w, tile.h;
            if (x + w > 0 and y + h > 0) then
                _texDraw(tile.tex, x, y, w, h, nil,
                    tile.srcX, tile.srcY, w, h, 0, 255, 0, false, true);
                -- drawRect(x, y, w, h, Color.new(255, 0, 0, 128));
            end;
        end;
    end;
end;

local clearAllTiles = function()
    _drawTileCache = {};
    _drawTileCacheCount = 0;
    _drawTileCacheChunks = {};
end;

---@return integer
local getTilesCount = function()
    return _drawTileCacheCount;
end;
--#endregion

--#region Fonts
---@type table<string, intraFontInstance>
local _drawTextCache = {};

local _fontLoad = intraFont.load;
local _fontPrint = intraFont.print;
local _fontWidth = intraFont.textW; --некорректно работает или типа того хзхз

---@param fontPath string
---@return intraFontInstance
local loadFont = function(fontPath)
    local font = _fontLoad(fontPath, FONT_DEFAULT_SIZE);
    _drawTextCache[fontPath] = font;
    return font;
end;

---@param fontPath string
---@param x number
---@param y number
---@param text string
---@param color? ColorInstance
---@param fontScale? number
---@param useCameraPos? boolean
local drawText = function(fontPath, x, y, text, color, fontScale, useCameraPos)
    local font = _drawTextCache[fontPath];
    if (not font) then font = loadFont(fontPath); end;

    color = color or _white;

    if (useCameraPos) then
        x, y = x - cameraX, y - cameraY;
    end;

    --dont render outside of screen
    if (x + 480 < 0 or x > 480
            or y + FONT_DEFAULT_SIZE < 0 or y > 272) then
        return;
    end;

    _fontPrint(x, y, text, color, font, fontScale);
    _drawCalls = _drawCalls + 1;
end;

-- ---@param fontPath string
-- ---@param x number
-- ---@param y number
-- ---@param text string
-- ---@param color? ColorInstance
-- ---@param fontScale? number
-- ---@param useCameraPos? boolean
-- local drawTextCenter = function(fontPath, x, y, text, color, fontScale, useCameraPos)
--     local font = _drawTextCache[fontPath];
--     if (not font) then
--         local data = _fontLoad(fontPath, FONT_DEFAULT_SIZE);
--         font = {
--             data = data,
--             w = {}
--         };
--         _drawTextCache[fontPath] = font;
--     end;

--     color = color or _white;

--     if (useCameraPos) then
--         x, y = x - cameraX, y - cameraY;
--     end;

--     local w = font.w;
--     if (not w[text]) then
--         w[text] = _fontWidth(font.data, text) / 4 * fontScale;
--     end;
--     print("width", w[text]);

--     _fontPrint(x - w[text], y, text, color, font.data, fontScale);
--     _drawCalls = _drawCalls + 1;
-- end;

--#endregion

--#region Sounds
local _soundLoad, _soundPlay, _soundUnload, _soundVolume, _soundStop = sound.cloud, sound.play, sound.unload,
    sound.volume, sound.stop;

---@type table<string, soundEnum|soundNumber>
local _playSoundCache = {};

---@type soundNumber
local last_channel_wav, last_channel_at3 = sound.WAV_1, sound.AT3_1;

---@param last_channel soundNumber
---@param from soundNumber
---@param to soundNumber
---@return soundNumber
---@nodiscard
local function caster_get_next_channel(last_channel, from, to)
    last_channel = last_channel + 1;
    if (last_channel > to) then last_channel = from; end;
    return last_channel;
end;

---@param ext 'wav'|'at3'|'mp3'
---@return soundEnum|soundNumber
local getFreeChannel = function(ext) return 1; end;

---@param ext 'wav'|'at3'|'mp3'
---@return soundEnum|soundNumber
getFreeChannel = function(ext)
    local channel = 0;
    if (ext == "wav") then
        last_channel_wav = caster_get_next_channel(last_channel_wav, 17, 47);
        channel = last_channel_wav;
    elseif (ext == "at3") then
        last_channel_at3 = caster_get_next_channel(last_channel_at3, 5, 6);
        channel = last_channel_at3;
    else --if (format == "mp3") then
        channel = sound.MP3;
    end;
    local state = sound.state(channel);
    if (state.state == "playing") then
        _soundStop(channel);
        _soundUnload(channel);
    elseif (state.state == "paused") then
        return getFreeChannel(ext);
    end;
    return channel;
end;

---@param path string
---@return soundEnum|soundNumber
local loadSound = function(path)
    local ext = path:sub(#path - 2);
    local channel = getFreeChannel(ext);
    _soundLoad(path, channel, true);
    _playSoundCache[path] = channel;
    return channel;
end;

---@param path string
---@param volume? number (0-100)
local playSound = function(path, volume)
    local channel = _playSoundCache[path];
    if (not channel) then channel = loadSound(path); end;

    volume = volume or 100;

    _soundStop(channel);
    _soundVolume(channel, volume, volume);
    _soundPlay(channel);
end;

local stopSound = function(path)
    local channel = _playSoundCache[path];
    if (not channel) then return; end;
    _soundStop(channel);
end;
--#endregion

--#region Preloader
local PRELOAD_TEXTURE_FORMATS = { ".png", ".jpg", "jpeg", ".bmp" };
local PRELOAD_SOUND_FORMATS = { ".wav", ".mp3", ".at3", ".ogg" };
local PRELOAD_FONT_FORMATS = { ".pgf", ".ttf", ".otf" };

---@param path string
local preloadAsset = function(path)
    local t = type(path);
    if (t ~= "string") then return; end;

    local len = #path;
    if (len < 4) then return; end;

    local ext = sub(lower(path), #path - 3);

    if (icontains(PRELOAD_TEXTURE_FORMATS, ext)) then
        if (not _drawTextureCache[path]) then
            loadTexture(path);
        end;
    elseif (icontains(PRELOAD_SOUND_FORMATS, ext)) then
        if (not _playSoundCache[path]) then
            loadSound(path);
        end;
    elseif (icontains(PRELOAD_FONT_FORMATS, ext)) then
        if (not _drawTextCache[path]) then
            loadFont(path);
        end;
    else
        print("[USGAPI] preload: unknown extension - ", ext);
    end;
end;

---@param ... (string|string[])
local preload = function(...)
    for i = 1, #arg do
        local v = arg[i];
        local t = type(v);
        if (t == "table") then
            for i1 = 1, #v do
                preloadAsset(v[i1]);
            end;
        else
            preloadAsset(v);
        end;
    end;
end;
--#endregion

--#region Basic
local getGamePath = function()
    local info = debug.getinfo(2, "S");
    return info.short_src:match("^(.*/)[^/]*$");
end;

local isEmulator = function()
    return System.getNickname() == "PPSSPP";
end;

---@return string version major.minor.patch
local getAPIVersion = function()
    return API_VERSION;
end;
--#endregion

--#region Debug

---Get string containing all the textures sizes
---@return string
local debugGetTextureSizes = function()
    local str = "Textures:\n";
    for texName, tex in pairs(_drawTextureCache) do
        str = str .. sf('%s: %.2fKb\n', texName, tex.size / 1024);
    end;
    return str;
end;

---Returns draw calls per frame
---@return integer
local debugGetDrawCalls = function()
    return _drawCalls;
end;

---Returns string of loaded sounds
---@return string
local debugGetSoundCache = function()
    local str = "Sound cache:\n";
    for sndName, channel in pairs(_playSoundCache) do
        local channelName = tostring(channel);
        for k, v in pairs(sound) do
            if (v == channel) then channelName = k; end;
        end;
        str = str .. sf('%s: %s\n', sndName, channelName);
    end;
    return str;
end;
--#endregion

--#region Unloaders
---Unloads all textures
local unloadAllTextures = function()
    local unload = Image.unload;
    for k, v in pairs(_drawTextureCache) do
        unload(v.data);
    end;
    _drawTextureCache = {};
end;

---Unloads all fonts
local unloadAllFonts = function()
    local unload = intraFont.unload;
    for k, v in pairs(_drawTextCache) do
        unload(v);
    end;
    _drawTextCache = {};
end;

local unloadAllSounds = function()
    for path, channel in pairs(_playSoundCache) do
        _soundUnload(channel);
    end;

    _playSoundCache = {};
    last_channel_wav = sound.WAV_1;
    last_channel_at3 = sound.AT3_1;
end;

---Unloads everything
local unloadAll = function()
    unloadAllTextures();
    unloadAllSounds();
    unloadAllFonts();
    clearAllTiles();
end;
--#endregion

_USGAPI_CACHE = {
    startFrame = startFrame,

    setCameraPos = setCameraPos,
    getCameraPos = getCameraPos,

    drawTexture = drawTexture,
    drawTextureSized = drawTextureSized,
    drawUITexture = drawUITexture,
    drawLine = drawLine,
    drawCircle = drawCircle,
    drawRect = drawRect,
    fillRect = fillRect,

    addTile = addTile,
    clearAllTiles = clearAllTiles,
    drawTiles = drawTiles,
    optimizeTiles = optimizeTiles,
    getTilesCount = getTilesCount,

    drawText = drawText,
    -- drawTextCenter = drawTextCenter,

    playSound = playSound,
    stopSound = stopSound,

    preload = preload,

    getGamePath = getGamePath,
    isEmulator = isEmulator,
    getAPIVersion = getAPIVersion,

    debugGetTextureSizes = debugGetTextureSizes,
    debugGetDrawCalls = debugGetDrawCalls,
    debugGetSoundCache = debugGetSoundCache,

    unloadAllTextures = unloadAllTextures,
    unloadAllSounds = unloadAllSounds,
    unloadAllFonts = unloadAllFonts,
    unloadAll = unloadAll
};

return _USGAPI_CACHE;
