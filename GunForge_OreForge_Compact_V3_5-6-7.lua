-- +1 Gun Forge | Ore Forge Compact V3 (experimental client GUI automation)
-- Uses the user's tested TOTAL Y offset of +43px (including GUI inset).
-- No remote calls, no item creation. Test one cycle before loop.
local Players = game:GetService('Players')
local VIM = game:GetService('VirtualInputManager')
local GuiService = game:GetService('GuiService')
local plr=Players.LocalPlayer
local pg=plr:WaitForChild('PlayerGui')
local env=getgenv and getgenv() or _G
if env.GF_CompactForgeStop then pcall(env.GF_CompactForgeStop) end
local old=pg:FindFirstChild('GF_CompactForgeV3'); if old then old:Destroy() end
local screen=Instance.new('ScreenGui');screen.Name='GF_CompactForgeV3';screen.ResetOnSpawn=false;screen.DisplayOrder=950;screen.Parent=pg
local function make(class,parent,props)
 local o=Instance.new(class)
 for k,v in pairs(props or {}) do o[k]=v end
 o.Parent=parent;return o
end
local C={bg=Color3.fromRGB(17,23,34),panel=Color3.fromRGB(32,42,58),green=Color3.fromRGB(30,145,110),red=Color3.fromRGB(153,61,66),white=Color3.fromRGB(236,241,247)}
local base=make('Frame',screen,{Size=UDim2.fromOffset(306,269),Position=UDim2.new(0,12,0.23,0),BackgroundColor3=C.bg,Active=true,Draggable=true})
make('UICorner',base,{CornerRadius=UDim.new(0,10)})
make('TextLabel',base,{Position=UDim2.fromOffset(10,5),Size=UDim2.fromOffset(228,30),BackgroundTransparency=1,Text='GUN FORGE  |  AUTO TEMPA',TextXAlignment=Enum.TextXAlignment.Left,TextSize=14,TextColor3=Color3.fromRGB(83,237,195),Font=Enum.Font.GothamBold})
local min=make('TextButton',base,{Position=UDim2.fromOffset(242,5),Size=UDim2.fromOffset(27,28),Text='−',BackgroundColor3=C.panel,TextColor3=C.white})
local close=make('TextButton',base,{Position=UDim2.fromOffset(274,5),Size=UDim2.fromOffset(26,28),Text='X',BackgroundColor3=C.red,TextColor3=C.white})
local select=make('TextButton',base,{Position=UDim2.fromOffset(10,42),Size=UDim2.fromOffset(286,35),BackgroundColor3=C.panel,TextColor3=C.white,Text='PILIH BIJIH  ▼',TextSize=14})
local amounts={5,6,7};local idx=1; local limitLoop=false
local amount=make('TextButton',base,{Position=UDim2.fromOffset(10,84),Size=UDim2.fromOffset(135,34),Text='BIJIH: 5x',BackgroundColor3=C.panel,TextColor3=C.white,TextSize=14})
local mode=make('TextButton',base,{Position=UDim2.fromOffset(153,84),Size=UDim2.fromOffset(143,34),Text='MODE: 1x',BackgroundColor3=C.panel,TextColor3=C.white,TextSize=14})
local start=make('TextButton',base,{Position=UDim2.fromOffset(10,125),Size=UDim2.fromOffset(286,39),BackgroundColor3=C.red,TextColor3=C.white,Text='AUTO FORGE: OFF',Font=Enum.Font.GothamBold,TextSize=16})
local status=make('TextLabel',base,{Position=UDim2.fromOffset(12,173),Size=UDim2.fromOffset(282,61),Text='Buka Tempa, pilih bijih, lalu mulai.\nOffset klik: +43px (teruji).',BackgroundTransparency=1,TextColor3=C.white,TextWrapped=true,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top})
local scan=make('TextButton',base,{Position=UDim2.fromOffset(10,233),Size=UDim2.fromOffset(139,29),Text='RESCAN BIJIH',BackgroundColor3=C.panel,TextColor3=C.white,TextSize=12})
local nfo=make('TextLabel',base,{Position=UDim2.fromOffset(158,234),Size=UDim2.fromOffset(137,28),Text='Selesai: 0',BackgroundTransparency=1,TextColor3=C.white,TextSize=12})
local menu=make('ScrollingFrame',base,{Position=UDim2.fromOffset(10,79),Size=UDim2.fromOffset(286,143),BackgroundColor3=Color3.fromRGB(25,34,49),BorderSizePixel=0,ScrollBarThickness=5,Visible=false,ZIndex=10,CanvasSize=UDim2.fromOffset(0,0)})
make('UIListLayout',menu,{Padding=UDim.new(0,3),SortOrder=Enum.SortOrder.LayoutOrder})
local visibleElements={select,amount,mode,start,status,scan,nfo,menu}
local running=true;local enabled=false;local busy=false;local chosen=nil;local completed=0
local totalY=43 -- ABSOLUTE tested correction, not 43+inset.
local function getBody()
 local f=pg:FindFirstChild('ForgeUI');local r=f and f:FindFirstChild('Root');return r and r:FindFirstChild('Body')
end
local function getGrid()
 local body=getBody();local op=body and body:FindFirstChild('OrePanel');return op and op:FindFirstChild('Grid'),body
end
local function isShown(o)
 if not o or not o:IsA('GuiObject') or not o.Visible or o.AbsoluteSize.X<3 or o.AbsoluteSize.Y<3 then return false end
 local p=o.Parent
 while p and p~=pg do if p:IsA('GuiObject') and not p.Visible then return false end;p=p.Parent end
 return true
end
local function cardText(item)
 local out={}
 for _,v in ipairs(item:GetDescendants()) do if (v:IsA('TextLabel') or v:IsA('TextButton')) and v.Text~='' then out[#out+1]=v.Text end end
 return table.concat(out,' / ')
end
local function click(o)
 if not isShown(o) then return false,'Item tidak terlihat, scroll daftar ore dahulu' end
 local p,s=o.AbsolutePosition,o.AbsoluteSize
 local x,y=p.X+s.X/2,p.Y+s.Y/2+totalY
 local ok,err=pcall(function()
  VIM:SendMouseButtonEvent(x,y,0,true,game,0)
  task.wait(.09)
  VIM:SendMouseButtonEvent(x,y,0,false,game,0)
 end)
 return ok,err
end
local function snapshot()
 local body=getBody();local cc=body and body:FindFirstChild('CenterColumn');local t=cc and cc:FindFirstChild('Tray');local row=t and t:FindFirstChild('SlotRow')
 if not row then return nil end
 local entries={}
 for _,slot in ipairs(row:GetChildren()) do
  if slot.Name:match('^Slot%d+$') then
   local pieces={slot.Name}
   for _,d in ipairs(slot:GetDescendants()) do
    if d:IsA('TextLabel') or d:IsA('TextButton') then pieces[#pieces+1]=d.Name..'='..d.Text end
    if d:IsA('ImageLabel') then pieces[#pieces+1]=d.Name..'='..d.Image end
   end
   entries[#entries+1]=table.concat(pieces,';')
  end
 end
 table.sort(entries);return table.concat(entries,'|')
end
local function selectedCount()
 local b=getBody();local c=b and b:FindFirstChild('CenterColumn');local t=c and c:FindFirstChild('Tray');local r=t and t:FindFirstChild('SlotRow')
 if not r then return nil end
 local best=nil
 for _,slot in ipairs(r:GetChildren()) do
  if slot.Name:match('^Slot%d+$') then
   for _,v in ipairs(slot:GetDescendants()) do
    if v:IsA('TextLabel') or v:IsA('TextButton') then
     local tx=v.Text:gsub('%s+','')
     local n=tx:match('^[xX×](%d+)$') or tx:match('^(%d+)[xX×]$')
     if n then best=math.max(best or 0,tonumber(n)) end
    end
   end
  end
 end
 return best
end
local function buttonForge()
 local b=getBody();local cc=b and b:FindFirstChild('CenterColumn');local t=cc and cc:FindFirstChild('Tray');local actions=t and t:FindFirstChild('Actions');return actions and actions:FindFirstChild('ForgeButton')
end
local function forgeLabel(button)
 if not button then return '' end
 local s=(button:IsA('TextButton') and button.Text or '')..' '..cardText(button)
 return string.lower(s)
end
local function stop(msg)
 enabled=false; start.Text='AUTO FORGE: OFF';start.BackgroundColor3=C.red
 if msg then status.Text=msg end
end
local function refresh()
 for _,b in ipairs(menu:GetChildren()) do if b:IsA('TextButton') then b:Destroy() end end
 local grid=getGrid()
 if not grid then status.Text='Buka menu Tempa > Senjata / Armor dahulu.';return end
 local ores={}
 for _,obj in ipairs(grid:GetChildren()) do if obj:IsA('GuiButton') then ores[#ores+1]=obj end end
 table.sort(ores,function(a,b)return a.Name<b.Name end)
 for i,obj in ipairs(ores) do
  local key=obj.Name
  local b=make('TextButton',menu,{Size=UDim2.new(1,-6,0,29),Text='  '..key..'   |   '..cardText(obj),TextXAlignment=Enum.TextXAlignment.Left,TextSize=11,TextColor3=C.white,BackgroundColor3=C.panel,LayoutOrder=i,ZIndex=11})
  b.MouseButton1Click:Connect(function() chosen=key;select.Text=key:upper()..' ▼';menu.Visible=false;status.Text='Dipilih '..key..'. Pastikan kartu terlihat di game.' end)
 end
 menu.CanvasSize=UDim2.fromOffset(0,#ores*32+4)
 status.Text='Ditemukan '..#ores..' bijih. Pilih via PILIH BIJIH.'
end
select.MouseButton1Click:Connect(function()
 if enabled then return end
 if not menu.Visible then refresh() end
 menu.Visible=not menu.Visible
end)
scan.MouseButton1Click:Connect(refresh)
amount.MouseButton1Click:Connect(function()if enabled then return end;idx=(idx%3)+1;amount.Text='BIJIH: '..amounts[idx]..'x' end)
mode.MouseButton1Click:Connect(function()if enabled then return end;limitLoop=not limitLoop;mode.Text=limitLoop and 'MODE: LOOP' or 'MODE: 1x' end)
local minimized=false
min.MouseButton1Click:Connect(function()
 minimized=not minimized
 for _,o in ipairs(visibleElements) do o.Visible=not minimized end
 base.Size=minimized and UDim2.fromOffset(306,36) or UDim2.fromOffset(306,269)
 min.Text=minimized and '+' or '−'
end)
local function dispose()
 running=false;stop();if screen.Parent then screen:Destroy() end
end
close.MouseButton1Click:Connect(dispose)
env.GF_CompactForgeStop=dispose
start.MouseButton1Click:Connect(function()
 if enabled then stop('Dihentikan.');return end
 if busy then return end
 if not chosen then status.Text='Pilih bijih terlebih dahulu.';return end
 local grid=getGrid();local ore=grid and grid:FindFirstChild(chosen)
 if not ore or not isShown(ore) then status.Text='Bijih tidak terlihat. Scroll daftar sampai '..chosen..' muncul.';return end
 if not buttonForge() then status.Text='Tombol ForgeButton tidak ditemukan.';return end
 menu.Visible=false
 enabled=true;start.Text='AUTO FORGE: ON';start.BackgroundColor3=C.green
 status.Text='Memulai '..amounts[idx]..' klik '..chosen..'...'
end)
local function doCycle()
 local grid=getGrid();local ore=grid and grid:FindFirstChild(chosen)
 if not ore then stop('Bijih hilang dari Grid.');return end
 local before=snapshot()
 if not before then stop('SlotRow tidak ditemukan.');return end
 for i=1,amounts[idx] do
  if not enabled or not running then return end
  grid=getGrid();ore=grid and grid:FindFirstChild(chosen)
  if not isShown(ore) then stop('Bijih tidak terlihat pada klik '..i..'.');return end
  status.Text=string.format('%s: ketuk %d/%d',chosen,i,amounts[idx])
  local ok,err=click(ore)
  if not ok then stop('Gagal ketuk: '..tostring(err));return end
  task.wait(.20)
  if i==1 then
   local after=snapshot()
   if not after or before==after then stop('Klik pertama belum mengubah SlotRow. Dihentikan agar aman.');return end
  end
 end
 task.wait(.4)
 if not enabled then return end
 local after=snapshot()
 if after==before then stop('Slot tidak berubah setelah ketukan.');return end
 local count=selectedCount()
 if count ~= amounts[idx] then
  stop('Isi slot tidak sesuai: '..tostring(count or 'tidak terbaca')..' (harus x'..amounts[idx]..'). Tempa TIDAK ditekan.')
  return
 end
 local forge=buttonForge()
 local label=forgeLabel(forge)
 if not forge or not isShown(forge) or not (label:find('forge',1,true) or label:find('tempa',1,true)) then
  stop('Bahan dimasukkan, tapi tombol Tempa belum aktif/terbaca. Cek manual.');return
 end
 status.Text='Bahan masuk; menekan Tempa...'
 local ok,err=click(forge)
 if not ok then stop('Klik Tempa gagal: '..tostring(err));return end
 task.wait(1.0)
 -- Click outside result panel, following the user's manual dismissal action.
 -- Click in the upper scene; never tap on another ore while popup is present.
 local camera=workspace.CurrentCamera
 if camera then
  local v=camera.ViewportSize
  pcall(function()
   local x,y=v.X*.54,v.Y*.19+totalY
   VIM:SendMouseButtonEvent(x,y,0,true,game,0);task.wait(.09)
   VIM:SendMouseButtonEvent(x,y,0,false,game,0)
  end)
 end
 task.wait(.65)
 local newSlot=snapshot()
 -- Only count if the input was accepted, the slot reset or result panel changed.
 if not newSlot or newSlot==after then
  stop('Belum terverifikasi: slot belum reset setelah Tempa. Periksa popup/hasil.');return
 end
 completed=completed+1;nfo.Text='Selesai: '..completed
 if not limitLoop then stop('Siklus 1 selesai (periksa hasil).');return end
 status.Text='Siklus '..completed..' selesai. Lanjut setelah jeda...'
 task.wait(1.2)
end
task.spawn(function()
 while running do
  if enabled and not busy then
   busy=true
   local ok,err=pcall(doCycle)
   if not ok then stop('Error: '..tostring(err):sub(1,100)) end
   busy=false
  end
  task.wait(.25)
 end
end)
refresh()
