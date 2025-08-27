local USGAPI = require("Libs.USGAPI");

local gamePath = USGAPI.getGamePath();

-- Константы игры
local SCREEN_WIDTH = 480;
local SCREEN_HEIGHT = 272;
local PADDLE_WIDTH = 10;
local PADDLE_HEIGHT = 60;
local BALL_SIZE = 8;
local PADDLE_SPEED = 4;
local BALL_SPEED = 3;
local MAX_BALL_SPEED = 6;

-- Игровые объекты
local leftPaddle = {
    x = 20,
    y = SCREEN_HEIGHT / 2 - PADDLE_HEIGHT / 2,
    width = PADDLE_WIDTH,
    height = PADDLE_HEIGHT,
    score = 0,
    targetY = SCREEN_HEIGHT / 2 - PADDLE_HEIGHT / 2
};

local rightPaddle = {
    x = SCREEN_WIDTH - 20 - PADDLE_WIDTH,
    y = SCREEN_HEIGHT / 2 - PADDLE_HEIGHT / 2,
    width = PADDLE_WIDTH,
    height = PADDLE_HEIGHT,
    score = 0,
    targetY = SCREEN_HEIGHT / 2 - PADDLE_HEIGHT / 2
};

local ball = {
    x = SCREEN_WIDTH / 2,
    y = SCREEN_HEIGHT / 2,
    size = BALL_SIZE,
    dx = BALL_SPEED,
    dy = BALL_SPEED,
    rotation = 0,
    trail = {}
};

local gameState = "playing"; -- "playing", "paused", "gameOver", "menu"
local winner = "";
local frameCount = 0;
local gameTime = 0;

-- Эффекты частиц
local particles = {};

-- Цвета (кешируем для производительности)
local colors = {
    white = Color.new(255, 255, 255),
    black = Color.new(0, 0, 0),
    red = Color.new(255, 0, 0),
    blue = Color.new(0, 0, 255),
    green = Color.new(0, 255, 0),
    yellow = Color.new(255, 255, 0),
    orange = Color.new(255, 165, 0),
    purple = Color.new(128, 0, 128),
    cyan = Color.new(0, 255, 255)
};

-- Кеш для цветов частиц (избегаем повторных вызовов Color.new/Color.get)
local particleColorCache = {};

-- Функция получения цвета с кешированием
local function getCachedColor(colorInstance, alpha)
    local key = tostring(colorInstance) .. "_" .. tostring(alpha);
    if not particleColorCache[key] then
        local colorData = Color.get(colorInstance);
        particleColorCache[key] = Color.new(colorData.r, colorData.g, colorData.b, alpha);
    end;
    return particleColorCache[key];
end;

-- Функция создания частицы
local function createParticle(x, y, color)
    local particle = {
        x = x,
        y = y,
        dx = (math.random() - 0.5) * 4,
        dy = (math.random() - 0.5) * 4,
        life = 30,
        maxLife = 30,
        color = color,
        size = math.floor(math.random() * 3) + 2 -- 2-4
    };
    table.insert(particles, particle);
end;

-- Функция обновления частиц
local function updateParticles()
    for i = #particles, 1, -1 do
        local particle = particles[i];
        particle.x = particle.x + particle.dx;
        particle.y = particle.y + particle.dy;
        particle.life = particle.life - 1;

        if particle.life <= 0 then
            table.remove(particles, i);
        end;
    end;
end;

-- Функция отрисовки частиц
local function drawParticles()
    for _, particle in ipairs(particles) do
        local alpha = (particle.life / particle.maxLife) * 255;
        local color = getCachedColor(particle.color, alpha);
        USGAPI.fillRect(particle.x, particle.y, particle.size, particle.size, color);
    end;
end;

-- Функция сброса мяча
local function resetBall()
    ball.x = SCREEN_WIDTH / 2;
    ball.y = SCREEN_HEIGHT / 2;
    ball.dx = BALL_SPEED * (math.random() > 0.5 and 1 or -1);
    ball.dy = BALL_SPEED * (math.random() > 0.5 and 1 or -1);
    ball.rotation = 0;
    ball.trail = {};

    -- Создаем эффект при сбросе мяча
    for i = 1, 10 do
        createParticle(ball.x, ball.y, colors.yellow);
    end;
end;

-- Функция проверки коллизии между мячом и ракеткой
local function checkPaddleCollision(ball, paddle)
    return ball.x < paddle.x + paddle.width and
        ball.x + ball.size > paddle.x and
        ball.y < paddle.y + paddle.height and
        ball.y + ball.size > paddle.y;
end;

-- Функция обработки ввода
local handleInput = function()
    -- Управление левой ракеткой (Up/Down)
    if buttons.held(buttons.up) and leftPaddle.y > 0 then
        leftPaddle.y = leftPaddle.y - PADDLE_SPEED;
    end;
    if buttons.held(buttons.down) and leftPaddle.y < SCREEN_HEIGHT - leftPaddle.height then
        leftPaddle.y = leftPaddle.y + PADDLE_SPEED;
    end;

    -- Управление правой ракеткой (Triangle/Cross)
    if buttons.held(buttons.triangle) and rightPaddle.y > 0 then
        rightPaddle.y = rightPaddle.y - PADDLE_SPEED;
    end;
    if buttons.held(buttons.cross) and rightPaddle.y < SCREEN_HEIGHT - rightPaddle.height then
        rightPaddle.y = rightPaddle.y + PADDLE_SPEED;
    end;

    -- Пауза
    if buttons.pressed(buttons.select) then
        if gameState == "playing" then
            gameState = "paused";
        elseif gameState == "paused" then
            gameState = "playing";
        end;
    end;

    -- Перезапуск игры
    if buttons.pressed(buttons.r) then
        leftPaddle.score = 0;
        rightPaddle.score = 0;
        resetBall();
        gameState = "playing";
        winner = "";
        particles = {};
        gameTime = 0;
        -- Очищаем кеш цветов
        particleColorCache = {};
    end;
end;

if (USGAPI.isEmulator()) then
    handleInput = function()
        -- Управление левой ракеткой (Up/Down)
        if buttons.held(buttons.up) and leftPaddle.y > 0 then
            leftPaddle.y = leftPaddle.y - PADDLE_SPEED;
        end;
        if buttons.held(buttons.down) and leftPaddle.y < SCREEN_HEIGHT - leftPaddle.height then
            leftPaddle.y = leftPaddle.y + PADDLE_SPEED;
        end;

        -- Управление правой ракеткой (Left/Right)
        if buttons.held(buttons.left) and rightPaddle.y > 0 then
            rightPaddle.y = rightPaddle.y - PADDLE_SPEED;
        end;
        if buttons.held(buttons.right) and rightPaddle.y < SCREEN_HEIGHT - rightPaddle.height then
            rightPaddle.y = rightPaddle.y + PADDLE_SPEED;
        end;

        -- Пауза
        if buttons.pressed(buttons.select) then
            if gameState == "playing" then
                gameState = "paused";
            elseif gameState == "paused" then
                gameState = "playing";
            end;
        end;

        -- Перезапуск игры
        if buttons.pressed(buttons.r) then
            leftPaddle.score = 0;
            rightPaddle.score = 0;
            resetBall();
            gameState = "playing";
            winner = "";
            particles = {};
            gameTime = 0;
            -- Очищаем кеш цветов
            particleColorCache = {};
        end;
    end;
end;

-- Функция обновления игры
local function updateGame()
    if gameState ~= "playing" then return; end;

    frameCount = frameCount + 1;
    gameTime = gameTime + 1 / 60; -- Предполагаем 60 FPS

    -- Обновление позиции мяча
    ball.x = ball.x + ball.dx;
    ball.y = ball.y + ball.dy;
    ball.rotation = ball.rotation + ball.dx * 2;

    -- Добавляем позицию в след мяча
    table.insert(ball.trail, { x = ball.x, y = ball.y });
    if #ball.trail > 5 then
        table.remove(ball.trail, 1);
    end;

    -- Отскок от верхней и нижней границы
    if ball.y <= 0 or ball.y >= SCREEN_HEIGHT - ball.size then
        ball.dy = -ball.dy;
        -- Создаем эффект при отскоке
        for i = 1, 5 do
            createParticle(ball.x, ball.y, colors.white);
        end;
        -- Попробуем воспроизвести звук отскока
        USGAPI.playSound(gamePath .. "bounce.wav", 50);
    end;

    -- Проверка коллизии с ракетками
    if checkPaddleCollision(ball, leftPaddle) then
        ball.dx = math.abs(ball.dx) * 1.1; -- Увеличиваем скорость
        ball.dy = ball.dy + (ball.y - (leftPaddle.y + leftPaddle.height / 2)) * 0.15;

        -- Создаем эффект при ударе
        for i = 1, 8 do
            createParticle(ball.x, ball.y, colors.blue);
        end;

        USGAPI.playSound(gamePath .. "hit.wav", 70);
    elseif checkPaddleCollision(ball, rightPaddle) then
        ball.dx = -math.abs(ball.dx) * 1.1; -- Увеличиваем скорость
        ball.dy = ball.dy + (ball.y - (rightPaddle.y + rightPaddle.height / 2)) * 0.15;

        -- Создаем эффект при ударе
        for i = 1, 8 do
            createParticle(ball.x, ball.y, colors.red);
        end;

        USGAPI.playSound(gamePath .. "hit.wav", 70);
    end;

    -- Ограничение скорости мяча
    if ball.dx > MAX_BALL_SPEED then ball.dx = MAX_BALL_SPEED; end;
    if ball.dx < -MAX_BALL_SPEED then ball.dx = -MAX_BALL_SPEED; end;
    if ball.dy > MAX_BALL_SPEED then ball.dy = MAX_BALL_SPEED; end;
    if ball.dy < -MAX_BALL_SPEED then ball.dy = -MAX_BALL_SPEED; end;

    -- Проверка гола
    if ball.x <= 0 then
        rightPaddle.score = rightPaddle.score + 1;
        resetBall();

        -- Создаем эффект при голе
        for i = 1, 15 do
            createParticle(SCREEN_WIDTH / 4, SCREEN_HEIGHT / 2, colors.red);
        end;

        USGAPI.playSound(gamePath .. "score.wav", 80);

        -- Проверка победы
        if rightPaddle.score >= 5 then
            gameState = "gameOver";
            winner = "Right Player";
        end;
    elseif ball.x >= SCREEN_WIDTH - ball.size then
        leftPaddle.score = leftPaddle.score + 1;
        resetBall();

        -- Создаем эффект при голе
        for i = 1, 15 do
            createParticle(SCREEN_WIDTH * 3 / 4, SCREEN_HEIGHT / 2, colors.blue);
        end;

        USGAPI.playSound(gamePath .. "score.wav", 80);

        -- Проверка победы
        if leftPaddle.score >= 5 then
            gameState = "gameOver";
            winner = "Left Player";
        end;
    end;

    -- Обновление частиц
    updateParticles();
end;

-- Функция отрисовки
local function drawGame()
    -- Отрисовка фона
    USGAPI.fillRect(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT, colors.black);

    -- Отрисовка центральной линии с анимацией
    for i = 0, SCREEN_HEIGHT, 20 do
        local alpha = 255;
        if frameCount % 60 < 30 then
            alpha = 128 + math.sin(frameCount * 0.1 + i * 0.1) * 127;
        end;
        local lineColor = Color.new(255, 255, 255, alpha);
        USGAPI.fillRect(SCREEN_WIDTH / 2 - 2, i, 4, 10, lineColor);
    end;

    -- Отрисовка следа мяча
    for i, pos in ipairs(ball.trail) do
        local alpha = (i / #ball.trail) * 128;
        local trailColor = Color.new(255, 255, 0, alpha);
        USGAPI.fillRect(pos.x, pos.y, ball.size, ball.size, trailColor);
    end;

    -- Отрисовка ракеток с эффектами
    local leftPaddleColor = Color.new(0, 100, 255);
    local rightPaddleColor = Color.new(255, 100, 0);

    -- Добавляем свечение к ракеткам
    USGAPI.fillRect(leftPaddle.x - 2, leftPaddle.y - 2, leftPaddle.width + 4, leftPaddle.height + 4,
        Color.new(0, 50, 128, 100));
    USGAPI.fillRect(rightPaddle.x - 2, rightPaddle.y - 2, rightPaddle.width + 4, rightPaddle.height + 4,
        Color.new(128, 50, 0, 100));

    USGAPI.fillRect(leftPaddle.x, leftPaddle.y, leftPaddle.width, leftPaddle.height, leftPaddleColor);
    USGAPI.fillRect(rightPaddle.x, rightPaddle.y, rightPaddle.width, rightPaddle.height, rightPaddleColor);

    -- Отрисовка мяча с вращением
    USGAPI.fillRect(ball.x, ball.y, ball.size, ball.size, colors.yellow);

    -- Отрисовка частиц
    drawParticles();

    -- Отрисовка счета с эффектами
    local leftScoreColor = Color.new(0, 200, 255);
    local rightScoreColor = Color.new(255, 200, 0);

    USGAPI.drawText("Fonts/arial.ttf", 50, 20, tostring(leftPaddle.score), leftScoreColor, 2.0);
    USGAPI.drawText("Fonts/arial.ttf", SCREEN_WIDTH - 80, 20, tostring(rightPaddle.score), rightScoreColor, 2.0);

    -- Отрисовка времени игры
    local minutes = math.floor(gameTime / 60);
    local seconds = math.floor(gameTime % 60);
    USGAPI.drawText("Fonts/arial.ttf", SCREEN_WIDTH / 2 - 20, 27, string.format("%02d:%02d", minutes, seconds),
        colors.white, 1.0);

    -- Отрисовка инструкций
    USGAPI.drawText("Fonts/arial.ttf", 10, SCREEN_HEIGHT - 60, "Left: Up/Down", colors.white, 0.8);
    USGAPI.drawText("Fonts/arial.ttf", 10, SCREEN_HEIGHT - 40, "Right: Triangle/Cross", colors.white, 0.8);
    USGAPI.drawText("Fonts/arial.ttf", 10, SCREEN_HEIGHT - 20, "Select: Pause | R: Restart", colors.white, 0.8);

    -- Отрисовка состояния игры
    if gameState == "paused" then
        USGAPI.drawText("Fonts/arial.ttf", SCREEN_WIDTH / 2 - 50, SCREEN_HEIGHT / 2 - 20, "PAUSED", colors.yellow, 1.5);
    elseif gameState == "gameOver" then
        USGAPI.drawText("Fonts/arial.ttf", SCREEN_WIDTH / 2 - 105, SCREEN_HEIGHT / 2 - 40, winner .. " WINS!",
            colors.green, 1.5);
        USGAPI.drawText("Fonts/arial.ttf", SCREEN_WIDTH / 2 - 65, SCREEN_HEIGHT / 2, "Press R to restart",
            colors.white, 1.0);

        -- Создаем эффект победы
        if frameCount % 10 == 0 then
            for i = 1, 5 do
                createParticle(math.floor(math.random() * SCREEN_WIDTH), math.floor(math.random() * SCREEN_HEIGHT),
                    colors.green);
            end;
        end;
    end;
end;

-- Основной игровой цикл
while true do
    -- Начало кадра
    USGAPI.startFrame();

    -- Обработка ввода
    handleInput();

    -- Обновление игры
    updateGame();

    -- Отрисовка
    drawGame();

    if (buttons.pressed(buttons.start)) then break; end;
end;

USGAPI.unloadAll();
