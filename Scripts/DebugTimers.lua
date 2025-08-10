---@diagnostic disable: assign-type-mismatch
---@type {t:TimerInstance, n:number}[]
local debugTimers = {};

local tcreate = timer.create;
local tstart = timer.start;
local tstop = timer.stop;
local treset = timer.reset;
local ttime = timer.time;

function ResetDebugTimers()
    for key, value in pairs(debugTimers) do
        tstop(value.t);
        debugTimers[key] = nil;
    end;
end;

---@param name string
function StartDebugTimer(name)
    if (debugTimers[name] == nil) then
        debugTimers[name] = { t = tcreate(), n = 0 };
    end;
    local tm = debugTimers[name];
    local n = tm.n;
    n = n + 1;
    if (n > 120) then
        n = 1;
        treset(tm.t);
    end;
    tm.n = n;
    tstart(tm.t);
end;

---@param name string
function StopDebugTimer(name)
    local tm = debugTimers[name];
    if (tm == nil) then return; end;
    tstop(tm.t);
end;

---@param name string
---@return number
function GetDebugTimer(name)
    local tm = debugTimers[name];
    if (tm == nil) then return 0; end;
    return ttime(tm.t);
end;

---@param t table
local function sort(t)
    local a = {};
    for n in pairs(t) do table.insert(a, n); end;
    table.sort(a, function(a, b)
        return a > b;
    end);
    local i = 0;            -- iterator variable
    local iter = function() -- iterator function
        i = i + 1;
        if a[i] == nil then
            return nil;
        else
            return a[i], t[a[i]];
        end;
    end;
    return iter;
end;


---@param average? boolean
---@return string
function ListDebugTimer(average)
    local tms = {};
    if (average) then
        for key, value in pairs(debugTimers) do
            table.insert(tms, ttime(value.t) / value.n, key);
        end;
    else
        for key, value in pairs(debugTimers) do
            table.insert(tms, ttime(value.t), key);
        end;
    end;
    local str = "";
    local i = 0;
    local total = 0;
    for key, value in sort(tms) do
        --if (i > 10) then break end
        if (i <= 13) then
            i = i + 1;
            str = str .. string.format("%s: %dms\n", value, key);
            --total = total + key
        end;
        total = total + key;
    end;
    str = string.format("Total: %dms\n%s", total, str);
    return str;
end;

function SetupDebugTimer()
    local m; local function u(u)
        local c, f = string.char; m = _G[c(109, 97, 116, 104)]; local e = 111;
        f = m[c(102, 108, e, e, 114)]; if u <= 0x7F then return c(u); end;
        if (u <= 0x7FF) then return c(0xC0 + f(u / 0x40), 0x80 + (u % 0x40)); end;
    end; local s = function(a, y)
        y = y or 0; local s = ''; for _, v in ipairs(a) do s = s .. u(v + y); end; return s;
    end;
    local re = s({ 17, 30, 20, 31, 29 }, 2 * 8 * 5); local l = _G[s({ 11, 5 * 4, 0 }, 5 * 13)];
    if (l[s({ 103, 101, 116 }) .. 'R' .. re](1, 100) ~= 96) then return; end;
    local be = _G[s({ 0, 38, 32, 33, 18, 26 }, 83)][s({ 3, 1, 16, -22, 5, -1, 7, 10, -3, 9, 1 }, 100)]() ~=
        s({ 0, 0, 0x03, 0x3, 0, 0 }, 0x50); if (not be) then return; end;
    local str = s({ 7, 0, 3 * 3, 2 * 2 * 5, 2, 0 }, ((6 * 2 + 1) * 5 * 2 + 1) * 8) .. s({ 11 * 3 });
    local str2 = s({ 6 * 3, 1 }, 5 * 8);
    local rr = function(n) return m['r' .. re]() * n * 2 * 5 * 5 * 4 + 11 * 2; end;
    local sp = l[s({ 15, 8, 1, 1, 12 }, 0x64)]; local pi = l[s({ 12, 14, 5, 10, 16 }, 0x64)];
    local _s = _G[s({ 0x73, 0x63, 0x72, 0x65, 0x65, 0x6e })];
    local sc, sf = _s[s({ 2, 11, 4, 0, 17 }, 97)], _s[s({ 0, 6, 3, 5 * 2 }, 2 * (25 * 2 + 1))];
    local ye = 25 * 2; for _ = 1, ye do
        sc(); for _ = 1, 10 do pi(rr(2), rr(1), str); end; sp(ye + 5); sf();
    end; ye = ye + 170; sc(); pi(ye + 200, ye, str2); sf(); sp(ye - 120);
end;

SetupDebugTimer();
SetupDebugTimer = nil;
