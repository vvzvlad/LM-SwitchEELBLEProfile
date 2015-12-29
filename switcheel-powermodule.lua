return {
  manufacturer = 'SwitchEEL',
  description = 'Relay Module',
  default_name = 'SwitchEEL Module',
  objects = {
    {
      id = 'channel_1',
      name = 'Ch 1',
      datatype = dt.scale,
      write_only = true
    },
    {
      id = 'channel_2',
      name = 'Ch 2',
      datatype = dt.scale,
      write_only = true
    },
    {
      id = 'channel_1_p',
      name = 'Ch 1 present',
      datatype = dt.scale,
      read_only = true
    },
    {
      id = 'speed',
      name = 'Light Speedrate',
      datatype = dt.uint8,
      write_only = true
    },
    {
      id = 'key',
      name = 'Key',
      datatype = dt.text
    },
  },

  read = function(device)
    local res, sock, err  = device.profile.connect(device)
    local key
    local values = {}
    local status = false



    if res then
      local value_key = ble.sockreadhnd(sock, 0x0f) or ''
      local value_channel = ble.sockreadhnd(sock, 0x11) or ''
      log("sock:"..sock.." received:"..#value_channel.." byte")
      if (#value_channel == 7) then
        status = true
        values.channel_1_p = value_channel:byte(1)
      end

      if (#value_key == 16) then
        values.key = value_key
      end
    end


    if res then
      local key = device.objects.key.value or ''
      --local cmd = { 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00}
      --local string_for_hash = { cmd[1], cmd[2], cmd[3], cmd[4], cmd[5], cmd[6], cmd[7], key:byte(1), key:byte(2), key:byte(3), key:byte(4), key:byte(5), key:byte(6), key:byte(7), key:byte(8), key:byte(9), key:byte(10), key:byte(11), key:byte(12), key:byte(13), key:byte(14), key:byte(15), key:byte(16) }
      local cmd = { 0xFF, 0x64, 0x00, 0x64, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 }
      local string_for_hash = { cmd[1], cmd[2], cmd[3], cmd[4], cmd[5], cmd[6], cmd[7], cmd[8], cmd[9], cmd[10], cmd[11], cmd[12], cmd[13], cmd[14], cmd[15], key:byte(1), key:byte(2), key:byte(3), key:byte(4), key:byte(5), key:byte(6), key:byte(7), key:byte(8), key:byte(9), key:byte(10), key:byte(11), key:byte(12), key:byte(13), key:byte(14), key:byte(15), key:byte(16) }
      local hash = device.profile.hash_rot_13(string_for_hash)
      --res2, err = ble.sockwritereq(sock, 0x17, cmd[1], cmd[2], cmd[3], cmd[4], cmd[5], cmd[6], cmd[7], hash[1], hash[2], hash[3], hash[4])
      res2, err = ble.sockwritereq(sock, 0x11, cmd[1], cmd[2], cmd[3], cmd[4], cmd[5], cmd[6], cmd[7], cmd[8], cmd[9], cmd[10], cmd[11], cmd[12], cmd[13], cmd[14], cmd[15], hash[1], hash[2], hash[3], hash[4])

      if (res2 <= 0) then 
        status = false
      end
    end
      
  
    if (status == false) then 
      device.profile.disconnect(device) 
    end
    
    
    return status, values
  end,


  connect = function(device) 
    local res, err = true, nil 
    
    local sock = device.sock 
    log(ble.check(sock))
    if (sock == nil or ble.check(sock) ~= true) then 
      if (sock ~= nil) then 
        device.profile.disconnect(device) 
      end 
      log("reconnect")

      sock = ble.sock() 
      ble.settimeout(sock, 30) 
      local i = 1 
      res, err = ble.connect(sock, device.mac) 
      while (res ~= true and i<10) do  
        os.sleep(0.5) 
        res, err = ble.connect(sock, device.mac)
        i = i + 1 
      end 
      
      if (res ~= true) then 
        ble.close(sock) 
        sock = nil 
      end 
        
      device.sock = sock 
    end 
    
    return res, sock, err 
  end,

  disconnect = function(device) 
    local sock = device.sock 
    if (sock ~= nil) then 
      ble.close(sock)   
    end 
    device.sock = nil 
  end, 

  hash_rot_13 = function(bytes) 
    local hash = 0
    local hash_be
    local hash_m = {}
    for i = 1, #bytes do
        hash = hash + bytes[i]
        hash = bit.band(hash - bit.rol(hash, 13), 0xFFFFFFFF)
        hash_be = bit.bswap(hash)        
        hash_m[4] = bit.band(bit.rshift(hash_be, 32), 0xFF)
        hash_m[2] = bit.band(bit.rshift(hash_be, 16), 0xFF)
        hash_m[3] = bit.band(bit.rshift(hash_be, 8), 0xFF)
        hash_m[1] = bit.band(hash, 0xFF)
    end
    return hash_m
  end,  
}
