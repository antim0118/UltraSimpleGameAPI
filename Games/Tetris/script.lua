local USGAPI = require("Scripts.USGAPI");

local buttonsPressed = buttons.pressed;
local drawText = USGAPI.drawText;
local fillRect = USGAPI.fillRect;
local drawRect = USGAPI.drawRect;

-- Получаем путь к игре для локальных ресурсов
local gamePath = USGAPI.getGamePath();

-- Константы экрана PSP
local SCREEN_WIDTH = 480;
local SCREEN_HEIGHT = 272;

-- Константы игры
local BOARD_WIDTH = 10;
local BOARD_HEIGHT = 20;
local BLOCK_SIZE = 12;
local BOARD_OFFSET_X = 140;
local BOARD_OFFSET_Y = 26;

local FONT_NAME = "Fonts/arial.ttf";

local gameIsRunning = true;

-- Цвета для блоков (красивые градиенты)
local LIGHT_COLOR = Color.new(255, 255, 255, 50);
local DARK_COLOR = Color.new(0, 0, 0, 50);
local BORDER_COLOR = Color.new(50, 50, 50);

local COLOR_WHITE = Color.new(255, 255, 255);
local COLOR_BLACK = Color.new(0, 0, 0);
local COLOR_GRAY = Color.new(200, 200, 200);

local COLORS = {
    Color.new(255, 0, 0),   -- Красный
    Color.new(0, 255, 0),   -- Зеленый
    Color.new(0, 0, 255),   -- Синий
    Color.new(255, 255, 0), -- Желтый
    Color.new(255, 0, 255), -- Пурпурный
    Color.new(0, 255, 255), -- Голубой
    Color.new(255, 165, 0)  -- Оранжевый
};

-- Фигуры Тетриса (тетромино)
local TETROMINOES = {
    -- I-фигура
    {
        { { 1, 1, 1, 1 } },
        color = 6
    },
    -- O-фигура
    {
        { { 1, 1 }, { 1, 1 } },
        color = 2
    },
    -- T-фигура
    {
        { { 0, 1, 0 }, { 1, 1, 1 } },
        color = 5
    },
    -- S-фигура
    {
        { { 0, 1, 1 }, { 1, 1, 0 } },
        color = 1
    },
    -- Z-фигура
    {
        { { 1, 1, 0 }, { 0, 1, 1 } },
        color = 0
    },
    -- J-фигура
    {
        { { 1, 0, 0 }, { 1, 1, 1 } },
        color = 3
    },
    -- L-фигура
    {
        { { 0, 0, 1 }, { 1, 1, 1 } },
        color = 4
    }
};

-- Состояние игры
local gameState = {
    board = {},
    currentPiece = nil,
    nextPiece = nil,
    score = 0,
    level = 1,
    lines = 0,
    gameOver = false,
    paused = false,
    dropTime = 0,
    dropSpeed = 1000, -- миллисекунды
    lastDrop = 0
};

-- Инициализация игрового поля
local function initBoard()
    for y = 1, BOARD_HEIGHT do
        gameState.board[y] = {};
        for x = 1, BOARD_WIDTH do
            gameState.board[y][x] = 0;
        end;
    end;
end;

-- Создание новой фигуры
local function createPiece()
    local pieceType = math.floor(math.random() * #TETROMINOES) + 1;
    local tetromino = TETROMINOES[pieceType];

    return {
        shape = tetromino[1],
        color = tetromino.color,
        x = math.floor(BOARD_WIDTH / 2) - math.floor(#tetromino[1][1] / 2),
        y = 1
    };
end;

-- Проверка коллизии
local function checkCollision(piece, dx, dy, rotation)
    local shape = piece.shape;
    if rotation then
        -- Простое вращение (можно улучшить)
        local newShape = {};
        for i = 1, #shape[1] do
            newShape[i] = {};
            for j = 1, #shape do
                newShape[i][j] = shape[#shape - j + 1][i];
            end;
        end;
        shape = newShape;
    end;

    for y = 1, #shape do
        for x = 1, #shape[y] do
            if shape[y][x] == 1 then
                local boardX = piece.x + x + dx;
                local boardY = piece.y + y + dy;

                if boardX < 1 or boardX > BOARD_WIDTH or
                    boardY > BOARD_HEIGHT or
                    (boardY >= 1 and gameState.board[boardY][boardX] ~= 0) then
                    return true;
                end;
            end;
        end;
    end;
    return false;
end;

-- Размещение фигуры на поле
local function placePiece()
    local piece = gameState.currentPiece;
    if (piece) then
        for y = 1, #piece.shape do
            for x = 1, #piece.shape[y] do
                if piece.shape[y][x] == 1 then
                    local boardX = piece.x + x;
                    local boardY = piece.y + y;
                    if boardY >= 1 then
                        gameState.board[boardY][boardX] = piece.color + 1;
                    end;
                end;
            end;
        end;
    end;
end;

-- Проверка и удаление заполненных линий
local function clearLines()
    local linesCleared = 0;

    for y = BOARD_HEIGHT, 1, -1 do
        local fullLine = true;
        for x = 1, BOARD_WIDTH do
            if gameState.board[y][x] == 0 then
                fullLine = false;
                break;
            end;
        end;

        if fullLine then
            -- Удаляем линию
            for moveY = y, 2, -1 do
                for x = 1, BOARD_WIDTH do
                    gameState.board[moveY][x] = gameState.board[moveY - 1][x];
                end;
            end;
            -- Очищаем верхнюю линию
            for x = 1, BOARD_WIDTH do
                gameState.board[1][x] = 0;
            end;
            linesCleared = linesCleared + 1;
            y = y + 1; -- Проверяем ту же позицию снова
        end;
    end;

    if linesCleared > 0 then
        gameState.lines = gameState.lines + linesCleared;
        gameState.score = gameState.score + (linesCleared * 100 * gameState.level);
        gameState.level = math.floor(gameState.lines / 10) + 1;
        gameState.dropSpeed = math.max(100, 1000 - (gameState.level - 1) * 50);

        -- Воспроизводим звук очистки линий
        USGAPI.playSound(gamePath .. "line_clear.wav", 80);
    end;
end;

-- Проверка окончания игры
local function checkGameOver()
    for x = 1, BOARD_WIDTH do
        if gameState.board[1][x] ~= 0 then
            gameState.gameOver = true;
            USGAPI.playSound(gamePath .. "game_over.wav", 90);
            return;
        end;
    end;
end;

-- Отрисовка блока с градиентом
local function drawBlock(x, y, colorIndex)
    local color = COLORS[colorIndex];
    if not color then return; end;

    local screenX = BOARD_OFFSET_X + (x - 1) * BLOCK_SIZE;
    local screenY = BOARD_OFFSET_Y + (y - 1) * BLOCK_SIZE;

    -- Основной цвет блока
    fillRect(screenX, screenY, BLOCK_SIZE, BLOCK_SIZE, color);

    -- Светлый градиент сверху
    fillRect(screenX, screenY, BLOCK_SIZE, 3, LIGHT_COLOR);

    -- Темный градиент снизу
    fillRect(screenX, screenY + BLOCK_SIZE - 3, BLOCK_SIZE, 3, DARK_COLOR);

    -- Контур
    drawRect(screenX, screenY, BLOCK_SIZE, BLOCK_SIZE, BORDER_COLOR);
end;

-- Отрисовка фигуры
local function drawPiece(piece, offsetX, offsetY)
    for y = 1, #piece.shape do
        for x = 1, #piece.shape[y] do
            if piece.shape[y][x] == 1 then
                local blockX = piece.x + x + offsetX;
                local blockY = piece.y + y + offsetY;
                if blockY >= 1 then
                    drawBlock(blockX, blockY, piece.color + 1);
                end;
            end;
        end;
    end;
end;

-- Отрисовка игрового поля
local function drawBoard()
    -- Фон поля
    fillRect(BOARD_OFFSET_X - 2, BOARD_OFFSET_Y - 2,
        BOARD_WIDTH * BLOCK_SIZE + 4, BOARD_HEIGHT * BLOCK_SIZE + 4,
        Color.new(30, 30, 30));

    -- Сетка поля
    for y = 1, BOARD_HEIGHT do
        for x = 1, BOARD_WIDTH do
            if gameState.board[y][x] ~= 0 then
                drawBlock(x, y, gameState.board[y][x]);
            end;
        end;
    end;

    -- Текущая фигура
    if gameState.currentPiece then
        drawPiece(gameState.currentPiece, 0, 0);
    end;
end;

-- Отрисовка UI
local function drawUI()
    -- Фон UI
    fillRect(10, 10, 120, 258, Color.new(40, 40, 40, 200));
    drawRect(10, 10, 120, 258, Color.new(100, 100, 100));

    -- Заголовок
    drawText(FONT_NAME, 15, 20, "TETRIS", COLOR_WHITE, 1.2);

    -- Счет
    drawText(FONT_NAME, 15, 45, "Score:", COLOR_GRAY, 0.8);
    drawText(FONT_NAME, 15, 60, tostring(gameState.score), Color.new(255, 255, 0));

    -- Уровень
    drawText(FONT_NAME, 15, 80, "Level:", COLOR_GRAY, 0.8);
    drawText(FONT_NAME, 15, 95, tostring(gameState.level), Color.new(0, 255, 255));

    -- Линии
    drawText(FONT_NAME, 15, 115, "Lines:", COLOR_GRAY, 0.8);
    drawText(FONT_NAME, 15, 130, tostring(gameState.lines), Color.new(255, 0, 255));

    -- Следующая фигура
    drawText(FONT_NAME, 15, 150, "Next:", COLOR_GRAY, 0.8);
    if gameState.nextPiece then
        local nextX = 15;
        local nextY = 165;
        for y = 1, #gameState.nextPiece.shape do
            for x = 1, #gameState.nextPiece.shape[y] do
                if gameState.nextPiece.shape[y][x] == 1 then
                    local blockX = nextX + (x - 1) * 8;
                    local blockY = nextY + (y - 1) * 8;
                    local color = COLORS[gameState.nextPiece.color + 1];
                    fillRect(blockX, blockY, 6, 6, color);
                    drawRect(blockX, blockY, 6, 6, BORDER_COLOR);
                end;
            end;
        end;
    end;

    -- Краткие инструкции (помещаются на экране)
    local texts = {
        "D-Pad: Move",
        "Down: Fast",
        "X: Rotate",
        "Square: Drop",
        "Select: Pause",
        "Start: Exit"
    };
    local textCol = Color.new(150, 150, 150);
    for i, text in ipairs(texts) do
        drawText(FONT_NAME, 15, 180 + i * 12, text, textCol, 0.7);
    end;
end;

-- Отрисовка экрана паузы
local function drawPauseScreen()
    fillRect(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT, Color.new(0, 0, 0, 150));
    drawText(FONT_NAME, SCREEN_WIDTH / 2 - 100, SCREEN_HEIGHT / 2 - 20, "PAUSED", COLOR_WHITE, 2.0);
    drawText(FONT_NAME, SCREEN_WIDTH / 2 - 100, SCREEN_HEIGHT / 2 + 10, "Press SELECT to continue",
        COLOR_GRAY, 1.0);
end;

-- Отрисовка экрана окончания игры
local function drawGameOverScreen()
    fillRect(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT, Color.new(0, 0, 0, 200));
    drawText(FONT_NAME, SCREEN_WIDTH / 2 - 100, SCREEN_HEIGHT / 2 - 40,
        "GAME OVER", Color.new(255, 0, 0), 2.5);
    drawText(FONT_NAME, SCREEN_WIDTH / 2 - 100, SCREEN_HEIGHT / 2,
        "Final Score: " .. gameState.score, Color.new(255, 255, 0), 1.5);
    drawText(FONT_NAME, SCREEN_WIDTH / 2 - 100, SCREEN_HEIGHT / 2 + 30,
        "Level: " .. gameState.level, Color.new(0, 255, 255), 1.2);
    drawText(FONT_NAME, SCREEN_WIDTH / 2 - 100, SCREEN_HEIGHT / 2 + 50,
        "Lines: " .. gameState.lines, Color.new(255, 0, 255), 1.2);
    drawText(FONT_NAME, SCREEN_WIDTH / 2 - 100, SCREEN_HEIGHT / 2 + 80,
        "Press X to restart", COLOR_WHITE, 1.0);
end;

-- Мгновенное падение фигуры
local function dropPiece()
    local dropDistance = 0;
    while not checkCollision(gameState.currentPiece, 0, 1) do
        gameState.currentPiece.y = gameState.currentPiece.y + 1;
        dropDistance = dropDistance + 1;
    end;

    -- Очки за быстрое падение (2 очка за каждый блок)
    gameState.score = gameState.score + (dropDistance * 2);

    -- Размещаем фигуру
    placePiece();
    clearLines();
    checkGameOver();

    if not gameState.gameOver then
        gameState.currentPiece = gameState.nextPiece;
        gameState.nextPiece = createPiece();

        -- Проверяем, можно ли разместить новую фигуру
        if checkCollision(gameState.currentPiece, 0, 0) then
            gameState.gameOver = true;
            USGAPI.playSound(gamePath .. "game_over.wav", 90);
        end;
    end;

    -- Воспроизводим звук падения
    USGAPI.playSound(gamePath .. "drop.wav", 80);
end;

-- Обработка ввода
local function handleInput()
    if gameState.gameOver then
        if buttonsPressed(buttons.cross) then
            -- Перезапуск игры
            initBoard();
            gameState.score = 0;
            gameState.level = 1;
            gameState.lines = 0;
            gameState.gameOver = false;
            gameState.currentPiece = createPiece();
            gameState.nextPiece = createPiece();
            gameState.dropSpeed = 1000;
            gameState.lastDrop = 0;
            USGAPI.playSound(gamePath .. "start.wav", 80);
        end;
        return;
    end;

    if gameState.paused then
        if buttonsPressed(buttons.select) then
            gameState.paused = false;
        end;
        return;
    end;

    if buttonsPressed(buttons.select) then
        gameState.paused = true;
        return;
    end;

    if buttonsPressed(buttons.start) then
        gameIsRunning = false;
        return;
    end;

    if not gameState.currentPiece then return; end;

    -- Движение влево
    if buttonsPressed(buttons.left) then
        if not checkCollision(gameState.currentPiece, -1, 0) then
            gameState.currentPiece.x = gameState.currentPiece.x - 1;
            USGAPI.playSound(gamePath .. "move.wav", 60);
        end;
    end;

    -- Движение вправо
    if buttonsPressed(buttons.right) then
        if not checkCollision(gameState.currentPiece, 1, 0) then
            gameState.currentPiece.x = gameState.currentPiece.x + 1;
            USGAPI.playSound(gamePath .. "move.wav", 60);
        end;
    end;

    -- Быстрое падение (кнопка вниз - удерживать)
    if buttons.held(buttons.down) then
        if not checkCollision(gameState.currentPiece, 0, 1) then
            gameState.currentPiece.y = gameState.currentPiece.y + 1;
            gameState.score = gameState.score + 1;
        end;
    end;

    -- Мгновенное падение (кнопка Square)
    if buttonsPressed(buttons.square) then
        dropPiece();
        return;
    end;

    -- Вращение
    if buttonsPressed(buttons.cross) then
        if not checkCollision(gameState.currentPiece, 0, 0, true) then
            -- Вращаем фигуру
            local shape = gameState.currentPiece.shape;
            local newShape = {};
            for i = 1, #shape[1] do
                newShape[i] = {};
                for j = 1, #shape do
                    newShape[i][j] = shape[#shape - j + 1][i];
                end;
            end;
            gameState.currentPiece.shape = newShape;
            USGAPI.playSound(gamePath .. "rotate.wav", 70);
        end;
    end;
end;

-- Обновление игры
local function updateGame()
    if gameState.gameOver or gameState.paused then return; end;

    local currentTime = os.clock() * 1000;

    -- Автоматическое падение
    if currentTime - gameState.lastDrop > gameState.dropSpeed then
        if not checkCollision(gameState.currentPiece, 0, 1) then
            gameState.currentPiece.y = gameState.currentPiece.y + 1;
        else
            -- Фигура достигла дна или другой фигуры
            placePiece();
            clearLines();
            checkGameOver();

            if not gameState.gameOver then
                gameState.currentPiece = gameState.nextPiece;
                gameState.nextPiece = createPiece();

                -- Проверяем, можно ли разместить новую фигуру
                if checkCollision(gameState.currentPiece, 0, 0) then
                    gameState.gameOver = true;
                    USGAPI.playSound(gamePath .. "game_over.wav", 90);
                end;
            end;
        end;
        gameState.lastDrop = currentTime;
    end;
end;

-- Основной игровой цикл
local function main()
    -- Инициализация
    initBoard();
    gameState.currentPiece = createPiece();
    gameState.nextPiece = createPiece();
    gameState.lastDrop = os.clock() * 1000;

    -- Воспроизводим стартовый звук
    USGAPI.playSound(gamePath .. "start.wav", 80);

    while gameIsRunning do
        -- Начало кадра
        USGAPI.startFrame(Color.new(20, 20, 30));

        -- Обработка ввода
        handleInput();

        -- Обновление игры
        updateGame();

        -- Отрисовка
        drawBoard();
        drawUI();

        if gameState.paused then
            drawPauseScreen();
        elseif gameState.gameOver then
            drawGameOverScreen();
        end;
    end;
end;

-- Запуск игры
main();
USGAPI.unloadAll();
