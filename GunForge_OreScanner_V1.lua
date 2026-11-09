-- +1 Gun Forge | Ore Scanner V1
-- Read-only: no item selection, no forging, no remotes.
local Players = game:GetService("Players")
local plr = Players.LocalPlayer
local pg = plr:WaitForChild("PlayerGui")
local previous = pg:FindFirstChild("GF_OreScanner_V1")
if previous then previous:Destroy() end
local gui = Instance.new("ScreenGui")
gui.Name = "GF_OreScanner_V1"
gui.ResetOnSpawn = false
gui.Parent = pg
local root = Instance.new("Frame")
root.Size = UDim2.fromOffset(390, 395)
root.Position = UDim2.new(.5, -195, .5, -197)
root.BackgroundColor3 = Color3.fromRGB(15,23,36)
root.Active = true
root.Draggable = true
root.Parent = gui
Instance.new("UICorner",root).CornerRadius=UDim.new(0,12)
local function label(parent, txt, pos, sz, fontSize)
 local l=Instance.new("TextLabel")
 l.BackgroundTransparency=1; l.Text=txt; l.TextColor3=Color3.fromRGB(230,240,245)
 l.TextXAlignment=Enum.TextXAlignment.Left; l.TextYAlignment=Enum.TextYAlignment.Center
 l.Font=Enum.Font.Gotham; l.TextSize=fontSize or 13; l.Position=pos; l.Size=sz; l.Parent=parent
 return l
end
label(root,"GUN FORGE | SCAN SEMUA BIJIH",UDim2.fromOffset(14,6),UDim2.new(1,-95,0,38),16)
local function button(txt,pos,size)
 local b=Instance.new("TextButton")
 b.Text=txt; b.Size=size; b.Position=pos; b.BackgroundColor3=Color3.fromRGB(44,100,157)
 b.TextColor3=Color3.new(1,1,1); b.Font=Enum.Font.GothamBold; b.TextSize=13; b.Parent=root
 Instance.new("UICorner",b).CornerRadius=UDim.new(0,7)
 return b
end
local close=button("X",UDim2.new(1,-42,0,9),UDim2.fromOffset(32,30))
close.BackgroundColor3=Color3.fromRGB(150,65,65)
close.MouseButton1Click:Connect(function() gui:Destroy() end)
local scanButton=button("SCAN BIJIH",UDim2.fromOffset(12,51),UDim2.fromOffset(175,38))
local copyButton=button("COPY HASIL",UDim2.fromOffset(198,51),UDim2.fromOffset(180,38))
local status=label(root,"Buka Tempa > Senjata / Armor lalu tekan SCAN.",UDim2.fromOffset(13,92),UDim2.new(1,-25,0,43),12)
status.TextWrapped=true
local scroll=Instance.new("ScrollingFrame")
scroll.Position=UDim2.fromOffset(12,139); scroll.Size=UDim2.new(1,-24,1,-151)
scroll.BackgroundColor3=Color3.fromRGB(23,34,49); scroll.ScrollBarThickness=5
scroll.CanvasSize=UDim2.fromOffset(0,0); scroll.Parent=root
Instance.new("UICorner",scroll).CornerRadius=UDim.new(0,8)
local listing=Instance.new("TextLabel")
listing.Position=UDim2.fromOffset(8,6); listing.Size=UDim2.new(1,-20,0,200)
listing.BackgroundTransparency=1; listing.Text="Belum dipindai."
listing.TextColor3=Color3.fromRGB(226,239,246); listing.Font=Enum.Font.Code
listing.TextSize=12; listing.TextXAlignment=Enum.TextXAlignment.Left
listing.TextYAlignment=Enum.TextYAlignment.Top; listing.TextWrapped=false
listing.Parent=scroll
local resultText=""
local function visibleInHierarchy(obj)
 local p=obj
 while p and p~=pg do
  if p:IsA("GuiObject") and not p.Visible then return false end
  p=p.Parent
 end
 return true
end
local function getScreenRoot()
 local forge=pg:FindFirstChild("LimitedForgeUI")
 if forge and forge.Enabled ~= false then return forge end
 for _,name in ipairs({"ForgeUI","CraftUI"}) do
  local other=pg:FindFirstChild(name)
  if other and other.Enabled ~= false then return other end
 end
 return nil
end
local function gather()
 local forge=getScreenRoot()
 if not forge then
  status.Text="LimitedForgeUI tidak ditemukan. Buka menu Tempa lalu SCAN lagi."
  return
 end
 local entries={}
 local seen={}
 -- This deliberately records raw GUI candidates, not assumptions about ore names.
 for _,obj in ipairs(forge:GetDescendants()) do
  if obj:IsA("GuiButton") or obj:IsA("ImageLabel") then
   if visibleInHierarchy(obj) then
    local texts={}
    local image=obj:IsA("ImageButton") or obj:IsA("ImageLabel")
    if obj:IsA("TextButton") and obj.Text~="" then table.insert(texts,obj.Text) end
    -- Ore cards typically contain labels for item name and amount.
    for _,d in ipairs(obj:GetDescendants()) do
     if (d:IsA("TextLabel") or d:IsA("TextButton")) and d.Text~="" and visibleInHierarchy(d) then
      table.insert(texts,d.Text)
     end
    end
    if #texts>0 and (obj:IsA("GuiButton") or image) then
     local nameText=table.concat(texts," / ")
     local key=obj:GetFullName()
     if not seen[key] and #nameText < 300 then
      seen[key]=true
      table.insert(entries,{path=key, text=nameText, typ=obj.ClassName})
     end
    end
   end
  end
 end
 table.sort(entries,function(a,b) return a.path<b.path end)
 local lines={"=== GUN FORGE | RAW ORE GUI SCAN ===", "ForgeRoot: "..forge:GetFullName(), "Candidates: "..tostring(#entries), "NOTE: Ini kandidat kartu, belum tentu semuanya bijih.", ""}
 for i,e in ipairs(entries) do
  table.insert(lines,string.format("%02d | %s | %s",i,e.typ,e.text))
  table.insert(lines,"PATH: "..e.path)
 end
 resultText=table.concat(lines,"\n")
 listing.Text=resultText
 listing.Size=UDim2.new(1,-20,0,math.max(210,#lines*16))
 scroll.CanvasSize=UDim2.fromOffset(0,listing.Size.Y.Offset+15)
 status.Text="Scan selesai: "..#entries.." kandidat. Copy hasil lalu kirim ke chat."
 print(resultText)
end
scanButton.MouseButton1Click:Connect(function()
 local ok,err=pcall(gather)
 if not ok then status.Text="Gagal scan: "..tostring(err) end
end)
copyButton.MouseButton1Click:Connect(function()
 if resultText=="" then status.Text="Tekan SCAN BIJIH terlebih dahulu."; return end
 if typeof(setclipboard)=="function" then
  local ok=pcall(setclipboard,resultText)
  status.Text=ok and "Hasil disalin. Tempel ke file TXT dan kirim." or "Clipboard gagal. Cek Output console."
 else
  status.Text="Clipboard tidak tersedia. Salin dari panel / Output console."
 end
end)
