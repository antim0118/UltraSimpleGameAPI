local USGAPI = require("Scripts.USGAPI");
local gamePath = USGAPI.getGamePath();

-- Config
local FONT = "Fonts/arial.ttf";
local SCREEN_WIDTH, SCREEN_HEIGHT = 480, 272;
local BG_WIDTH, BG_HEIGHT = 363, 272;
local BG_X = math.floor((SCREEN_WIDTH - BG_WIDTH) / 2);

-- Colors (cache for performance)
local colors = {
    white = Color.new(255, 255, 255),
    black = Color.new(0, 0, 0),
    blackOverlay = Color.new(0, 0, 0, 180),
    gray = Color.new(200, 200, 200),
    yellow = Color.new(255, 230, 120),
    cyan = Color.new(120, 220, 255),
    menuShadow = Color.new(0, 0, 0, 160),
};

-- Sound effects (SE) and background music (BGM)
local S = {
    move = gamePath .. "assets/se/sys003.wav",
    confirm = gamePath .. "assets/se/sys004.wav",
    advance = gamePath .. "assets/se/sys002.wav",
};

local BGM = {
    title = gamePath .. "assets/bgm/rakuen_short.at3",
    routeA = gamePath .. "assets/bgm/m01.at3",
    routeA2 = gamePath .. "assets/bgm/m04.at3",
    routeB = gamePath .. "assets/bgm/m02.at3",
    routeB2 = gamePath .. "assets/bgm/m06.at3",
};

local currentBGM = nil;
local function setBGM(path, volume)
    if currentBGM == path then return; end;
    if currentBGM then USGAPI.stopSound(currentBGM); end;
    if path then USGAPI.playSound(path, volume or 80); end;
    currentBGM = path;
end;

-- Simple helpers
local function clamp(v, lo, hi) if v < lo then return lo; elseif v > hi then return hi; else return v; end; end;

-- Text drawing helpers
local function drawTextShadowed(font, x, y, text, color, scale)
    USGAPI.drawText(font, x + 1, y + 1, text, colors.menuShadow, scale or 1.0);
    USGAPI.drawText(font, x, y, text, color or colors.white, scale or 1.0);
end;

-- New: character stand rendering (left/right)
local function drawStands(leftPath, rightPath)
    if leftPath and #leftPath > 0 then
        USGAPI.drawTexture(leftPath, 50, 0);
    end;
    if rightPath and #rightPath > 0 then
        USGAPI.drawTexture(rightPath, 200, 0);
    end;
end;

-- New: CG event rendering
local function drawCG(cgPath)
    if cgPath and #cgPath > 0 then
        USGAPI.drawTexture(cgPath, BG_X, 0);
    end;
    drawTextShadowed(FONT, SCREEN_WIDTH - 160, SCREEN_HEIGHT - 20, "X - Далее", colors.cyan, 0.8);
end;

local function wrapText(text, lineLen)
    -- naive wrapper by words; returns array of lines
    local lines = {};
    local current = "";
    for word in string.gmatch(text, "[^%s]+") do
        if #current == 0 then
            current = word;
        elseif #current + 1 + #word <= lineLen then
            current = current .. " " .. word;
        else
            table.insert(lines, current);
            current = word;
        end;
    end;
    if #current > 0 then table.insert(lines, current); end;
    return lines;
end;

-- VN script data (expanded with stands/CG and branching)
local scenes = {
    { kind = "title", bgm = BGM.title },
    {
        kind = "dialog",
        bg = gamePath .. "assets/cg/bg/bg_0010e.png",
        speaker = "Нарратор",
        text = "Тёмная комната. Тишина давит. Так всё и начинается...",
        standLeft = nil,
        standRight = nil,
        bgm = BGM.routeA, -- вступление игровой части
    },
    {
        kind = "dialog",
        bg = gamePath .. "assets/cg/bg/bg_0013c.png",
        speaker = "Нэму",
        text = "Ты проснулся? Нам пора решить, куда идти дальше.",
        standLeft = gamePath .. "assets/cg/stand/01_nem/st_nem01_1116c.png",
        standRight = nil,
    },
    {
        kind = "choice",
        bg = gamePath .. "assets/cg/bg/bg_0013c.png",
        prompt = "Куда отправиться?",
        options = {
            { label = "Пойти с Нэму", nextIndex = 5 },
            { label = "Остаться в комнате", nextIndex = 27 },
        }
    },
    -- Branch A: Follow Nemu (5..26)
    { kind = "cg",    cg = gamePath .. "assets/cg/ev/ev_nem_t01_01.png", bgm = BGM.routeA }, -- 5
    {
        kind = "dialog",
        bg = gamePath .. "assets/cg/bg/bg_0050a.png",
        speaker = "Нарратор",
        text = "Вы идёте за Нэму... Впереди ждут ответы и новые вопросы.",
        standLeft = gamePath .. "assets/cg/stand/01_nem/st_nem01_1105c.png",
        standRight = nil,
    },
    {
        kind = "dialog",
        bg = gamePath .. "assets/cg/bg/bg_1010d.png",
        speaker = "Нэму",
        text = "Коридор тянется. Здесь редко кто ходит — поэтому тихо.",
        standLeft = gamePath .. "assets/cg/stand/01_nem/st_nem01_1113c.png",
        standRight = nil,
    },
    {
        kind = "dialog",
        bg = gamePath .. "assets/cg/bg/bg_1011a.png",
        speaker = "Нарратор",
        text = "Свет люминесцентных ламп мерцал, словно нерешительная мысль.",
        standLeft = nil,
        standRight = nil,
        bgm = BGM.routeA2,
    },
    {
        kind = "dialog",
        bg = gamePath .. "assets/cg/bg/bg_1020d.png",
        speaker = "Нэму",
        text = "Сюда. Я кое-что хочу показать.",
        standLeft = gamePath .. "assets/cg/stand/01_nem/st_nem01_1116b.png",
        standRight = nil,
    },
    { kind = "cg", cg = gamePath .. "assets/cg/ev/ev_op_t01_01.png" },
    {
        kind = "dialog",
        bg = gamePath .. "assets/cg/bg/bg_1023a.png",
        speaker = "Нарратор",
        text = "За дверью оказалась небольшая смотровая. Снизу — город, сверху — серое небо.",
        standLeft = nil,
        standRight = nil,
    },
    {
        kind = "dialog",
        bg = gamePath .. "assets/cg/bg/bg_1020f.png",
        speaker = "Нэму",
        text = "Иногда полезно посмотреть со стороны. Так легче услышать себя.",
        standLeft = gamePath .. "assets/cg/stand/01_nem/st_nem01_1105c.png",
        standRight = nil,
    },
    {
        kind = "dialog",
        bg = gamePath .. "assets/cg/bg/bg_1030b.png",
        speaker = "Нарратор",
        text = "Ветер мягко толкал облака. Мы молчали какое-то время.",
        standLeft = nil,
        standRight = nil,
    },
    {
        kind = "dialog",
        bg = gamePath .. "assets/cg/bg/bg_1040d.png",
        speaker = "Нэму",
        text = "Я не прошу верить слепо. Просто идём. Если станет не по себе — вернёмся.",
        standLeft = gamePath .. "assets/cg/stand/01_nem/st_nem02_1115c.png",
        standRight = nil,
    },
    { kind = "cg", cg = gamePath .. "assets/cg/ev/ev_nem_t03_01.png" },
    {
        kind = "dialog",
        bg = gamePath .. "assets/cg/bg/bg_1040e.png",
        speaker = "Нарратор",
        text = "На лестнице пахло железом. Под ногами звенели ступени.",
        standLeft = nil,
        standRight = nil,
    },
    {
        kind = "dialog",
        bg = gamePath .. "assets/cg/bg/bg_1050c.png",
        speaker = "Нэму",
        text = "Ещё немного.",
        standLeft = gamePath .. "assets/cg/stand/01_nem/st_nem02_1111bt.png",
        standRight = nil,
    },
    {
        kind = "dialog",
        bg = gamePath .. "assets/cg/bg/bg_2010d.png",
        speaker = "Нарратор",
        text = "Мы вышли во внутренний двор. Здесь было удивительно тихо, почти как в начале пути.",
        standLeft = nil,
        standRight = nil,
    },
    { kind = "cg", cg = gamePath .. "assets/cg/ev/ev_st_nem_02.png" },
    {
        kind = "dialog",
        bg = gamePath .. "assets/cg/bg/bg_2020c.png",
        speaker = "Нэму",
        text = "Спасибо, что идёшь со мной. Иногда этого достаточно, чтобы всё сдвинулось.",
        standLeft = gamePath .. "assets/cg/stand/01_nem/st_nem01_1102c.png",
        standRight = nil,
    },
    {
        kind = "dialog",
        bg = gamePath .. "assets/cg/bg/bg_2021a.png",
        speaker = "Нарратор",
        text = "Мы сидели на ступенях и смотрели на мигающие окна. Время тянулось мягко и незаметно.",
        standLeft = nil,
        standRight = nil,
        bgm = BGM.routeA,
    },
    { kind = "cg", cg = gamePath .. "assets/cg/ev/ev_nem_t06_02.png" },
    {
        kind = "dialog",
        bg = gamePath .. "assets/cg/bg/bg_2030a.png",
        speaker = "Нэму",
        text = "Пора возвращаться. Завтра продолжим.",
        standLeft = gamePath .. "assets/cg/stand/01_nem/st_nem01_1116c.png",
        standRight = nil,
    },
    {
        kind = "dialog",
        bg = gamePath .. "assets/cg/bg/bg_2032a.png",
        speaker = "Нарратор",
        text = "Мы поднялись и пошли назад. Шаги звучали увереннее, чем раньше.",
        standLeft = nil,
        standRight = nil,
    },
    { kind = "cg", cg = gamePath .. "assets/cg/ev/ev_op_t01_02.png" },
    {
        kind = "dialog",
        bg = gamePath .. "assets/cg/bg/bg_2035a.png",
        speaker = "Нарратор",
        text = "Продолжение следует...",
        standLeft = nil,
        standRight = nil,
        nextIndex = 1, -- jump to title end
    },

    -- Branch B: Stay in the room (27..44)
    {
        kind = "dialog",
        bg = gamePath .. "assets/cg/bg/bg_0010e.png",
        speaker = "Нарратор",
        text = "Вы остались. Комната будто стала ещё тише.",
        standLeft = nil,
        standRight = nil,
        bgm = BGM.routeB,
    }, -- 27
    { kind = "cg", cg = gamePath .. "assets/cg/ev/ev_st_nem_01.png" },
    {
        kind = "dialog",
        bg = gamePath .. "assets/cg/bg/bg_0011a.png",
        speaker = "Нэму",
        text = "Хорошо. Тогда просто посидим. Иногда и это — выбор.",
        standLeft = gamePath .. "assets/cg/stand/01_nem/st_nem01_1101an.png",
        standRight = nil,
    },
    {
        kind = "dialog",
        bg = gamePath .. "assets/cg/bg/bg_0011b.png",
        speaker = "Нарратор",
        text = "Стрелка часов отмеряла секунды. С каждым щелчком становилось яснее, чего вы хотите на самом деле.",
        standLeft = nil,
        standRight = nil,
        bgm = BGM.routeB2,
    },
    { kind = "cg", cg = gamePath .. "assets/cg/ev/ev_nem_t01_03.png" },
    {
        kind = "dialog",
        bg = gamePath .. "assets/cg/bg/bg_0011c.png",
        speaker = "Нэму",
        text = "Когда будешь готов — скажи. Мы никуда не торопимся.",
        standLeft = gamePath .. "assets/cg/stand/01_nem/st_nem01_1102b.png",
        standRight = nil,
    },
    {
        kind = "dialog",
        bg = gamePath .. "assets/cg/bg/bg_0013a.png",
        speaker = "Нарратор",
        text = "Дверь оставалась закрытой, но внутри что-то сдвинулось.",
        standLeft = nil,
        standRight = nil,
    },
    { kind = "cg", cg = gamePath .. "assets/cg/ev/ev_st_nem_03.png" },
    {
        kind = "dialog",
        bg = gamePath .. "assets/cg/bg/bg_0013b.png",
        speaker = "Нэму",
        text = "Улыбка — уже движение. Пойдём чуть позже.",
        standLeft = gamePath .. "assets/cg/stand/01_nem/st_nem01_1113b.png",
        standRight = nil,
    },
    {
        kind = "dialog",
        bg = gamePath .. "assets/cg/bg/bg_0013d.png",
        speaker = "Нарратор",
        text = "Чай остыл, но разговор — нет. Слова текли спокойно и легко.",
        standLeft = nil,
        standRight = nil,
    },
    { kind = "cg", cg = gamePath .. "assets/cg/ev/ev_nem_t06_01.png" },
    {
        kind = "dialog",
        bg = gamePath .. "assets/cg/bg/bg_0013e.png",
        speaker = "Нэму",
        text = "Теперь — давай попробуем ещё раз. Только шаг за шагом.",
        standLeft = gamePath .. "assets/cg/stand/01_nem/st_nem02_1116ct.png",
        standRight = nil,
    },
    {
        kind = "dialog",
        bg = gamePath .. "assets/cg/bg/bg_0024a.png",
        speaker = "Нарратор",
        text = "Мы поднялись и аккуратно открыли дверь. Коридор встретил знакомой тишиной.",
        standLeft = nil,
        standRight = nil,
    },
    { kind = "cg", cg = gamePath .. "assets/cg/ev/ev_op_t01_03.png" },
    {
        kind = "dialog",
        bg = gamePath .. "assets/cg/bg/bg_0030a.png",
        speaker = "Нэму",
        text = "Видишь? Иногда всё проще, чем кажется.",
        standLeft = gamePath .. "assets/cg/stand/01_nem/st_nem01_1113an.png",
        standRight = nil,
    },
    {
        kind = "dialog",
        bg = gamePath .. "assets/cg/bg/bg_0031a.png",
        speaker = "Нарратор",
        text = "Мы сделали несколько шагов — и стало ясно: дальше мы справимся.",
        standLeft = nil,
        standRight = nil,
    },
    { kind = "cg", cg = gamePath .. "assets/cg/ev/ev_nem_t10_04.png" },
    {
        kind = "dialog",
        bg = gamePath .. "assets/cg/bg/bg_0033c.png",
        speaker = "Нарратор",
        text = "Продолжение следует...",
        standLeft = nil,
        standRight = nil,
        nextIndex = 1, -- jump to title end
    },
};

-- If a choice option has nextIndex = nil, continue linearly (wrap to title at end)
local function resolveNextIndex(currentIndex)
    if currentIndex + 1 > #scenes then return 1; else return currentIndex + 1; end;
end;

-- UI drawing
local function drawTitle()
    -- Use title background if present, fallback to black
    local titleBg = gamePath .. "assets/cgsys/title/back.png";
    USGAPI.drawTexture(titleBg, BG_X, 0);
    drawTextShadowed(FONT, 80, 40, "Euphoria", colors.white, 2.0);
    drawTextShadowed(FONT, 80, 90, "Нажмите X, чтобы начать", colors.cyan, 1.2);
end;

local function drawTextbox()
    local boxHeight = 90;
    USGAPI.fillRect(0, SCREEN_HEIGHT - boxHeight, SCREEN_WIDTH, boxHeight, colors.blackOverlay);
    USGAPI.drawRect(0, SCREEN_HEIGHT - boxHeight, SCREEN_WIDTH - 1, boxHeight - 1, colors.gray);
end;

-- Updated: accepts stand paths to draw characters
local function drawDialog(bgPath, speaker, text, standLeft, standRight)
    if bgPath then USGAPI.drawTexture(bgPath, BG_X, 0); end;
    drawStands(standLeft, standRight);
    drawTextbox();
    if speaker and #speaker > 0 then
        drawTextShadowed(FONT, 18, SCREEN_HEIGHT - 80, speaker .. ":", colors.yellow, 1.0);
    end;
    local wrapped = wrapText(text or "", 56);
    local startY = SCREEN_HEIGHT - 60;
    local lineH = 18;
    for i = 1, math.min(#wrapped, 3) do
        drawTextShadowed(FONT, 18, startY + (i - 1) * lineH, wrapped[i], colors.white, 1.0);
    end;
    drawTextShadowed(FONT, SCREEN_WIDTH - 160, SCREEN_HEIGHT - 20, "X - Далее", colors.cyan, 0.8);
end;

-- Updated: choice buttons using cgsys assets
local function drawChoices(bgPath, prompt, options, selected)
    if bgPath then USGAPI.drawTexture(bgPath, BG_X, 0); end;
    -- choice background if exists
    local cselBack = gamePath .. "assets/cgsys/csel/back.png";
    USGAPI.drawTexture(cselBack, BG_X, 0);

    drawTextbox();
    drawTextShadowed(FONT, 18, SCREEN_HEIGHT - 80, prompt or "", colors.yellow, 1.0);

    local x = 26;
    local y0 = SCREEN_HEIGHT - 64;
    local spacing = 22;

    for i, opt in ipairs(options) do
        local isSel = (i == selected);
        drawTextShadowed(FONT, x + 10, y0 + (i - 1) * spacing + 4, opt.label or "",
            isSel and colors.cyan or colors.white, 1.0);
    end;

    drawTextShadowed(FONT, SCREEN_WIDTH - 250, SCREEN_HEIGHT - 20, "ВВЕРХ/ВНИЗ, X - Выбор", colors.cyan, 0.8);
end;

-- State
local state = {
    index = 1,
    selectedChoice = 1,
};

-- Main loop
while true do
    USGAPI.startFrame();

    local node = scenes[state.index];
    if not node then
        state.index = 1; node = scenes[state.index];
    end;

    if (LUA.getRAM() < 10485760) then --10mb
        USGAPI.unloadAllTextures();
    end;

    -- Apply per-scene BGM if specified
    if node.bgm ~= nil then setBGM(node.bgm, 80); end;

    if node.kind == "title" then
        drawTitle();
        if buttons.pressed(buttons.cross) then
            USGAPI.playSound(S.confirm, 80);
            state.index = resolveNextIndex(state.index);
        end;
    elseif node.kind == "dialog" then
        drawDialog(node.bg, node.speaker, node.text, node.standLeft, node.standRight);
        if buttons.pressed(buttons.cross) or buttons.pressed(buttons.circle) then
            USGAPI.playSound(S.advance, 25);
            if node.nextIndex and scenes[node.nextIndex] then
                state.index = node.nextIndex;
            else
                state.index = resolveNextIndex(state.index);
            end;
        end;
    elseif node.kind == "cg" then
        drawCG(node.cg);
        if buttons.pressed(buttons.cross) or buttons.pressed(buttons.circle) then
            USGAPI.playSound(S.advance, 25);
            if node.nextIndex and scenes[node.nextIndex] then
                state.index = node.nextIndex;
            else
                state.index = resolveNextIndex(state.index);
            end;
        end;
    elseif node.kind == "choice" then
        state.selectedChoice = clamp(state.selectedChoice, 1, #node.options);
        drawChoices(node.bg, node.prompt, node.options, state.selectedChoice);

        if buttons.pressed(buttons.up) then
            USGAPI.playSound(S.move, 70);
            state.selectedChoice = clamp(state.selectedChoice - 1, 1, #node.options);
        elseif buttons.pressed(buttons.down) then
            USGAPI.playSound(S.move, 70);
            state.selectedChoice = clamp(state.selectedChoice + 1, 1, #node.options);
        elseif buttons.pressed(buttons.cross) then
            USGAPI.playSound(S.confirm, 80);
            local chosen = node.options[state.selectedChoice];
            if chosen and chosen.nextIndex and scenes[chosen.nextIndex] then
                state.index = chosen.nextIndex;
            else
                state.index = resolveNextIndex(state.index);
            end;
            state.selectedChoice = 1;
        end;
    else
        state.index = resolveNextIndex(state.index);
    end;

    if (buttons.pressed(buttons.start)) then
        break;
    end;
end;
