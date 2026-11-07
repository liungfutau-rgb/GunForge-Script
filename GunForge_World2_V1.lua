-- +1 Gun Forge | World 2 Hub V1 (experimental)
-- Independent implementation informed by the publicly available ValueHat loader.
-- Client-side automation cannot guarantee server-approved damage or teleports.
local Players = game:GetService('Players')
local RunService = game:GetService('RunService')
local WS = game:GetService('Workspace')
local RS = game:GetService('ReplicatedStorage')
local P = Players.LocalPlayer
local PG = P:WaitForChild('PlayerGui')
local GLOBAL = (getgenv and getgenv()) or _G
if type(GLOBAL.GFWorld2Stop) == 'function' then pcall(GLOBAL.GFWorld2Stop) end
local active = true
local options = {aim=false, attack=false, stage=false, collect=false, show=false}
local config = {start=70, finish=113, range=220, fireInterval=0.35, walkDistance=24}
local lastTarget, status = nil, 'Ready | World 2'
local history = {}
local connections = {}
local function log(message)
    status = tostring(message)
    history[#history+1] = os.date('%H:%M:%S') .. ' ' .. status
    if #history > 80 then table.remove(history,1) end
    print('[GF W2] ' .. status)
end
local function charInfo()
    local c=P.Character; if not c then return end
    local h=c:FindFirstChildOfClass('Humanoid')
    local root=c:FindFirstChild('HumanoidRootPart')
    if not h or not root or h.Health<=0 then return end
    return c,h,root
end
local function validEnemy(m)
    if not m or not m:IsA('Model') or not m.Parent then return false end
    local hp=m:GetAttribute('Hp'); local id=m:GetAttribute('EnemyId'); local sector=m:GetAttribute('SectorId')
    local part=m:FindFirstChild('HumanoidRootPart') or m.PrimaryPart or m:FindFirstChildWhichIsA('BasePart',true)
    return typeof(id)=='number' and typeof(sector)=='number' and typeof(hp)=='number' and hp>0 and part~=nil, part, id, sector
end
local function nearestEnemy(root)
    local f=WS:FindFirstChild('EnemyFolder'); if not f then return nil end
    local best,bestPart,bestD=nil,nil,config.range
    for _,m in ipairs(f:GetChildren()) do
        local ok,part,id,sector=validEnemy(m)
        if ok then
            local d=(part.Position-root.Position).Magnitude
            if d<bestD then best,bestPart,bestD=m,part,d end
        end
    end
    return best,bestPart,bestD
end
local function stageModel(n)
    local f=WS:FindFirstChild('Stages'); return f and f:FindFirstChild('Stage'..tostring(n))
end
local function stagePoint(n)
    local m=stageModel(n); if not m then return end
    local floor=m:FindFirstChild('Floor',true)
    if not floor then return end
    if floor:IsA('BasePart') then return floor.Position+Vector3.new(0,3,0) end
    if floor:IsA('Model') then return floor:GetPivot().Position+Vector3.new(0,3,0) end
end
local function stageAliveCount(n)
    local folder=WS:FindFirstChild('EnemyFolder'); if not folder then return 0 end
    local count=0
    for _,m in ipairs(folder:GetChildren()) do
        local ok,_,_,sector=validEnemy(m)
        if ok and sector==n then count+=1 end
    end
    return count
end
local function findPromptPosition(prompt)
    local parent=prompt.Parent
    if parent and parent:IsA('Attachment') then parent=parent.Parent end
    if parent and parent:IsA('BasePart') then return parent.Position end
    if parent and parent:IsA('Model') then return parent:GetPivot().Position end
end
local function make(class, parent, props)
    local ob=Instance.new(class)
    for key,value in pairs(props or {}) do ob[key]=value end
    ob.Parent=parent; return ob
end
local gui=make('ScreenGui',PG,{Name='GunForgeWorld2Hub',ResetOnSpawn=false,IgnoreGuiInset=true})
local frame=make('Frame',gui,{Size=UDim2.fromOffset(340,420),Position=UDim2.new(0.5,-170,0.5,-210),BackgroundColor3=Color3.fromRGB(17,22,35),BorderSizePixel=0,Active=true,Draggable=true})
make('UICorner',frame,{CornerRadius=UDim.new(0,13)})
local hdr=make('TextLabel',frame,{Size=UDim2.new(1,-70,0,40),Position=UDim2.fromOffset(12,5),BackgroundTransparency=1,Text='GUN FORGE  |  WORLD 2',TextColor3=Color3.fromRGB(80,242,186),Font=Enum.Font.GothamBold,TextSize=17,TextXAlignment=Enum.TextXAlignment.Left})
local minimize=make('TextButton',frame,{Size=UDim2.fromOffset(33,30),Position=UDim2.new(1,-73,0,8),Text='—',TextSize=19,TextColor3=Color3.new(1,1,1),BackgroundColor3=Color3.fromRGB(42,53,72)})
local close=make('TextButton',frame,{Size=UDim2.fromOffset(33,30),Position=UDim2.new(1,-36,0,8),Text='X',TextSize=17,TextColor3=Color3.new(1,1,1),BackgroundColor3=Color3.fromRGB(126,48,67)})
local body=make('ScrollingFrame',frame,{Position=UDim2.fromOffset(10,48),Size=UDim2.new(1,-20,1,-96),CanvasSize=UDim2.fromOffset(0,480),ScrollBarThickness=3,BackgroundTransparency=1,BorderSizePixel=0})
make('UIListLayout',body,{Padding=UDim.new(0,7),SortOrder=Enum.SortOrder.LayoutOrder})
local function label(t)
 return make('TextLabel',body,{Size=UDim2.new(1,-5,0,25),BackgroundTransparency=1,Text=t,Font=Enum.Font.GothamBold,TextSize=14,TextColor3=Color3.fromRGB(171,205,222),TextXAlignment=Enum.TextXAlignment.Left})
end
local buttons={}
local function toggle(name,key)
 local b=make('TextButton',body,{Size=UDim2.new(1,-5,0,36),BackgroundColor3=Color3.fromRGB(43,52,70),TextColor3=Color3.new(1,1,1),TextSize=14,Font=Enum.Font.Gotham,Text=name..': OFF'})
 make('UICorner',b,{CornerRadius=UDim.new(0,8)}); buttons[key]=b
 b.MouseButton1Click:Connect(function()
    options[key]=not options[key]
    b.Text=name..(options[key] and ': ON' or ': OFF')
    b.BackgroundColor3=options[key] and Color3.fromRGB(29,119,91) or Color3.fromRGB(43,52,70)
    log(name..(options[key] and ' enabled' or ' disabled'))
 end)
end
label('COMBAT')
toggle('Camera Lock', 'aim')
toggle('Attack (RequestFire test)', 'attack')
label('STAGE / MOVEMENT')
local function inputRow(name, default, onCommit)
 local row=make('Frame',body,{Size=UDim2.new(1,-5,0,36),BackgroundTransparency=1})
 make('TextLabel',row,{Size=UDim2.new(0.53,0,1,0),BackgroundTransparency=1,Text=name,TextXAlignment=Enum.TextXAlignment.Left,TextColor3=Color3.new(1,1,1),Font=Enum.Font.Gotham,TextSize=13})
 local box=make('TextBox',row,{Position=UDim2.new(0.55,0,0,2),Size=UDim2.new(0.45,0,1,-4),Text=tostring(default),ClearTextOnFocus=false,BackgroundColor3=Color3.fromRGB(45,54,72),TextColor3=Color3.new(1,1,1),Font=Enum.Font.Gotham,TextSize=14})
 make('UICorner',box,{CornerRadius=UDim.new(0,7)})
 box.FocusLost:Connect(function()
    local n=tonumber(box.Text)
    if n then onCommit(math.floor(n)) else log('Invalid number: '..name) end
 end)
 return box
end
inputRow('Start stage',config.start,function(v) config.start=math.max(1,v) end)
inputRow('Last stage',config.finish,function(v) config.finish=math.max(1,v) end)
toggle('Auto Stage (walk)', 'stage')
label('COLLECTION')
toggle('Auto Collect Nearby Scrap', 'collect')
label('DIAGNOSTIC')
local stats=make('TextLabel',frame,{Position=UDim2.new(0,10,1,-43),Size=UDim2.new(1,-20,0,36),BackgroundTransparency=1,Text='Ready',TextColor3=Color3.fromRGB(210,230,235),TextScaled=false,TextSize=12,Font=Enum.Font.Gotham,TextWrapped=true})
local function updateStatus() if stats.Parent then stats.Text=status end end
local small=false
minimize.MouseButton1Click:Connect(function()
 small=not small
 body.Visible=not small;stats.Visible=not small
 frame.Size=small and UDim2.fromOffset(340,48) or UDim2.fromOffset(340,420)
 minimize.Text=small and '+' or '—'
end)
local lastError=''
local remote
local function getRemote()
    if remote and remote.Parent then return remote end
    local plus=RS:FindFirstChild('PlusPlus')
    local remotes=plus and plus:FindFirstChild('Remotes')
    local req=remotes and remotes:FindFirstChild('RequestFire')
    if req and req:IsA('RemoteEvent') then remote=req return req end
end
-- Render-step camera tracking; does not modify server damage.
RunService:BindToRenderStep('GF_W2_AIM',Enum.RenderPriority.Camera.Value+1,function()
 if not active or not options.aim then return end
 local _,_,root=charInfo(); if not root then return end
 local ok,part=validEnemy(lastTarget)
 if not ok then lastTarget=nearestEnemy(root); ok,part=validEnemy(lastTarget) end
 local camera=WS.CurrentCamera
 if ok and camera then camera.CFrame=CFrame.lookAt(camera.CFrame.Position,part.Position) end
end)
local lastAttack=0
local sectorNow=nil
local stageTimer=0
local stageReached=false
local lastCollect=0
local attempted={}
task.spawn(function()
 while active do
  local _,hum,root=charInfo()
  if root then
    local target,part,dist=nearestEnemy(root)
    if target and options.attack and os.clock()-lastAttack>=config.fireInterval then
      local fire=getRemote()
      if fire then
        local ok,err=pcall(function() fire:FireServer(target:GetAttribute('EnemyId'),part.CFrame) end)
        if not ok and err~=lastError then lastError=err log('Attack error: '..tostring(err)) end
      elseif lastError~='missing_fire' then
        lastError='missing_fire';log('RequestFire RemoteEvent not found')
      end
      lastAttack=os.clock()
    end
    if target and not options.aim then lastTarget=target end
    if options.stage then
      if sectorNow==nil then
        sectorNow=config.start;stageTimer=os.clock();stageReached=false
        log('Stage start '..sectorNow)
      end
      if sectorNow>config.finish then
        options.stage=false;buttons.stage.Text='Auto Stage (walk): OFF';buttons.stage.BackgroundColor3=Color3.fromRGB(43,52,70)
        log('Stage target complete')
      else
        local p=stagePoint(sectorNow)
        if not p then
          log('Stage'..sectorNow..'/Floor not found; stopping stage mode')
          options.stage=false;buttons.stage.Text='Auto Stage (walk): OFF';buttons.stage.BackgroundColor3=Color3.fromRGB(43,52,70)
          sectorNow=nil
        else
          local d=(root.Position-p).Magnitude
          if d>23 and not stageReached then
            hum:MoveTo(p)
          else
            stageReached=true
            local live=stageAliveCount(sectorNow)
            if live==0 then
              if os.clock()-stageTimer>2 then
                -- Prefer movement through existing corridor; never teleport over server gates.
                local nextPoint=stagePoint(sectorNow+1)
                if nextPoint then
                  hum:MoveTo(nextPoint)
                  if (root.Position-nextPoint).Magnitude<24 then
                    sectorNow+=1;stageTimer=os.clock();stageReached=false;log('Reached Stage '..sectorNow)
                  end
                else
                  log('No next Stage floor found; stopping')
                  options.stage=false;buttons.stage.Text='Auto Stage (walk): OFF';buttons.stage.BackgroundColor3=Color3.fromRGB(43,52,70)
                end
              end
            else
              stageTimer=os.clock()
            end
          end
        end
      end
    else
      sectorNow=nil;stageReached=false
    end
    if options.collect and os.clock()-lastCollect>1.4 then
      lastCollect=os.clock()
      local drops=WS:FindFirstChild('ScrapDrops')
      if drops then
        local nearest,dp,dmin=nil,nil,80
        for _,drop in ipairs(drops:GetChildren()) do
          if drop.Name=='Scrap' then
            local base=drop:IsA('BasePart') and drop or (drop:IsA('Model') and (drop.PrimaryPart or drop:FindFirstChildWhichIsA('BasePart',true)))
            if base then
              local d=(root.Position-base.Position).Magnitude
              if d<dmin then nearest,dp,dmin=drop,base,d end
            end
          end
        end
        if nearest then
          if dmin>7 then hum:MoveTo(dp.Position) else
            local prompt=nearest:FindFirstChildWhichIsA('ProximityPrompt',true)
            if prompt and type(fireproximityprompt)=='function' then
              local ok,err=pcall(fireproximityprompt,prompt)
              if not ok then log('Collect prompt failed: '..tostring(err)) end
            else log('No compatible Scrap prompt') end
          end
        end
      end
    end
  end
  updateStatus()
  task.wait(0.25)
 end
end)
GLOBAL.GFWorld2Stop=function()
 active=false
 for k in pairs(options) do options[k]=false end
 pcall(function() RunService:UnbindFromRenderStep('GF_W2_AIM') end)
 if gui.Parent then gui:Destroy() end
 print('[GF W2] stopped')
end
close.MouseButton1Click:Connect(GLOBAL.GFWorld2Stop)
log('Loaded. Experimental: verify each feature in World 2.')
