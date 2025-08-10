local USGAPI = require("Scripts.USGAPI");

local gamePath = USGAPI.getGamePath();

-- Инициализация игры
local cookies = 0;
local cookiesPerClick = 1;
local cookiesPerSecond = 0;
local lastTime = 0;
local lastSaveTime = 0;

-- Улучшения
local upgrades = {
    {
        name = "Cursor",
        cost = 15,
        cookiesPerSecond = 0.1,
        owned = 0,
        description = "Automatically produces cookies",
        texture = gamePath .. "img/cursor.png"
    },
    {
        name = "Grandma",
        cost = 100,
        cookiesPerSecond = 1,
        owned = 0,
        description = "A nice grandma to bake more cookies",
        texture = gamePath .. "img/alternateGrandma.png"
    },
    {
        name = "Farm",
        cost = 1100,
        cookiesPerSecond = 8,
        owned = 0,
        description = "Grows cookie plants from cookie seeds",
        texture = gamePath .. "img/farm.png"
    },
    {
        name = "Mine",
        cost = 12000,
        cookiesPerSecond = 47,
        owned = 0,
        description = "Mines out delicious chocolate chips",
        texture = gamePath .. "img/factory.png"
    }
};

-- Функция для сохранения игры
local function saveGame()
    local saveFile = io.open(gamePath .. "save.dat", "w");
    if saveFile then
        saveFile:write("cookies=" .. cookies .. "\n");
        saveFile:write("cookiesPerClick=" .. cookiesPerClick .. "\n");
        saveFile:write("cookiesPerSecond=" .. cookiesPerSecond .. "\n");

        for i, upgrade in ipairs(upgrades) do
            saveFile:write("upgrade" .. i .. "_owned=" .. upgrade.owned .. "\n");
            saveFile:write("upgrade" .. i .. "_cost=" .. upgrade.cost .. "\n");
        end;

        saveFile:close();
    end;
end;

-- Функция для загрузки игры
local function loadGame()
    local saveFile = io.open(gamePath .. "save.dat", "r");
    if saveFile then
        for line in saveFile:lines() do
            local key, value = line:match("(.+)=(.+)");
            if key and value then
                if key == "cookies" then
                    cookies = tonumber(value) or 0;
                elseif key == "cookiesPerClick" then
                    cookiesPerClick = tonumber(value) or 1;
                elseif key == "cookiesPerSecond" then
                    cookiesPerSecond = tonumber(value) or 0;
                elseif key:match("upgrade(%d+)_owned") then
                    local index = tonumber(key:match("upgrade(%d+)_owned"));
                    if index and upgrades[index] then
                        upgrades[index].owned = tonumber(value) or 0;
                    end;
                elseif key:match("upgrade(%d+)_cost") then
                    local index = tonumber(key:match("upgrade(%d+)_cost"));
                    if index and upgrades[index] then
                        upgrades[index].cost = tonumber(value) or upgrades[index].cost;
                    end;
                end;
            end;
        end;
        saveFile:close();

        -- Пересчитываем cookiesPerSecond на основе загруженных улучшений
        cookiesPerSecond = 0;
        for _, upgrade in ipairs(upgrades) do
            cookiesPerSecond = cookiesPerSecond + (upgrade.cookiesPerSecond * upgrade.owned);
        end;
    end;
end;

-- Загружаем сохраненную игру при запуске
loadGame();

-- Кеширование цветов для производительности
local colors = {
    white = Color.new(255, 255, 255),
    black = Color.new(0, 0, 0),
    brown = Color.new(139, 69, 19),
    gold = Color.new(255, 215, 0),
    green = Color.new(0, 255, 0),
    red = Color.new(255, 0, 0),
    blue = Color.new(0, 0, 255),
    gray = Color.new(128, 128, 128),
    darkGray = Color.new(64, 64, 64)
};

-- Переменные для интерфейса
local selectedUpgrade = 1;
local cookieScale = 1.0;
local cookieRotation = 0;
local particles = {};

-- Функция для создания частиц
local function createParticle(x, y, value)
    table.insert(particles, {
        x = x,
        y = y,
        value = value,
        life = 60,
        maxLife = 60,
        velocityY = -2
    });
end;

-- Функция для обновления частиц
local function updateParticles()
    for i = #particles, 1, -1 do
        local particle = particles[i];
        particle.y = particle.y + particle.velocityY;
        particle.life = particle.life - 1;

        if particle.life <= 0 then
            table.remove(particles, i);
        end;
    end;
end;

-- Функция для отрисовки частиц
local function drawParticles()
    for _, particle in ipairs(particles) do
        local alpha = (particle.life / particle.maxLife) * 255;
        local scale = 0.5 + (particle.life / particle.maxLife) * 0.5;

        USGAPI.drawText("Fonts/arial.ttf", particle.x, particle.y,
            "+" .. particle.value, Color.new(255, 215, 0, alpha), scale);
    end;
end;

-- Функция для покупки улучшения
local function buyUpgrade(index)
    local upgrade = upgrades[index];
    if cookies >= upgrade.cost then
        cookies = cookies - upgrade.cost;
        upgrade.owned = upgrade.owned + 1;
        upgrade.cost = math.floor(upgrade.cost * 1.15); -- Увеличение стоимости на 15%
        cookiesPerSecond = cookiesPerSecond + upgrade.cookiesPerSecond;

        -- Создать частицу
        createParticle(400, 200 + (index - 1) * 30, "Bought!");

        -- Воспроизвести звук покупки
        USGAPI.playSound(gamePath .. "snd/buy1.wav");

        -- Сохраняем игру после покупки
        saveGame();
    end;
end;

-- Основной игровой цикл
while true do
    -- Начало кадра
    USGAPI.startFrame();

    -- Получение времени для автоматического производства
    local currentTime = os.time();
    if lastTime > 0 then
        local timeDiff = currentTime - lastTime;
        cookies = cookies + (cookiesPerSecond * timeDiff);
    end;
    lastTime = currentTime;

    -- Автосохранение каждые 30 секунд
    if currentTime - lastSaveTime >= 30 then
        saveGame();
        lastSaveTime = currentTime;
    end;

    -- Обработка ввода
    if buttons.pressed(buttons.start) then
        -- Сохраняем игру перед выходом
        saveGame();

        -- Выход из игры
        USGAPI.unloadAll();
        break;
    end;

    -- Навигация по улучшениям
    if buttons.pressed(buttons.up) then
        selectedUpgrade = selectedUpgrade - 1;
        if selectedUpgrade < 1 then selectedUpgrade = #upgrades; end;
        USGAPI.playSound(gamePath .. "snd/clickOn.wav");
    end;

    if buttons.pressed(buttons.down) then
        selectedUpgrade = selectedUpgrade + 1;
        if selectedUpgrade > #upgrades then selectedUpgrade = 1; end;
        USGAPI.playSound(gamePath .. "snd/clickOn.wav");
    end;

    -- Покупка улучшения
    if buttons.pressed(buttons.cross) then
        buyUpgrade(selectedUpgrade);
    end;

    -- Клик по печеньке (в центре экрана)
    if buttons.pressed(buttons.circle) then
        local mouseX, mouseY = 240, 136; -- Центр экрана
        local cookieSize = 64;           -- Размер области клика под текстуру 64x64

        -- Проверка клика по печеньке
        if mouseX >= 240 - cookieSize / 2 and mouseX <= 240 + cookieSize / 2 and
            mouseY >= 136 - cookieSize / 2 and mouseY <= 136 + cookieSize / 2 then
            cookies = cookies + cookiesPerClick;
            createParticle(240, 136, cookiesPerClick);

            -- Анимация печеньки
            cookieScale = 1.2;
            -- cookieRotation = cookieRotation + 10; -- Убираем поворот

            -- Воспроизвести звук клика
            USGAPI.playSound(gamePath .. "snd/click1.wav");
        end;
    end;

    -- Анимация печеньки
    if cookieScale > 1.0 then
        cookieScale = cookieScale - 0.02;
    end;

    -- Обновление частиц
    updateParticles();

    -- Отрисовка фона (локальная текстура)
    USGAPI.drawTexture(gamePath .. "img/bgChocoDark.jpg", 0, 0);

    -- Отрисовка печеньки (локальная текстура)
    local cookieSize = 64 * cookieScale; -- Размер текстуры с учетом масштаба
    local centerX = 240;
    local centerY = 136;

    -- Позиционируем текстуру так, чтобы центр был в центре экрана
    USGAPI.drawTexture(gamePath .. "img/perfectCookie.png",
        centerX - (cookieSize / 2), centerY - (cookieSize / 2),
        0, 255);

    -- Отрисовка частиц
    drawParticles();

    -- Отрисовка статистики
    USGAPI.drawText("Fonts/arial.ttf", 10, 10, "Cookies: " .. math.floor(cookies), colors.white, 1.0);
    USGAPI.drawText("Fonts/arial.ttf", 10, 30, "Per Click: " .. cookiesPerClick, colors.white, 0.8);
    USGAPI.drawText("Fonts/arial.ttf", 10, 50, "Per Second: " .. string.format("%.1f", cookiesPerSecond), colors.white,
        0.8);

    -- Отображение времени последнего сохранения
    local timeSinceSave = os.time() - lastSaveTime;
    USGAPI.drawText("Fonts/arial.ttf", 10, 70, "Auto-save in: " .. (30 - (timeSinceSave % 30)) .. "s", colors.yellow,
        0.7);

    -- Отрисовка улучшений
    USGAPI.drawText("Fonts/arial.ttf", 300, 10, "UPGRADES", colors.white, 1.2);
    USGAPI.drawText("Fonts/arial.ttf", 300, 30, "Use UP/DOWN to select", colors.gray, 0.7);
    USGAPI.drawText("Fonts/arial.ttf", 300, 45, "Press X to buy", colors.gray, 0.7);
    USGAPI.drawText("Fonts/arial.ttf", 300, 60, "Press START to exit", colors.red, 0.7);

    for i, upgrade in ipairs(upgrades) do
        local y = 80 + (i - 1) * 30;
        local color = colors.white;

        -- Выделение выбранного улучшения (локальная текстура)
        if i == selectedUpgrade then
            -- Используем текстуру для выделения
            USGAPI.drawTexture(gamePath .. "img/blackGradient.png", 295, y - 4, 0, 128);
            color = colors.white;
        elseif cookies >= upgrade.cost then
            color = colors.green;
        else
            color = colors.gray;
        end;

        -- Отрисовка иконки улучшения
        USGAPI.drawTexture(upgrade.texture, 300, y - 6, 0, 255);

        USGAPI.drawText("Fonts/arial.ttf", 330, y,
            upgrade.name .. " (" .. upgrade.owned .. ")", color, 0.8);
        USGAPI.drawText("Fonts/arial.ttf", 330, y + 15,
            "Cost: " .. upgrade.cost .. " | +" .. upgrade.cookiesPerSecond .. "/s", color, 0.6);
    end;

    -- Отрисовка инструкций
    USGAPI.drawText("Fonts/arial.ttf", 10, 240, "Click O to click cookie", colors.white, 0.7);
    USGAPI.drawText("Fonts/arial.ttf", 10, 255, "Click X to buy upgrades", colors.white, 0.7);
end;
