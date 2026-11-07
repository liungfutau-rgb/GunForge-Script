-- Gun Forge World 2 Hub V2
-- Walk-based farming. Does not bypass server stage locks or create server rewards.
-- Uploaded to GitHub by user; never execute untrusted remote code.
local Players=game:GetService('Players')
local RunService=game:GetService('RunService')
local WS=game:GetService('Workspace')
local RS=game:GetService('ReplicatedStorage')
local player=Players.LocalPlayer
local pg=player:WaitForChild('PlayerGui')
local env=(getgenv and getgenv()) or _G
if type(env.GFWorld2Stop)=='function' then pcall(env.GFWorld2Stop) end
local running=true
local state={aim=false,attack=false,stage=false,loop=false,collect=false}
local cfg={start=70,finish=113,range=220,attackEvery=0.35,collectRange=90}
local currentStage=nil
local mode='IDLE' -- RUN, RETURN, IDLE
local returnStage=nil
local returnStarted=0
local clearSince=nil
local lastAttack=0
local lastCollect=0
local lastNotice=''
local currentTarget=nil
local status='Ready'
local pickedNames={}
local allDrops=true
local connections={}
local stageMap={}
local function msg(s)
 status=tostring(s)
 if status~=lastNotice then print('[GF W2 V2] '..status);lastNotice=status end
end
local function make(class,parent,props)
 local x=Instance.new(class)
 for k,v in pairs(props or {}) do x[k]=v end
 x.Parent=parent
 return x
end
local function char()
 local c=player.Character
 local h=c and c:FindFirstChildOfClass('Humanoid')
 local r=c and c:FindFirstChild('HumanoidRootPart')
 if h and r and h.Health>0 then return c,h,r end
end
local function stagePoint(n)
 local container=WS:FindFirstChild('Stages')
 local stage=container and container:FindFirstChild('Stage'..tostring(n))
 if not stage then return nil end
 local floor=stage:FindFirstChild('Floor',true)
 if floor and floor:IsA('BasePart') then return floor.Position+Vector3.new(0,3,0) end
 if floor and floor:IsA('Model') then return floor:GetPivot().Position+Vector3.new(0,3,0) end
 if stage:IsA('Model') then return stage:GetPivot().Position+Vector3.new(0,3,0) end
end
local function nearestStage(pos)
 local folder=WS:FindFirstChild('Stages')
 if not folder then return nil end
 local bestN,bestD=nil,math.huge
 for _,obj in ipairs(folder:GetChildren()) do
  local n=tonumber(obj.Name:match('^Stage(%d+)$'))
  if n then
   local p=stagePoint(n)
   if p then
    local d=(p-pos).Magnitude
    if d<bestD then bestN,bestD=n,d end
   end
  end
 end
 return bestN,bestD
end
local function enemyInfo(m)
 if not (m and m:IsA('Model') and m.Parent) then return nil end
 local hp,id,sector=m:GetAttribute('Hp'),m:GetAttribute('EnemyId'),m:GetAttribute('SectorId')
 if type(hp)~='number' or hp<=0 or type(id)~='number' or type(sector)~='number' then return nil end
 local part=m:FindFirstChild('HumanoidRootPart') or m.PrimaryPart or m:FindFirstChildWhichIsA('BasePart',true)
 if not part then return nil end
 return part,id,sector
end
local function enemyCount(n)
 local folder=WS:FindFirstChild('EnemyFolder')
 if not folder then return 0 end
 local count=0
 for _,m in ipairs(folder:GetChildren()) do
  local part,_,sector=enemyInfo(m)
  if part and sector==n then count+=1 end
 end
 return count
end
local function nearestEnemy(root)
 local folder=WS:FindFirstChild('EnemyFolder')
 if not folder then return nil end
 local target,part,dist=nil,nil,cfg.range
 for _,m in ipairs(folder:GetChildren()) do
  local p,_,sector=enemyInfo(m)
  if p and (not currentStage or sector==currentStage) then
   local d=(root.Position-p.Position).Magnitude
   if d<dist then target,part,dist=m,p,d end
  end
 end
 return target,part,dist
end
local function getFire()
 local plus=RS:FindFirstChild('PlusPlus')
 local remotes=plus and plus:FindFirstChild('Remotes')
 local f=remotes and remotes:FindFirstChild('RequestFire')
 if f and f:IsA('RemoteEvent') then return f end
end
local gui=make('ScreenGui',pg,{Name='GunForgeWorld2HubV2',ResetOnSpawn=false,IgnoreGuiInset=true})
local frame=make('Frame',gui,{Size=UDim2.fromOffset(356,495),Position=UDim2.new(.5,-178,.5,-247),BackgroundColor3=Color3.fromRGB(17,22,35),BorderSizePixel=0,Active=true,Draggable=true})
make('UICorner',frame,{CornerRadius=UDim.new(0,12)})
make('TextLabel',frame,{Position=UDim2.fromOffset(12,5),Size=UDim2.new(1,-92,0,39),BackgroundTransparency=1,Text='GUN FORGE | WORLD 2 V2',TextColor3=Color3.fromRGB(80,242,186),TextXAlignment=Enum.TextXAlignment.Left,Font=Enum.Font.GothamBold,TextSize=15})
local min=make('TextButton',frame,{Position=UDim2.new(1,-76,0,8),Size=UDim2.fromOffset(32,30),BackgroundColor3=Color3.fromRGB(43,54,73),Text='—',TextColor3=Color3.new(1,1,1),TextSize=19})
local close=make('TextButton',frame,{Position=UDim2.new(1,-40,0,8),Size=UDim2.fromOffset(32,30),BackgroundColor3=Color3.fromRGB(126,48,67),Text='X',TextColor3=Color3.new(1,1,1),TextSize=16})
local body=make('ScrollingFrame',frame,{Position=UDim2.fromOffset(12,46),Size=UDim2.new(1,-24,1,-91),CanvasSize=UDim2.fromOffset(0,640),ScrollBarThickness=4,BorderSizePixel=0,BackgroundTransparency=1})
make('UIListLayout',body,{Padding=UDim.new(0,6),SortOrder=Enum.SortOrder.LayoutOrder})
local function section(t)
 make('TextLabel',body,{Size=UDim2.new(1,-8,0,23),BackgroundTransparency=1,Text=t,TextXAlignment=Enum.TextXAlignment.Left,TextColor3=Color3.fromRGB(170,210,227),Font=Enum.Font.GothamBold,TextSize=13})
end
local function button(label,cb)
 local b=make('TextButton',body,{Size=UDim2.new(1,-8,0,35),Text=label,TextSize=13,TextColor3=Color3.new(1,1,1),Font=Enum.Font.Gotham,BackgroundColor3=Color3.fromRGB(45,56,75)})
 make('UICorner',b,{CornerRadius=UDim.new(0,7)})
 table.insert(connections,b.MouseButton1Click:Connect(function() if running then cb(b) end end))
 return b
end
local buttons={}
local function toggle(label,key)
 local b=button(label..': OFF',function(self)
  state[key]=not state[key]
  self.Text=label..(state[key] and ': ON' or ': OFF')
  self.BackgroundColor3=state[key] and Color3.fromRGB(30,117,90) or Color3.fromRGB(45,56,75)
  msg(label..(state[key] and ' ON' or ' OFF'))
 end)
 buttons[key]=b
 return b
end
local function off(key,label)
 state[key]=false
 local b=buttons[key]
 if b then b.Text=label..': OFF';b.BackgroundColor3=Color3.fromRGB(45,56,75) end
end
local function numberField(label,value,callback)
 local row=make('Frame',body,{Size=UDim2.new(1,-8,0,35),BackgroundTransparency=1})
 make('TextLabel',row,{Size=UDim2.new(.55,0,1,0),Text=label,TextXAlignment=Enum.TextXAlignment.Left,BackgroundTransparency=1,TextColor3=Color3.new(1,1,1),TextSize=13})
 local box=make('TextBox',row,{Position=UDim2.new(.57,0,0,1),Size=UDim2.new(.42,0,1,-2),Text=tostring(value),ClearTextOnFocus=false,TextColor3=Color3.new(1,1,1),TextSize=13,BackgroundColor3=Color3.fromRGB(44,55,74)})
 make('UICorner',box,{CornerRadius=UDim.new(0,7)})
 table.insert(connections,box.FocusLost:Connect(function()
  local n=tonumber(box.Text)
  if n then n=math.floor(n);callback(n);box.Text=tostring(n) else msg('Nomor tidak valid: '..label) end
 end))
 return box
end
section('COMBAT')
toggle('Camera Lock','aim')
toggle('Attack (experimental)','attack')
section('STAGE / LOOP')
local startInput=numberField('Start stage',cfg.start,function(v) cfg.start=math.max(1,v) end)
local finishInput=numberField('Last stage',cfg.finish,function(v) cfg.finish=math.max(1,v) end)
button('SYNC: stage tempat berdiri',function()
 local _,_,r=char();if not r then return msg('Karakter belum siap') end
 local n,d=nearestStage(r.Position)
 if not n then return msg('Tidak ada Stage/Floor terdeteksi') end
 currentStage=n;mode='IDLE';clearSince=nil
 msg('Di sekitar Stage '..n..' ('..math.floor(d)..' studs)')
end)
button('START dari posisi saat ini',function()
 local _,_,r=char();if not r then return msg('Karakter belum siap') end
 local n,d=nearestStage(r.Position)
 if not n or d>180 then return msg('Dekati stage yang sudah terbuka dahulu') end
 if cfg.finish<cfg.start then return msg('Last stage harus >= Start stage') end
 if n>cfg.finish then return msg('Posisi sekarang melewati Last stage') end
 currentStage=n;mode='RUN';clearSince=nil
 state.stage=true
 local b=buttons.stage
 if b then b.Text='Auto Stage (walk): ON';b.BackgroundColor3=Color3.fromRGB(30,117,90) end
 if n<cfg.start then msg('Mulai Stage '..n..'; menuju '..cfg.start..' melalui jalur sah')
 elseif n>cfg.start then msg('Mulai dari Stage '..n..'; tidak bisa mundur otomatis ke '..cfg.start)
 else msg('Mulai farming Stage '..n) end
end)
toggle('Auto Stage (walk)','stage')
toggle('Loop after Last Stage','loop')
section('ITEM / HUNT YANG SUDAH DROP')
local dropChoices={}
local selectedLabel=make('TextLabel',body,{Size=UDim2.new(1,-8,0,36),BackgroundTransparency=1,Text='Item: ALL (scan dulu)',TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,TextColor3=Color3.fromRGB(217,225,235),TextSize=12})
local cycle=button('PILIH ITEM: ALL',function(self)
 if #dropChoices==0 then return msg('Tekan RESCAN ITEM dahulu') end
 local old=0
 for i,name in ipairs(dropChoices) do if not allDrops and pickedNames[name] then old=i;break end end
 local nextIndex=(old+1)%(#dropChoices+1)
 pickedNames={};allDrops=nextIndex==0
 if nextIndex>0 then pickedNames[dropChoices[nextIndex]]=true end
 local text=allDrops and 'ALL' or dropChoices[nextIndex]
 self.Text='PILIH ITEM: '..text
 selectedLabel.Text='Item yang dituju: '..text
end)
button('RESCAN ITEM DI ScrapDrops',function()
 local folder=WS:FindFirstChild('ScrapDrops')
 if not folder then return msg('ScrapDrops tidak ditemukan') end
 local seen={}
 for _,d in ipairs(folder:GetChildren()) do seen[d.Name]=true end
 dropChoices={}
 for name in pairs(seen) do table.insert(dropChoices,name) end
 table.sort(dropChoices)
 pickedNames={};allDrops=true
 cycle.Text='PILIH ITEM: ALL';selectedLabel.Text='Ditemukan '..#dropChoices..' nama item. Pilih lewat tombol.'
 msg('Nama item yang tersedia: '..(#dropChoices>0 and table.concat(dropChoices,', ') or 'kosong'))
end)
toggle('Auto Collect Dropped Item','collect')
local footer=make('TextLabel',frame,{Position=UDim2.new(0,12,1,-42),Size=UDim2.new(1,-24,0,37),BackgroundTransparency=1,Text='Ready',TextColor3=Color3.fromRGB(219,231,240),Font=Enum.Font.Gotham,TextWrapped=true,TextSize=12})
local hidden=false
min.MouseButton1Click:Connect(function()
 hidden=not hidden
 body.Visible=not hidden;footer.Visible=not hidden
 frame.Size=hidden and UDim2.fromOffset(356,48) or UDim2.fromOffset(356,495)
 min.Text=hidden and '+' or '—'
end)
-- Local camera lock. Aiming alone does not guarantee server-side hits.
RunService:BindToRenderStep('GF_W2_V2_AIM',Enum.RenderPriority.Camera.Value+1,function()
 if not running or not state.aim then return end
 local _,_,r=char();if not r then return end
 local part=enemyInfo(currentTarget)
 if not part then currentTarget=nearestEnemy(r);part=enemyInfo(currentTarget) end
 local cam=WS.CurrentCamera
 if part and cam then cam.CFrame=CFrame.lookAt(cam.CFrame.Position,part.Position) end
end)
local function go(h,p)
 if p then h:MoveTo(p) end
end
local function enterReturn()
 mode='RETURN';returnStage=cfg.finish-1;returnStarted=os.clock();clearSince=nil
 msg('Loop: mencoba berjalan kembali ke Stage '..cfg.start)
end
local function stageTick(h,r)
 if not state.stage then mode='IDLE';currentStage=nil;clearSince=nil;return end
 if not currentStage then
  local n,d=nearestStage(r.Position)
  if not n or d>180 then return msg('Masuk ke area stage terlebih dahulu') end
  currentStage=n;mode='RUN';clearSince=nil
 end
 if mode=='RETURN' then
  local n=returnStage
  if n<cfg.start then
   local p=stagePoint(cfg.start)
   if not p then off('stage','Auto Stage (walk)');return msg('Stage awal tidak tersedia') end
   if (r.Position-p).Magnitude<25 then
    currentStage=cfg.start;mode='RUN';clearSince=nil
    return msg('Loop dimulai ulang pada Stage '..cfg.start)
   end
   go(h,p)
  else
   local p=stagePoint(n)
   if not p then off('stage','Auto Stage (walk)');return msg('Stage '..n..' tidak ditemukan saat kembali') end
   if (r.Position-p).Magnitude<28 then returnStage=n-1;returnStarted=os.clock() else go(h,p) end
  end
  if os.clock()-returnStarted>18 then
   off('stage','Auto Stage (walk)');mode='IDLE'
   msg('Tidak bisa kembali lewat jalur; ulangi melalui menu reset game')
  end
  return
 end
 if currentStage>cfg.finish then
  if state.loop then enterReturn() else
   off('stage','Auto Stage (walk)');mode='IDLE';msg('Last stage selesai')
  end
  return
 end
 local p=stagePoint(currentStage)
 if not p then off('stage','Auto Stage (walk)');mode='IDLE';return msg('Stage '..currentStage..' tidak ditemukan') end
 local dist=(r.Position-p).Magnitude
 if dist>28 then go(h,p);clearSince=nil;return end
 local alive=enemyCount(currentStage)
 if alive>0 then clearSince=nil;return end
 -- Guard against a brief empty EnemyFolder during spawning.
 if not clearSince then clearSince=os.clock() end
 if os.clock()-clearSince<1.8 then return end
 if currentStage>=cfg.finish then
  currentStage+=1;clearSince=nil
  return
 end
 local nextP=stagePoint(currentStage+1)
 if not nextP then off('stage','Auto Stage (walk)');mode='IDLE';return msg('Stage berikutnya tidak tersedia') end
 go(h,nextP)
 if (r.Position-nextP).Magnitude<28 then
  currentStage+=1;clearSince=nil
  msg('Berada di Stage '..currentStage)
 end
end
local function collectiblePart(item)
 if item:IsA('BasePart') then return item end
 if item:IsA('Model') then return item.PrimaryPart or item:FindFirstChildWhichIsA('BasePart',true) end
end
local function collectTick(h,r)
 if not state.collect or os.clock()-lastCollect<1.2 then return end
 lastCollect=os.clock()
 local folder=WS:FindFirstChild('ScrapDrops')
 if not folder then return end
 local best,bestPart,bestDistance=nil,nil,cfg.collectRange
 for _,item in ipairs(folder:GetChildren()) do
  if allDrops or pickedNames[item.Name] then
   local p=collectiblePart(item)
   if p then local d=(p.Position-r.Position).Magnitude
    if d<bestDistance then best,bestPart,bestDistance=item,p,d end
   end
  end
 end
 if not best then return end
 if bestDistance>7 then
  if not state.stage then go(h,bestPart.Position) end
  return
 end
 local prompt=best:FindFirstChildWhichIsA('ProximityPrompt',true)
 if prompt and type(fireproximityprompt)=='function' then
  local ok,err=pcall(fireproximityprompt,prompt)
  if not ok then msg('Interaksi gagal: '..tostring(err)) end
 else
  msg('Item tidak memakai prompt yang didukung')
 end
end
task.spawn(function()
 while running do
  local _,h,r=char()
  if h and r then
   if state.attack or state.aim then
    local target,part=nearestEnemy(r)
    currentTarget=target
    if state.attack and target and part and os.clock()-lastAttack>=cfg.attackEvery then
     local f=getFire()
     if f then
      local id=target:GetAttribute('EnemyId')
      local ok,err=pcall(function() f:FireServer(id,part.CFrame) end)
      if not ok then msg('RequestFire gagal: '..tostring(err)) end
     else msg('RequestFire tidak tersedia') end
     lastAttack=os.clock()
    end
   end
   if state.stage then stageTick(h,r) end
   collectTick(h,r)
  end
  if footer.Parent then
   footer.Text=string.format('Stage: %s | Mode: %s | %s',tostring(currentStage or '-'),mode,status)
  end
  task.wait(.3)
 end
end)
env.GFWorld2Stop=function()
 if not running then return end
 running=false
 pcall(function()RunService:UnbindFromRenderStep('GF_W2_V2_AIM')end)
 for _,c in ipairs(connections) do pcall(function()c:Disconnect()end) end
 if gui.Parent then gui:Destroy() end
 print('[GF W2 V2] stopped')
end
close.MouseButton1Click:Connect(env.GFWorld2Stop)
msg('V2 siap. Stage awal mesti bisa diakses melalui game.')
