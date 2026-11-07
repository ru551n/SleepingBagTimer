-- ponytail: matches English buff name; switch to a spell ID for other locales
local MATCH = "well-rested" -- buff name, lowercase
local ITEM_ID = 211527 -- Cozy Sleeping Bag
local STACK_SECS, MAX_STACKS = 60, 3
local W, PAD, ROW = 220, 10, 22
local BAR_W = W - 2 * PAD - 22

local f = CreateFrame("Frame", "SleepingBagTimerFrame", UIParent, "BackdropTemplate")
f:SetSize(W, 60)
f:SetPoint("CENTER", 0, 200)
f:SetMovable(true)
f:EnableMouse(true)
f:RegisterForDrag("LeftButton")
f:SetScript("OnDragStart", f.StartMoving)
f:SetScript("OnDragStop", f.StopMovingOrSizing)
f:SetBackdrop({
  bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
  edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
  edgeSize = 14, insets = { left = 3, right = 3, top = 3, bottom = 3 },
})
f:SetBackdropColor(0.05, 0.05, 0.1, 0.85)
f:SetBackdropBorderColor(0.6, 0.5, 0.3)

-- header: bag icon + title, gold like Blizzard frames
local headIcon = f:CreateTexture(nil, "ARTWORK")
headIcon:SetSize(18, 18)
headIcon:SetPoint("TOPLEFT", PAD, -PAD)
headIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
title:SetPoint("LEFT", headIcon, "RIGHT", 6, 0)
title:SetText("Cozy Sleeping Bag")
local line = f:CreateTexture(nil, "ARTWORK")
line:SetColorTexture(0.6, 0.5, 0.3, 0.6)
line:SetSize(W - 2 * PAD, 1)
line:SetPoint("TOPLEFT", PAD, -PAD - 23)

local function newRow(iconPath)
  local r = CreateFrame("Frame", nil, f)
  r:SetSize(W - 2 * PAD, ROW)
  r.icon = r:CreateTexture(nil, "ARTWORK")
  r.icon:SetSize(16, 16)
  r.icon:SetPoint("LEFT")
  r.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  r.icon:SetTexture(iconPath)
  r.label = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  r.label:SetPoint("LEFT", r.icon, "RIGHT", 6, 0)
  r.time = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  r.time:SetPoint("RIGHT")
  return r
end

-- sleeping row: 3-minute bar, one mark per stack minute
local sleepRow = newRow("Interface\\Icons\\Spell_Nature_Sleep")
local bar = CreateFrame("StatusBar", nil, sleepRow)
bar:SetSize(BAR_W, 14)
bar:SetPoint("LEFT", sleepRow.icon, "RIGHT", 6, 0)
bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
bar:SetStatusBarColor(0.35, 0.6, 1)
bar:SetMinMaxValues(0, STACK_SECS * MAX_STACKS)
local barBg = bar:CreateTexture(nil, "BACKGROUND")
barBg:SetAllPoints()
barBg:SetColorTexture(0, 0, 0, 0.5)
for i = 1, MAX_STACKS - 1 do
  local t = bar:CreateTexture(nil, "OVERLAY")
  t:SetColorTexture(1, 0.85, 0.4)
  t:SetSize(2, 14)
  t:SetPoint("LEFT", BAR_W * i / MAX_STACKS - 1, 0)
end
sleepRow.label:SetParent(bar)
sleepRow.label:ClearAllPoints()
sleepRow.label:SetPoint("LEFT", bar, 4, 0)
sleepRow.time:SetParent(bar)
sleepRow.time:ClearAllPoints()
sleepRow.time:SetPoint("RIGHT", bar, -4, 0)

local buffRow = newRow("Interface\\Icons\\Spell_Nature_Sleep")
local cdRow = newRow("Interface\\Icons\\INV_Misc_PocketWatch_01")
cdRow.label:SetText("Bag cooldown")
cdRow.time:SetTextColor(1, 0.5, 0.4)

local function fmt(s)
  s = math.max(0, math.floor(s))
  if s >= 3600 then return format("%d:%02d:%02d", s / 3600, s % 3600 / 60, s % 60) end
  return format("%d:%02d", s / 60, s % 60)
end

-- Forever hides some auras as "secret"; addons error on reading them, so skip those
local isSecret = issecretvalue or function() return false end
local secretSeen = 0

local function buff() -- stacks, expirationTime, icon
  secretSeen = 0
  for i = 1, 40 do
    local ok, a = pcall(C_UnitAuras.GetBuffDataByIndex, "player", i)
    if ok and not a then return end
    if not ok or isSecret(a) or isSecret(a.name) then
      secretSeen = secretSeen + 1
    elseif a.name and a.name:lower():find(MATCH, 1, true) then
      return math.max(a.applications or 1, 1), a.expirationTime, a.icon
    end
  end
end

local function cooldown() -- start, duration of the bag item
  return C_Container.GetItemCooldown(ITEM_ID)
end

-- sleepStart: set on bag use, resynced on every new stack; nil = not sleeping
local acc, sleepStart, lastStacks = 0, nil, 0
local bagSpell = select(2, C_Item.GetItemSpell(ITEM_ID))

f:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
f:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", "player")
f:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP", "player")
f:SetScript("OnEvent", function(_, event, _, _, spellID)
  bagSpell = bagSpell or select(2, C_Item.GetItemSpell(ITEM_ID)) -- item may load late
  if spellID ~= bagSpell then return end
  sleepStart = event ~= "UNIT_SPELLCAST_CHANNEL_STOP" and GetTime() or nil
end)

f:SetScript("OnUpdate", function(_, dt)
  acc = acc + dt
  if acc < 0.1 then return end
  acc = 0
  local now = GetTime()
  local stacks, expires, buffIcon = buff()
  stacks = stacks or 0
  if stacks > lastStacks then sleepStart = now - stacks * STACK_SECS end
  lastStacks = stacks
  if GetUnitSpeed("player") > 0 then sleepStart = nil end
  local elapsed = sleepStart and now - sleepStart or math.huge
  -- a missed stack tick also means you got up
  local sleeping = stacks < MAX_STACKS and elapsed < (stacks + 1) * STACK_SECS + 5
  if not sleeping then sleepStart = nil end
  local start, dur = cooldown()
  local cdLeft = (start and start > 0 and dur > 1.5) and start + dur - now or 0
  local hasBuff = expires and expires > 0

  headIcon:SetTexture(C_Item.GetItemIconByID(ITEM_ID))
  if sleeping then
    bar:SetValue(elapsed)
    sleepRow.label:SetText(format("Resting %d/%d", stacks, MAX_STACKS))
    sleepRow.time:SetText("next " .. fmt((stacks + 1) * STACK_SECS - elapsed))
  end
  if hasBuff then
    if buffIcon then buffRow.icon:SetTexture(buffIcon) end
    buffRow.label:SetText(format("Well-Rested  |cff66ff66+%d%% XP|r", stacks))
    buffRow.time:SetText(fmt(expires - now))
  end
  cdRow.time:SetText(fmt(cdLeft))

  -- stack visible rows under the header and fit the frame to them
  local y = -PAD - 28
  for _, r in ipairs({ { sleepRow, sleeping }, { buffRow, hasBuff }, { cdRow, cdLeft > 0 } }) do
    r[1]:SetShown(r[2])
    if r[2] then
      r[1]:SetPoint("TOPLEFT", PAD, y)
      y = y - ROW
    end
  end
  f:SetHeight(-y + PAD - 4)
  -- alpha, not Hide: OnUpdate must keep running
  local show = sleeping or hasBuff or cdLeft > 0
  f:SetAlpha(show and 1 or 0)
  f:EnableMouse(show)
end)

SLASH_SLEEPINGBAGTIMER1 = "/sbt"
SlashCmdList.SLEEPINGBAGTIMER = function()
  local start, dur = cooldown()
  local stacks = buff()
  print(format("SBT: bagSpell=%s stacks=%s secretAuras=%d sleepStart=%s cd=%s/%s now=%.1f",
    tostring(bagSpell), tostring(stacks), secretSeen, tostring(sleepStart),
    tostring(start), tostring(dur), GetTime()))
end
