local USGAPI = require("Libs.USGAPI");

-- Получение пути к игре
local gamePath = USGAPI.getGamePath();

-- Константы
local SCREEN_WIDTH = 480;
local SCREEN_HEIGHT = 272;
local HEART_SIZE = 16;
local BULLET_SIZE = 8;


-- Состояния игры
local GAME_STATE = {
    MENU = 1,
    DIALOG = 2,
    BATTLE = 3,
    GAME_OVER = 4
};

-- Текущее состояние
local gameState = GAME_STATE.MENU;

-- Игровые переменные
local player = {
    x = SCREEN_WIDTH / 2,
    y = SCREEN_HEIGHT / 2,
    hp = 20,
    maxHp = 20
};

local menu = {
    selected = 1,
    options = { "START", "CONTINUE", "EXIT" }
};

---@type UndertaleBoss
local currentBoss = nil;
local bullets = {};
local dialogIndex = 1;
local dialogText = "";
local dialogTimer = 0;
local battleTimer = 0;

local gameIsRunning = true;

-- Цвета
local colors = {
    white = Color.new(255, 255, 255),
    red = Color.new(255, 0, 0),
    blue = Color.new(0, 0, 255),
    orange = Color.new(255, 165, 0),
    black = Color.new(0, 0, 0),
    yellow = Color.new(255, 255, 0)
};

---@alias UndertaleBoss {name:string, sprite:string, fullSprite: string, background:string, music:string, dialog: string[], bulletPattern:string }

--- Боссы и их данные
---@type UndertaleBoss[]
local bosses = {
    {
        name = "Toriel",
        sprite = "toriel.png",
        fullSprite = "toriel_full.png",
        background = "background_ruins.png",
        music = "ruins_theme.at3",
        dialog = {
            "Howdy! I'm Toriel, caretaker of the \nRuins.",
            "I pass through this place every day \nto see if anyone has fallen down.",
            "You are the first human to come here \nin a long time.",
            "Come! I will guide you through the \ncatacombs."
        },
        bulletPattern = "simple"
    },
    {
        name = "Papyrus",
        sprite = "papyrus.png",
        fullSprite = "papyrus_full.png",
        background = "background_snowdin.png",
        music = "snowdin_theme.at3",
        dialog = {
            "NYEH HEH HEH!",
            "I, THE GREAT PAPYRUS, WILL CAPTURE \nYOU!",
            "PREPARE YOURSELF FOR MY SPECIAL \nATTACK!",
            "NYEH HEH HEH HEH!"
        },
        bulletPattern = "blue_red"
    },
    {
        name = "Undyne",
        sprite = "undyne.png",
        fullSprite = "undyne_full.png",
        background = "background_waterfall.png",
        music = "waterfall_theme.at3",
        dialog = {
            "You're not going anywhere!",
            "I'll make sure you never see the \nlight of day again!",
            "DIE, HUMAN!"
        },
        bulletPattern = "fast"
    },
    {
        name = "Mettaton",
        sprite = "mettaton.png",
        fullSprite = "mettaton_full.png",
        background = "background_hotland.png",
        music = "hotland_theme.at3",
        dialog = {
            "OH YES!",
            "WELCOME TO THE HOTTEST SHOW IN THE \nUNDERGROUND!",
            "I'M METTATON!",
            "LET'S MAKE THIS ENTERTAINING!"
        },
        bulletPattern = "orange"
    },
    {
        name = "Asgore",
        sprite = "asgore.png",
        fullSprite = "asgore_full.png",
        background = "background_ruins.png",
        music = "final_battle.at3",
        dialog = {
            "I am so sorry, my child.",
            "But I cannot let you leave.",
            "I must destroy you.",
            "For the sake of all monsterkind."
        },
        bulletPattern = "final"
    }
};

local random = function(from, to)
    return math.random() * (to - from) + from;
end;

local currentBossIndex = 1;

-- Функции инициализации
local function initGame()
    player.x = SCREEN_WIDTH / 2;
    player.y = SCREEN_HEIGHT / 2;
    player.hp = player.maxHp;
    gameState = GAME_STATE.MENU;
    menu.selected = 1;
    bullets = {};
    dialogIndex = 1;
    dialogTimer = 0;
    battleTimer = 0;
end;

-- Функции боя
local function startNewGame()
    if (currentBoss) then
        USGAPI.stopSound(gamePath .. "assets/music/" .. currentBoss.music);
    end;
    currentBossIndex = 1;
    currentBoss = bosses[currentBossIndex];
    dialogIndex = 1;
    dialogText = currentBoss.dialog[1];
    gameState = GAME_STATE.DIALOG;
    USGAPI.playSound(gamePath .. "assets/music/" .. currentBoss.music, 80);
end;

local function startBattle()
    gameState = GAME_STATE.BATTLE;
    bullets = {};
    battleTimer = 0;
    USGAPI.playSound(gamePath .. "assets/sounds/battle_start.wav");
end;

local function endBattle(spared)
    if spared then
        currentBossIndex = currentBossIndex + 1;
        if currentBossIndex > #bosses then
            -- Игра завершена
            gameState = GAME_STATE.MENU;
            USGAPI.playSound(gamePath .. "assets/sounds/save_point.wav");
        else
            if (currentBoss) then
                USGAPI.stopSound(gamePath .. "assets/music/" .. currentBoss.music);
            end;
            -- Следующий босс
            currentBoss = bosses[currentBossIndex];
            dialogIndex = 1;
            dialogText = currentBoss.dialog[1];
            gameState = GAME_STATE.DIALOG;
            USGAPI.playSound(gamePath .. "assets/music/" .. currentBoss.music, 80);
        end;
    else
        -- Game Over
        gameState = GAME_STATE.GAME_OVER;
        USGAPI.playSound(gamePath .. "assets/sounds/game_over.wav");
    end;
end;

-- Функции обработки ввода
local function handleMenuInput()
    if buttons.pressed(buttons.up) then
        menu.selected = menu.selected - 1;
        if menu.selected < 1 then menu.selected = #menu.options; end;
        USGAPI.playSound(gamePath .. "assets/sounds/menu_select.wav");
    elseif buttons.pressed(buttons.down) then
        menu.selected = menu.selected + 1;
        if menu.selected > #menu.options then menu.selected = 1; end;
        USGAPI.playSound(gamePath .. "assets/sounds/menu_select.wav");
    elseif buttons.pressed(buttons.cross) then
        USGAPI.playSound(gamePath .. "assets/sounds/menu_confirm.wav");
        if menu.selected == 1 then     -- START
            startNewGame();
        elseif menu.selected == 2 then -- CONTINUE
            startNewGame();            -- Упрощенно, всегда начинаем новую игру
        elseif menu.selected == 3 then -- EXIT
            gameIsRunning = false;
        end;
    end;
end;

local function handleBattleInput()
    -- Движение сердца
    if buttons.held(buttons.up) and player.y > 50 then
        player.y = player.y - 3;
    end;
    if buttons.held(buttons.down) and player.y < SCREEN_HEIGHT - 50 then
        player.y = player.y + 3;
    end;
    if buttons.held(buttons.left) and player.x > 50 then
        player.x = player.x - 3;
    end;
    if buttons.held(buttons.right) and player.x < SCREEN_WIDTH - 50 then
        player.x = player.x + 3;
    end;

    -- Действия в бою
    if buttons.pressed(buttons.cross) then -- SPARE
        USGAPI.playSound(gamePath .. "assets/sounds/spare_success.wav");
        endBattle(true);
    elseif buttons.pressed(buttons.circle) then -- FIGHT
        USGAPI.playSound(gamePath .. "assets/sounds/battle_start.wav");
        -- Упрощенно, сразу побеждаем
        endBattle(true);
    end;
end;

local function handleDialogInput()
    if buttons.pressed(buttons.cross) then
        USGAPI.playSound(gamePath .. "assets/sounds/dialog_next.wav");
        dialogIndex = dialogIndex + 1;
        if dialogIndex > #currentBoss.dialog then
            startBattle();
        else
            dialogText = currentBoss.dialog[dialogIndex];
        end;
    end;
end;

-- Функции отрисовки
local function drawMenu()
    -- Фон
    USGAPI.fillRect(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT, colors.black);

    -- Заголовок
    USGAPI.drawText(gamePath .. "assets/fonts/undertale.ttf", SCREEN_WIDTH / 2 - 100, 50, "UNDERTALE", colors.white, 2.0);

    -- Опции меню
    for i, option in ipairs(menu.options) do
        local color = (i == menu.selected) and colors.yellow or colors.white;
        local y = 120 + (i - 1) * 40;
        USGAPI.drawText(gamePath .. "assets/fonts/undertale.ttf", SCREEN_WIDTH / 2 - 50, y, option, color, 1.0);
    end;
end;

local function drawBattle()
    -- Фон
    USGAPI.drawTexture(gamePath .. "assets/sprites/" .. currentBoss.background, 0, 0);

    -- UI рамка
    USGAPI.drawTexture(gamePath .. "assets/sprites/ui_frame.png", 0, 0);

    -- Сердце игрока
    USGAPI.drawTexture(gamePath .. "assets/sprites/heart.png", player.x - HEART_SIZE / 2, player.y - HEART_SIZE / 2);

    -- Пульсы
    for _, bullet in ipairs(bullets) do
        local bulletSprite = "";
        if bullet.type == "red" then
            bulletSprite = "bullet_red.png";
        elseif bullet.type == "blue" then
            bulletSprite = "bullet_blue.png";
        elseif bullet.type == "orange" then
            bulletSprite = "bullet_orange.png";
        end;
        USGAPI.drawTexture(gamePath .. "assets/sprites/" .. bulletSprite, bullet.x - BULLET_SIZE / 2,
            bullet.y - BULLET_SIZE / 2);
    end;

    -- Спрайт босса
    USGAPI.drawTexture(gamePath .. "assets/sprites/" .. currentBoss.sprite, SCREEN_WIDTH - 100, 50);

    -- HP
    USGAPI.drawText(gamePath .. "assets/fonts/undertale.ttf", 28, 30, "HP: " .. player.hp .. "/" .. player.maxHp,
        colors.white,
        1.0);

    -- Имя босса
    USGAPI.drawText(gamePath .. "assets/fonts/undertale.ttf", 28, 50, currentBoss.name, colors.white, 1.0);
end;

local function drawDialog()
    -- Фон
    USGAPI.fillRect(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT, colors.black);

    -- Спрайт босса
    USGAPI.drawTexture(gamePath .. "assets/sprites/" .. currentBoss.fullSprite, 176, 30);

    -- Рамка диалога
    USGAPI.drawTexture(gamePath .. "assets/sprites/menu_frame.png", 50, 150);

    -- Текст диалога
    USGAPI.drawText(gamePath .. "assets/fonts/undertale.ttf", 90, 190, dialogText, colors.white, 1);
end;

local function drawGameOver()
    -- Фон
    USGAPI.fillRect(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT, colors.black);

    -- Текст Game Over
    USGAPI.drawText(gamePath .. "assets/fonts/undertale.ttf", SCREEN_WIDTH / 2 - 80, SCREEN_HEIGHT / 2 - 50, "GAME OVER",
        colors.red, 2.0);
    USGAPI.drawText(gamePath .. "assets/fonts/undertale.ttf", SCREEN_WIDTH / 2 - 100, SCREEN_HEIGHT / 2 + 20,
        "Press X to restart", colors.white, 1.0);
end;

-- Система пуль
local function createBulletPattern()
    if currentBoss.bulletPattern == "simple" then
        -- Простые красные пули
        for i = 1, 3 do
            table.insert(bullets, {
                x = random(100, SCREEN_WIDTH - 100),
                y = -20,
                vx = 0,
                vy = 2,
                type = "red"
            });
        end;
    elseif currentBoss.bulletPattern == "blue_red" then
        -- Синие и красные пули
        for i = 1, 2 do
            table.insert(bullets, {
                x = random(100, SCREEN_WIDTH - 100),
                y = -20,
                vx = 0,
                vy = 1.5,
                type = "blue"
            });
        end;
        for i = 1, 2 do
            table.insert(bullets, {
                x = random(100, SCREEN_WIDTH - 100),
                y = SCREEN_HEIGHT + 20,
                vx = 0,
                vy = -1.5,
                type = "red"
            });
        end;
    elseif currentBoss.bulletPattern == "fast" then
        -- Быстрые пули
        for i = 1, 4 do
            table.insert(bullets, {
                x = random(100, SCREEN_WIDTH - 100),
                y = -20,
                vx = 0,
                vy = 3,
                type = "red"
            });
        end;
    elseif currentBoss.bulletPattern == "orange" then
        -- Оранжевые пули
        for i = 1, 3 do
            table.insert(bullets, {
                x = random(100, SCREEN_WIDTH - 100),
                y = -20,
                vx = 0,
                vy = 2,
                type = "orange"
            });
        end;
    elseif currentBoss.bulletPattern == "final" then
        -- Финальный паттерн - все типы пуль
        for i = 1, 2 do
            table.insert(bullets, {
                x = random(100, SCREEN_WIDTH - 100),
                y = -20,
                vx = 0,
                vy = 2,
                type = "red"
            });
        end;
        for i = 1, 2 do
            table.insert(bullets, {
                x = random(100, SCREEN_WIDTH - 100),
                y = -20,
                vx = 0,
                vy = 1.5,
                type = "blue"
            });
        end;
        for i = 1, 2 do
            table.insert(bullets, {
                x = random(100, SCREEN_WIDTH - 100),
                y = -20,
                vx = 0,
                vy = 2,
                type = "orange"
            });
        end;
    end;
end;

local function updateBullets()
    for i = #bullets, 1, -1 do
        local bullet = bullets[i];
        bullet.x = bullet.x + bullet.vx;
        bullet.y = bullet.y + bullet.vy;

        -- Удаление пуль за пределами экрана
        if bullet.y < -50 or bullet.y > SCREEN_HEIGHT + 50 or
            bullet.x < -50 or bullet.x > SCREEN_WIDTH + 50 then
            table.remove(bullets, i);
        end;
    end;
end;

local function checkCollisions()
    for _, bullet in ipairs(bullets) do
        local dx = player.x - bullet.x;
        local dy = player.y - bullet.y;
        local distance = math.sqrt(dx * dx + dy * dy);

        if distance < HEART_SIZE / 2 + BULLET_SIZE / 2 then
            -- Коллизия с пулей
            if bullet.type == "red" then
                -- Красная пуля - урон
                player.hp = player.hp - 5;
                USGAPI.playSound(gamePath .. "assets/sounds/heart_hurt.wav");
                if player.hp <= 0 then
                    endBattle(false);
                end;
            elseif bullet.type == "blue" then
                -- Синяя пуля - урон только при движении
                if buttons.held(buttons.up) or buttons.held(buttons.down) or
                    buttons.held(buttons.left) or buttons.held(buttons.right) then
                    player.hp = player.hp - 5;
                    USGAPI.playSound(gamePath .. "assets/sounds/heart_hurt.wav");
                    if player.hp <= 0 then
                        endBattle(false);
                    end;
                end;
            elseif bullet.type == "orange" then
                -- Оранжевая пуля - урон только при неподвижности
                if not (buttons.held(buttons.up) or buttons.held(buttons.down) or
                        buttons.held(buttons.left) or buttons.held(buttons.right)) then
                    player.hp = player.hp - 5;
                    USGAPI.playSound(gamePath .. "assets/sounds/heart_hurt.wav");
                    if player.hp <= 0 then
                        endBattle(false);
                    end;
                end;
            end;
        end;
    end;
end;

-- Функции обновления
local function updateMenu()
    handleMenuInput();
end;

local function updateBattle()
    handleBattleInput();
    updateBullets();
    checkCollisions();
    battleTimer = battleTimer + 1;

    -- Создание пуль в зависимости от паттерна
    if battleTimer % 60 == 0 then -- Каждую секунду
        createBulletPattern();
    end;
end;

local function updateDialog()
    handleDialogInput();
end;

local function updateGameOver()
    if buttons.pressed(buttons.cross) then
        initGame();
    end;
end;

-- Основной игровой цикл
local function main()
    initGame();

    while gameIsRunning do
        USGAPI.startFrame();

        -- Обновление в зависимости от состояния
        if gameState == GAME_STATE.MENU then
            updateMenu();
            drawMenu();
        elseif gameState == GAME_STATE.DIALOG then
            updateDialog();
            drawDialog();
        elseif gameState == GAME_STATE.BATTLE then
            updateBattle();
            drawBattle();
        elseif gameState == GAME_STATE.GAME_OVER then
            updateGameOver();
            drawGameOver();
        end;

        if buttons.pressed(buttons.start) then break; end;
    end;
end;

-- Запуск игры
main();
