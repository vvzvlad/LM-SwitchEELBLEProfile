return {
  manufacturer = 'SwitchEEL',
  description = 'SwitchEEL Relay',
  default_name = 'SwitchEEL Module',
  objects = {
    {
      id = 'power',
      name = 'Power',
      datatype = dt.bool
    },
  },
  read = function(device)
    local sock
    values = {}

    sock = ble.sock()
    ble.settimeout(sock, 30)
    res = ble.connect(sock, device.mac)

    if res then
      value_0x2af3 = ble.sockreadhnd(sock, 0x2af3) or ''
      log(value_0x2af3)
      if (#value_0x2af3 == 7) then   
        status = true
        if (value_0x2af3:byte(1) == 0) then
          values.power = false
        else
          values.power = true
        end
      end
    end

    ble.close(sock)
   
    return status, values
  end,
  write = function(device, object, value)
    local sock
    sock = ble.sock()
    ble.settimeout(sock, 30)
    res = ble.connect(sock, device.mac)

    if (object.id == 'power') then
      if res then
        if (value == true) then
          ble.sockwritecmd(sock, 0x21, 0x55, 0x10, 0x01, 0x0D, 0x0A)
        end
        if (value == false) then
          ble.sockwritecmd(sock, 0x21, 0x55, 0x10, 0x00, 0x0D, 0x0A)
        end
      end
    end

    ble.close(sock)
  end
}
