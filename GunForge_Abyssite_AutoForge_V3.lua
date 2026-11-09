-- +1 GUN FORGE | ABYSSITE x14 AUTO FORGE V3
-- Experimental GUI automation. Forge menu must be open. No server bypass.
-- START is limited to 1 cycle initially. Increase only after confirming one success.
local Players=game:GetService('Players')
local UIS=game:GetService('UserInputService')
local VIM=game:GetService('VirtualInputManager')
local player=Players.LocalPlayer
local pg=player:WaitForChild('PlayerGui')
local env=(getgenv and getgenv()) or _G
if type(env.GF_Forge_Stop)=='function' then pcall(env.GF_Forge_Stop) end
local old=pg:FindFirstChild('GF_Forge_V3');if old then old:Destroy() end
local active,enabled=true,false
local crafted,limit=0,1
local interval=3
local function create(cls,parent,props)
 local o=Instance.new(cls)
 for k,v in pairs(props) do o[k]=v end
 o.Parent=parent
 return o
end
local gui=create('ScreenGui',pg,{Name='GF_Forge_V3',ResetOnSpawn=false,DisplayOrder=60})
local frame=create('Frame',gui,{Size=UDim2.fromOffset(335,285),Position=UDim2.new(.5,-167,.24,0),Active=true,Draggable=true,BackgroundColor3=Color3.fromRGB(18,24,37)})
create('UICorner',frame,{CornerRadius=UDim.new(0,12)})
local title=create('TextLabel',frame,{Size=UDim2.new(1,-82,0,38),BackgroundTransparency=1,Text='ABYSSITE x14  |  AUTO FORGE V3',TextSize=14,Font=Enum.Font.GothamBold,TextColor3=Color3.fromRGB(80,234,183)})
local mini=create('TextButton',frame,{Size=UDim2.fromOffset(30,29),Position=UDim2.new(1,-70,0,4),Text='—',TextSize=18,BackgroundColor3=Color3.fromRGB(53,70,91),TextColor3=Color3.new(1,1,1)})
local close=create('TextButton',frame,{Size=UDim2.fromOffset(30,29),Position=UDim2.new(1,-35,0,4),Text='X',BackgroundColor3=Color3.fromRGB(135,55,68),TextColor3=Color3.new(1,1,1)})
local toggle=create('TextButton',frame,{Size=UDim2.new(1,-24,0,43),Position=UDim2.fromOffset(12,43),Text='AUTO FORGE: OFF',Font=Enum.Font.GothamBold,TextSize=16,BackgroundColor3=Color3.fromRGB(149,53,65),TextColor3=Color3.new(1,1,1)})
create('UICorner',toggle,{CornerRadius=UDim.new(0,8)})
local status=create('TextLabel',frame,{Size=UDim2.new(1,-24,0,90),Position=UDim2.fromOffset(12,91),Text='Buka Tempa > Senjata, lalu tekan CEK.',TextWrapped=true,TextSize=13,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,BackgroundTransparency=1,TextColor3=Color3.fromRGB(230,233,240)})
local count=create('TextLabel',frame,{Size=UDim2.new(1,-24,0,25),Position=UDim2.fromOffset(12,186),Text='Percobaan: 0  |  Maks: 1',TextSize=13,TextXAlignment=Enum.TextXAlignment.Left,BackgroundTransparency=1,TextColor3=Color3.fromRGB(155,199,229)})
local scan=create('TextButton',frame,{Size=UDim2.new(.5,-17,0,35),Position=UDim2.fromOffset(12,230),Text='CEK ORE + TEMPA',TextSize=12,Font=Enum.Font.GothamBold,BackgroundColor3=Color3.fromRGB(48,93,143),TextColor3=Color3.new(1,1,1)})
local maxBtn=create('TextButton',frame,{Size=UDim2.new(.5,-17,0,35),Position=UDim2.new(.5,5,0,230),Text='MODE: 1 KALI',TextSize=12,Font=Enum.Font.GothamBold,BackgroundColor3=Color3.fromRGB(53,80,103),TextColor3=Color3.new(1,1,1)})
for _,b in ipairs({scan,maxBtn}) do create('UICorner',b,{CornerRadius=UDim.new(0,7)}) end
local function visible(o)
 local a=o
 while a and a~=pg do
  if a:IsA('GuiObject') and not a.Visible then return false end
  a=a.Parent
 end
 return true
end
local function norm(t)
 return tostring(t or ''):lower():gsub('%s+',''):gsub('×','x')
end
local function textOf(o)
 if o:IsA('TextLabel') or o:IsA('TextButton') then return o.Text end
 return ''
end
local function candidates(test)
 local seen,out={},{}
 for _,o in ipairs(pg:GetDescendants()) do
  if not o:IsDescendantOf(gui) and visible(o) and test(norm(textOf(o))) then
   local a=o
   while a and a~=pg and not a:IsA('GuiButton') do a=a.Parent end
   if a and a:IsA('GuiButton') and not seen[a] then
    seen[a]=true;out[#out+1]=a
   end
  end
 end
 return out
end
local function oreCandidate()
 local list=candidates(function(s) return s:find('abyssite',1,true) or s:find('abbysite',1,true) end)
 table.sort(list,function(a,b) return a.AbsolutePosition.X>b.AbsolutePosition.X end)
 return list[1],#list
end
local function greenScore(b)
 local c=b.BackgroundColor3
 return c.G-c.R*.5-c.B*.25
end
local function forgeCandidate()
 local list=candidates(function(s) return s=='tempa' or s=='forge' end)
 -- Prefer green, bottom-of-screen action buttons, never a page title.
 table.sort(list,function(a,b)
  local function score(x)
   local p=x.AbsolutePosition;local size=x.AbsoluteSize
   local camera=workspace.CurrentCamera
   local vh=camera and camera.ViewportSize.Y or 800
   return greenScore(x)*3 + (p.Y+size.Y/2)/math.max(1,vh)*1.5 + (size.X>110 and .35 or 0)
  end
  return score(a)>score(b)
 end)
 return list[1],#list
end
local function selected14()
 for _,o in ipairs(pg:GetDescendants()) do
  if not o:IsDescendantOf(gui) and visible(o) then
   local s=norm(textOf(o))
   if s=='x14' or s=='14/14' then return true end
  end
 end
 return false
end
local function clickGui(b)
 if not b or not b.Parent or not visible(b) then return false,'Tombol tidak tersedia' end
 local ap,sz=b.AbsolutePosition,b.AbsoluteSize
 local x,y=ap.X+sz.X/2,ap.Y+sz.Y/2
 if sz.X<=0 or sz.Y<=0 then return false,'Ukuran tombol 0' end
 local ok,err=pcall(function()
  -- Use an actual GUI input rather than GuiButton:Activate() alone.
  VIM:SendMouseButtonEvent(x,y,0,true,game,0)
  task.wait(.11)
  VIM:SendMouseButtonEvent(x,y,0,false,game,0)
 end)
 if not ok then return false,'Input tidak didukung: '..tostring(err) end
 return true
end
local function isOverlay()
 for _,o in ipairs(pg:GetDescendants()) do
  if not o:IsDescendantOf(gui) and visible(o) then
   local s=norm(textOf(o))
   if s:find('clickanywheretocontinue',1,true) or s:find('klikdimanasajauntukmelanjutkan',1,true) then return true end
  end
 end
 return false
end
local function stopRun(message)
 enabled=false
 toggle.Text='AUTO FORGE: OFF'
 toggle.BackgroundColor3=Color3.fromRGB(149,53,65)
 if message then status.Text=message end
end
local function check()
 local ore,n=oreCandidate()
 local forge,m=forgeCandidate()
 status.Text='Ore: '..(ore and 'ADA' or 'TIDAK')..' ('..n..')'..' | Tempa: '..(forge and 'KANDIDAT' or 'TIDAK')..' ('..m..')'..'\nSlot x14: '..tostring(selected14())..'\nTempa path: '..(forge and forge:GetFullName():sub(-85) or '-')
end
scan.MouseButton1Click:Connect(check)
maxBtn.MouseButton1Click:Connect(function()
 if enabled then return end
 limit=limit==1 and 5 or (limit==5 and 0 or 1)
 maxBtn.Text=limit==0 and 'MODE: LOOP' or ('MODE: '..limit..' KALI')
 count.Text='Percobaan: '..crafted..' | Maks: '..(limit==0 and '∞' or limit)
end)
toggle.MouseButton1Click:Connect(function()
 if enabled then stopRun('Dihentikan.');return end
 local ore=oreCandidate();local forge=forgeCandidate()
 if not ore or not forge then status.Text='Buka menu Tempa > Senjata. Tekan CEK untuk melihat tombol.';return end
 enabled=true;crafted=0
 toggle.Text='AUTO FORGE: ON'
 toggle.BackgroundColor3=Color3.fromRGB(39,154,103)
 status.Text='Aktif. Menyiapkan Abyssite x14...'
end)
local minimized=false
mini.MouseButton1Click:Connect(function()
 minimized=not minimized
 frame.Size=minimized and UDim2.fromOffset(335,38) or UDim2.fromOffset(335,285)
 for _,v in ipairs({toggle,status,count,scan,maxBtn}) do v.Visible=not minimized end
 mini.Text=minimized and '+' or '—'
end)
local function dispose()
 active=false;stopRun()
 if gui.Parent then gui:Destroy() end
end
close.MouseButton1Click:Connect(dispose)
env.GF_Forge_Stop=dispose
-- This automation does not invent items. It clicks buttons only if the game GUI exposes them.
task.spawn(function()
 while active do
  if enabled then
   local ok,err=pcall(function()
    if not selected14() then
     local ore=oreCandidate()
     if not ore then stopRun('Abyssite tidak ditemukan. Cek stok/menu.');return end
     status.Text='Memilih Abyssite untuk x14...'
     local good,msg=clickGui(ore)
     if not good then stopRun(msg);return end
     task.wait(.55)
    end
    if not enabled then return end
    if not selected14() then
     stopRun('Belum terlihat x14. Pilih 14 Abyssite manual sekali, lalu tes ulang.');return
    end
    local forge=forgeCandidate()
    if not forge then stopRun('Tombol Tempa tidak terdeteksi.');return end
    status.Text='Mencoba Tempa x14...'
    local good,msg=clickGui(forge)
    if not good then stopRun(msg);return end
    task.wait(.8)
    if not enabled then return end
    -- Without inventory evidence, do not claim success. Stop if slot is unchanged.
    if selected14() and not isOverlay() then
     stopRun('Sesudah klik, slot masih x14: belum terverifikasi berhasil. Cek Forge manual.');return
    end
    crafted=crafted+1
    count.Text='Percobaan: '..crafted..' | Maks: '..(limit==0 and '∞' or limit)
    if isOverlay() then
     stopRun('Popup hasil muncul. Tutup manual dahulu; loop otomatis dihentikan.');return
    end
    if limit>0 and crafted>=limit then stopRun('Batas percobaan tercapai: '..crafted);return end
    status.Text='Percobaan '..crafted..' terpicu. Menunggu berikutnya...'
   end)
   if not ok then stopRun('Error: '..tostring(err):sub(1,150)) end
  end
  task.wait(interval)
 end
end)
print('[GF] Auto Forge Abyssite V3 loaded')
