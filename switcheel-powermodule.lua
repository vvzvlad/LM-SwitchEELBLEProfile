return {
  manufacturer = 'SwitchEEL',
  description = 'Relay Module',
  default_name = 'SwitchEEL Module',
  version = 1, 
  objects = {
    {
      id = 'channel_1',
      name = '1 сhannel(scale)',
      datatype = dt.scale,
      write_only = true
    },
    {
      id = 'channel_1_p',
      name = '1 сhannel(scale) presente',
      datatype = dt.scale,
      read_only = true
    },
    {
      id = 'channel_1_b',
      name = '1 сhannel(bin)',
      datatype = dt.bool,
      write_only = true
    },
    {
      id = 'channel_1_p_b',
      name = '1 сhannel(bin) presente',
      datatype = dt.bool,
      read_only = true
    },

    {
      id = 'channel_2',
      name = '2 сhannel(scale)',
      datatype = dt.scale,
      write_only = true
    },
    {
      id = 'channel_2_p',
      name = '2 сhannel(scale) presente',
      datatype = dt.scale,
      read_only = true
    },
    {
      id = 'channel_2_b',
      name = '2 сhannel(bin)',
      datatype = dt.bool,
      write_only = true
    },
    {
      id = 'channel_2_p_b',
      name = '2 сhannel(bin) presente',
      datatype = dt.bool,
      read_only = true
    },
  },

  read = function(device)
    --log('Attempting read device '..device.name..'('..device.id..')')
    local res, sock, err  = device.profile.connect(device)
    local values = {}
    local status = false

    if (err ~= nil) then
      log('Read connect from '..device.name..'('..device.id..')'..' return error: '..err..'(use socket '..sock..'), attempt to reconnect..')
      device.profile.disconnect(device)
      res, sock, err  = device.profile.connect(device)
      if (err ~= nil) then
        log('Second read connect from '..device.name..'('..device.id..')'..' return error: '..err..'(use socket '..sock..')')
        res = false
      end
    end
    if (res == true) then
      status = true
    end

    if (res == true) then
      local value_key = ble.sockreadhnd(sock, 0x0f) or ble.sockreadhnd(sock, 0x0f) or ''
      local value_channel = ''
      local v_c = {ble.sockreadhnd(sock, 0x11) or '', ble.sockreadhnd(sock, 0x11) or '', ble.sockreadhnd(sock, 0x11) or '', ble.sockreadhnd(sock, 0x11) or '', ble.sockreadhnd(sock, 0x11) or ''}
      for i = 1, #v_c do 
        if (#v_c[i] == 7) then
          value_channel = v_c[i]
          break
        end
      end

      if (#value_channel == 7) then
        values.channel_1_p = value_channel:byte(1)
        values.channel_2_p = value_channel:byte(2)
        --device.profile.channel_update(sock, device, values.channel_1_p, values.channel_2_p) --write correct command+hash for save connection
        --log('Read data from device '..device.name..'('..device.id..')'..' return '..#value_channel..' bytes(use socket '..sock..')')
      else
        log('Read data from device '..device.name..'('..device.id..')'..' not return bytes:'..#v_c[1]..#v_c[2]..#v_c[3]..#v_c[4]..#v_c[5]..' (use socket '..sock..')')
      end

      if (#value_key == 16) then
        local switcheel_keys = storage.get("switcheel_keys") or {}
        if (switcheel_keys[device.id] == nil) then
          switcheel_keys[device.id] = value_key
          log('Saved key to storage for '..device.name..'('..device.id..')')
        end
        storage.set("switcheel_keys", switcheel_keys) 
      end
    end

    return status, values
  end,

  write = function(device, object, value)
    if (object.id == 'channel_1' or object.id == 'channel_2' or object.id == 'channel_1_b' or object.id == 'channel_2_b') then
      --log('Attempting write to '..device.name..'('..device.id..')'.." object "..object.id)
      local res, sock, err  = device.profile.connect(device)
      local status = false
      local err_update
      local err_update_accumulator
      if (err ~= nil and err ~= 'failed to bind socket') then log('Write connect to '..device.name..'('..device.id..')'..' return error: '..err..'(use socket '..sock..')') end
      if (err == 'failed to bind socket') then log('Write connect to '..device.name..'('..device.id..')'..' return error: '..err..'(maybe device power-off?)') end
      if (res == true) then
        i = 0
        err_update_accumulator = ''
        while (status == false and i<10) do
          if (i == 2) then
            device.profile.disconnect(device)
            res, sock, err  = device.profile.connect(device)
            if (err ~= nil) then log('Write second connect to '..device.name..'('..device.id..')'..' return error: '..err..'(use socket '..sock..')') end
          end 
          
          if (object.id == 'channel_1') then
            status, err_update = device.profile.channel_update(sock, device, value, nil)
          elseif (object.id == 'channel_2') then
            status, err_update = device.profile.channel_update(sock, device, nil, value)
          elseif (object.id == 'channel_1_b') then
            if (value == true) then value = 100 elseif (value == false) then value = 0 end
            status, err_update = device.profile.channel_update(sock, device, value, nil)
          elseif (object.id == 'channel_2_b') then
            if (value == true) then value = 100 elseif (value == false) then value = 0 end
            status, err_update = device.profile.channel_update(sock, device, nil, value)
          end

          if (err_update ~= nil) then
            err_update_accumulator = err_update
          end

          if (i ~= 0) then os.sleep(0.3) end
          i = i + 1
        end  
        if (i ~= 1 and i ~= 3 and status == true) then 
          log('Channel '..device.name..'('..device.id..')'..' updated after '..i-1..' times: error '..err_update_accumulator) 
        elseif (i == 3 and status == true) then 
          log('Channel '..device.name..'('..device.id..')'..' updated after reconnect(2 times): error '..err_update_accumulator) 
        elseif (status == false) then 
          log('Channel '..device.name..'('..device.id..')'..' NOT updated after '..i-1..' times: error '..err_update_accumulator) 
        end
      end
    end
  end,

  channel_update = function(sock, device, channel_1_value, channel_2_value) 
    local cmd = {}
    local string_for_hash, hash
    local hash_key = ''

    local switcheel_keys = storage.get("switcheel_keys") or {}
    if (switcheel_keys[device.id] ~= nil) then
      hash_key = switcheel_keys[device.id]
      --log('Read key from storage for '..device.name..'('..device.id..')')
    end
        
    if (#hash_key ~= 16) then log('Not read correct key for device '..device.name..'('..device.id..')') end

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
        --log('Write command to '..device.name..'('..device.id..')'..' return error: '..err..'(use socket '..sock..')')
        return false, err
      else
        --log('Write command to '..device.name..'('..device.id..')'..' return ok(use socket '..sock..')')
       return true
      end
    end
  end,

  connect = function(device) 
    local sock = device.sock 
    local res, err = true, nil
    local i = 1

    if (ble.check(sock) == true) then
      --log('Connection to device '..device.name..'('..device.id..')'..' is active, use it')
    else

      if (sock ~= nil) then 
        ble.close(sock) 
        sock = nil
      end 

      sock = ble.sock() 
      ble.settimeout(sock, 30)
      res, err = ble.connect(sock, device.mac) 
      while (res ~= true and i<10) do 
        if (i == 4) then
          ble.close(sock) 
          sock = nil 
          ble.down()
          ble.up()
          sock = ble.sock() 
          ble.settimeout(sock, 30) 
          log('Interface ble restarted(from connect to '..device.name..'('..device.id..')'..')')
        end
        res, err = ble.connect(sock, device.mac) 
        os.sleep(0.3)
        i = i + 1
      end 
      if (res == true and i~=1 and i~=10) then log('Connected to '..device.name..'('..device.id..')'..' after '..i..' times') end
      if (i==10 and res ~= true) then log('Connection losed to '..device.name..'('..device.id..')') end

      if (res ~= true) then
        ble.close(sock) 
        sock = nil 
      end

      device.sock = sock
    end

    if (sock == nil) then 
      sock = 'nil' 
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
