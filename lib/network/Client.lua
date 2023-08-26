local json = filesystem.doFile("/lib/json.lua")
local net = computer.getPCIDevices(findClass("NetworkCard"))[1]

local doSyncRequest = function(client, target, port, payload, timeout, procedure)
    local clientPort = client.currentPort

    net:open(clientPort)

    for k,v in pairs({clientPort = clientPort}) do payload[k] = v end
    procedure(target, port, json.encode(payload))

    local e, receiver, sender, port, responsePayload, format = event.pull(timeout)
    net:close(clientPort)

    if (responsePayload ~= nil and format == "application/json") then
        responsePayload = json.decode(responsePayload)
    end

    client.currentPort = client.currentPort + 1
    if (client.currentPort > client.maxPort) then
        client.currentPort = client.minPort
    end

    return responsePayload
end

local Client = {
    minPort = 3000,
    maxPort = 4000,
    currentPort = 3000,
    syncSend = function (self, target, port, payload, timeout)
        local procedure = function(target, port, payload)
            net:send(target, port, payload, "application/json")
        end

        return doSyncRequest(self, target, port, payload, timeout, procedure)
    end,
    
    syncBroadcast = function (self, port, payload, timeout)
        local procedure = function(_, port, payload)
            net:broadcast(port, payload, "application/json")
        end
        
        return doSyncRequest(self, nil, port, payload, timeout, procedure)
    end
}

function Client:new(config)
    o = config or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

return Client
