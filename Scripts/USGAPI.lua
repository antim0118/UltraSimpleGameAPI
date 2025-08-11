--[[

    ___ USGAPI v1.0 by antim ___
    ________ 09.08.2025 ________
    https://github.com/antim0118
    https://t.me/atgamedev

]] --

if (_USGAPI_CACHE) then return _USGAPI_CACHE; end;

--#region CONSTANTS
local API_VERSION = "1.0.0";

local FONT_DEFAULT_SIZE = 16;
--#endregion

local sf = string.format;

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
    LUA.print(210, 5, sf("%.2fMb", LUA.getRAM() / 1024 / 1024));
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
local loadTexture = function(texturePath)
    local data = _texLoad(texturePath);
    local w, h = Image.W(data), Image.H(data);
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

--#region Fonts
---@type table<string, intraFontInstance>
local _drawTextCache = {};

local _fontLoad = intraFont.load;
local _fontPrint = intraFont.print;
local _fontWidth = intraFont.textW; --некорректно работает или типа того хзхз

---@param fontPath string
---@param x number
---@param y number
---@param text string
---@param color? ColorInstance
---@param fontScale? number
---@param useCameraPos? boolean
local drawText = function(fontPath, x, y, text, color, fontScale, useCameraPos)
    local font = _drawTextCache[fontPath];
    if (not font) then
        font = _fontLoad(fontPath, FONT_DEFAULT_SIZE);
        _drawTextCache[fontPath] = font;
    end;

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
---@param volume? number (0-100)
local playSound = function(path, volume)
    local channel = _playSoundCache[path];
    if (not channel) then
        local ext = path:sub(#path - 2);
        channel = getFreeChannel(ext);
        _soundLoad(path, channel, true);
        _playSoundCache[path] = channel;
    end;

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

-- ---Unloads all fonts
-- local unloadAllFonts = function()
--     local unload = intraFont.un;
--     for k, v in pairs(_drawTextureCache) do
--         unload(v);
--     end;
--     _drawTextureCache = {};
-- end;

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

    drawText = drawText,
    -- drawTextCenter = drawTextCenter,

    playSound = playSound,
    stopSound = stopSound,

    getGamePath = getGamePath,
    isEmulator = isEmulator,
    getAPIVersion = getAPIVersion,

    debugGetTextureSizes = debugGetTextureSizes,
    debugGetDrawCalls = debugGetDrawCalls,
    debugGetSoundCache = debugGetSoundCache,

    unloadAllTextures = unloadAllTextures,
    unloadAllSounds = unloadAllSounds,
    unloadAll = unloadAll
};

return _USGAPI_CACHE;
