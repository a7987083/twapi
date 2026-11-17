local addonName, NS = ...
NS = NS or {}
_G.RavenAPIExplorer = NS
local API = NS

-- Names are discovered from the actual client; never assume a different build's APIs.
local verbs = {
  Get="获取", Is="判断", Has="检查是否具有", Can="检查能否", Set="设置",
  Unit="单位", Spell="技能", Item="物品", Map="地图", Player="玩家",
  Position="位置", World="世界", Health="生命值", Power="资源值",
  Name="名称", Level="等级", Info="信息", Cooldown="冷却",
  Distance="距离", Range="范围", Target="目标", Time="时间",
  Current="当前", Count="数量", Num="数量", GUID="GUID",
  Quest="任务", Aura="光环", Buff="增益", Debuff="减益",
  Chat="聊天", Guild="公会", Action="动作", Frame="框架",
  Texture="纹理", Sound="音效", Create="创建", Remove="移除",
  Delete="删除", Send="发送", Register="注册", Unregister="取消注册",
  Update="更新", Show="显示", Hide="隐藏", Toggle="切换",
  Start="开始", Stop="停止", Enable="启用", Disable="禁用",
  Add="添加", Find="查找", Search="搜索", List="列表",
  Best="最佳", For="针对", From="从", To="到", By="按",
  All="全部", ID="ID", Type="类型", Index="索引"
}
local known = {
 UnitHealth={"获取单位当前生命值","单位","读取指定 unit token 的当前生命值。"},
 UnitHealthMax={"获取单位最大生命值","单位","返回指定单位的生命值上限。"},
 UnitName={"获取单位名称","单位","查询指定单位的名称。"},
 UnitGUID={"获取单位 GUID","单位","查询指定单位标识。"},
 UnitPosition={"获取单位世界坐标","单位","部分单位 token 不提供坐标；实际结果可能为 nil。"},
 UnitDistanceSquared={"获取单位距离平方","单位","使用单个 unit token；仅对支持的单位类型有意义。"},
 CheckInteractDistance={"检查交互距离条件","距离","返回指定交互距离档位是否满足；不同档位用途不同。"},
 GetSpellInfo={"获取技能资料","技能","返回技能名称、图标、施法时间、射程等资料。"},
 GetSpellCooldown={"获取技能冷却","技能","返回技能当前冷却信息。"},
 GetItemInfo={"获取物品资料","物品","物品未缓存时可能返回 nil。"},
 ["C_Map.GetBestMapForUnit"]={"获取单位对应地图 ID","地图","获取指定单位当前最佳地图 ID。"},
 ["C_Map.GetPlayerMapPosition"]={"获取单位地图位置","地图","获得地图上的归一化坐标，不是世界坐标。"},
 ["C_ChatInfo.SendAddonMessage"]={"发送插件消息","通信","有副作用；测试台禁止执行。"},
 ClosestUnitPosition={"最近单位的位置接口","位置","名称可枚举，参数及具体语义未验证。"},
 ClosestGameObjectPosition={"最近游戏对象的位置接口","位置","名称可枚举，参数及具体语义未验证。"}
}
local categoryRules = {
 {"^C_Map%.","地图"},{"^C_Item%.","物品"},{"^C_ChatInfo%.","通信"},
 {"^Unit","单位"},{"^GetSpell","技能"},{"^IsSpell","技能"},
 {"^GetItem","物品"},{"^GetQuest","任务"},{"^C_Quest","任务"},
 {"^CreateFrame","界面"},{"^C_Timer","计时"}
}
local function Tokenize(text)
  -- Chinese hints are generated only; not documented API semantics.
  text = text:gsub("([a-z])([A-Z])","%1 %2"):gsub("([A-Z])([A-Z][a-z])","%1 %2")
  local parts={}
  for p in text:gmatch("[%w]+") do parts[#parts+1]=verbs[p] or p end
  return table.concat(parts," ")
end
function API.Describe(name)
  local found=known[name]
  if found then return found[1],found[2],found[3],true end
  local section=name:match("^([%w_]+)%.")
  local category="其他"
  for _,rule in ipairs(categoryRules) do if name:find(rule[1]) then category=rule[2];break end end
  -- A translated keyword is a search hint, not a verified explanation.
  local hint=Tokenize((name:match("[^.]+$") or name):gsub("_"," "))
  return hint.."（待核实）",category,"此名称来自运行时函数枚举；签名、行为和权限未验证。",false
end
local allowed={
 UnitHealth={args={"unit"},sample="target"},
 UnitHealthMax={args={"unit"},sample="target"},
 UnitName={args={"unit"},sample="target"},
 UnitLevel={args={"unit"},sample="target"},
 UnitGUID={args={"unit"},sample="target"},
 UnitCreatureType={args={"unit"},sample="target"},
 UnitExists={args={"unit"},sample="target"},
 UnitPosition={args={"unit"},sample="player"},
 UnitInRange={args={"unit"},sample="target"},
 UnitDistanceSquared={args={"unit"},sample="target"},
 GetSpellInfo={args={"number"},sample="116"},
 GetSpellCooldown={args={"number"},sample="116"},
 GetItemInfo={args={"number"},sample="6948"},
 ["C_Map.GetBestMapForUnit"]={args={"unit"},sample="player"}
}
API.SafeCalls=allowed
local function Resolve(name)
  local current=_G
  for part in name:gmatch("[^.]+") do
    if type(current)~="table" then return nil end
    current=rawget(current,part)
  end
  return type(current)=="function" and current or nil
end
local function ReadArgs(info,input)
  local result={}
  for piece in (input..","):gmatch("(.-),") do
    local val=piece:match("^%s*(.-)%s*$")
    if #val>100 then return nil,"参数过长" end
    result[#result+1]=val
  end
  if #result~=#info.args then return nil,"参数个数不匹配（需要 "..#info.args.." 个）" end
  for i,kind in ipairs(info.args) do
    if kind=="number" then
      result[i]=tonumber(result[i])
      if not result[i] then return nil,"参数必须是数字" end
    elseif kind=="unit" then
      if not result[i]:match("^[%a][%w]*$") then return nil,"无效的 Unit Token" end
    end
  end
  return result
end
local function Render(value)
  if value==nil then return "nil" end
  local kind=type(value)
  if kind=="string" then return string.format("%q",value:sub(1,180)) end
  if kind=="number" or kind=="boolean" then return tostring(value) end
  return "<"..kind..">"
end
function API.Run(name,input)
  local spec=allowed[name]
  if not spec then return false,"未列入人工审核的只读调用白名单" end
  local fn=Resolve(name)
  if not fn then return false,"函数当前不存在" end
  local args,err=ReadArgs(spec,input)
  if not args then return false,err end
  local result={pcall(fn,unpack(args))}
  local ok=table.remove(result,1)
  local pieces={}
  for i=1,#result do pieces[#pieces+1]=Render(result[i]) end
  -- Capture fixed common nil-result cases too; Lua table length may truncate trailing nils.
  local output=ok and (#pieces>0 and table.concat(pieces,", ") or "(无返回值或 nil)") or tostring(result[1])
  API.DB.history=API.DB.history or {}
  table.insert(API.DB.history,1,{name=name,args=input,ok=ok,result=output,time=date("%Y-%m-%d %H:%M:%S")})
  while #API.DB.history>100 do table.remove(API.DB.history) end
  return ok,output
end
function API.Scan()
  local seen, list = {}, {}
  local function Add(name)
    if not seen[name] then seen[name]=true; list[#list+1]=name end
  end
  for key,value in pairs(_G) do
    if type(key)=="string" then
      if type(value)=="function" then Add(key)
      elseif type(value)=="table" and key:match("^C_") then
        for sub,fn in pairs(value) do
          if type(sub)=="string" and type(fn)=="function" then Add(key.."."..sub) end
        end
      end
    end
  end
  table.sort(list)
  API.list=list
  local version,build=GetBuildInfo()
  API.DB.lastScan={version=version,build=build,count=#list}
  return #list
end
function API.Init()
  RavenAPIExplorerDB=type(RavenAPIExplorerDB)=="table" and RavenAPIExplorerDB or {}
  API.DB=RavenAPIExplorerDB
  API.DB.history=API.DB.history or {}
  API.Scan()
end
