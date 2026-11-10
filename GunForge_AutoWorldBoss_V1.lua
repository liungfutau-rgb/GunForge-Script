-- +1 Gun Forge | AUTO WORLD BOSS V1 (Delta / Roblox Luau)
-- Separate compact menu. Client UI automation: no damage edits or unauthorized rewards.
-- Intended workflow: built-in AFK farm -> click WORLD BOSS GO -> assist fight -> return via result Back button.
-- Requires in-game GO and Back controls to exist; special mechanics may still need player input.
local Players = game:GetService('Players')
local RunService = game:GetService('RunService')
local UIS = game:GetService('UserInputService')
local VIM = game:GetService('VirtualInputManager')
local GS = game:GetService('GuiService')
local WS = game:GetService('Workspace')
local P = Players.LocalPlayer
local PG = P:WaitForChild('PlayerGui')
local env = (getgenv and getgenv()) or _G
if type(env.GF_AutoBossStop) == 'function' then pcall(env.GF_AutoBossStop) end
local old = PG:FindFirstChild('GF_AutoWorldBoss_V1')
if old then old:Destroy() end

local active = true
local settings = { autoJoin=false, autoAttack=false, autoReturn=false, offsetY=0 }
local state = 'FARMING'
local lastJoin, lastReturn, lastAttack, lastStatus, bossSeenAt = 0,0,0,'',0
local enteredAt, rewardAt, bossMissingSince, bossDetectAt = 0,0,0,0
local joinTries, returnTries = 0,0
local lastToolWarning = 0
local minimize = false
local seenLog = {}
local C = {bg=Color3.fromRGB(17,23,34),panel=Color3.fromRGB(33,44,61),muted=Color3.fromRGB(187,208,220),white=Color3.fromRGB(241,245,249),green=Color3.fromRGB(31,145,112),red=Color3.fromRGB(157,62,70)}
local function mk(class,parent,props)
 local v = Instance.new(class)
 for k,x in pairs(props or {}) do v[k]=x end
 v.Parent=parent
 return v
end
local screen=mk('ScreenGui',PG,{Name='GF_AutoWorldBoss_V1',DisplayOrder=970,ResetOnSpawn=false})
local panel=mk('Frame',screen,{Size=UDim2.fromOffset(305,284),Position=UDim2.new(0,12,0.38,0),Active=true,Draggable=true,BackgroundColor3=C.bg,BorderSizePixel=0})
mk('UICorner',panel,{CornerRadius=UDim.new(0,11)})
mk('TextLabel',panel,{Position=UDim2.fromOffset(11,6),Size=UDim2.fromOffset(225,30),BackgroundTransparency=1,Text='AUTO WORLD BOSS',TextColor3=Color3.fromRGB(99,241,202),Font=Enum.Font.GothamBold,TextSize=15,TextXAlignment=Enum.TextXAlignment.Left})
local mini=mk('TextButton',panel,{Position=UDim2.fromOffset(241,7),Size=UDim2.fromOffset(26,27),BackgroundColor3=C.panel,TextColor3=C.white,Text='−',TextSize=19})
local close=mk('TextButton',panel,{Position=UDim2.fromOffset(273,7),Size=UDim2.fromOffset(26,27),BackgroundColor3=C.red,TextColor3=C.white,Text='X',TextSize=16})
local joinB=mk('TextButton',panel,{Position=UDim2.fromOffset(10,46),Size=UDim2.fromOffset(285,35),BackgroundColor3=C.panel,TextColor3=C.white,Font=Enum.Font.GothamBold,TextSize=13,Text='AUTO JOIN (GO): OFF'})
local attackB=mk('TextButton',panel,{Position=UDim2.fromOffset(10,87),Size=UDim2.fromOffset(285,35),BackgroundColor3=C.panel,TextColor3=C.white,Font=Enum.Font.GothamBold,TextSize=13,Text='AUTO ATTACK: OFF'})
local returnB=mk('TextButton',panel,{Position=UDim2.fromOffset(10,128),Size=UDim2.fromOffset(285,35),BackgroundColor3=C.panel,TextColor3=C.white,Font=Enum.Font.GothamBold,TextSize=13,Text='AUTO RETURN: OFF'})
local offsetMinus=mk('TextButton',panel,{Position=UDim2.fromOffset(10,170),Size=UDim2.fromOffset(36,28),BackgroundColor3=C.panel,TextColor3=C.white,Text='−',TextSize=19})
local offsetTxt=mk('TextLabel',panel,{Position=UDim2.fromOffset(48,170),Size=UDim2.fromOffset(198,28),Text='KOORDINAT Y: +0 px',BackgroundTransparency=1,TextSize=12,TextColor3=C.muted})
local offsetPlus=mk('TextButton',panel,{Position=UDim2.fromOffset(258,170),Size=UDim2.fromOffset(36,28),BackgroundColor3=C.panel,TextColor3=C.white,Text='+',TextSize=19})
local statusTxt=mk('TextLabel',panel,{Position=UDim2.fromOffset(11,207),Size=UDim2.fromOffset(283,52),BackgroundTransparency=1,TextColor3=C.white,TextSize=12,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,Text='Status: SIAP\nMenunggu World Boss GO'})
local scanB=mk('TextButton',panel,{Position=UDim2.fromOffset(10,256),Size=UDim2.fromOffset(285,22),Text='SCAN GO / STATUS',BackgroundColor3=C.panel,TextColor3=C.white,TextSize=12})
for _,v in ipairs({mini,close,joinB,attackB,returnB,offsetMinus,offsetPlus,scanB}) do
 mk('UICorner',v,{CornerRadius=UDim.new(0,7)})
end
local function update(msg)
 if msg and msg~=lastStatus then lastStatus=msg; print('[GF AUTO BOSS] '..msg) end
 if statusTxt.Parent then statusTxt.Text='Mode: '..state..'\n'..(lastStatus ~= '' and lastStatus or 'Menunggu World Boss GO') end
end
local function toggle(key,b,label)
 settings[key]=not settings[key]
 b.Text=label..': '..(settings[key] and 'ON' or 'OFF')
 b.BackgroundColor3=settings[key] and C.green or C.panel
 update(label..' '..(settings[key] and 'aktif' or 'nonaktif'))
end
joinB.MouseButton1Click:Connect(function() toggle('autoJoin',joinB,'AUTO JOIN (GO)') end)
attackB.MouseButton1Click:Connect(function() toggle('autoAttack',attackB,'AUTO ATTACK') end)
returnB.MouseButton1Click:Connect(function() toggle('autoReturn',returnB,'AUTO RETURN') end)
local function drawOffset() offsetTxt.Text=string.format('KOORDINAT Y: %+d px',settings.offsetY) end
offsetMinus.MouseButton1Click:Connect(function() settings.offsetY=math.max(-100,settings.offsetY-5);drawOffset() end)
offsetPlus.MouseButton1Click:Connect(function() settings.offsetY=math.min(100,settings.offsetY+5);drawOffset() end)
mini.MouseButton1Click:Connect(function()
 minimize=not minimize
 for _,v in ipairs({joinB,attackB,returnB,offsetMinus,offsetPlus,offsetTxt,statusTxt,scanB}) do v.Visible=not minimize end
 panel.Size=minimize and UDim2.fromOffset(305,40) or UDim2.fromOffset(305,284)
 mini.Text=minimize and '+' or '−'
end)
local renderConn=nil
local function stop()
 active=false
 if renderConn then renderConn:Disconnect();renderConn=nil end
 if screen.Parent then screen:Destroy() end
end
env.GF_AutoBossStop=stop
close.MouseButton1Click:Connect(stop)
local function visible(v)
 if not v or not v.Parent or not v:IsA('GuiObject') or not v.Visible or v.AbsoluteSize.X<4 or v.AbsoluteSize.Y<4 then return false end
 local p=v.Parent
 while p and p~=PG do
  if p:IsA('GuiObject') and not p.Visible then return false end
  if p:IsA('ScreenGui') and not p.Enabled then return false end
  p=p.Parent
 end
 return true
end
local function txt(v)
 if v:IsA('TextLabel') or v:IsA('TextButton') or v:IsA('TextBox') then return string.lower((v.Text or ''):gsub('%s+',' ')) end
 return ''
end
local function ancestorText(obj,depth)
 local parent=obj
 for _=1,depth do
  if not parent or parent==PG then break end
  local parts={string.lower(parent.Name)}
  local count=0
  for _,v in ipairs(parent:GetDescendants()) do
   if count>=75 then break end
   if visible(v) and (v:IsA('TextLabel') or v:IsA('TextButton')) then
    parts[#parts+1]=txt(v)
    count+=1
   end
  end
  local s=table.concat(parts,' | ')
  if s:find('world boss',1,true) or s:find('worldboss',1,true) or s:find('gourdzilla',1,true) then return true,s end
  parent=parent.Parent
 end
 return false,''
end
-- A GO button is accepted only if within a visible World Boss notification.
local function findGo()
 local best=nil
 for _,v in ipairs(PG:GetDescendants()) do
  if v:IsA('GuiButton') and visible(v) and v~=joinB then
   local t=txt(v)
   if t=='go' or t=='go!' or t=='join' or t=='join!' or t=='enter' or t=='enter!' then
    local ok=ancestorText(v,3)
    if ok then best=v;break end
   end
  end
 end
 return best
end
local function resultShown()
 for _,v in ipairs(PG:GetDescendants()) do
  if (v:IsA('TextLabel') or v:IsA('TextButton')) and visible(v) then
   local t=txt(v)
   if t:find('boss defeated',1,true) or t:find('world boss defeated',1,true) or
      t:find('boss reward',1,true) or t:find('raid completed',1,true) or
      t:find('raid complete',1,true) then return true end
  end
 end
 return false
end
-- Return only when a boss result appeared; never press unrelated Back while farming.
local function findReturnButton()
 for _,v in ipairs(PG:GetDescendants()) do
  if v:IsA('GuiButton') and visible(v) and v~=close then
   local t=txt(v)
   if t=='back' or t=='back!' or t=='return' or t=='return!' or t=='leave' or t=='leave!' or t=='exit' then
    local ok=ancestorText(v,4)
    if ok then return v end
   end
  end
 end
 return nil
end
local function tapButton(b)
 if not visible(b) then return false,'button not visible' end
 local pos,size=b.AbsolutePosition,b.AbsoluteSize
 local x=math.floor(pos.X+size.X/2)
 local y=math.floor(pos.Y+size.Y/2+settings.offsetY)
 local ok,err=pcall(function()
  VIM:SendMouseButtonEvent(x,y,0,true,game,0)
  task.wait(.075)
  VIM:SendMouseButtonEvent(x,y,0,false,game,0)
 end)
 return ok,tostring(err or '')
end
-- Nearby combat targets: only boss-named models; optionally lantern for its shield phase.
local names={'gourdzilla','worldboss','world boss','raidboss','raid boss'}
local function matchesBossName(s)
 s=string.lower(s or '')
 for _,n in ipairs(names) do if s:find(n,1,true) then return true end end
 return false
end
local function modelPart(m)
 return m.PrimaryPart or m:FindFirstChild('HumanoidRootPart') or m:FindFirstChildWhichIsA('BasePart',true)
end
local function nearestBoss()
 local char=P.Character;local root=char and char:FindFirstChild('HumanoidRootPart')
 if not root then return end
 local best,part,dist=nil,nil,math.huge
 for _,m in ipairs(WS:GetDescendants()) do
  if m:IsA('Model') and matchesBossName(m.Name) then
   local bp=modelPart(m)
   local h=m:FindFirstChildOfClass('Humanoid')
   local hp=m:GetAttribute('Hp')
   local alive=(not h or h.Health>0) and (type(hp)~='number' or hp>0)
   if bp and alive then
    local d=(bp.Position-root.Position).Magnitude
    if d<dist and d<1800 then best,part,dist=m,bp,d end
   end
  end
 end
 return best,part
end
local function lanternPhase()
 for _,v in ipairs(PG:GetDescendants()) do
  if (v:IsA('TextLabel') or v:IsA('TextButton')) and visible(v) then
   local t=txt(v)
   if t:find('shoot the lantern',1,true) or t:find('destroy the lantern',1,true) then return true end
  end
 end
 return false
end
local function nearestLantern()
 local char=P.Character;local root=char and char:FindFirstChild('HumanoidRootPart')
 if not root then return end
 local best,dist=nil,math.huge
 for _,v in ipairs(WS:GetDescendants()) do
  if v:IsA('BasePart') and v.Name:lower():find('lantern',1,true) then
   local d=(v.Position-root.Position).Magnitude
   if d<dist and d<600 then best,dist=v,d end
  end
 end
 return best
end
local trackedPart=nil
renderConn=RunService.RenderStepped:Connect(function()
 if not active or not settings.autoAttack or state~='BOSS' or not trackedPart or not trackedPart.Parent then return end
 local cam=WS.CurrentCamera
 if cam then cam.CFrame=CFrame.lookAt(cam.CFrame.Position,trackedPart.Position) end
end)
local function fireTool()
 local char=P.Character
 local hum=char and char:FindFirstChildOfClass('Humanoid')
 if not char or not hum or hum.Health<=0 then return false end
 local tool=char:FindFirstChildOfClass('Tool')
 if not tool then
  local bag=P:FindFirstChildOfClass('Backpack')
  tool=bag and bag:FindFirstChildOfClass('Tool')
  if tool then pcall(function() hum:EquipTool(tool) end) end
 end
 if not tool then return false end
 local ok=pcall(function() tool:Activate() end)
 return ok
end
scanB.MouseButton1Click:Connect(function()
 local go=findGo()
 local boss,part=nearestBoss()
 update('GO: '..(go and go:GetFullName() or 'belum ditemukan')..' | Boss: '..(boss and boss.Name or 'belum terlihat'))
end)
-- State machine: do not touch the existing Auto Farm toggle.
task.spawn(function()
 while active do
  local now=os.clock()
  local go = findGo()
  local boss,bossPart=nearestBoss()
  local result = resultShown()
  if go and settings.autoJoin and state~='BOSS' and now-lastJoin>12 then
   local ok,err=tapButton(go)
   lastJoin=now
   joinTries+=1
   if ok then
    state='JOINING'
    enteredAt=now
    update('GO ditekan (percobaan '..joinTries..'); menunggu arena')
   else update('GO gagal: '..err) end
  end
  if state=='JOINING' then
   if boss then
    state='BOSS';bossSeenAt=now;bossMissingSince=0;bossDetectAt=now
    update('Boss terdeteksi: '..boss.Name)
   elseif result then
    state='RESULT';rewardAt=now
    update('Hasil World Boss terdeteksi')
   elseif now-enteredAt>60 then
    -- Do not guess where the player is; return to monitoring after timeout.
    state='FARMING';update('Arena belum terdeteksi; periksa status GO')
   end
  elseif state=='BOSS' then
   if result then
    state='RESULT';rewardAt=now;trackedPart=nil
    update('Hasil Boss terdeteksi; menunggu tombol kembali')
   elseif boss then
    bossMissingSince=0;bossSeenAt=now
    if settings.autoAttack then
     trackedPart=(lanternPhase() and nearestLantern()) or bossPart
     if now-lastAttack>0.2 then
      lastAttack=now
      if not fireTool() and now-lastToolWarning>7 then
       lastToolWarning=now;update('Senjata Tool belum ditemukan; aktifkan AIM/FIRE bawaan')
      end
     end
    else trackedPart=nil end
   else
    trackedPart=nil
    if bossMissingSince==0 then bossMissingSince=now end
    if now-bossMissingSince>35 then
     -- Boss disappearance alone is not a verified victory; don't click Back.
     state='WAIT_RESULT';update('Boss menghilang; menunggu layar hasil')
    end
   end
  elseif state=='WAIT_RESULT' then
   if result then state='RESULT';rewardAt=now;update('Layar hasil terdeteksi')
   elseif boss then state='BOSS';bossMissingSince=0;update('Boss muncul kembali') end
  elseif state=='RESULT' then
   if settings.autoReturn and now-rewardAt>2 and now-lastReturn>10 then
    local back=findReturnButton()
    if back then
     local ok,err=tapButton(back)
     lastReturn=now;returnTries+=1
     if ok then
      state='RETURNING';enteredAt=now
      update('Tombol kembali ditekan; cek Auto Farm bawaan')
     else update('Kembali gagal: '..err) end
    elseif now-rewardAt>20 then update('Hasil terlihat, tetapi tombol Back/Leave Boss belum ditemukan') end
   end
  elseif state=='RETURNING' then
   if now-enteredAt>12 then
    state='FARMING';trackedPart=nil
    update('Kembali ke pemantauan; Auto Farm bawaan tidak diubah')
   end
  elseif state=='FARMING' then
   if result then state='RESULT';rewardAt=now;update('Hasil Boss terdeteksi')
   elseif boss and now-lastJoin<90 then
    state='BOSS';bossSeenAt=now;update('Boss terdeteksi: '..boss.Name)
   end
  end
  task.wait(1.5)
 end
end)
update('SIAP. Aktifkan Auto Join + Attack + Return. AFK Farm bawaan tetap terpisah.')
