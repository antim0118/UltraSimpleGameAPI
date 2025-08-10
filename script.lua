require('Utils.Load');
require('Scripts.Tasks');
local USGAPI = require('Scripts.USGAPI');
local UI = require('Scripts.UI');

while true do
    USGAPI.startFrame();
    UI.update();
    UI.drawXMB();
    UI.drawGames();
end;
