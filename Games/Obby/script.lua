local USGAPI = require("Scripts.USGAPI");

local gamePath = USGAPI.getGamePath();

-- Игровые константы
local SCREEN_WIDTH = 480;
local SCREEN_HEIGHT = 272;
local PLAYER_SIZE = 20;
local PLATFORM_HEIGHT = 15;
local GRAVITY = 0.8;
local JUMP_FORCE = -15;
local MOVE_SPEED = 3;

-- Игровые переменные
local player = {
    x = 50,
    y = 200,
    velX = 0,
    velY = 0,
    onGround = false,
    alive = true
};

local camera = {
    x = 0,
    y = 0
};

local platforms = {};
local obstacles = {};
local checkpoints = {};
local currentLevel = 1;
local score = 0;
local gameState = "playing"; -- "playing", "paused", "gameOver", "victory"

-- Цвета
local colors = {
    player = Color.new(0, 150, 255),
    platform = Color.new(100, 100, 100),
    obstacle = Color.new(255, 0, 0),
    checkpoint = Color.new(0, 255, 0),
    background = Color.new(50, 50, 100),
    text = Color.new(255, 255, 255),
    ui = Color.new(200, 200, 200)
};

-- Функция создания уровня
local function createLevel(level)
    platforms = {};
    obstacles = {};
    checkpoints = {};

    if level == 1 then
        -- Платформы уровня 1
        table.insert(platforms, { x = 0, y = 250, width = 100, height = PLATFORM_HEIGHT });
        table.insert(platforms, { x = 150, y = 220, width = 80, height = PLATFORM_HEIGHT });
        table.insert(platforms, { x = 280, y = 190, width = 80, height = PLATFORM_HEIGHT });
        table.insert(platforms, { x = 410, y = 160, width = 80, height = PLATFORM_HEIGHT });
        table.insert(platforms, { x = 540, y = 130, width = 80, height = PLATFORM_HEIGHT });
        table.insert(platforms, { x = 670, y = 100, width = 80, height = PLATFORM_HEIGHT });
        table.insert(platforms, { x = 800, y = 70, width = 80, height = PLATFORM_HEIGHT });
        table.insert(platforms, { x = 930, y = 40, width = 80, height = PLATFORM_HEIGHT });
        table.insert(platforms, { x = 1060, y = 10, width = 80, height = PLATFORM_HEIGHT });

        -- Препятствия
        table.insert(obstacles, { x = 200, y = 200, width = 20, height = 20 });
        table.insert(obstacles, { x = 350, y = 170, width = 20, height = 20 });
        table.insert(obstacles, { x = 500, y = 140, width = 20, height = 20 });
        table.insert(obstacles, { x = 650, y = 110, width = 20, height = 20 });

        -- Чекпоинты
        table.insert(checkpoints, { x = 280, y = 170 });
        table.insert(checkpoints, { x = 540, y = 110 });
        table.insert(checkpoints, { x = 800, y = 50 });
    elseif level == 2 then
        -- Платформы уровня 2 (сложнее)
        table.insert(platforms, { x = 0, y = 250, width = 80, height = PLATFORM_HEIGHT });
        table.insert(platforms, { x = 120, y = 200, width = 60, height = PLATFORM_HEIGHT });
        table.insert(platforms, { x = 220, y = 150, width = 60, height = PLATFORM_HEIGHT });
        table.insert(platforms, { x = 320, y = 100, width = 60, height = PLATFORM_HEIGHT });
        table.insert(platforms, { x = 420, y = 50, width = 60, height = PLATFORM_HEIGHT });
        table.insert(platforms, { x = 520, y = 0, width = 60, height = PLATFORM_HEIGHT });
        table.insert(platforms, { x = 620, y = 50, width = 60, height = PLATFORM_HEIGHT });
        table.insert(platforms, { x = 720, y = 100, width = 60, height = PLATFORM_HEIGHT });
        table.insert(platforms, { x = 820, y = 150, width = 60, height = PLATFORM_HEIGHT });
        table.insert(platforms, { x = 920, y = 200, width = 60, height = PLATFORM_HEIGHT });
        table.insert(platforms, { x = 1020, y = 250, width = 60, height = PLATFORM_HEIGHT });

        -- Препятствия
        table.insert(obstacles, { x = 150, y = 180, width = 15, height = 15 });
        table.insert(obstacles, { x = 250, y = 130, width = 15, height = 15 });
        table.insert(obstacles, { x = 350, y = 80, width = 15, height = 15 });
        table.insert(obstacles, { x = 450, y = 30, width = 15, height = 15 });
        table.insert(obstacles, { x = 550, y = -20, width = 15, height = 15 });
        table.insert(obstacles, { x = 650, y = 30, width = 15, height = 15 });
        table.insert(obstacles, { x = 750, y = 80, width = 15, height = 15 });
        table.insert(obstacles, { x = 850, y = 130, width = 15, height = 15 });
        table.insert(obstacles, { x = 950, y = 180, width = 15, height = 15 });

        -- Чекпоинты
        table.insert(checkpoints, { x = 320, y = 80 });
        table.insert(checkpoints, { x = 620, y = 30 });
        table.insert(checkpoints, { x = 920, y = 180 });
    end;
end;

-- Функция проверки коллизий
local function checkCollision(rect1, rect2)
    local rect1Width = rect1.width or PLAYER_SIZE;
    local rect1Height = rect1.height or PLAYER_SIZE;
    local rect2Width = rect2.width or PLAYER_SIZE;
    local rect2Height = rect2.height or PLAYER_SIZE;

    return rect1.x < rect2.x + rect2Width and
        rect1.x + rect1Width > rect2.x and
        rect1.y < rect2.y + rect2Height and
        rect1.y + rect1Height > rect2.y;
end;

-- Функция сброса игрока
local function resetPlayer()
    player.x = 50;
    player.y = 200;
    player.velX = 0;
    player.velY = 0;
    player.onGround = false;
    player.alive = true;
end;

-- Функция обработки ввода
local function handleInput()
    -- Пауза (работает всегда)
    if buttons.pressed(buttons.select) then
        if gameState == "playing" then
            gameState = "paused";
        elseif gameState == "paused" then
            gameState = "playing";
        end;
    end;

    -- Рестарт при проигрыше (работает всегда)
    if buttons.pressed(buttons.circle) and gameState == "gameOver" then
        resetPlayer();
        gameState = "playing";
        return; -- Выходим, чтобы не обрабатывать остальной ввод
    end;

    -- Остальной ввод только если игрок жив
    if not player.alive then return; end;

    -- Движение влево/вправо
    if buttons.held(buttons.left) then
        player.velX = -MOVE_SPEED;
    elseif buttons.held(buttons.right) then
        player.velX = MOVE_SPEED;
    else
        player.velX = player.velX * 0.8; -- Трение
    end;

    -- Прыжок
    if buttons.pressed(buttons.cross) and player.onGround then
        player.velY = JUMP_FORCE;
        player.onGround = false;
        -- Попытка воспроизвести звук прыжка
        USGAPI.playSound(gamePath .. "jump.wav");
    end;
end;

-- Функция обновления физики
local function updatePhysics()
    if not player.alive then return; end;

    -- Применение гравитации
    player.velY = player.velY + GRAVITY;

    -- Обновление позиции
    player.x = player.x + player.velX;
    player.y = player.y + player.velY;

    -- Проверка коллизий с платформами
    player.onGround = false;
    for i, platform in ipairs(platforms) do
        if checkCollision(player, platform) then
            -- Коллизия сверху платформы (приземление)
            if player.velY > 0 and player.y < platform.y then
                player.y = platform.y - PLAYER_SIZE;
                player.velY = 0;
                player.onGround = true;
            end;
        end;
    end;

    -- Проверка коллизий с препятствиями
    for i, obstacle in ipairs(obstacles) do
        if checkCollision(player, obstacle) then
            player.alive = false;
            gameState = "gameOver";
            -- Попытка воспроизвести звук смерти
            USGAPI.playSound(gamePath .. "death.wav");
            break;
        end;
    end;

    -- Проверка достижения финиша
    if player.x > 1100 then
        if currentLevel == 1 then
            currentLevel = 2;
            createLevel(currentLevel);
            resetPlayer();
            score = score + 100;
        else
            gameState = "victory";
            score = score + 200;
        end;
    end;

    -- Проверка падения
    if player.y > SCREEN_HEIGHT + 50 then
        player.alive = false;
        gameState = "gameOver";
    end;
end;

-- Функция обновления камеры
local function updateCamera()
    camera.x = player.x - SCREEN_WIDTH / 2;
    camera.y = player.y - SCREEN_HEIGHT / 2;

    -- Ограничения камеры
    if camera.x < 0 then camera.x = 0; end;
    if camera.y < 0 then camera.y = 0; end;

    USGAPI.setCameraPos(camera.x, camera.y);
end;

-- Функция отрисовки
local function draw()
    -- Отрисовка фона
    USGAPI.fillRect(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT, colors.background);

    -- Отрисовка платформ
    for i, platform in ipairs(platforms) do
        USGAPI.fillRect(platform.x - camera.x, platform.y - camera.y,
            platform.width, platform.height, colors.platform);
    end;

    -- Отрисовка препятствий
    for i, obstacle in ipairs(obstacles) do
        USGAPI.fillRect(obstacle.x - camera.x, obstacle.y - camera.y,
            obstacle.width, obstacle.height, colors.obstacle);
    end;

    -- Отрисовка чекпоинтов
    for i, checkpoint in ipairs(checkpoints) do
        USGAPI.drawCircle(checkpoint.x - camera.x, checkpoint.y - camera.y,
            10, colors.checkpoint);
    end;

    -- Отрисовка игрока
    if player.alive then
        USGAPI.fillRect(player.x - camera.x, player.y - camera.y,
            PLAYER_SIZE, PLAYER_SIZE, colors.player);
    end;

    -- Отрисовка UI
    USGAPI.drawText("Fonts/arial.ttf", 10, 10, "Level: " .. currentLevel, colors.text);
    USGAPI.drawText("Fonts/arial.ttf", 10, 30, "Score: " .. score, colors.text);

    if gameState == "paused" then
        USGAPI.drawText("Fonts/arial.ttf", SCREEN_WIDTH / 2 - 50, SCREEN_HEIGHT / 2,
            "PAUSED", colors.ui, 2.0);
        USGAPI.drawText("Fonts/arial.ttf", SCREEN_WIDTH / 2 - 100, SCREEN_HEIGHT / 2 + 30,
            "Press START to continue", colors.ui);
    elseif gameState == "gameOver" then
        USGAPI.drawText("Fonts/arial.ttf", SCREEN_WIDTH / 2 - 80, SCREEN_HEIGHT / 2,
            "GAME OVER", colors.ui, 2.0);
        USGAPI.drawText("Fonts/arial.ttf", SCREEN_WIDTH / 2 - 100, SCREEN_HEIGHT / 2 + 30,
            "Press CIRCLE to restart", colors.ui);
    elseif gameState == "victory" then
        USGAPI.drawText("Fonts/arial.ttf", SCREEN_WIDTH / 2 - 60, SCREEN_HEIGHT / 2,
            "VICTORY!", colors.ui, 2.0);
        USGAPI.drawText("Fonts/arial.ttf", SCREEN_WIDTH / 2 - 100, SCREEN_HEIGHT / 2 + 30,
            "Final Score: " .. score, colors.ui);
    end;

    -- Инструкции
    USGAPI.drawText("Fonts/arial.ttf", 10, SCREEN_HEIGHT - 60,
        "D-Pad: Move, X: Jump", colors.text);
    USGAPI.drawText("Fonts/arial.ttf", 10, SCREEN_HEIGHT - 40,
        "SELECT: Pause, CIRCLE: Restart", colors.text);
    USGAPI.drawText("Fonts/arial.ttf", 10, SCREEN_HEIGHT - 20,
        "START: Exit", colors.text);
end;

-- Инициализация игры
createLevel(currentLevel);

-- Основной игровой цикл
while true do
    USGAPI.startFrame();

    if gameState == "playing" then
        handleInput();
        updatePhysics();
        updateCamera();
    elseif gameState == "paused" then
        handleInput(); -- Только для выхода из паузы
    elseif gameState == "gameOver" or gameState == "victory" then
        handleInput(); -- Только для рестарта
    end;

    draw();

    if (buttons.pressed(buttons.start)) then break; end;
end;

USGAPI.unloadAll();
