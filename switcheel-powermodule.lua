return {
  manufacturer = 'SwitchEEL',
  description = 'Relay Module',
  default_name = 'SwitchEEL Module',
  objects = {
    {
      id = 'channel_1',
      name = 'Ch_w 1',
      datatype = dt.scale,
      write_only = true
    },
    {
      id = 'channel_1_p',
      name = 'Ch_p 1',
      datatype = dt.scale,
      read_only = true
    },
    {
      id = 'channel_2',
      name = 'Ch_w 2',
      datatype = dt.scale,
      write_only = true
    },
    {
      id = 'channel_2_p',
      name = 'Ch_p 2',
      datatype = dt.scale,
      read_only = true
    },
    {
      id = 'key',
      name = 'Key',
      datatype = dt.text
    },
  },

  read = function(device)
    local res, sock, err  = device.profile._connect(device)
    if (err ~= nil) then log('Read connect from '..device.id..' error: '..err) end
    local values = {}
    local status = false

    if (res == true) then
      local value_key = ble.sockreadhnd(sock, 0x0f) or ''
      local value_channel = ble.sockreadhnd(sock, 0x11) or ''
      log("sock:"..sock.." received:"..#value_channel.." byte")
      if (#value_channel == 7) then
        status = true
        values.channel_1_p = value_channel:byte(1)
        values.channel_2_p = value_channel:byte(2)
      end

      if (#value_key == 16) then
        values.key = value_key
        log('Saved key from '..device.id)
      end
    end

    device.profile._disconnect(device, sock) 
    return status, values
  end,

  write = function(device, object, value)
    if (object.id == 'channel_1' or object.id == 'channel_2') then
        log('Attempting write to '..device.id.." object "..object.id)
        local res, sock, err  = device.profile._connect(device)
        local cmd = {}
        local string_for_hash, hash
        local hash_key = ''
        if (device.objects.key ~= nil) then hash_key = device.objects.key.value end 
        if (err ~= nil) then log('Write connect to '..device.id..' return error: '..err) end
        if (#hash_key ~= 16) then log('Not read correct key for device '..device.id) end
          if (res == true and #hash_key == 16) then
          if (object.id == 'channel_1') then
            cmd = { 0x01, value, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 }
          elseif (object.id == 'channel_2') then
            cmd = { 0x02, 0x00, 0x00, value, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 }
          end
          string_for_hash = { cmd[1], cmd[2], cmd[3], cmd[4], cmd[5], cmd[6], cmd[7], cmd[8], cmd[9], cmd[10], cmd[11], cmd[12], cmd[13], cmd[14], cmd[15], hash_key:byte(1), hash_key:byte(2), hash_key:byte(3), hash_key:byte(4), hash_key:byte(5), hash_key:byte(6), hash_key:byte(7), hash_key:byte(8), hash_key:byte(9), hash_key:byte(10), hash_key:byte(11), hash_key:byte(12), hash_key:byte(13), hash_key:byte(14), hash_key:byte(15), hash_key:byte(16) }
          hash = device.profile._hash(string_for_hash)
          res2, err = ble.sockwritereq(sock, 0x11, cmd[1], cmd[2], cmd[3], cmd[4], cmd[5], cmd[6], cmd[7], cmd[8], cmd[9], cmd[10], cmd[11], cmd[12], cmd[13], cmd[14], cmd[15], hash[1], hash[2], hash[3], hash[4])
          if (res2 <= 0) then log('Write command to '..device.id..' return error: '..err) end
          log('Write command to '..device.id..' return ok')
        end
        device.profile._disconnect(device, sock) 
    end
  end,


  _connect = function(device) 
    local sock
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

    return res, sock, err 
  end,

  _disconnect = function(device, sock) 
    if (sock ~= nil) then 
      ble.close(sock)   
    end 
    sock = nil
  end, 

  _hash = function(bytes) 
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
