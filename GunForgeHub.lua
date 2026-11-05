-- Gun Forge Hub | clean independent Luau GUI
-- Client-side prototype; no damage/ammo modification.
local Players = game:GetService('Players')
local RunService = game:GetService('RunService')
local UIS = game:GetService('UserInputService')
local player = Players.LocalPlayer
local pg = player:WaitForChild('PlayerGui')
local env = (type(getgenv)=='function' and getgenv()) or _G
if type(env.GunForgeHubCleanup)=='function' then pcall(env.GunForgeHubCleanup) end
local old = pg:FindFirstChild('GunForgeHubUI')
if old then old:Destroy() end

local state = {aim=false,esp=false,attack=false,follow=false, running=true, range=180, attackDistance=16, target=nil}
local connections = {}
local highlights = {}
local currentTab = 'Combat'
local palette = {bg=Color3.fromRGB(12,16,26),side=Color3.fromRGB(18,24,37),card=Color3.fromRGB(27,35,50),accent=Color3.fromRGB(57,218,169),text=Color3.fromRGB(236,244,249),sub=Color3.fromRGB(153,169,189),off=Color3.fromRGB(68,80,98)}
local function add(parent,class,props)
    local item=Instance.new(class)
    for k,v in pairs(props or {}) do item[k]=v end
    item.Parent=parent
    return item
end
local function round(object,r) add(object,'UICorner',{CornerRadius=UDim.new(0,r or 10)}) end
local function label(parent,text,size,color,props)
    local p=props or {}; p.Text=text; p.TextSize=size or 14; p.TextColor3=color or palette.text; p.Font=Enum.Font.Gotham; p.BackgroundTransparency=1; p.TextXAlignment=p.TextXAlignment or Enum.TextXAlignment.Left
    return add(parent,'TextLabel',p)
end
local gui=add(pg,'ScreenGui',{Name='GunForgeHubUI',ResetOnSpawn=false,IgnoreGuiInset=true,DisplayOrder=50})
local main=add(gui,'Frame',{Size=UDim2.fromOffset(560,365),Position=UDim2.new(0.5,-280,0.5,-182),BackgroundColor3=palette.bg,BorderSizePixel=0,Active=true})
round(main,15)
add(main,'UIStroke',{Color=Color3.fromRGB(56,70,91),Thickness=1})
local head=add(main,'Frame',{Size=UDim2.new(1,0,0,51),BackgroundColor3=palette.side,BorderSizePixel=0})
round(head,15)
label(head,'✦  GUN FORGE HUB',17,palette.accent,{Position=UDim2.fromOffset(18,9),Size=UDim2.fromOffset(360,30),Font=Enum.Font.GothamBold})
local mini=add(head,'TextButton',{Size=UDim2.fromOffset(33,28),Position=UDim2.new(1,-76,0,10),Text='—',TextSize=21,TextColor3=palette.text,BackgroundColor3=palette.card,BorderSizePixel=0,Font=Enum.Font.GothamBold});round(mini,7)
local close=add(head,'TextButton',{Size=UDim2.fromOffset(33,28),Position=UDim2.new(1,-39,0,10),Text='×',TextSize=22,TextColor3=palette.text,BackgroundColor3=Color3.fromRGB(100,49,64),BorderSizePixel=0});round(close,7)
local sidebar=add(main,'Frame',{Position=UDim2.fromOffset(0,51),Size=UDim2.new(0,146,1,-51),BackgroundColor3=palette.side,BorderSizePixel=0})
local sideList=add(sidebar,'UIListLayout',{Padding=UDim.new(0,7),HorizontalAlignment=Enum.HorizontalAlignment.Center,SortOrder=Enum.SortOrder.LayoutOrder})
add(sidebar,'UIPadding',{PaddingTop=UDim.new(0,15)})
local content=add(main,'Frame',{Position=UDim2.fromOffset(154,60),Size=UDim2.new(1,-164,1,-69),BackgroundTransparency=1})
local heading=label(content,'Combat',21,palette.text,{Size=UDim2.new(1,0,0,32),Font=Enum.Font.GothamBold})
local subtitle=label(content,'Client-side controls • Experimental',11,palette.sub,{Position=UDim2.fromOffset(0,35),Size=UDim2.new(1,0,0,20)})
local scroll=add(content,'ScrollingFrame',{Position=UDim2.fromOffset(0,63),Size=UDim2.new(1,0,1,-100),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,CanvasSize=UDim2.fromOffset(0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y})
add(scroll,'UIListLayout',{Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder})
local status=label(content,'Status: Idle',12,palette.sub,{Position=UDim2.new(0,0,1,-27),Size=UDim2.new(1,0,0,24)})
local tabs={};local showTab
for i,tab in ipairs({'Combat','Farming','Visual','Settings'}) do
    local b=add(sidebar,'TextButton',{Size=UDim2.fromOffset(128,39),Text=tab,TextSize=14,TextColor3=palette.sub,BackgroundColor3=palette.card,Font=Enum.Font.GothamMedium,BorderSizePixel=0,LayoutOrder=i})
    round(b,8);tabs[tab]=b
    table.insert(connections,b.MouseButton1Click:Connect(function()showTab(tab)end))
end
local function character()
    local c=player.Character
    return c,c and c:FindFirstChildOfClass('Humanoid'),c and c:FindFirstChild('HumanoidRootPart')
end
local function valid(model)
    if not model or not model.Parent then return false end
    local h=model:FindFirstChildOfClass('Humanoid')
    return h and h.Health>0 and (model:FindFirstChild('HumanoidRootPart') or model.PrimaryPart) and not Players:GetPlayerFromCharacter(model)
end
local function partOf(model)
    return model and (model:FindFirstChild('Head') or model:FindFirstChild('HumanoidRootPart') or model.PrimaryPart)
end
local function scanTarget()
    local c,h,root=character()
    if not root or not h or h.Health<=0 then return nil end
    local chosen,dist=nil,state.range
    for _,obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA('Humanoid') then
            local model=obj.Parent
            if model~=c and valid(model) then
                local pt=partOf(model)
                if pt then
                    local d=(root.Position-pt.Position).Magnitude
                    if d<dist then chosen,dist=model,d end
                end
            end
        end
    end
    return chosen
end
local function row(title,description,field,initial)
    local f=add(scroll,'Frame',{Size=UDim2.new(1,-6,0,61),BackgroundColor3=palette.card,BorderSizePixel=0});round(f,9)
    label(f,title,14,palette.text,{Position=UDim2.fromOffset(12,8),Size=UDim2.new(1,-112,0,20),Font=Enum.Font.GothamMedium})
    label(f,description,10,palette.sub,{Position=UDim2.fromOffset(12,32),Size=UDim2.new(1,-105,0,18)})
    local b=add(f,'TextButton',{Size=UDim2.fromOffset(72,29),Position=UDim2.new(1,-83,0,16),Text=initial and 'ON' or 'OFF',TextColor3=palette.text,TextSize=12,Font=Enum.Font.GothamBold,BackgroundColor3=initial and palette.accent or palette.off,BorderSizePixel=0});round(b,7)
    table.insert(connections,b.MouseButton1Click:Connect(function()
        state[field]=not state[field]
        b.Text=state[field] and 'ON' or 'OFF';b.BackgroundColor3=state[field] and palette.accent or palette.off
    end))
end
local function info(title,description)
    local f=add(scroll,'Frame',{Size=UDim2.new(1,-6,0,67),BackgroundColor3=palette.card,BorderSizePixel=0});round(f,9)
    label(f,title,14,palette.text,{Position=UDim2.fromOffset(12,8),Size=UDim2.new(1,-24,0,20),Font=Enum.Font.GothamBold})
    label(f,description,11,palette.sub,{Position=UDim2.fromOffset(12,31),Size=UDim2.new(1,-24,0,31),TextWrapped=true})
end
local function inputRow()
    local f=add(scroll,'Frame',{Size=UDim2.new(1,-6,0,62),BackgroundColor3=palette.card,BorderSizePixel=0});round(f,9)
    label(f,'Target range (studs)',13,palette.text,{Position=UDim2.fromOffset(12,9),Size=UDim2.fromOffset(210,23)})
    local box=add(f,'TextBox',{Size=UDim2.fromOffset(90,32),Position=UDim2.new(1,-102,0,15),Text=tostring(state.range),TextSize=14,TextColor3=palette.text,BackgroundColor3=palette.side,ClearTextOnFocus=false,BorderSizePixel=0});round(box,7)
    table.insert(connections,box.FocusLost:Connect(function()
        state.range=math.clamp(tonumber(box.Text) or state.range,20,500);box.Text=tostring(state.range)
    end))
end
showTab=function(tab)
    currentTab=tab;heading.Text=tab
    for name,b in pairs(tabs) do b.BackgroundColor3=name==tab and Color3.fromRGB(30,95,81) or palette.card;b.TextColor3=name==tab and palette.accent or palette.sub end
    for _,v in ipairs(scroll:GetChildren()) do if v:IsA('Frame') then v:Destroy() end end
    if tab=='Combat' then
        row('Camera Aim','Aim camera at nearest NPC','aim',state.aim)
        row('Tool Activate','Activate equipped Tool periodically','attack',state.attack)
        row('Follow Target','Walk toward selected NPC','follow',state.follow)
        info('Targeting limitation','Damage, ammo, and hit registration remain controlled by the game.')
    elseif tab=='Farming' then
        info('Farming Stage','Navigation and stage changes need game-specific object names. Not enabled in this prototype.')
        info('Custom Start Stage','Only works when the game exposes an unlocked stage selection.')
        info('No Reload / One Shot','Not implemented: server-controlled ammunition and damage cannot be guaranteed locally.')
    elseif tab=='Visual' then
        row('Monster Highlight','Highlight nearby detected NPCs','esp',state.esp)
        info('Live Target','The status bar below shows the current target.')
    elseif tab=='Settings' then
        inputRow()
        info('Minimize','Use the — button to collapse the menu; tap + to restore.')
        info('Close','Use × to stop all loops, remove highlights, and close the hub.')
    end
end
showTab('Combat')
local minimized=false
local floating=add(gui,'TextButton',{Size=UDim2.fromOffset(57,57),Position=UDim2.new(0,20,0.48,0),BackgroundColor3=palette.side,Text='GF',TextColor3=palette.accent,TextSize=19,Font=Enum.Font.GothamBold,Visible=false,Active=true,Draggable=true,BorderSizePixel=0});round(floating,14)
local function setMini(value)minimized=value;main.Visible=not value;floating.Visible=value end
table.insert(connections,mini.MouseButton1Click:Connect(function()setMini(true)end))
table.insert(connections,floating.MouseButton1Click:Connect(function()setMini(false)end))
-- drag main by header (touch + mouse)
local drag,dragOrigin,posOrigin=false,nil,nil
local function onDragStart(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
        drag=true;dragOrigin=input.Position;posOrigin=main.Position
    end
end
table.insert(connections,head.InputBegan:Connect(onDragStart))
table.insert(connections,UIS.InputChanged:Connect(function(input)
    if drag and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
        local delta=input.Position-dragOrigin
        main.Position=UDim2.new(posOrigin.X.Scale,posOrigin.X.Offset+delta.X,posOrigin.Y.Scale,posOrigin.Y.Offset+delta.Y)
    end
end))
table.insert(connections,UIS.InputEnded:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then drag=false end
end))
local function clearHighlights()
    for model,h in pairs(highlights) do if h then h:Destroy() end;highlights[model]=nil end
end
local function cleanup()
    if not state.running then return end
    state.running=false;state.aim=false;state.attack=false;state.follow=false;state.esp=false
    clearHighlights()
    for _,conn in ipairs(connections) do conn:Disconnect() end
    if gui.Parent then gui:Destroy() end
    if env.GunForgeHubCleanup==cleanup then env.GunForgeHubCleanup=nil end
end
env.GunForgeHubCleanup=cleanup
table.insert(connections,close.MouseButton1Click:Connect(cleanup))
table.insert(connections,RunService.RenderStepped:Connect(function()
    if not state.running or not state.aim or not valid(state.target) then return end
    local camera=workspace.CurrentCamera;local pt=partOf(state.target)
    if camera and pt then camera.CFrame=CFrame.lookAt(camera.CFrame.Position,pt.Position) end
end))
task.spawn(function()
    local lastShot=0
    while state.running do
        if state.aim or state.attack or state.follow or state.esp then
            if not valid(state.target) then state.target=scanTarget() end
            local target=state.target
            if target then
                status.Text='Target: '..target.Name
                local c,h,root=character();local part=partOf(target)
                if c and h and root and part then
                    local distance=(root.Position-part.Position).Magnitude
                    if distance>state.range then state.target=nil
                    elseif state.follow and distance>state.attackDistance then h:MoveTo(part.Position)
                    elseif state.attack and os.clock()-lastShot>=0.3 then
                        local tool=c:FindFirstChildOfClass('Tool')
                        if tool then pcall(function()tool:Activate()end) end
                        lastShot=os.clock()
                    end
                end
            else status.Text='Status: No NPC in range' end
        else status.Text='Status: Idle';state.target=nil end
        if state.esp then
            local _,_,root=character()
            if root then
                for _,obj in ipairs(workspace:GetDescendants()) do
                    if obj:IsA('Humanoid') and valid(obj.Parent) then
                        local model=obj.Parent;local pt=partOf(model)
                        if pt and (root.Position-pt.Position).Magnitude<=state.range and not highlights[model] then
                            local h=Instance.new('Highlight');h.Name='GFHubHighlight';h.FillTransparency=0.75;h.OutlineColor=palette.accent;h.Adornee=model;h.Parent=model;highlights[model]=h
                        end
                    end
                end
                for model,h in pairs(highlights) do
                    local pt=partOf(model)
                    if not valid(model) or not pt or (root.Position-pt.Position).Magnitude>state.range then h:Destroy();highlights[model]=nil end
                end
            end
        elseif next(highlights) then clearHighlights() end
        task.wait(0.5)
    end
end)
print('[Gun Forge Hub] UI initialized - experimental features only')
