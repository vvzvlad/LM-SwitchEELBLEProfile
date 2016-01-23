1)Подключить модуль к питанию и нагрузке
2)Во вкладке BLE создать новое устройство для этого модуля, указать драйвер и настроить один или два канала, указав обьекты. Каналы, помеченные как сhannel(scale) служат для управления диммируемой нагрузкой, как сhannel(bin) — недиммируемой. Канал один и тот же, различаются типы обьектов для управления для того, чтобы нельзя
было случайно установить уровень диммирования для нагрузки, которая это не поддерживает. 
Для тестирования можно установить  сhannel(scale).
3)Указать Poll interval(частоту опроса) устройства в районе 2..10 секунд, сохранить настройки, дождаться появления данных от модуля в колонке current value
4)Выключить модуль, а зачем 5 раз подать и снять питание, в последний раз не отключая его от сети. Интервал между включениями не должен составлять больше 3 секунд
Т.е(считаем, что после 3 шага модуль включен): Выключить. Включить-выключить. Включить-выключить. Включить-выключить. Включить-выключить. Включить.
5)Дождаться сообщения в логе: Saved key to storage for 123(00:02:77:14:34:1D)
6)Выключить в свойствах BLE опрос, установив Poll interval в 0 секунд. 
7)Изменением обьекта, привязанного на шаге 2, управлять модулем. Питание на нагрузку должно изменять синхронно с состоянием обьекта. 