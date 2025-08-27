local USGAPI = require('Libs.USGAPI');

local gamePath = USGAPI.getGamePath();

while true do
    USGAPI.startFrame();

    USGAPI.drawTexture(gamePath .. "Tex.jpg", 10, 10);

    if (buttons.pressed(buttons.start)) then break; end;
end;

USGAPI.unloadAll();
