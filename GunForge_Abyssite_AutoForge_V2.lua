-- +1 GUN FORGE | ABYSSITE x14 AUTO FORGE V2
-- Client UI automation. No forged-item creation / no server bypass.
-- Upload as a NEW file; leave Tower World 1 V3 unchanged.
local Players = game:GetService('Players')
local player = Players.LocalPlayer
local pg = player:WaitForChild('PlayerGui')
local E = (getgenv and getgenv()) or _G
if type(E.GF_AbyssiteForge_Stop)=='function' then pcall(E.GF_AbyssiteForge_Stop) end
local old=pg:FindFirstChild('GF_AbyssiteForge_V2'); if old then old:Destroy() end
local running,enabled=true,false
local count=0
local delaySeconds=2.5
local function mk(class,parent,props)
 local o=Instance.new(class)
 for k,v in pairs(props) do o[k]=v end
 o.Parent=parent
 return o
end
local gui=mk('ScreenGui',pg,{Name='GF_AbyssiteForge_V2',ResetOnSpawn=false,DisplayOrder=50})
local frame=mk('Frame',gui,{Size=UDim2.fromOffset(305,248),Position=UDim2.new(.5,-152,.28,0),BackgroundColor3=Color3.fromRGB(19,25,37),Active=true,Draggable=true})
mk('UICorner',frame,{CornerRadius=UDim.new(0,12)})
local title=mk('TextLabel',frame,{Size=UDim2.new(1,-80,0,39),BackgroundTransparency=1,Text='ABYSSITE  x14 | AUTO FORGE',TextSize=15,Font=Enum.Font.GothamBold,TextColor3=Color3.fromRGB(79,238,190)})
local min=mk('TextButton',frame,{Size=UDim2.fromOffset(32,30),Position=UDim2.new(1,-72,0,4),Text='—',TextSize=18,BackgroundColor3=Color3.fromRGB(57,68,88),TextColor3=Color3.new(1,1,1)})
local close=mk('TextButton',frame,{Size=UDim2.fromOffset(32,30),Position=UDim2.new(1,-36,0,4),Text='X',BackgroundColor3=Color3.fromRGB(132,50,64),TextColor3=Color3.new(1,1,1)})
local toggle=mk('TextButton',frame,{Size=UDim2.new(1,-24,0,43),Position=UDim2.fromOffset(12,50),Text='AUTO FORGE: OFF',Font=Enum.Font.GothamBold,TextSize=16,BackgroundColor3=Color3.fromRGB(139,50,63),TextColor3=Color3.new(1,1,1)})
mk('UICorner',toggle,{CornerRadius=UDim.new(0,8)})
local status=mk('TextLabel',frame,{Size=UDim2.new(1,-24,0,65),Position=UDim2.fromOffset(12,100),Text='Buka Tempa > Senjata. Pastikan Abyssite tersedia.',TextWrapped=true,TextSize=13,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,BackgroundTransparency=1,TextColor3=Color3.fromRGB(231,234,242)})
local attempts=mk('TextLabel',frame,{Size=UDim2.new(1,-24,0,25),Position=UDim2.fromOffset(12,172),Text='Proses: 0  |  Interval: 2.5s',TextSize=13,TextXAlignment=Enum.TextXAlignment.Left,BackgroundTransparency=1,TextColor3=Color3.fromRGB(160,197,230)})
local scan=mk('TextButton',frame,{Size=UDim2.new(1,-24,0,31),Position=UDim2.fromOffset(12,205),Text='CEK TOMBOL + ORE',Font=Enum.Font.GothamBold,TextSize=13,BackgroundColor3=Color3.fromRGB(57,90,133),TextColor3=Color3.new(1,1,1)})
mk('UICorner',scan,{CornerRadius=UDim.new(0,7)})
local function visible(o)
 local x=o
 while x and x~=pg do
  if x:IsA('GuiObject') and (not x.Visible) then return false end
  x=x.Parent
 end
 return true
end
local function descText(o)
 if o:IsA('TextLabel') or o:IsA('TextButton') then return o.Text or '' end
 return ''
end
local function normalized(s)
 return string.lower((s or ''):gsub('%s+',''))
end
local function clickableForText(test)
 local match={}
 for _,o in ipairs(pg:GetDescendants()) do
  if not o:IsDescendantOf(gui) and visible(o) and test(normalized(descText(o))) then
   local a=o
   while a and a~=pg and not a:IsA('GuiButton') do a=a.Parent end
   if a and a:IsA('GuiButton') and a.Active and (a.Interactable~=false) then match[a]=true end
  end
 end
 local out={};for b in pairs(match) do out[#out+1]=b end
 return out
end
local function findOre()
 local buttons=clickableForText(function(s) return s:find('abyssite',1,true)~=nil or s:find('abbysite',1,true)~=nil end)
 -- Exclude forge-selected mini-cards when possible: prefer right-most candidate.
 table.sort(buttons,function(a,b) return a.AbsolutePosition.X>b.AbsolutePosition.X end)
 return buttons[1],#buttons
end
local function findForge()
 local btn=clickableForText(function(s) return s=='tempa' or s=='forge' end)
 return #btn==1 and btn[1] or nil,#btn
end
local function selected14()
 -- The game in the supplied video displays x14 on the selected-material card.
 for _,o in ipairs(pg:GetDescendants()) do
  if not o:IsDescendantOf(gui) and visible(o) then
   local s=normalized(descText(o))
   if s=='x14' or s=='×14' or s=='14/14' then return true end
  end
 end
 return false
end
local function resultOverlayVisible()
 for _,o in ipairs(pg:GetDescendants()) do
  if not o:IsDescendantOf(gui) and visible(o) then
   local t=normalized(descText(o))
   if t:find('klikdimanasajauntukmelanjutkan',1,true)
      or t:find('clickanywheretocontinue',1,true) then return true end
  end
 end
 return false
end
local function dismissResult()
 if not resultOverlayVisible() then return false,'Tidak mendeteksi popup hasil' end
 local v=game:GetService('VirtualInputManager')
 local center=workspace.CurrentCamera.ViewportSize/2
 local ok,err=pcall(function()
  v:SendMouseButtonEvent(center.X,center.Y,0,true,game,0)
  task.wait(.08)
  v:SendMouseButtonEvent(center.X,center.Y,0,false,game,0)
 end)
 if not ok then return false,'Tidak bisa menutup popup: '..tostring(err) end
 task.wait(.45)
 if resultOverlayVisible() then return false,'Popup hasil belum tertutup' end
 return true
end
local function uiClick(b)
 if not b or not b.Parent then return false,'Tombol hilang' end
 local ok,err=pcall(function() b:Activate() end)
 if not ok then return false,tostring(err) end
 return true,nil
end
local function setOn(v)
 enabled=v
 toggle.Text='AUTO FORGE: '..(v and 'ON' or 'OFF')
 toggle.BackgroundColor3=v and Color3.fromRGB(40,150,105) or Color3.fromRGB(139,50,63)
end
local function fail(s)
 status.Text=s
 setOn(false)
 warn('[GF AUTO FORGE] '..s)
end
scan.MouseButton1Click:Connect(function()
 local ore,n=findOre();local forge,m=findForge()
 status.Text='Abyssite: '..(ore and 'TERDETEKSI' or ('TIDAK ('..n..')'))..' | Tempa: '..(forge and 'ADA' or ('TIDAK ('..m..')'))..' | Slot x14: '..tostring(selected14())
end)
toggle.MouseButton1Click:Connect(function()
 if enabled then setOn(false);status.Text='Dihentikan.';return end
 local ore=findOre();local forge=findForge()
 if not ore or not forge then status.Text='Buka menu Tempa > Senjata. Tekan CEK dulu.';return end
 count=0;setOn(true);status.Text='Aktif. Memilih Abyssite x14...'
end)
local minimized=false
min.MouseButton1Click:Connect(function()
 minimized=not minimized
 frame.Size=minimized and UDim2.fromOffset(305,38) or UDim2.fromOffset(305,248)
 toggle.Visible=not minimized;status.Visible=not minimized;attempts.Visible=not minimized;scan.Visible=not minimized
 min.Text=minimized and '+' or '—'
end)
local function stop()
 running=false;enabled=false
 if gui.Parent then gui:Destroy() end
end
close.MouseButton1Click:Connect(stop)
E.GF_AbyssiteForge_Stop=stop
-- One sequential loop; never sends rapid repeated forge actions.
task.spawn(function()
 while running do
  if enabled then
   local ok,err=pcall(function()
    local forge=findForge()
    if not forge then fail('Menu Tempa tertutup / tombol tidak ditemukan.');return end
    local had14=selected14()
    if not had14 then
     local ore=findOre()
     if not ore then fail('Abyssite tidak terlihat. Mungkin stok habis.');return end
     status.Text='Memilih Abyssite...'
     local hit,msg=uiClick(ore)
     if not hit then fail('Tidak bisa memilih Abyssite: '..msg);return end
     task.wait(.55)
     if not enabled or not running then return end
    end
    -- Stop if GUI didn't show 14; this is an intentional safeguard.
    if not selected14() then
     fail('Slot x14 belum terdeteksi. Periksa apakah pemilihan ore berhasil.');return
    end
    status.Text='Slot x14 terdeteksi. Menempa...'
    local b=findForge()
    if not b then fail('Tombol Tempa tidak ditemukan.');return end
    local hit,msg=uiClick(b)
    if not hit then fail('Tempa gagal: '..msg);return end
    task.wait(.65)
    if not enabled or not running then return end
    -- Only count a forge after a result overlay was observed, to avoid false positives.
    local dismissed,reason=dismissResult()
    if not dismissed then fail(reason..'. Periksa apakah tombol Tempa bekerja.');return end
    count=count+1
    attempts.Text='Proses terpicu: '..count..' | Interval: '..delaySeconds..'s'
    status.Text='Percobaan '..count..' selesai. Menunggu putaran berikutnya...'
   end)
   if not ok then fail('Error: '..tostring(err):sub(1,115)) end
  end
  task.wait(delaySeconds)
 end
end)
print('[GF] Abyssite x14 Auto Forge V2 loaded. Forge UI must already be open.')
