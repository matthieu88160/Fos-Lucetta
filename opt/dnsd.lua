local net = computer.getPCIDevices(findClass("NetworkCard"))[1]
net:open(53)
event.listen(net)

json = filesystem.doFile("/lib/json.lua")

local Logger = filesystem.doFile("/lib/Logger/Logger.lua")
local logger = Logger:new{filename = "/var/log/dns.log"}

local hostnameList = {}
if (filesystem.isFile("/etc/hostname")) then
    net:broadcast(53)
    local e, _, selfCard = event.pull()
    
    local hostnames = filesystem.open("/etc/hostname", "r")
    hostnameList[hostnames:read(100)] = selfCard
    hostnames:close()
end

while true do
    local e, receiver, sender, port, rawPayload, format = event.pull(1000)

    local error = e == nil
    if (format ~= "application/json") then
        logger:log(Logger.LEVEL_INFO, json.encode({sender = sender, rawPayload = rawPayload, message = "Not application/json format"}))
        error = true
    end

    local payload = json.decode(rawPayload)
    if (payload.type == nil) then
        logger:log(Logger.LEVEL_INFO, json.encode({sender = sender, rawPayload = rawPayload, message = "Missing request type"}))
        error = true
    end
    if (payload.hostname == nil) then
        logger:log(Logger.LEVEL_INFO, json.encode({sender = sender, rawPayload = rawPayload, message = "Missing request hostname"}))
        error = true
    end

    if (not error and payload.type == "register") then
        logger:log(Logger.LEVEL_DEBUG, json.encode({sender = sender, rawPayload = rawPayload, message = "Entry stored"}))
        hostnameList[payload.hostname] = sender

        net:send(
            sender,
            payload.clientPort,
            json.encode(
                {status = "Created", code = 201, contentType = "application/json", body = json.encode({data = "ack"})}
            ),
            "application/json"
        )
    elseif (not error and payload.type == "resolve") then
        logger:log(Logger.LEVEL_DEBUG, json.encode({sender = sender, rawPayload = rawPayload, message = "Entry requested"}))

        if (hostnameList[payload.hostname] ~= nil) then
            net:send(
                sender,
                payload.clientPort,
                json.encode(
                    {status = "Ok", code = 200, contentType = "application/json", body = json.encode({data = hostnameList[payload.hostname]})}
                ),
                "application/json"
            )
        else
            net:send(
                sender,
                payload.clientPort,
                json.encode(
                    {status = "Not found", code = 404, contentType = "application/json", body = json.encode({error = "Entry not found"})}
                ),
                "application/json"
            )
        end
    elseif (not error) then
        logger:log(Logger.LEVEL_INFO, json.encode({sender = sender, rawPayload = rawPayload, message = "Operation not recognized"}))

        net:send(
            sender,
            payload.clientPort,
            json.encode(
                {status = "Client error", code = 400, contentType = "application/json", body = json.encode({error = "Operation not recognized"})}
            ),
            "application/json"
        )
    else
        net:send(
            sender,
            payload.clientPort,
            json.encode(
                {status = "Client error", code = 400, contentType = "application/json", body = json.encode({error = "Unknown error"})}
            ),
            "application/json"
        )
    end
end
