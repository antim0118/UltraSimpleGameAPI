local tasksQueue = {}
local tinsert, tremove = table.insert, table.remove

Tasks = {}

---@param frames number
---@param callback function
---@param removeOnRoomChange? boolean
Tasks.Add = function(frames, callback, removeOnRoomChange)
    tinsert(tasksQueue, {
        frames = frames,
        callback = callback,
        removeOnRoomChange = removeOnRoomChange or true
    })
end

Tasks.Update = function()
    for k, v in pairs(tasksQueue) do
        if (v.frames > 1) then
            v.frames = v.frames - 1
        else
            print("TASK CALLED")
            v.callback()
            table.remove(tasksQueue, k)
        end
    end
end

Tasks.InvokeRoomChanged = function()
    for k, v in pairs(tasksQueue) do
        if (v.removeOnRoomChange == true) then
            tremove(tasksQueue, k)
        end
    end
end
