-- +1 Gun Forge | Abyssite Click Diagnostic V6
-- This is a one-click diagnostic. It never invokes Forge or loops.
local Players=game:GetService('Players')
local VIM=game:GetService('VirtualInputManager')
local pg=Players.LocalPlayer:WaitForChild('PlayerGui')
local root=pg:FindFirstChild('LimitedForgeUI')
if not root then warn('Buka menu Tempa dahulu (LimitedForgeUI belum ditemukan).');return end
local old=pg:FindFirstChild('AbyssiteDiagnosticV6')
if old then old:Destroy() end
local gui=Instance.new('ScreenGui')
gui.Name='AbyssiteDiagnosticV6';gui.ResetOnSpawn=false;gui.Parent=pg
local frame=Instance.new('Frame',gui)
frame.Size=UDim2.fromOffset(350,240);frame.Position=UDim2.new(.5,-175,.25,0)
frame.BackgroundColor3=Color3.fromRGB(19,27,39);frame.Active=true;frame.Draggable=true
Instance.new('UICorner',frame).CornerRadius=UDim.new(0,10)
local title=Instance.new('TextLabel',frame)
title.Size=UDim2.new(1,-35,0,35);title.BackgroundTransparency=1;title.Text='ABYSSITE | TES 1 KLIK V6';title.TextColor3=Color3.fromRGB(70,235,183);title.TextSize=16
local close=Instance.new('TextButton',frame)
close.Position=UDim2.new(1,-32,0,2);close.Size=UDim2.fromOffset(28,28);close.Text='X'
close.MouseButton1Click:Connect(function()gui:Destroy()end)
local info=Instance.new('TextLabel',frame)
info.Position=UDim2.fromOffset(10,38);info.Size=UDim2.new(1,-20,0,132)
info.BackgroundTransparency=1;info.TextWrapped=true;info.TextXAlignment=Enum.TextXAlignment.Left;info.TextYAlignment=Enum.TextYAlignment.Top
info.TextColor3=Color3.new(1,1,1);info.TextSize=14;info.Text='Buka Tempa > Senjata, kosongkan slot secara manual. Pastikan Abyssite terlihat. Lalu tekan TES.'
local test=Instance.new('TextButton',frame)
test.Position=UDim2.fromOffset(10,175);test.Size=UDim2.new(1,-20,0,45);test.Text='TES 1 KLIK ABYSSITE';test.TextSize=15;test.TextColor3=Color3.new(1,1,1);test.BackgroundColor3=Color3.fromRGB(43,102,171)
Instance.new('UICorner',test).CornerRadius=UDim.new(0,8)
local function shown(o)
 local n=o
 while n and n~=pg do
  if n:IsA('GuiObject') and (not n.Visible or n.AbsoluteSize.X<2 or n.AbsoluteSize.Y<2) then return false end
  n=n.Parent
 end
 return true
end
local function textOf(o)
 if o:IsA('TextLabel') or o:IsA('TextButton') or o:IsA('TextBox') then return o.Text end
 return ''
end
local function getOre()
 local candidates={}
 for _,o in ipairs(root:GetDescendants()) do
  if shown(o) and string.find(string.lower(textOf(o)),'abyssite',1,true) then
   local n=o
   while n and n~=root and not n:IsA('GuiButton') do n=n.Parent end
   if n and n:IsA('GuiButton') and shown(n) then candidates[n]=true end
  end
 end
 local list={}
 for n in pairs(candidates) do table.insert(list,n) end
 table.sort(list,function(a,b)return a.AbsolutePosition.X>b.AbsolutePosition.X end)
 return list[1],#list
end
local function snapshot()
 local result={}
 for _,o in ipairs(root:GetDescendants()) do
  if shown(o) and o:IsA('GuiObject') then
   local t=textOf(o)
   local image=(o:IsA('ImageLabel') or o:IsA('ImageButton')) and o.Image or ''
   local key=o:GetFullName()
   result[key]=t..'|image='..image..'|visible='..tostring(o.Visible)
  end
 end
 return result
end
local busy=false
test.MouseButton1Click:Connect(function()
 if busy then return end
 busy=true;test.Text='MENGETES...'
 local ore,count=getOre()
 if not ore then
  info.Text='Abyssite tidak ditemukan sebagai GuiButton di LimitedForgeUI. Kirim screenshot ini.'
 else
  local before=snapshot()
  local p,s=ore.AbsolutePosition,ore.AbsoluteSize
  local x,y=p.X+s.X/2,p.Y+s.Y/2
  local ok,err=pcall(function()
   VIM:SendMouseButtonEvent(x,y,0,true,game,0)
   task.wait(.09)
   VIM:SendMouseButtonEvent(x,y,0,false,game,0)
  end)
  task.wait(.55)
  local after=snapshot();local changes={}
  for key,value in pairs(after) do
   if before[key]~=value then table.insert(changes,key:sub(-100)..' => '..value:sub(1,80))end
  end
  table.sort(changes)
  print('=== ABYSSITE CLICK TEST V6 ===')
  print('Ore button:',ore:GetFullName(),'candidates=',count,'inputOK=',ok,'error=',err)
  print('GUI changes:',#changes)
  for i=1,math.min(#changes,40) do print(changes[i])end
  info.Text='Tombol Abyssite: '..ore.Name..'\nKandidat: '..count..' | Input: '..(ok and 'TERKIRIM' or 'ERROR')..'\nPerubahan GUI: '..#changes..' elemen\n\nLihat slot Forge secara langsung: apakah 1 bahan masuk?\nKirim screenshot ini dan jawaban YA/TIDAK.'
 end
 test.Text='TES 1 KLIK ABYSSITE';busy=false
end)
