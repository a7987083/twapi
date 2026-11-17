local _,API=...
local ROWS=12
local frame=CreateFrame("Frame","RavenAPIExplorerFrame",UIParent,"BackdropTemplate")
frame:SetSize(850,540)
frame:SetPoint("CENTER")
frame:SetFrameStrata("DIALOG")
frame:SetClampedToScreen(true)
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart",frame.StartMoving)
frame:SetScript("OnDragStop",frame.StopMovingOrSizing)
frame:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=14,insets={left=3,right=3,top=3,bottom=3}})
frame:SetBackdropColor(0.035,0.05,0.08,0.96)
frame:Hide()
local function Text(parent,size,text,x,y,width)
  local fs=parent:CreateFontString(nil,"OVERLAY","GameFontNormal")
  fs:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
  fs:SetWidth(width)
  fs:SetJustifyH("LEFT")
  fs:SetText(text or "")
  return fs
end
local title=Text(frame,18,"RavenCraft API Explorer  |cff60cafa中文查询|r",16,-15,650)
local version=Text(frame,12,"",18,-43,650)
local close=CreateFrame("Button",nil,frame,"UIPanelCloseButton")
close:SetPoint("TOPRIGHT",frame,"TOPRIGHT",-3,-3)
local search=CreateFrame("EditBox",nil,frame,"InputBoxTemplate")
search:SetSize(332,28)
search:SetPoint("TOPLEFT",frame,"TOPLEFT",22,-79)
search:SetAutoFocus(false)
search:SetMaxLetters(120)
local hint=Text(frame,12,"输入英文名称或中文关键词",23,-112,345)
local listTitle=Text(frame,12,"已发现 API",20,-139,340)
local rows={}
local offset=0
local current=nil
local filtered={}
local detailTitle=Text(frame,17,"选择一个 API",383,-88,430)
local detailChinese=Text(frame,15,"",383,-121,440)
local detailCat=Text(frame,12,"",383,-153,440)
local detailExplain=Text(frame,13,"",383,-183,440)
detailExplain:SetHeight(65)
detailExplain:SetJustifyV("TOP")
local paramTitle=Text(frame,13,"参数（仅审核通过的只读 API 可执行）",383,-275,440)
local paramInput=CreateFrame("EditBox",nil,frame,"InputBoxTemplate")
paramInput:SetSize(405,26)
paramInput:SetPoint("TOPLEFT",frame,"TOPLEFT",391,-303)
paramInput:SetAutoFocus(false)
paramInput:SetMaxLetters(200)
local resultTitle=Text(frame,13,"结果 / 错误：",383,-370,440)
local result=Text(frame,12,"未执行",383,-393,435)
result:SetHeight(85)
result:SetJustifyV("TOP")
local run=CreateFrame("Button",nil,frame,"UIPanelButtonTemplate")
run:SetSize(94,26)
run:SetPoint("TOPLEFT",frame,"TOPLEFT",383,-338)
run:SetText("只读测试")
local refresh=CreateFrame("Button",nil,frame,"UIPanelButtonTemplate")
refresh:SetSize(102,24)
refresh:SetPoint("BOTTOMLEFT",frame,"BOTTOMLEFT",19,15)
refresh:SetText("重新扫描")
local export=CreateFrame("Button",nil,frame,"UIPanelButtonTemplate")
export:SetSize(118,24)
export:SetPoint("BOTTOMLEFT",frame,"BOTTOMLEFT",130,15)
export:SetText("保存导出快照")
local status=Text(frame,11,"",383,-493,440)
for i=1,ROWS do
  local btn=CreateFrame("Button",nil,frame)
  btn:SetSize(337,26)
  btn:SetPoint("TOPLEFT",frame,"TOPLEFT",18,-163-(i-1)*26)
  local bg=btn:CreateTexture(nil,"BACKGROUND")
  bg:SetAllPoints()
  bg:SetColorTexture(0.13,0.21,0.28,i%2==0 and 0.35 or 0.18)
  local label=btn:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
  label:SetPoint("LEFT",btn,"LEFT",5,0)
  label:SetWidth(325)
  label:SetJustifyH("LEFT")
  btn.label=label
  btn:SetScript("OnClick",function()
    current=btn.api
    if not current then return end
    local zh,cat,desc,verified=API.Describe(current)
    detailTitle:SetText(current)
    detailChinese:SetText(zh)
    detailCat:SetText("分类："..cat.."  |  "..(verified and "有人工说明" or "仅名称推测，待核实"))
    detailExplain:SetText(desc)
    local spec=API.SafeCalls[current]
    paramInput:SetText(spec and spec.sample or "")
    run:SetEnabled(spec~=nil)
    result:SetText(spec and "可进行手动只读测试" or "未审核的 API 禁止在测试台执行")
  end)
  rows[i]=btn
end
local function Redraw()
  listTitle:SetText("匹配结果："..#filtered.."  /  "..#(API.list or {}))
  for i=1,ROWS do
    local name=filtered[i+offset]
    local btn=rows[i]
    btn.api=name
    if name then
      local zh=API.Describe(name)
      btn.label:SetText(name)
      btn:Show()
      btn:SetScript("OnEnter",function(self)
        GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
        GameTooltip:AddLine(name,0.4,0.8,1)
        GameTooltip:AddLine(zh,1,1,1,true)
        GameTooltip:Show()
      end)
      btn:SetScript("OnLeave",function() GameTooltip:Hide() end)
    else btn:Hide() end
  end
end
local function Filter()
  filtered={}
  local term=search:GetText():lower()
  for _,name in ipairs(API.list or {}) do
    if term=="" or name:lower():find(term,1,true) then
      filtered[#filtered+1]=name
    elseif term~="" then
      local zh=API.Describe(name)
      if zh:lower():find(term,1,true) then filtered[#filtered+1]=name end
    end
  end
  offset=0
  Redraw()
end
search:SetScript("OnTextChanged",Filter)
frame:EnableMouseWheel(true)
frame:SetScript("OnMouseWheel",function(_,delta)
  offset=math.max(0,math.min(math.max(0,#filtered-ROWS),offset-delta*3))
  Redraw()
end)
run:SetScript("OnClick",function()
  if not current then return end
  local ok,answer=API.Run(current,paramInput:GetText())
  result:SetText((ok and "|cff70ff9a成功：|r" or "|cffff7777错误：|r")..answer)
end)
refresh:SetScript("OnClick",function()
  API.Scan()
  Filter()
  status:SetText("已重新扫描并更新版本信息")
end)
export:SetScript("OnClick",function()
  -- Snapshot is stored as a normal SavedVariable; written to disk on reload/logout.
  local db=API.DB
  local version,build=GetBuildInfo()
  db.export={version=version,build=build,count=#(API.list or {}),functions=API.list,created=date("%Y-%m-%d %H:%M:%S")}
  status:SetText("快照已加入 SavedVariables；请 /reload 或正常退出以落盘")
end)
SLASH_RAVENAPI1="/ravenapi"
SLASH_RAVENAPI2="/ra"
SlashCmdList.RAVENAPI=function()
  if frame:IsShown() then
    frame:Hide()
  else
    if not API.DB then API.Init() end
    local ver,build=GetBuildInfo()
    version:SetText("客户端 "..tostring(ver).."  Build "..tostring(build).."  |  API: "..#(API.list or {}))
    Filter()
    frame:Show()
  end
end

local loader=CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent",function()
  API.Init()
  local ver,build=GetBuildInfo()
  version:SetText("客户端 "..tostring(ver).."  Build "..tostring(build).."  |  API: "..#(API.list or {}))
  Filter()
end)
