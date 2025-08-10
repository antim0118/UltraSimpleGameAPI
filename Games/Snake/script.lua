-- Ассеты (пример/плейсхолдеры, см. инструкции в конце файла):
-- Глобальные: Fonts/arial.ttf
-- Локальные (в папке игры): eat.wav, gameover.wav (по желанию)

local USGAPI                  = require("Scripts.USGAPI");

-- Инициализация
local gamePath                = USGAPI.getGamePath();

-- Кеш цветов
local colors                  = {
    white  = Color.new(255, 255, 255),
    black  = Color.new(0, 0, 0),
    red    = Color.new(255, 0, 0),
    green  = Color.new(0, 200, 0),
    lgreen = Color.new(100, 255, 100),
    yellow = Color.new(255, 215, 0),
    gray   = Color.new(60, 60, 60),
    bg     = Color.new(20, 20, 20),
    grid   = Color.new(40, 40, 40)
};

-- Константы поля 30x17 (16px клетки = ровно 480x272)
local CELL_SIZE               = 16;
local GRID_COLS               = 30;
local GRID_ROWS               = 17;
local BOARD_W                 = GRID_COLS * CELL_SIZE; -- 480
local BOARD_H                 = GRID_ROWS * CELL_SIZE; -- 272

-- Скорость (кадры на шаг змейки)
local INITIAL_FRAMES_PER_STEP = 8; -- стартовая «медленнее — больше число»
local MIN_FRAMES_PER_STEP     = 3; -- потолок ускорения
local SPEEDUP_EVERY_FOOD      = 5; -- каждые N фруктов ускоряемся на 1 кадр

-- Состояние игры
local state                   = {
    running = true,
    alive = true,
    score = 0,
    framesPerStep = INITIAL_FRAMES_PER_STEP,
    framesSinceMove = 0,
    dirX = 1,
    dirY = 0,   -- текущее направление
    nextDX = 1,
    nextDY = 0, -- направление, выбранное игроком
    snake = {}, -- массив сегментов { {x=..,y=..}, ... } голова = [1]
    food = { x = 0, y = 0 },
    frame = 0,
};

-- Утилиты
local function randInt(min, max)
    return math.floor(math.random() * (max - min + 1)) + min;
end;

local function indexToXY(i)
    -- вспомогательная, если бы сканировали поле; не используется в текущей логике
    local y = math.floor(i / GRID_COLS);
    local x = i - y * GRID_COLS;
    return x, y;
end;

local function spawnFood()
    -- Случайно ищем свободную клетку
    for _ = 1, 1024 do
        local fx = randInt(0, GRID_COLS - 1);
        local fy = randInt(0, GRID_ROWS - 1);
        local collides = false;
        for i = 1, #state.snake do
            local s = state.snake[i];
            if s.x == fx and s.y == fy then
                collides = true; break;
            end;
        end;
        if not collides then
            state.food.x = fx; state.food.y = fy;
            return;
        end;
    end;
    -- Фолбэк (на случай почти полного поля): линейный поиск
    for y = 0, GRID_ROWS - 1 do
        for x = 0, GRID_COLS - 1 do
            local collides = false;
            for i = 1, #state.snake do
                local s = state.snake[i];
                if s.x == x and s.y == y then
                    collides = true; break;
                end;
            end;
            if not collides then
                state.food.x = x; state.food.y = y;
                return;
            end;
        end;
    end;
end;

local function resetGame()
    state.alive = true;
    state.score = 0;
    state.framesPerStep = INITIAL_FRAMES_PER_STEP;
    state.framesSinceMove = 0;
    state.dirX, state.dirY = 1, 0;
    state.nextDX, state.nextDY = 1, 0;
    state.snake = {};

    -- Начальная змейка по центру, длиной 4, направлена вправо
    local startX = math.floor(GRID_COLS / 2) - 2;
    local startY = math.floor(GRID_ROWS / 2);
    state.snake[1] = { x = startX + 3, y = startY };
    state.snake[2] = { x = startX + 2, y = startY };
    state.snake[3] = { x = startX + 1, y = startY };
    state.snake[4] = { x = startX + 0, y = startY };

    spawnFood();
end;

local function trySetDirection(dx, dy)
    -- Запрещаем мгновенный разворот на 180°
    if dx ~= 0 and state.dirX ~= 0 then return; end;
    if dy ~= 0 and state.dirY ~= 0 then return; end;
    state.nextDX = dx; state.nextDY = dy;
end;

local function handleInput()
    if buttons.held(buttons.left) then trySetDirection(-1, 0); end;
    if buttons.held(buttons.right) then trySetDirection(1, 0); end;
    if buttons.held(buttons.up) then trySetDirection(0, -1); end;
    if buttons.held(buttons.down) then trySetDirection(0, 1); end;
end;

local function speedByScore()
    local bonus = math.floor(state.score / SPEEDUP_EVERY_FOOD);
    local fps = INITIAL_FRAMES_PER_STEP - bonus;
    if fps < MIN_FRAMES_PER_STEP then fps = MIN_FRAMES_PER_STEP; end;
    return fps;
end;

local function stepSnake()
    -- Применяем запрошенное направление, если не противоположно текущему
    if not (state.nextDX == -state.dirX and state.nextDY == -state.dirY) then
        state.dirX, state.dirY = state.nextDX, state.nextDY;
    end;

    local head = state.snake[1];
    local newX = head.x + state.dirX;
    local newY = head.y + state.dirY;

    -- Столкновение со стеной
    if newX < 0 or newX >= GRID_COLS or newY < 0 or newY >= GRID_ROWS then
        state.alive = false;
        USGAPI.playSound(gamePath .. "gameover.wav", 80);
        return;
    end;

    -- Столкновение с собой
    for i = 1, #state.snake do
        if state.snake[i].x == newX and state.snake[i].y == newY then
            state.alive = false;
            USGAPI.playSound(gamePath .. "gameover.wav", 80);
            return;
        end;
    end;

    -- Двигаем голову
    table.insert(state.snake, 1, { x = newX, y = newY });

    -- Проверка еды
    if newX == state.food.x and newY == state.food.y then
        state.score = state.score + 1;
        state.framesPerStep = speedByScore();
        USGAPI.playSound(gamePath .. "eat.wav", 90);
        spawnFood();
    else
        -- Не выросли — убрать хвост
        table.remove(state.snake);
    end;
end;

local function update()
    handleInput();

    state.frame = state.frame + 1; if state.frame > 1000000 then state.frame = 0; end;

    if not state.alive then
        -- Ожидаем рестарт по Cross
        if buttons.held(buttons.cross) then
            resetGame();
        end;
        return;
    end;

    state.framesSinceMove = state.framesSinceMove + 1;
    if state.framesSinceMove >= state.framesPerStep then
        state.framesSinceMove = 0;
        stepSnake();
    end;
end;

local function drawBoard()
    -- Фон поля
    USGAPI.fillRect(0, 0, BOARD_W, BOARD_H, colors.bg);
    -- Сетка
    for c = 1, GRID_COLS - 1 do
        local x = c * CELL_SIZE;
        USGAPI.drawLine(x, 0, x, BOARD_H, colors.grid);
    end;
    for r = 1, GRID_ROWS - 1 do
        local y = r * CELL_SIZE;
        USGAPI.drawLine(0, y, BOARD_W, y, colors.grid);
    end;
    -- Рамка поля
    USGAPI.drawRect(0, 0, BOARD_W - 1, BOARD_H - 1, colors.white);
end;

local function drawFood()
    local x = state.food.x * CELL_SIZE;
    local y = state.food.y * CELL_SIZE;
    USGAPI.fillRect(x, y, CELL_SIZE, CELL_SIZE, colors.red);
    -- Блик/анимация
    local pulse = (state.frame % 30) < 15;
    if pulse then
        USGAPI.fillRect(x + 4, y + 4, 5, 5, colors.yellow);
    else
        USGAPI.fillRect(x + 5, y + 5, 3, 3, colors.white);
    end;
end;

local function drawSnake()
    for i = 1, #state.snake do
        local seg = state.snake[i];
        local sx = seg.x * CELL_SIZE;
        local sy = seg.y * CELL_SIZE;
        local col = (i == 1) and colors.yellow or colors.green;
        -- Тело
        USGAPI.fillRect(sx, sy, CELL_SIZE, CELL_SIZE, col);
        -- Контур сегмента
        USGAPI.drawRect(sx, sy, CELL_SIZE, CELL_SIZE, colors.lgreen);

        -- Глаза у головы
        if i == 1 then
            local eyeSize = 3;
            local margin = 3;
            if state.dirX == 1 then
                local ex = sx + CELL_SIZE - margin - eyeSize;
                USGAPI.fillRect(ex, sy + 4, eyeSize, eyeSize, colors.black);
                USGAPI.fillRect(ex, sy + CELL_SIZE - eyeSize - 4, eyeSize, eyeSize, colors.black);
            elseif state.dirX == -1 then
                local ex = sx + margin;
                USGAPI.fillRect(ex, sy + 4, eyeSize, eyeSize, colors.black);
                USGAPI.fillRect(ex, sy + CELL_SIZE - eyeSize - 4, eyeSize, eyeSize, colors.black);
            elseif state.dirY == 1 then
                local ey = sy + CELL_SIZE - margin - eyeSize;
                USGAPI.fillRect(sx + 4, ey, eyeSize, eyeSize, colors.black);
                USGAPI.fillRect(sx + CELL_SIZE - eyeSize - 4, ey, eyeSize, eyeSize, colors.black);
            else -- state.dirY == -1
                local ey = sy + margin;
                USGAPI.fillRect(sx + 4, ey, eyeSize, eyeSize, colors.black);
                USGAPI.fillRect(sx + CELL_SIZE - eyeSize - 4, ey, eyeSize, eyeSize, colors.black);
            end;
        end;
    end;
end;

local function drawUI()
    -- Панель счёта
    USGAPI.fillRect(4, 4, 120, 22, colors.black);
    USGAPI.drawRect(4, 4, 120, 22, colors.gray);
    USGAPI.drawText("Fonts/arial.ttf", 10, 8, "Score: " .. state.score, colors.white, 1.0);

    if not state.alive then
        local panelW, panelH = 280, 90;
        local px = math.floor((BOARD_W - panelW) / 2);
        local py = math.floor((BOARD_H - panelH) / 2);
        USGAPI.fillRect(px, py, panelW, panelH, colors.black);
        USGAPI.drawRect(px, py, panelW, panelH, colors.white);
        USGAPI.drawText("Fonts/arial.ttf", px + 66, py + 22, "GAME OVER", colors.white, 1.5);
        USGAPI.drawText("Fonts/arial.ttf", px + 34, py + 54, "Press Cross to restart", colors.white, 1.0);
    end;
end;

-- Подготовка игры
resetGame();

-- Главный цикл
while true do
    USGAPI.startFrame();
    if buttons.held(buttons.start) then break; end;

    update();

    -- Отрисовка
    drawBoard();
    drawFood();
    drawSnake();
    drawUI();
end;

-- Инструкции по ассетам (для удобства — комментарий):
-- 1) Поместите шрифт: Fonts/arial.ttf (глобальная папка ресурсов)
-- 2) Доп. звуки (необязательно): в папку игры рядом со script.lua
--    <gamePath>eat.wav, <gamePath>gameover.wav
--    Если файлов нет, игра всё равно запустится (USGAPI сам кэширует и проигрывает при наличии).
