-- +1 Gun Forge | Ore Picker + Single Click Test V1
-- Read GUI ore entries, choose an ore, test ONE click. No forging and no looping.
local Players = game:GetService('Players')
local VIM = game:GetService('VirtualInputManager')
local player = Players.LocalPlayer
local pg = player:WaitForChild('PlayerGui')
local old = pg:FindFirstChild('GF_OrePicker_Test_V1')
if old then old:Destroy() end

local screen = Instance.new('ScreenGui')
screen.Name='GF_OrePicker_Test_V1'
screen.ResetOnSpawn=false
screen.DisplayOrder=900
screen.Parent=pg

local function ui(class,parent,props)
    local v=Instance.new(class)
    for k,value in pairs(props or {}) do v[k]=value end
    v.Parent=parent
    return v
end
local bg=ui('Frame',screen,{Size=UDim2.fromOffset(330,420),Position=UDim2.new(0,16,0.18,0),BackgroundColor3=Color3.fromRGB(19,23,35),Active=true,Draggable=true})
ui('UICorner',bg,{CornerRadius=UDim.new(0,11)})
local title=ui('TextLabel',bg,{Position=UDim2.fromOffset(14,8),Size=UDim2.fromOffset(260,32),Text='GUN FORGE | PILIH BIJIH',BackgroundTransparency=1,TextColor3=Color3.fromRGB(60,238,191),TextSize=17,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left})
local min=ui('TextButton',bg,{Position=UDim2.fromOffset(282,8),Size=UDim2.fromOffset(35,31),Text='—',TextSize=23,TextColor3=Color3.new(1,1,1),BackgroundColor3=Color3.fromRGB(50,60,75)})
local hint=ui('TextLabel',bg,{Position=UDim2.fromOffset(12,45),Size=UDim2.fromOffset(306,38),Text='Buka Tempa > Senjata / Armor, lalu SCAN.',TextWrapped=true,TextColor3=Color3.fromRGB(208,216,230),TextSize=13,BackgroundTransparency=1,TextXAlignment=Enum.TextXAlignment.Left})
local rescan=ui('TextButton',bg,{Position=UDim2.fromOffset(12,87),Size=UDim2.fromOffset(306,36),Text='RESCAN DAFTAR BIJIH',BackgroundColor3=Color3.fromRGB(37,90,143),TextColor3=Color3.new(1,1,1),TextSize=15,Font=Enum.Font.GothamBold})
local list=ui('ScrollingFrame',bg,{Position=UDim2.fromOffset(12,130),Size=UDim2.fromOffset(306,165),BackgroundColor3=Color3.fromRGB(29,35,50),BorderSizePixel=0,ScrollBarThickness=6,CanvasSize=UDim2.fromOffset(0,0)})
ui('UICorner',list,{CornerRadius=UDim.new(0,7)})
local layout=ui('UIListLayout',list,{Padding=UDim.new(0,4),SortOrder=Enum.SortOrder.LayoutOrder})
local selectedLbl=ui('TextLabel',bg,{Position=UDim2.fromOffset(12,303),Size=UDim2.fromOffset(306,24),Text='Dipilih: belum ada',TextColor3=Color3.fromRGB(255,223,126),TextSize=14,BackgroundTransparency=1,TextXAlignment=Enum.TextXAlignment.Left})
local test=ui('TextButton',bg,{Position=UDim2.fromOffset(12,332),Size=UDim2.fromOffset(306,38),Text='TES 1 KLIK BIJIH PILIHAN',BackgroundColor3=Color3.fromRGB(32,137,94),TextColor3=Color3.new(1,1,1),TextSize=15,Font=Enum.Font.GothamBold})
local status=ui('TextLabel',bg,{Position=UDim2.fromOffset(12,373),Size=UDim2.fromOffset(306,42),Text='Status: siap.',TextColor3=Color3.fromRGB(210,222,234),TextSize=12,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,BackgroundTransparency=1})
local small=false
min.MouseButton1Click:Connect(function()
    small=not small
    bg.Size=small and UDim2.fromOffset(330,43) or UDim2.fromOffset(330,420)
    for _,v in ipairs({hint,rescan,list,selectedLbl,test,status}) do v.Visible=not small end
    min.Text=small and '+' or '—'
end)

local chosenName=nil
local busy=false
local function forgeRoot()
    local forge=pg:FindFirstChild('ForgeUI')
    local root=forge and forge:FindFirstChild('Root')
    local body=root and root:FindFirstChild('Body')
    local orePanel=body and body:FindFirstChild('OrePanel')
    return orePanel and orePanel:FindFirstChild('Grid'), body
end
local function displayText(button)
    local parts={}
    for _,d in ipairs(button:GetDescendants()) do
        if (d:IsA('TextLabel') or d:IsA('TextButton')) and d.Text ~= '' then
            table.insert(parts,d.Text)
        end
    end
    return table.concat(parts,' / ')
end
local function slotSignature(body)
    local center=body and body:FindFirstChild('CenterColumn')
    local tray=center and center:FindFirstChild('Tray')
    local row=tray and tray:FindFirstChild('SlotRow')
    if not row then return 'SlotRow tidak ditemukan' end
    local parts={}
    for _,slot in ipairs(row:GetChildren()) do
        if slot.Name:match('^Slot%d+$') then
            local text={}
            for _,d in ipairs(slot:GetDescendants()) do
                if d:IsA('TextLabel') then table.insert(text,d.Name..'='..d.Text) end
                if d:IsA('ImageLabel') then table.insert(text,d.Name..':image='..d.Image) end
            end
            table.insert(parts,slot.Name..'{'..table.concat(text,',')..'}')
        end
    end
    table.sort(parts)
    return table.concat(parts,' | ')
end
local function scan()
    for _,c in ipairs(list:GetChildren()) do if c:IsA('TextButton') then c:Destroy() end end
    local grid=forgeRoot()
    if not grid then status.Text='ForgeUI.Root.Body.OrePanel.Grid tidak ditemukan. Buka menu Tempa dulu.' return end
    local buttons={}
    for _,c in ipairs(grid:GetChildren()) do
        if c:IsA('GuiButton') then table.insert(buttons,c) end
    end
    table.sort(buttons,function(a,b) return a.Name < b.Name end)
    for i,c in ipairs(buttons) do
        local label=displayText(c)
        local name=c.Name
        local btn=ui('TextButton',list,{Size=UDim2.new(1,-8,0,32),BackgroundColor3=Color3.fromRGB(43,49,68),TextColor3=Color3.new(1,1,1),TextSize=12,TextXAlignment=Enum.TextXAlignment.Left,Text='  '..name..'  |  '..label,LayoutOrder=i})
        btn.MouseButton1Click:Connect(function()
            chosenName=name
            selectedLbl.Text='Dipilih: '..name
            status.Text='Terpilih: '..name..'. Tekan TES untuk mencoba satu klik saja.'
        end)
    end
    list.CanvasSize=UDim2.fromOffset(0,#buttons*36+8)
    status.Text='Ditemukan '..#buttons..' tombol bijih. Pilih satu dari daftar.'
end
rescan.MouseButton1Click:Connect(scan)

test.MouseButton1Click:Connect(function()
    if busy then return end
    if not chosenName then status.Text='Pilih bijih pada daftar terlebih dahulu.' return end
    local grid,body=forgeRoot()
    local item=grid and grid:FindFirstChild(chosenName)
    if not item or not item:IsA('GuiButton') then status.Text='Bijih tidak ditemukan. Tekan RESCAN.' return end
    if not item.Visible or not item:IsDescendantOf(pg) then status.Text='Tombol bijih tidak terlihat. Gulir daftar pada game agar terlihat.' return end
    busy=true
    local before=slotSignature(body)
    local pos=item.AbsolutePosition
    local size=item.AbsoluteSize
    local x,y=pos.X+size.X/2,pos.Y+size.Y/2
    status.Text='Menguji satu klik pada '..chosenName..'...'
    local ok,err=pcall(function()
        VIM:SendMouseButtonEvent(x,y,0,true,game,0)
        task.wait(0.09)
        VIM:SendMouseButtonEvent(x,y,0,false,game,0)
    end)
    task.wait(0.6)
    local after=slotSignature(body)
    if not ok then
        status.Text='Input executor ditolak: '..tostring(err):sub(1,130)
    elseif before ~= after then
        status.Text='TES: ada perubahan slot. Periksa apakah tepat 1 bijih masuk.'
    else
        status.Text='TES: belum terlihat perubahan slot. Coba klik bijih manual untuk pembanding.'
    end
    print('[GF Ore Test] bijih='..chosenName,'inputOK='..tostring(ok),'slotChanged='..tostring(before~=after))
    busy=false
end)
scan()
