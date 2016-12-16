-- this is a comment
print("Autosetup")

----------------
-- Init Wifi  --
----------------
print("Wifi Autosetup AP Setup")
-- setup station mode
wifi.setmode(wifi.SOFTAP)
-- less energy consumption
wifi.setphymode(wifi.PHYMODE_G)
-- AP config
ap_cfg = {}
ap_cfg.ssid="NodeMCU"
ap_cfg.pwd="lkwpeter"
ap_cfg.auth=wifi.OPEN
ap_cfg.max=1
ap_cfg.save=false
local success = wifi.ap.config(ap_cfg) and "true" or "false"
print("wifi.ap.config() : " .. success)

ip_cfg = {
    ip="192.168.4.1",
    netmask="255.255.255.0",
    gateway="192.168.4.1"
}
local successs = wifi.ap.setip(ip_cfg) and "true" or "false"
print("wifi.ap.setip() : " .. successs)

dhcp_config ={
    start = "192.168.4.2"
}
wifi.ap.dhcp.config(dhcp_config)
local successss = wifi.ap.dhcp.start() and "true" or "false"
print("wifi.ap.dhcp.start() : " .. successss)

print("--------------------------------")
apip = wifi.ap.getip()
print("wifi.ap.getip() : " .. apip~=nil and apip or "noapip. LOL.")

----------------
-- Web Server --
----------------
print("Starting Web Server...")
-- a simple HTTP server
if srv~=nil then
  print("found an open server. closing it...")
  srv:close()
  print("done. now tyring to start...")
end

function Sendfile(sck, filename, sentCallback)
    print("opening file "..filename.."...")
    if not file.open(filename, "r") then
        sck:close()
        return
    end
    local function sendChunk()
        local line = file.read(512)
        if (line and #line>0) then 
            sck:send(line, sendChunk) 
        else
            file.close()
            collectgarbage()
            if sentCallback then
                sentCallback()
            else
                sck:close()
            end
        end
    end
    sendChunk()
end

----------------
-- Web Server --
----------------
srv = net.createServer(net.TCP)
srv:listen(80, function(conn)
    conn:on("receive", function(sck, request_payload)
        -- == DATA == --
        local payload = ""
        if request_payload == nil or request_payload == "" then
            payload = ""
        else
            payload = request_payload
        end
        print(payload)
    
        -- === FUNCTIONS ===
        function respondMain()
            sck:send("HTTP/1.1 200 OK\r\n" ..
                    "Server: NodeMCU on ESP8266\r\n" ..
                    "Content-Type: text/html; charset=UTF-8\r\n\r\n", 
                    function()
                        Sendfile(sck, "1.html", 
                            function() 
                                sck:close()
                            end)
            end)
        end

        function respondStatus()
            sck:send("HTTP/1.1 200 OK\r\n" ..
                "Server: NodeMCU on ESP8266\r\n"..
                "Content-Type: application/json; charset=UTF-8\r\n\r\n" ..
                "{\"seconds_until_switchoff_counter\":" .. seconds_until_switchoff_counter .. 
                ",\"relais_state\":" .. relais_state .. "}", 
                function()
                    sck:close()
                end
            )
        end

        function respondOK()
            sck:send("HTTP/1.1 200 OK\r\n" ..
                "Server: NodeMCU on ESP8266\r\n", 
                function()
                    sck:close()
                end
            )
        end

        function respond204()
            sck:send("HTTP/1.1 204 OK\r\n" ..
                "Server: NodeMCU on ESP8266\r\n", 
                function()
                    sck:close()
                end
            )
        end

        function respondNotFound()
            sck:send("HTTP/1.1 404 Not Found\r\n" ..
                "Server: NodeMCU on ESP8266\r\n", 
                function()
                    sck:close()
                end
            )
        end

        function respondError()
            sck:send("HTTP/1.1 400 Bad Request\r\n" ..
                "Server: NodeMCU on ESP8266\r\n", 
                function()
                    sck:close()
                end
            )
        end
        
        function handleGET(path)
            print("### handleGET() ###")
            -- path?
            if string.match(path, "status") then
                print(" --> GETOST /status")
                respondStatus()
            elseif string.match(path, "generate_204") then
                print(" - respond204()")
                respond204()
            elseif string.len(path)==1 then
                print(" - respondMain()") 
                respondMain()
            else
                print(" - respond404") 
                respondNotFound()
            end
        end

        -- handle posted data updates
        function handlePOST(path)
            print("### handlePOST() ###")
            -- path?
            if string.match(path, "setwificonfig") then
                print(" --> POST /setwificonfig")
                respondMain()
            else
                respondNotFound()
            end
            
            
        end
        -- === FUNCTIONS - END ===
        
        -- === ACTUAL EVALUATION ===
        local GET_requestpath = string.match(payload, "GET (.*) HTTP") --or "N/A"
        local POST_requestpath = string.match(payload, "POST (.*) HTTP") --or "N/A"
        print(" GET_requestpath: " .. (GET_requestpath or "???") )
        print(" POST_requestpath: " .. (POST_requestpath or "???") )
        
        if GET_requestpath then
            handleGET(GET_requestpath)
        elseif POST_requestpath then
            handlePOST(POST_requestpath)
        else
            print("# cannot handle request. olny GET and POST are allowed.")
            respondError()
        end
        
    end)
        
end)