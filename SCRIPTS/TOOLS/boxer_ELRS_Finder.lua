-- finder.lua  (EdgeTX / Boxer B&W friendly)
-- Lost model finder using getRSSI()

local lastBeep = 0
local avg = -120

local function clamp(x, a, b)
  if x < a then return a elseif x > b then return b else return x end
end

local function readSignal()
  local rssi = getRSSI()
  if rssi and rssi ~= 0 then
    return rssi, "RSSI", true
  end
  return -120, "NO TEL", false
end

local function run_func(event)
  local now = getTime()
  local raw, kind, valid = readSignal()

  if valid then
    -- mocniejsze wygĹadzanie
    avg = 0.92 * avg + 0.08 * raw
  else
    avg = -120
  end

  -- uĹźyteczny zakres zawÄĹźony: -105 .. -65 dBm
  local strength = clamp((avg + 105) * (100 / 40), 0, 100)

  -- martwa strefa: poniĹźej 20% brak dĹşwiÄku
  if valid and strength > 20 then
    local active = strength - 20  -- 0..80

    -- wolniejszy zakres: 2.0s .. 0.25s
    local period = clamp(200 - active * 2.2, 25, 200)

    -- Ĺagodniejsza zmiana tonu
    local freq = 500 + active * 5

    if now - lastBeep >= period then
      playTone(freq, 20, 0, 0)
      lastBeep = now
    end
  end

  lcd.clear()
  lcd.drawText(2, 2, "ELRS Finder", MIDSIZE)
  lcd.drawText(2, 18, "Src:" .. kind, 0)
  lcd.drawText(68, 18, string.format("Raw:%d", raw), 0)

  lcd.drawText(2, 30, "Strength:", 0)
  lcd.drawRectangle(58, 30, 66, 10)
  lcd.drawFilledRectangle(59, 31, math.floor(strength * 64 / 100), 8, 0)

  lcd.drawText(2, 44, string.format("Avg RSSI:%d", avg), 0)

  if not valid then
    lcd.drawText(2, 54, "Waiting for telemetry...", 0)
  elseif strength <= 20 then
    lcd.drawText(2, 54, "Far: silent zone", 0)
  else
    lcd.drawText(2, 54, "Close: beeps speed up", 0)
  end

  return 0
end

return { run = run_func }
