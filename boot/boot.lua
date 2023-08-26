-- initialize json.lua
if (not fs.isFile("/lib/json.lua")) then
    local card = computer.getPCIDevices(findClass("FINInternetCard"))[1]
    
    local req = card:request("https://raw.githubusercontent.com/rxi/json.lua/master/json.lua", "GET", "")
    local _, libdata = req:await()
    local file = filesystem.open("/lib/json.lua", "w")
    file:write(libdata)
    file:close()
end
