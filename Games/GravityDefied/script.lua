local USGAPI = require("Libs.USGAPI");

-- Кеш путей и цветов
local gamePath = USGAPI.getGamePath();
local assets = gamePath .. "assets/";

local colors = {
    white = Color.new(255, 255, 255),
    black = Color.new(0, 0, 0),
    red   = Color.new(220, 50, 50),
    green = Color.new(50, 220, 80),
    blue  = Color.new(60, 120, 240),
    gray  = Color.new(180, 180, 180),
    dark  = Color.new(50, 50, 50),
    sky   = Color.new(220, 235, 255),
    uiBg  = Color.new(0, 0, 0, 90),
};

-- Утилиты
local function clamp(v, mn, mx)
    if v < mn then return mn; end;
    if v > mx then return mx; end;
    return v;
end;

local function lerp(a, b, t)
    return a + (b - a) * t;
end;

local function degToRad(d)
    return d * math.pi / 180.0;
end;

local function radToDeg(r)
    return r * 180.0 / math.pi;
end;

-- Состояния игры
local STATE = { TITLE = 1, SELECT = 2, PLAYING = 3, FINISHED = 4 };
local state = STATE.TITLE;

-- Прогресс/медали в рамках сессии
-- medal: 0 - нет, 1 - бронза, 2 - серебро, 3 - золото
local levelBestMedal = { 0, 0, 0 };
local highestUnlocked = 1;

-- Данные уровней
local levels = {
    {
        name = "Level 1",
        points = {
            { x = 0,   y = 220 }, { x = 120, y = 220 }, { x = 200, y = 200 }, { x = 300, y = 210 },
            { x = 380, y = 190 }, { x = 500, y = 210 }, { x = 620, y = 210 }, { x = 760, y = 200 },
            { x = 880, y = 220 }, { x = 1000, y = 220 }
        },
        startX = 20,
        finishX = 980,
        timeThresholds = { gold = 12.0, silver = 18.0, bronze = 25.0 },
    },
    {
        name = "Level 2",
        points = {
            { x = 0,   y = 230 }, { x = 80, y = 230 }, { x = 120, y = 210 }, { x = 180, y = 190 },
            { x = 260, y = 210 }, { x = 340, y = 200 }, { x = 420, y = 210 }, { x = 520, y = 220 },
            { x = 600,  y = 180 }, { x = 700, y = 200 }, { x = 800, y = 180 }, { x = 900, y = 230 },
            { x = 1020, y = 230 }
        },
        startX = 10,
        finishX = 1000,
        timeThresholds = { gold = 16.0, silver = 24.0, bronze = 32.0 },
    },
    {
        name = "Level 3",
        points = {
            { x = 0,   y = 240 }, { x = 80, y = 240 }, { x = 140, y = 210 }, { x = 200, y = 180 },
            { x = 260, y = 210 }, { x = 320, y = 170 }, { x = 420, y = 190 }, { x = 520, y = 160 },
            { x = 620,  y = 200 }, { x = 700, y = 150 }, { x = 820, y = 220 }, { x = 940, y = 200 },
            { x = 1060, y = 240 }
        },
        startX = 10,
        finishX = 1040,
        timeThresholds = { gold = 20.0, silver = 30.0, bronze = 42.0 },
    },
};

-- Предрасчёт пределов уровня (ширина/высота)
local function computeBounds(level)
    local minX, maxX = 1e9, -1e9;
    local minY, maxY = 1e9, -1e9;
    for i = 1, #level.points do
        local p = level.points[i];
        if p.x < minX then minX = p.x; end;
        if p.x > maxX then maxX = p.x; end;
        if p.y < minY then minY = p.y; end;
        if p.y > maxY then maxY = p.y; end;
    end;
    return minX, maxX, minY, maxY;
end;

-- Вычисление высоты земли и угла касательной для заданного x
local function getGroundInfo(level, x)
    local pts = level.points;
    if x <= pts[1].x then
        local p1, p2 = pts[1], pts[2];
        local dx, dy = (p2.x - p1.x), (p2.y - p1.y);
        local angle = radToDeg(math.atan2(dy, dx));
        return p1.y, angle;
    end;
    for i = 1, #pts - 1 do
        local p1, p2 = pts[i], pts[i + 1];
        if x >= p1.x and x <= p2.x then
            local t = (x - p1.x) / (p2.x - p1.x);
            local y = lerp(p1.y, p2.y, t);
            local dx, dy = (p2.x - p1.x), (p2.y - p1.y);
            local angle = radToDeg(math.atan2(dy, dx));
            return y, angle;
        end;
    end;
    local pnm1, pn = pts[#pts - 1], pts[#pts];
    local dx, dy = (pn.x - pnm1.x), (pn.y - pnm1.y);
    local angle = radToDeg(math.atan2(dy, dx));
    return pn.y, angle;
end;

-- Рендер рельефа
local function drawGround(level)
    local camX, camY = USGAPI.getCameraPos();
    local pts = level.points;
    for i = 1, #pts - 1 do
        -- утолщаем рельеф двойной линией
        USGAPI.drawLine(pts[i].x - camX, pts[i].y - camY, pts[i + 1].x - camX, pts[i + 1].y - camY, colors.gray);
        USGAPI.drawLine(pts[i].x - camX, pts[i].y - camY + 1, pts[i + 1].x - camX, pts[i + 1].y - camY + 1, colors.dark);
    end;
end;

-- Рендер флажков старта/финиша
local function drawFlags(level)
    -- Анимированные спрайты, будем выбирать один из трёх по времени
    local frame = (os.time() % 3);
    local startTex = assets ..
        (frame == 0 and "s_flag_start0.png" or (frame == 1 and "s_flag_start1.png" or "s_flag_start2.png"));
    local finishTex = assets ..
        (frame == 0 and "s_flag_finish0.png" or (frame == 1 and "s_flag_finish1.png" or "s_flag_finish2.png"));
    -- Привязка к земле
    local sy = select(1, getGroundInfo(level, level.startX));
    local fy = select(1, getGroundInfo(level, level.finishX));
    USGAPI.drawTexture(startTex, level.startX - 4, sy - 64);
    USGAPI.drawTexture(finishTex, level.finishX - 4, fy - 74);
end;

-- Байк (состояние)
local player = {
    x = 0,
    y = 0,
    vx = 0,
    vy = 0,
    angle = 0,    -- градусы
    angleVel = 0, -- градусы/кадр
    onGround = false,
};

local function resetPlayer(level)
    player.x = level.startX;
    local gy = select(1, getGroundInfo(level, player.x));
    player.y = gy - 12;
    player.vx = 0;
    player.vy = 0;
    player.angle = 0;
    player.angleVel = 0;
    player.onGround = true;
end;

-- Параметры физики
local gravity = 0.35;
local accel = 0.12;
local brake = 0.20;
local maxSpeed = 4.2;
local friction = 0.02;

local alignStrengthGround = 0.2;  -- стремление угла к наклону поверхности (на земле)
local balanceInputGround = 0.9;   -- влияние кнопок Left/Right на угол на земле
local balanceInputAir = 1.4;      -- влияние кнопок Left/Right в воздухе (вращение)

local clearance = 12.0;           -- зазор до земли (центр рамы)
local crashAngleThreshold = 70.0; -- порог краша по рассогласованию с поверхностью

-- Камера
local camX, camY = 0, 0;

-- Выбранный уровень
local currentLevelIndex = 1;
local levelStartFrames = 0; -- кадры с начала уровня
local finishedTimeSec = 0;

-- Рендер байка (упрощённый)
local function drawBike()
    -- Параметры внешнего вида
    local wheelBase = 40;
    local wheelRadius = 10;
    local ang = degToRad(player.angle);
    local dx = math.cos(ang) * (wheelBase * 0.5);
    local dy = math.sin(ang) * (wheelBase * 0.5);

    local backX, backY = player.x - dx, player.y - dy;
    local frontX, frontY = player.x + dx, player.y + dy;

    -- колёса
    USGAPI.drawTexture(assets .. "s_wheel1.png", backX - wheelRadius, backY - wheelRadius);
    USGAPI.drawTexture(assets .. "s_wheel2.png", frontX - wheelRadius, frontY - wheelRadius);

    -- корпус/двигатель грубо в центре
    USGAPI.drawTexture(assets .. "s_engine.png", player.x - 12, player.y - 24);

    -- шлем над центром
    USGAPI.drawTexture(assets .. "s_helmet.png", player.x - 8, player.y - 38);
end;

-- Обновление физики
local function updatePhysics(level)
    -- Управление скоростью по X
    if buttons.held(buttons.r) or buttons.held(buttons.up) then
        player.vx = player.vx + accel;
    end;
    if buttons.held(buttons.l) or buttons.held(buttons.down) then
        player.vx = player.vx - brake;
        if player.vx < 0 then player.vx = 0; end;
    end;
    -- Сопротивление
    if player.vx > 0 then
        player.vx = player.vx - friction;
        if player.vx < 0 then player.vx = 0; end;
    end;
    player.vx = clamp(player.vx, 0, maxSpeed);

    -- Вертикальная динамика
    local gx, gyAngle = getGroundInfo(level, player.x);
    -- gyAngle возвращает угол наклона поверхности; gy - высота на x
    local gy = select(1, getGroundInfo(level, player.x));

    -- Проверка контакта: если ниже поверхности - прижимаем
    if player.y >= gy - clearance then
        player.onGround = true;
        player.y = gy - clearance;
        player.vy = 0;
    else
        player.onGround = false;
    end;

    if not player.onGround then
        player.vy = player.vy + gravity;
        -- кручение в воздухе
        if buttons.held(buttons.left) then
            player.angle = player.angle - balanceInputAir;
        elseif buttons.held(buttons.right) then
            player.angle = player.angle + balanceInputAir;
        end;
    else
        -- Выравнивание к наклону поверхности + влияние игрока
        local target = gyAngle;
        if buttons.held(buttons.left) then
            target = target - balanceInputGround;
        elseif buttons.held(buttons.right) then
            target = target + balanceInputGround;
        end;
        player.angle = lerp(player.angle, target, alignStrengthGround);
    end;

    -- Обновление позиции
    player.x = player.x + player.vx;
    player.y = player.y + player.vy;

    -- Повторная проверка контакта после перемещения
    gy = select(1, getGroundInfo(level, player.x));
    if player.y >= gy - clearance then
        player.onGround = true;
        player.y = gy - clearance;
        player.vy = 0;
    end;

    -- Краш: слишком большой угол относительно поверхности при касании
    local _, groundAngle = getGroundInfo(level, player.x);
    if player.onGround then
        if math.abs(player.angle - groundAngle) > crashAngleThreshold then
            return true; -- краш
        end;
    end;

    return false;
end;

-- Камера следует за байком
local function updateCamera(level)
    local minX, maxX, _, maxY = computeBounds(level);
    local levelWidth = maxX - minX;
    local levelHeight = maxY;

    local targetX = player.x - 240;
    local targetY = player.y - 136;
    camX = lerp(camX, targetX, 0.15);
    camY = lerp(camY, targetY, 0.20);

    camX = clamp(camX, 0, math.max(0, maxX - 480));
    camY = clamp(camY, 0, math.max(0, levelHeight - 272));

    USGAPI.setCameraPos(camX, camY);
end;

-- HUD
local function drawHUD(level)
    -- фон верхней панели
    USGAPI.fillRect(0, 0, 480, 24, colors.uiBg);

    -- Время (тень + текст)
    local seconds = levelStartFrames / 60.0;
    USGAPI.drawText("Fonts/arial.ttf", 9, 9, string.format("Время: %.2f c", seconds), colors.black);
    USGAPI.drawText("Fonts/arial.ttf", 8, 8, string.format("Время: %.2f c", seconds), colors.white);

    -- нижняя панель подсказок
    USGAPI.fillRect(0, 224, 480, 48, colors.uiBg);
    USGAPI.drawText("Fonts/arial.ttf", 9, 233, "R/▲ — газ,  L/▼ — тормоз,  ◄/► — баланс", colors.black);
    USGAPI.drawText("Fonts/arial.ttf", 8, 232, "R/▲ — газ,  L/▼ — тормоз,  ◄/► — баланс", colors.white);
    USGAPI.drawText("Fonts/arial.ttf", 9, 253, "X — рестарт,  △ — меню,  START — выход", colors.black);
    USGAPI.drawText("Fonts/arial.ttf", 8, 252, "X — рестарт,  △ — меню,  START — выход", colors.white);
end;

-- Level Select UI
local selectIndex = 1;

local function medalToTexture(m)
    if m == 3 then return assets .. "s_medal_gold.png"; end;
    if m == 2 then return assets .. "s_medal_silver.png"; end;
    if m == 1 then return assets .. "s_medal_bronze.png"; end;
    return nil;
end;

local function drawLevelSelect()
    USGAPI.drawText("Fonts/arial.ttf", 40, 20, "Выбор уровня", colors.white);
    local baseX = 60;
    local gap = 140;

    for i = 1, 3 do
        local x = baseX + (i - 1) * gap;
        local y = 80;
        local unlocked = (i <= highestUnlocked);
        local wheel = assets ..
            (i == 1 and "levels_wheel0.png" or (i == 2 and "levels_wheel1.png" or "levels_wheel2.png"));
        USGAPI.drawTexture(wheel, x, y);
        USGAPI.drawText("Fonts/arial.ttf", x, y + 60, levels[i].name, unlocked and colors.white or colors.gray);

        -- Медаль
        local mtex = medalToTexture(levelBestMedal[i]);
        if mtex then
            USGAPI.drawTexture(mtex, x + 40, y + 10);
        end;

        -- Блокировка
        if not unlocked then
            local lock = assets .. (i == 1 and "s_lock0.png" or (i == 2 and "s_lock1.png" or "s_lock2.png"));
            USGAPI.drawTexture(lock, x + 10, y + 10);
        end;

        -- Выделение текущего
        if i == selectIndex then
            USGAPI.drawRect(x - 10, y - 10, 120, 100, colors.blue);
        end;
    end;

    USGAPI.drawText("Fonts/arial.ttf", 40, 230, "◄/► — выбрать, X — начать, △ — титульный", colors.gray);
end;

-- Title screen
local function drawTitle()
    -- Лого
    USGAPI.drawTexture(assets .. "gd.png", 120, 40);
    -- Подложка и текст
    USGAPI.fillRect(120, 188, 240, 28, colors.uiBg);
    USGAPI.drawText("Fonts/arial.ttf", 181, 201, "Нажмите X", colors.black);
    USGAPI.drawText("Fonts/arial.ttf", 180, 200, "Нажмите X", colors.white);
end;

-- Finished screen
local function drawFinished(level, medalTier)
    local tex = medalToTexture(medalTier);
    USGAPI.fillRect(90, 50, 300, 150, colors.uiBg);
    USGAPI.drawText("Fonts/arial.ttf", 121, 61, "Финиш!", colors.black);
    USGAPI.drawText("Fonts/arial.ttf", 120, 60, "Финиш!", colors.green);
    USGAPI.drawText("Fonts/arial.ttf", 121, 91, string.format("Время: %.2f c", finishedTimeSec), colors.black);
    USGAPI.drawText("Fonts/arial.ttf", 120, 90, string.format("Время: %.2f c", finishedTimeSec), colors.white);
    if tex then
        USGAPI.drawTexture(tex, 200, 115);
    else
        USGAPI.drawText("Fonts/arial.ttf", 121, 121, "Без медали", colors.black);
        USGAPI.drawText("Fonts/arial.ttf", 120, 120, "Без медали", colors.gray);
    end;
    USGAPI.drawText("Fonts/arial.ttf", 121, 181, "X — повтор,  △ — меню,  R — следующий", colors.black);
    USGAPI.drawText("Fonts/arial.ttf", 120, 180, "X — повтор,  △ — меню,  R — следующий", colors.gray);
end;

-- Вспомогательные
local function timeToMedal(level, seconds)
    local t = level.timeThresholds;
    if seconds <= t.gold then return 3; end;
    if seconds <= t.silver then return 2; end;
    if seconds <= t.bronze then return 1; end;
    return 0;
end;

local function startLevel(i)
    currentLevelIndex = i;
    resetPlayer(levels[i]);
    camX, camY = 0, 0;
    levelStartFrames = 0;
    state = STATE.PLAYING;
end;

local function completeLevel()
    local lvl = levels[currentLevelIndex];
    finishedTimeSec = levelStartFrames / 60.0;
    local medal = timeToMedal(lvl, finishedTimeSec);
    if medal > levelBestMedal[currentLevelIndex] then
        levelBestMedal[currentLevelIndex] = medal;
    end;
    if currentLevelIndex == highestUnlocked and highestUnlocked < #levels then
        highestUnlocked = highestUnlocked + 1;
    end;
    state = STATE.FINISHED;
end;

-- Главный цикл игры
while true do
    USGAPI.startFrame(colors.sky);

    -- START — выход и очистка
    if buttons.pressed(buttons.start) then
        USGAPI.unloadAll();
        return;
    end;

    if state == STATE.TITLE then
        -- Ввод
        if buttons.pressed(buttons.cross) then
            state = STATE.SELECT;
        end;
        -- Рендер (без камеры)
        USGAPI.setCameraPos(0, 0);
        drawTitle();
    elseif state == STATE.SELECT then
        -- Ввод
        if buttons.pressed(buttons.left) then
            selectIndex = selectIndex - 1;
            if selectIndex < 1 then selectIndex = 1; end;
        end;
        if buttons.pressed(buttons.right) then
            selectIndex = selectIndex + 1;
            if selectIndex > #levels then selectIndex = #levels; end;
        end;
        if buttons.pressed(buttons.triangle) then
            state = STATE.TITLE;
        end;
        if buttons.pressed(buttons.cross) then
            if selectIndex <= highestUnlocked then
                startLevel(selectIndex);
            end;
        end;

        -- Рендер (без камеры)
        USGAPI.setCameraPos(0, 0);
        drawLevelSelect();
    elseif state == STATE.PLAYING then
        local lvl = levels[currentLevelIndex];
        levelStartFrames = levelStartFrames + 1;

        -- Игровой ввод
        if buttons.pressed(buttons.triangle) then
            state = STATE.SELECT;
        end;
        if buttons.pressed(buttons.cross) then
            startLevel(currentLevelIndex);
        end;

        -- Физика
        local crashed = updatePhysics(lvl);

        -- Достигнут финиш?
        if player.x >= lvl.finishX then
            completeLevel();
        end;

        -- Камера
        updateCamera(lvl);

        -- Рендер
        drawGround(lvl);
        drawFlags(lvl);
        drawBike();
        drawHUD(lvl);

        -- Краш сообщение
        if crashed then
            USGAPI.fillRect(100, 110, 280, 28, colors.uiBg);
            USGAPI.drawText("Fonts/arial.ttf", 121, 121, "Падение! Нажмите X", colors.black);
            USGAPI.drawText("Fonts/arial.ttf", 120, 120, "Падение! Нажмите X", colors.red);
            if buttons.pressed(buttons.cross) then
                startLevel(currentLevelIndex);
            end;
        end;
    elseif state == STATE.FINISHED then
        local lvl = levels[currentLevelIndex];
        -- Ввод на экране финиша
        if buttons.pressed(buttons.cross) then
            startLevel(currentLevelIndex);
        elseif buttons.pressed(buttons.triangle) then
            state = STATE.SELECT;
        elseif buttons.pressed(buttons.r) then
            local nextIdx = currentLevelIndex + 1;
            if nextIdx <= #levels and nextIdx <= highestUnlocked then
                startLevel(nextIdx);
            end;
        end;

        -- Рендер (без камеры)
        USGAPI.setCameraPos(0, 0);
        local medalTier = timeToMedal(lvl, finishedTimeSec);
        drawFinished(lvl, medalTier);
    end;
end;
