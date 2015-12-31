return {
  manufacturer = 'SwitchEEL',
  description = 'Relay Module',
  default_name = 'SwitchEEL Module',
  version = 1, 
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
    --log('Attempting read device '..device.id)
    device.profile.disconnect(device) --dirty hack :(
    local res, sock, err  = device.profile.connect(device)
    local values = {}
    local status = false

    if (err ~= nil) then
      log('Read connect from '..device.id..' return error: '..err..'(use socket '..sock..'), attempt to reconnect..')
      device.profile.disconnect(device)
      res, sock, err  = device.profile.connect(device)
      if (err ~= nil) then
        log('Read connect from '..device.id..' return error: '..err..'(use socket '..sock..')')
        res = false
      end
    end


    if (res == true) then
      local value_key = ble.sockreadhnd(sock, 0x0f) or ''
      local value_channel = ble.sockreadhnd(sock, 0x11) or ''

      if (#value_channel == 7) then
        status = true
        values.channel_1_p = value_channel:byte(1)
        values.channel_2_p = value_channel:byte(2)
        device.profile.channel_update(sock, device, values.channel_1_p, values.channel_2_p) --write correct command+hash for save connection
        log('Read data from device '..device.id..' return '..#value_channel..' bytes(use socket '..sock..')')
      else
        log('Read data from device '..device.id..' not return bytes(use socket '..sock..'), disconnect')
        device.profile.disconnect(device)
      end

      if (#value_key == 16) then
        values.key = value_key
        log('Saved key from '..device.id)
      end
    end

    return status, values
  end,

  write = function(device, object, value)
    if (object.id == 'channel_1' or object.id == 'channel_2') then
        --log('Attempting write to '..device.id.." object "..object.id)
        local res, sock, err  = device.profile.connect(device)
        if (err ~= nil) then log('Write connect to '..device.id..' return error: '..err..'(use socket '..sock..')') end

        if (res == true ) then
          if (object.id == 'channel_1') then
            device.profile.channel_update(sock, device, value, nil)
          elseif (object.id == 'channel_2') then
            device.profile.channel_update(sock, device, nil, value)
          end
        end
    end
  end,

  channel_update = function(sock, device, channel_1_value, channel_2_value) 
      local cmd = {}
      local string_for_hash, hash
      local hash_key = ''
      if (device.objects.key ~= nil) then hash_key = device.objects.key.value end 
      if (#hash_key ~= 16) then log('Not read correct key for device '..device.id) end

      if (channel_2_value == nil and channel_1_value ~= nil) then
        cmd = { 0x01, channel_1_value, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 }
      end

      if (channel_1_value == nil and channel_2_value ~= nil) then
        cmd = { 0x02, 0x00, 0x00, channel_2_value, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 }
      end

      if (channel_1_value ~= nil and channel_2_value ~= nil) then
        cmd = { 0x03, channel_1_value, 0x00, channel_2_value, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 }
      end

      if (#hash_key == 16) then
        string_for_hash = { cmd[1], cmd[2], cmd[3], cmd[4], cmd[5], cmd[6], cmd[7], cmd[8], cmd[9], cmd[10], cmd[11], cmd[12], cmd[13], cmd[14], cmd[15], hash_key:byte(1), hash_key:byte(2), hash_key:byte(3), hash_key:byte(4), hash_key:byte(5), hash_key:byte(6), hash_key:byte(7), hash_key:byte(8), hash_key:byte(9), hash_key:byte(10), hash_key:byte(11), hash_key:byte(12), hash_key:byte(13), hash_key:byte(14), hash_key:byte(15), hash_key:byte(16) }
        hash = device.profile.hash(string_for_hash)
        res2, err = ble.sockwritereq(sock, 0x11, cmd[1], cmd[2], cmd[3], cmd[4], cmd[5], cmd[6], cmd[7], cmd[8], cmd[9], cmd[10], cmd[11], cmd[12], cmd[13], cmd[14], cmd[15], hash[1], hash[2], hash[3], hash[4])
        if (res2 <= 0) then
          log('Write command to '..device.id..' return error: '..err..'(use socket '..sock..')')
          device.profile.disconnect(device)
        else
          log('Write command to '..device.id..' return ok(use socket '..sock..')')
        end
      end
  end,

  connect = function(device) 
    local sock = device.sock 
    local res, err = true, nil 
    if (ble.check(sock) == true) then
      log('Connection to device '..device.id..' is active, use it')
    end

    if (ble.check(sock) == false) then

      if (sock ~= nil) then 
        ble.close(sock) 
        sock = nil
      end 

      sock = ble.sock() 
      ble.settimeout(sock, 30) 
      local i = 1 
      res, err = ble.connect(sock, device.mac) 
      while (res ~= true and i<10) do  
        os.sleep(0.5) 
        res, err = ble.connect(sock, device.mac)
        i = i + 1 
        if (i == 7) then
          ble.close(sock) 
          sock = nil 
          ble.down()
          ble.up()
          log("Interface ble restarted")
          sock = ble.sock() 
          ble.settimeout(sock, 30) 
        end
      end 

      if (res ~= true) then
        ble.close(sock) 
        sock = nil 
      end

      if (res == true) then log('Connection to device '..device.id..' is established after losing')  end
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

  hash = function(bytes) 
    local hash = 0
    local hash_m = {}
    for i = 1, #bytes do
        hash = hash + bytes[i]
        hash = bit.band(hash - bit.rol(hash, 13), 0xFFFFFFFF)
    end
    hash_m[4] = bit.band(bit.rshift(hash, 8*3), 0xFF)
    hash_m[3] = bit.band(bit.rshift(hash, 8*2), 0xFF)
    hash_m[2] = bit.band(bit.rshift(hash, 8*1), 0xFF)
    hash_m[1] = bit.band(hash, 0xFF)
    return hash_m
  end,  
}
