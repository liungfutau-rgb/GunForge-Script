-- +1 GUN FORGE | ABYSSITE AUTO FORGE V4
-- UI automation: tap Abyssite 14 times -> Forge -> dismiss result -> repeat.
-- Open Tempa > Senjata first. Works only if GUI actions can be simulated in your client.
-- Starts in TEST 1x mode; switch to LOOP only after successfully testing.

local Players = game:GetService('Players')
local VIM = game:GetService('VirtualInputManager')
local player = Players.LocalPlayer
local pg = player:WaitForChild('PlayerGui')
local env = (getgenv and getgenv()) or _G
if type(env.GF_AbyssiteV4Stop) == 'function' then pcall(env.GF_AbyssiteV4Stop) end
local old = pg:FindFirstChild('GF_AbyssiteV4')
if old then old:Destroy() end

local running, enabled, minimized = true, false, false
local completed, maxCycles = 0, 1 -- 0 means unlimited looping
local TAP_DELAY, AFTER_FORGE_DELAY, CYCLE_DELAY = .18, 1.15, 1.5
local INPUT_OFFSET = Vector2.new(0, 0) -- adjust only if executor coordinates are offset

local function make(class, parent, properties)
    local object = Instance.new(class)
    for key, value in pairs(properties) do object[key] = value end
    object.Parent = parent
    return object
end
local gui = make('ScreenGui', pg, {Name='GF_AbyssiteV4', ResetOnSpawn=false, DisplayOrder=100})
local panel = make('Frame', gui, {Size=UDim2.fromOffset(355,300), Position=UDim2.new(.5,-177,.18,0),
    BackgroundColor3=Color3.fromRGB(19,26,40), Active=true, Draggable=true})
make('UICorner', panel, {CornerRadius=UDim.new(0,10)})
make('TextLabel', panel, {Size=UDim2.new(1,-88,0,38), BackgroundTransparency=1,
    Text='ABYSSITE ×14 | AUTO FORGE V4', Font=Enum.Font.GothamBold, TextSize=14,
    TextColor3=Color3.fromRGB(85,239,194)})
local mini = make('TextButton',panel,{Size=UDim2.fromOffset(30,30),Position=UDim2.new(1,-70,0,4),
    Text='—', TextSize=18, BackgroundColor3=Color3.fromRGB(58,78,105), TextColor3=Color3.new(1,1,1)})
local exit = make('TextButton',panel,{Size=UDim2.fromOffset(30,30),Position=UDim2.new(1,-35,0,4),
    Text='X', TextSize=16, BackgroundColor3=Color3.fromRGB(146,59,68), TextColor3=Color3.new(1,1,1)})
local start = make('TextButton',panel,{Size=UDim2.new(1,-24,0,44),Position=UDim2.fromOffset(12,44),
    Text='AUTO FORGE: OFF', Font=Enum.Font.GothamBold, TextSize=17,
    BackgroundColor3=Color3.fromRGB(155,58,68),TextColor3=Color3.new(1,1,1)})
make('UICorner',start,{CornerRadius=UDim.new(0,8)})
local state = make('TextLabel',panel,{Size=UDim2.new(1,-24,0,105),Position=UDim2.fromOffset(12,93),
    Text='Buka Tempa > Senjata. Pastikan slot bahan kosong, lalu tekan CEK.',
    TextWrapped=true, TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,
    TextSize=13, BackgroundTransparency=1,TextColor3=Color3.fromRGB(231,235,242)})
local tally = make('TextLabel',panel,{Size=UDim2.new(1,-24,0,25),Position=UDim2.fromOffset(12,207),
    Text='Forge berhasil: 0 | Mode: 1x', TextXAlignment=Enum.TextXAlignment.Left, TextSize=13,
    BackgroundTransparency=1,TextColor3=Color3.fromRGB(167,205,240)})
local check = make('TextButton',panel,{Size=UDim2.new(.5,-18,0,37),Position=UDim2.fromOffset(12,245),
    Text='CEK GUI',BackgroundColor3=Color3.fromRGB(54,103,160),TextColor3=Color3.new(1,1,1),
    Font=Enum.Font.GothamBold,TextSize=13})
local mode = make('TextButton',panel,{Size=UDim2.new(.5,-18,0,37),Position=UDim2.new(.5,6,0,245),
    Text='MODE: 1 KALI',BackgroundColor3=Color3.fromRGB(66,85,113),TextColor3=Color3.new(1,1,1),
    Font=Enum.Font.GothamBold,TextSize=13})
for _,b in ipairs({check,mode}) do make('UICorner',b,{CornerRadius=UDim.new(0,7)}) end

local function normalize(t)
    return tostring(t or ''):lower():gsub('%s+', ''):gsub('×','x')
end
local function shown(object)
    if not object or not object.Parent then return false end
    local node = object
    while node and node ~= pg do
        if node:IsA('GuiObject') and (not node.Visible or node.AbsoluteSize.X < 2 or node.AbsoluteSize.Y < 2) then return false end
        node = node.Parent
    end
    return true
end
local function extractText(object)
    if object:IsA('TextLabel') or object:IsA('TextButton') or object:IsA('TextBox') then return tostring(object.Text) end
    return ''
end
local function toButton(object)
    local node = object
    while node and node ~= pg do
        if node:IsA('GuiButton') then return node end
        node = node.Parent
    end
    return nil
end
local function screenBottom(o)
    local view = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.Y or 800
    return (o.AbsolutePosition.Y + o.AbsoluteSize.Y/2) / math.max(view, 1)
end
local function getOre()
    local possibilities, unique = {}, {}
    for _,obj in ipairs(pg:GetDescendants()) do
        if not obj:IsDescendantOf(gui) and shown(obj) then
            local txt = normalize(extractText(obj))
            if txt:find('abyssite',1,true) or txt:find('abbysite',1,true) then
                local btn = toButton(obj)
                if btn and shown(btn) and not unique[btn] then
                    unique[btn] = true
                    possibilities[#possibilities+1] = btn
                end
            end
        end
    end
    table.sort(possibilities, function(a,b)
        -- inventory is in the right side of the forge UI
        return a.AbsolutePosition.X > b.AbsolutePosition.X
    end)
    return possibilities[1], #possibilities
end
local function getForge()
    local possibilities, seen = {}, {}
    for _,obj in ipairs(pg:GetDescendants()) do
        if not obj:IsDescendantOf(gui) and shown(obj) then
            local txt = normalize(extractText(obj))
            if txt == 'tempa' or txt == 'forge' then
                local btn = toButton(obj)
                if btn and shown(btn) and not seen[btn] then
                    seen[btn]=true
                    possibilities[#possibilities+1]=btn
                end
            end
        end
    end
    table.sort(possibilities, function(a,b)
        -- action button at bottom center, not the menu title at the top
        local function score(o)
            local c = o.BackgroundColor3
            return screenBottom(o)*2 + (c.G-c.R*.6-c.B*.3)*2 + (o.AbsoluteSize.X > 100 and .5 or 0)
        end
        return score(a)>score(b)
    end)
    local best = possibilities[1]
    if best and screenBottom(best) < .5 then best=nil end
    return best, #possibilities
end
local function selectionAmount()
    -- The selected ore shows as an icon with text x14, sometimes "×14".
    -- The inventory count (for example 72) is not the selected amount.
    local highest = 0
    for _,obj in ipairs(pg:GetDescendants()) do
        if not obj:IsDescendantOf(gui) and shown(obj) then
            local s = normalize(extractText(obj))
            local n = s:match('^x(%d+)$') or s:match('^(%d+)/14$')
            if n then highest = math.max(highest, tonumber(n) or 0) end
        end
    end
    return highest
end
local function clickPoint(x,y)
    local ok, err = pcall(function()
        x,y = x+INPUT_OFFSET.X,y+INPUT_OFFSET.Y
        VIM:SendMouseButtonEvent(x,y,0,true,game,0)
        task.wait(.075)
        VIM:SendMouseButtonEvent(x,y,0,false,game,0)
    end)
    return ok,err
end
local function tap(button)
    if not shown(button) then return false,'Tombol tidak terlihat' end
    local p,s = button.AbsolutePosition,button.AbsoluteSize
    if s.X < 2 or s.Y < 2 then return false,'Ukuran tombol nol' end
    return clickPoint(p.X+s.X/2,p.Y+s.Y/2)
end
local function stop(message)
    enabled=false
    start.Text='AUTO FORGE: OFF'
    start.BackgroundColor3=Color3.fromRGB(155,58,68)
    if message then state.Text=message end
end
local function update()
    tally.Text='Forge selesai/terverifikasi: '..completed..' | Mode: '..(maxCycles==0 and 'LOOP' or (maxCycles..'x'))
end
local function checkGUI()
    local ore,oc = getOre()
    local forge,fc = getForge()
    local amount=selectionAmount()
    state.Text=string.format('Abyssite: %s (%d kandidat)\nForge: %s (%d kandidat)\nSlot bahan: x%d\n%s',
      ore and 'TERDETEKSI' or 'TIDAK ADA',oc, forge and 'TERDETEKSI' or 'TIDAK ADA',fc,amount,
      forge and ('Forge path: '..forge:GetFullName():sub(-65)) or 'Buka mesin Tempa > Senjata.')
end
check.MouseButton1Click:Connect(checkGUI)
mode.MouseButton1Click:Connect(function()
    if enabled then return end
    maxCycles = maxCycles==1 and 5 or (maxCycles==5 and 0 or 1)
    mode.Text=maxCycles==0 and 'MODE: LOOP' or ('MODE: '..maxCycles..' KALI')
    update()
end)
start.MouseButton1Click:Connect(function()
    if enabled then stop('Dihentikan oleh pengguna.'); return end
    local ore = getOre()
    if not ore then state.Text='Tidak menemukan tombol Abyssite. Buka menu Tempa dan scroll ke Abyssite.'; return end
    if selectionAmount() ~= 0 then
        state.Text='Kosongkan slot bahan dahulu (Bersihkan). Script memulai dari slot kosong.'
        return
    end
    enabled=true;completed=0;update()
    start.Text='AUTO FORGE: ON';start.BackgroundColor3=Color3.fromRGB(37,145,102)
    state.Text='Mulai: menekan Abyssite 14 kali...'
end)
mini.MouseButton1Click:Connect(function()
    minimized=not minimized
    panel.Size=minimized and UDim2.fromOffset(355,38) or UDim2.fromOffset(355,300)
    for _,o in ipairs({start,state,tally,check,mode}) do o.Visible=not minimized end
    mini.Text=minimized and '+' or '—'
end)
local function dispose()
    running=false;stop()
    if gui.Parent then gui:Destroy() end
end
exit.MouseButton1Click:Connect(dispose)
env.GF_AbyssiteV4Stop=dispose

local function forgeOnce()
    -- 1. Tap the SAME Abyssite inventory tile 14 times, not "14 pieces" in one click.
    for n=1,14 do
        if not enabled then return end
        local ore=getOre()
        if not ore then stop('Abyssite hilang saat klik ke-'..n); return end
        state.Text=string.format('Memasukkan Abyssite: klik %d/14',n)
        local ok,err=tap(ore)
        if not ok then stop('Gagal klik Abyssite: '..tostring(err));return end
        task.wait(TAP_DELAY)
    end
    if not enabled then return end
    task.wait(.35)
    -- 2. Verify actual x14 in forge slots to avoid spending a wrong combination.
    local amount=selectionAmount()
    if amount~=14 then
        stop('Sesudah 14 klik, slot terbaca x'..amount..' (harus x14). Cek input GUI/posisi ore. Forge TIDAK ditekan.')
        return
    end
    -- 3. Tap the bottom green Forge button.
    local forge=getForge()
    if not forge then stop('Slot x14 benar, tetapi tombol Tempa hijau tidak ditemukan.');return end
    state.Text='Slot x14 ✓ | menekan Tempa...'
    local ok,err=tap(forge)
    if not ok then stop('Klik Forge gagal: '..tostring(err));return end
    task.wait(AFTER_FORGE_DELAY)
    if not enabled then return end
    -- 4. If slot still shows x14, forge is likely not processed. Don't spend further materials.
    if selectionAmount()==14 then
        stop('Slot masih x14 sesudah Forge; tidak terkonfirmasi berhasil. Hentikan untuk pemeriksaan.')
        return
    end
    -- 5. Dismiss popup by tapping a blank area near screen center, away from our GUI.
    -- It is intentionally done only after the selected materials have disappeared.
    local viewport=workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1000,700)
    state.Text='Tempa terpicu. Menutup popup hasil...'
    clickPoint(viewport.X*.57,viewport.Y*.38)
    task.wait(.65)
    if not enabled then return end
    completed=completed+1;update()
    if maxCycles>0 and completed>=maxCycles then
        stop('Selesai '..completed..' siklus. Jika sukses, ubah MODE menjadi LOOP.')
        return
    end
    if selectionAmount()~=0 then
        stop('Slot belum kosong untuk siklus berikutnya. Berhenti untuk keamanan.')
        return
    end
    state.Text='Siklus '..completed..' selesai. Mengulang...'
    task.wait(CYCLE_DELAY)
end

task.spawn(function()
    while running do
        if enabled then
            local ok,err=pcall(forgeOnce)
            if not ok then stop('Kesalahan script: '..tostring(err):sub(1,180)) end
        end
        task.wait(.3)
    end
end)
print('[GunForge] Abyssite x14 Auto Forge V4 started. Test 1 cycle first.')
