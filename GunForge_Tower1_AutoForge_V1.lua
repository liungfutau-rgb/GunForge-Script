-- +1 GUN FORGE | TOWER WORLD 1 + FORGE ASSIST V1
-- Tower code adapted from TowerAutoClear_Stable_V3.lua.
-- Forge is EXPERIMENTAL: manual selection/fill is required. Do not assume GUI activation works in every version.
local Players = game:GetService('Players')
local RunService = game:GetService('RunService')
local player = Players.LocalPlayer
local pg = player:WaitForChild('PlayerGui')
local env = (getgenv and getgenv()) or _G
if type(env.GF_TowerForge_Stop) == 'function' then pcall(env.GF_TowerForge_Stop) end
if type(env.GunForgeTowerStop) == 'function' then pcall(env.GunForgeTowerStop) end
pcall(function() RunService:UnbindFromRenderStep('GunForgeTowerAim') end)
local old = pg:FindFirstChild('GF_TowerForge_V1'); if old then old:Destroy() end
local alive, towerOn, forgeOn, target = true, false, false, nil
local forgeInterval = 3 -- seconds; deliberately conservative
local forgeClicks = 0
local maxForgeClicks = 1 -- manual rearm for each attempt by default
local function mk(class, parent, props)
 local obj = Instance.new(class)
 for k,v in pairs(props or {}) do obj[k]=v end
 obj.Parent=parent
 return obj
end
local gui=mk('ScreenGui',pg,{Name='GF_TowerForge_V1',ResetOnSpawn=false})
local frame=mk('Frame',gui,{Size=UDim2.fromOffset(335,290),Position=UDim2.new(.5,-167,.35,0),BackgroundColor3=Color3.fromRGB(20,24,37),Active=true,Draggable=true})
mk('UICorner',frame,{CornerRadius=UDim.new(0,12)})
local title=mk('TextLabel',frame,{Size=UDim2.new(1,-90,0,38),BackgroundTransparency=1,Text='GUN FORGE  |  WORLD 1',Font=Enum.Font.GothamBold,TextSize=16,TextColor3=Color3.fromRGB(65,244,196)})
local min=mk('TextButton',frame,{Size=UDim2.fromOffset(32,30),Position=UDim2.new(1,-72,0,4),Text='−',TextSize=21,BackgroundColor3=Color3.fromRGB(48,55,73),TextColor3=Color3.new(1,1,1)})
local close=mk('TextButton',frame,{Size=UDim2.fromOffset(32,30),Position=UDim2.new(1,-36,0,4),Text='X',BackgroundColor3=Color3.fromRGB(132,53,69),TextColor3=Color3.new(1,1,1)})
local tabs=mk('Frame',frame,{Size=UDim2.new(1,-20,0,34),Position=UDim2.fromOffset(10,43),BackgroundTransparency=1})
local tab1=mk('TextButton',tabs,{Size=UDim2.new(.49,0,1,0),Text='TOWER',BackgroundColor3=Color3.fromRGB(44,130,108),TextColor3=Color3.new(1,1,1)})
local tab2=mk('TextButton',tabs,{Size=UDim2.new(.49,0,1,0),Position=UDim2.new(.51,0,0,0),Text='FORGE',BackgroundColor3=Color3.fromRGB(45,53,73),TextColor3=Color3.new(1,1,1)})
local tower=mk('Frame',frame,{Size=UDim2.new(1,-20,0,193),Position=UDim2.fromOffset(10,86),BackgroundTransparency=1})
local forge=mk('Frame',frame,{Size=UDim2.new(1,-20,0,193),Position=UDim2.fromOffset(10,86),BackgroundTransparency=1,Visible=false})
local function label(parent,text,y,h)
 return mk('TextLabel',parent,{Size=UDim2.new(1,0,0,h or 35),Position=UDim2.fromOffset(0,y),BackgroundTransparency=1,Text=text,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,TextColor3=Color3.fromRGB(227,233,242),TextSize=13})
end
local function button(parent,text,y)
 return mk('TextButton',parent,{Size=UDim2.new(1,0,0,43),Position=UDim2.fromOffset(0,y),Text=text,Font=Enum.Font.GothamBold,TextSize=15,BackgroundColor3=Color3.fromRGB(131,52,66),TextColor3=Color3.new(1,1,1)})
end
local tb=button(tower,'AUTO CLEAR TOWER: OFF',5)
local ts=label(tower,'Status: Nonaktif',62,47)
label(tower,'World 1 • auto target, camera lock, walk + Tool activate. Bukan One Shot.',115,65)
local fb=button(forge,'AUTO FORGE: OFF',0)
local fs=label(forge,'Pilih Weapon/Armor dan isi bahan secara manual pada menu Tempa.',48,48)
local repeatBtn=button(forge,'BATAS PER SESI: 1 FORGE',103)
local help=label(forge,'Eksperimental: hanya mencoba tombol Tempa yang terlihat. Tidak mengisi 14 bahan otomatis.',153,40)
local function getChar()
 local c=player.Character
 return c, c and c:FindFirstChildOfClass('Humanoid'), c and c:FindFirstChild('HumanoidRootPart')
end
local function findEnemy()
 local char,hum,root=getChar()
 if not root or not hum or hum.Health<=0 then return nil end
 local nearest,dist=nil,150
 for _,x in ipairs(workspace:GetDescendants()) do
  if x:IsA('Humanoid') and x.Health>0 then
   local m=x.Parent
   if m and m:IsA('Model') and m~=char and not Players:GetPlayerFromCharacter(m) then
    local p=m:FindFirstChild('HumanoidRootPart') or m.PrimaryPart
    if p then
     local d=(p.Position-root.Position).Magnitude
     if d<dist then nearest,dist=m,d end
    end
   end
  end
 end
 return nearest
end
pcall(function() RunService:UnbindFromRenderStep('GunForgeTowerAim') end)
RunService:BindToRenderStep('GunForgeTowerAim',Enum.RenderPriority.Camera.Value+1,function()
 if not alive or not towerOn or not target or not target.Parent then return end
 local h=target:FindFirstChildOfClass('Humanoid')
 if not h or h.Health<=0 then target=nil; return end
 local p=target:FindFirstChild('Head') or target:FindFirstChild('HumanoidRootPart') or target.PrimaryPart
 local cam=workspace.CurrentCamera
 if p and cam then cam.CFrame=CFrame.lookAt(cam.CFrame.Position,p.Position) end
end)
task.spawn(function()
 while alive do
  if towerOn then
   local c,h,r=getChar()
   if h and r and h.Health>0 then
    target=findEnemy()
    if target then
     ts.Text='Target: '..target.Name
     local p=target:FindFirstChild('HumanoidRootPart') or target.PrimaryPart
     if p then
      if (r.Position-p.Position).Magnitude>12 then h:MoveTo(p.Position)
      else
       h:MoveTo(r.Position)
       local tool=c:FindFirstChildOfClass('Tool')
       if tool then pcall(function() tool:Activate() end) end
      end
     end
    else ts.Text='Menunggu monster berikutnya' end
   else ts.Text='Menunggu karakter' end
  end
  task.wait(.4)
 end
end)
tb.MouseButton1Click:Connect(function()
 towerOn=not towerOn
 tb.Text='AUTO CLEAR TOWER: '..(towerOn and 'ON' or 'OFF')
 tb.BackgroundColor3=towerOn and Color3.fromRGB(41,150,112) or Color3.fromRGB(131,52,66)
 if not towerOn then target=nil; ts.Text='Status: Nonaktif' end
end)
local function visibleThroughHierarchy(o)
 local p=o
 while p and p~=pg do
  if p:IsA('GuiObject') and not p.Visible then return false end
  p=p.Parent
 end
 return true
end
local function forgeButton()
 local candidates={}
 for _,o in ipairs(pg:GetDescendants()) do
  if o:IsA('TextButton') and not o:IsDescendantOf(gui) and visibleThroughHierarchy(o) then
   local text=string.lower(o.Text or '')
   if text=='tempa' or text=='forge' then table.insert(candidates,o) end
  end
 end
 return #candidates==1 and candidates[1] or nil,#candidates
end
repeatBtn.MouseButton1Click:Connect(function()
 if forgeOn then fs.Text='Matikan Auto Forge sebelum mengubah batas.'; return end
 maxForgeClicks=(maxForgeClicks==1 and 5 or 1)
 repeatBtn.Text='BATAS PER SESI: '..maxForgeClicks..' FORGE'
end)
fb.MouseButton1Click:Connect(function()
 forgeOn=not forgeOn
 forgeClicks=0
 fb.Text='AUTO FORGE: '..(forgeOn and 'ON' or 'OFF')
 fb.BackgroundColor3=forgeOn and Color3.fromRGB(41,150,112) or Color3.fromRGB(131,52,66)
 fs.Text=forgeOn and 'Mencari tombol Tempa aktif...' or 'Auto Forge berhenti.'
end)
task.spawn(function()
 while alive do
  if forgeOn then
   local b,n=forgeButton()
   if not b then
    fs.Text='Tombol Tempa belum ditemukan (kandidat: '..n..'). Buka menu forge & isi bahan.'
   elseif not b.Active or not b.Interactable then
    fs.Text='Tombol Tempa belum aktif. Periksa jumlah bahan.'
   else
    local ok,err=pcall(function() b:Activate() end)
    if ok then
     forgeClicks=forgeClicks+1
     fs.Text='Percobaan aktivasi Tempa '..forgeClicks..'/'..maxForgeClicks..'. Periksa hasil di game.'
    else fs.Text='Aktivasi gagal: '..tostring(err):sub(1,70) end
    if not ok or forgeClicks>=maxForgeClicks then
     forgeOn=false
     fb.Text='AUTO FORGE: OFF'
     fb.BackgroundColor3=Color3.fromRGB(131,52,66)
    end
   end
  end
  task.wait(forgeInterval)
 end
end)
local function switch(isForge)
 tower.Visible=not isForge; forge.Visible=isForge
 tab1.BackgroundColor3=isForge and Color3.fromRGB(45,53,73) or Color3.fromRGB(44,130,108)
 tab2.BackgroundColor3=isForge and Color3.fromRGB(44,130,108) or Color3.fromRGB(45,53,73)
end
tab1.MouseButton1Click:Connect(function() switch(false) end)
tab2.MouseButton1Click:Connect(function() switch(true) end)
local minimized=false
min.MouseButton1Click:Connect(function()
 minimized=not minimized
 frame.Size=minimized and UDim2.fromOffset(335,38) or UDim2.fromOffset(335,290)
 tabs.Visible=not minimized; tower.Visible=not minimized and not forge.Visible
 -- Persist chosen active tab when minimizing.
 if minimized then frame:SetAttribute('LastTabForge',forge.Visible); forge.Visible=false
 else switch(frame:GetAttribute('LastTabForge')==true) end
 min.Text=minimized and '+' or '−'
end)
local function stop()
 alive=false; towerOn=false; forgeOn=false; target=nil
 pcall(function() RunService:UnbindFromRenderStep('GunForgeTowerAim') end)
 if gui.Parent then gui:Destroy() end
end
close.MouseButton1Click:Connect(stop)
env.GF_TowerForge_Stop=stop
print('[Gun Forge] Tower1 + Forge Assist loaded. Forge is experimental; prepare materials manually.')
