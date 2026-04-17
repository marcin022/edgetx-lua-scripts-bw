-- ELRS_Finder.lua (EdgeTX/Boxer B/W friendly)
-- ELRS/CRSF RSSI-based lost model finder (Geiger style)
-- Auto-discovers telemetry sensors on startup

local lastBeep = 0
local avg = -120
local have = { rssi=false, snr=false, rql=false }
local initDone = false

-- reset telemetry on init
local function init_func()
  -- Reset wszystkich slotów sensorów (EdgeTX ma max 60 slotów)
  for i = 0, 59 do
    local sensor = model.getSensor(i)
    if sensor ~= nil then
      model.resetSensor(i)
    end
  end
  initDone = true
end

local function readSignal()
  local rssi = getValue("1RSS")
  if rssi and rssi ~= 0 then have.rssi=true; return rssi, "dBm" end
  local snr = getValue("RSNR")
  if snr and snr ~= 0 then have.snr=true; return (snr*2-120), "SNR" end
  local rql = getValue("RQly")
  if rql and rql ~= 0 then have.rql=true; return (rql-120), "LQ" end
  return -120, "NA"
end

local function clamp(x,a,b)
  if x<a then return a elseif x>b then return b else return x end
end

local function run_func(event)
  local now = getTime()
  local raw, kind = readSignal()

  avg = 0.8*avg + 0.2*(raw)
  local strength = clamp( (avg + 110) * (100/(70)), 0, 100 )
  local period = clamp( 120 - strength, 10, 120 )

  if now - lastBeep >= period then
    local freq = 600 + (strength*6)
    playTone(freq, 30, 0, 0)
    lastBeep = now
  end

  lcd.clear()
  lcd.drawText(2,2,"ELRS Finder", MIDSIZE)
  lcd.drawText(2,18,string.format("Src:%s", kind), 0)
  lcd.drawText(60,18,string.format("Raw:%d", raw), 0)
  lcd.drawText(2,30,"Strength:", 0)
  lcd.drawRectangle(58,30,66,10)
  local bar = math.floor(strength * 64 / 100)
  lcd.drawFilledRectangle(59,31,bar,8, 0)
  lcd.drawText(2,44,string.format("Avg dBm est:%d", avg), 0)
  lcd.drawText(2,54,"Tip: Lower TX power as you get close.", 0)
  return 0
end

return { init=init_func, run=run_func }
