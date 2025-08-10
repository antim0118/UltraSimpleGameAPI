local abs = math.abs;

---@param from number
---@param to number
---@param value number
---@return number
math.lerp = function(from, to, value)
    return from + (to - from) * value;
end;

---@param from number
---@param to number
---@param value number
---@return number
math.lerpWithClamp = function(from, to, value)
    if (abs(to - from) < 1) then return to; end;
    return from + (to - from) * value;
end;
