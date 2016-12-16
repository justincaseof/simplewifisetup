-- comment
print("Starting Bootloader...")
button_pin = 0
luafilename = "autosetup.lua"
gpio.mode(button_pin, gpio.INPUT)
local buttonpressed = gpio.read(button_pin)
print(" -> buttonpressed: "..((buttonpressed==0 and "yes") or "no"))

function teststuff()
    file.open("client_ssid.txt", "r")
    client_ssid=file.readline()
    file.close()
    file.open("client_password.txt", "r")
    client_password=file.readline()
    file.close()
    print("client_ssid: '" .. (client_ssid==nil and "N/A" or client_ssid) .. "'")
    print("client_password: '" .. (client_password==nil and "N/A" or client_password) .. "'")

    print("  again: " .. string.gsub(client_password, "%%2C", ","))
end
--

if(buttonpressed==0) then
    print(" -> interrupting autostart")
else
    print(" -> performing startup of " .. luafilename)
    tmr.alarm(0, 5000, tmr.ALARM_SINGLE, function() 
        
        teststuff()
        
        dofile(luafilename)
        tmr.alarm(1, 5000, tmr.ALARM_SINGLE, function() 
	        print("starting DNS liar...")
	        dofile("dns-liar.lua")
	    end) 
    end) 
end
