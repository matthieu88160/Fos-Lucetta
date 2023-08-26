local Logger = {
    filename = nil,
    file = nil,
    LEVEL_DEBUG = "DEBUG",
    LEVEL_NOTICE = "NOTICE",
    LEVEL_INFO = "INFO",
    LEVEL_WARNING = "WARNING",
    LEVEL_ERROR = "ERROR",
    LEVEL_CRITICAL = "CRITICAL",
    LEVEL_EMERGENCY = "EMERGENCY",
}

function Logger:new(config)
    o = config or {filename = nil, file = nil}
    setmetatable(o, self)
    self.__index = self
    return o
end

function Logger:log(severity, message)
    if (self.file == nil) then
        self.file = filesystem.open(self.filename, "+a")
    end

    local t, time = computer.magicTime()
    self.file:write("["..time.."]"..severity..": "..message.."\n")
    self.file:close()
    self.file = nil
end

return Logger