local lastSecond = "0";
local countedFrames = 0;
local FPS = 60;

---@return integer
LUA.getFPS = function()
    local seconds = System.getTime().seconds;
    if lastSecond ~= seconds then
        lastSecond = seconds;
        FPS = countedFrames;
        countedFrames = 0;
    end
    countedFrames = countedFrames + 1;
    return FPS;
end
