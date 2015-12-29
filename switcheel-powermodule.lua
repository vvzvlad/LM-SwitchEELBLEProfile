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
 
    local values = {}
    local status = false
    local res, sock, err  = device.profile._connect(device)
    

    if res then
      local value_key = ble.sockreadhnd(sock, 0x0f)
      local value_channel = ble.sockreadhnd(sock, 0x11)

      if (value_channel ~= nil and #value_key == 7) then
        values.channel_1_p = value:byte(1)
        status = true
      end

      if (value_key ~= nil and #value_key == 16) then
        values.key = value_key
      end
    end

    if not status then 
      device.profile._disconnect(device) 
    end 
    return status, values
  end,

  write = function(device, object, value)
    local handlers = {
    key = 0x0f,
    channels = 0x11,
    }

    local res, sock, err  = device.profile._connect(device)

    if (res and (object.id == 'channel_1' or object.id == 'channel_2') and sock) then
      local key = device.objects.key.value
      local cmd = {}
      if (object.id == 'channel_1') then
          cmd = { 0x01, value, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 }
      end
      if (object.id == 'channel_2') then
          cmd = { 0x02, 0x00, 0x00, value, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 }
      end

      local string_for_hash = { cmd[1], cmd[2], cmd[3], cmd[4], cmd[5], cmd[6], cmd[7], cmd[8], cmd[9], cmd[10], cmd[11], cmd[12], cmd[13], cmd[14], cmd[15], key:byte(1), key:byte(2), key:byte(3), key:byte(4), key:byte(5), key:byte(6), key:byte(7), key:byte(8), key:byte(9), key:byte(10), key:byte(11), key:byte(12), key:byte(13), key:byte(14), key:byte(15), key:byte(16) }
      local hash = device.profile.hash_rot_13(string_for_hash)
      res2, err = ble.sockwritereq(sock, handlers.channels, cmd[1], cmd[2], cmd[3], cmd[4], cmd[5], cmd[6], cmd[7], cmd[8], cmd[9], cmd[10], cmd[11], cmd[12], cmd[13], cmd[14], cmd[15], hash[1], hash[2], hash[3], hash[4])
      
      if res2<=0 then 
        device.profile._disconnect(device) 
      end 
    end
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

  _connect = function(device) 
    local res, err = true, nil 
    
    local sock = device.sock 
    
    if not sock or not ble.check(sock) then 
      if sock then 
        ble.close(sock) 
      end 
      
      sock = ble.sock() 
      ble.settimeout(sock, 30) 
      local i = 1 
      res, err = 1, ble.connect(sock, device.mac) 
      while not res and i<10 do 
        os.sleep(0.5) 
        res, err = ble.connect(sock, device.mac)
        i = i + 1 
      end 
      
      if not res then 
        ble.close(sock) 
        sock = nil 
      end 
        
      device.sock = sock 
    end 
    
    return res, sock, err 
  end,

  _disconnect = function(device) 
    local sock = device.sock 
    if sock then 
      ble.close(sock)   
    end 
    device.sock = nil 
  end 
}
