-- ╔══════════════════════════════════════════════════════════════╗
-- ║  N E X U S  U I   ·   v1.0   ·   Amethyst Theme            ║
-- ║  github.com/YOUR_USERNAME/NexusUI                           ║
-- ║                                                             ║
-- ║  LOAD:                                                      ║
-- ║  local NexusUI = loadstring(game:HttpGet(RAW_URL))()        ║
-- ╚══════════════════════════════════════════════════════════════╝

local NexusUI = {}

local Players            = game:GetService("Players")
local TweenService       = game:GetService("TweenService")
local UserInputService   = game:GetService("UserInputService")
local HttpService        = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

------------------------------------------------------------------------
-- UTILITIES
------------------------------------------------------------------------

local function Clamp(v,mn,mx) return math.max(mn,math.min(mx,v)) end
local function Round(v,d) local f=10^(d or 0);return math.floor(v*f+0.5)/f end
local function Lighten(c,a) local h,s,v=Color3.toHSV(c);return Color3.fromHSV(h,math.max(0,s-a*0.3),math.min(1,v+a)) end
local function GetUIScale()
    local cam=workspace.CurrentCamera;if not cam then return 1 end
    local w=cam.ViewportSize.X
    if w<=480 then return 0.72 elseif w<=768 then return 0.86 elseif w<=1024 then return 0.94 end
    return 1
end

------------------------------------------------------------------------
-- THEMES
------------------------------------------------------------------------

local Themes = {
    Amethyst = {
        Background=Color3.fromRGB(12,9,20),     Surface=Color3.fromRGB(21,16,36),
        Surface2=Color3.fromRGB(30,23,50),       Surface3=Color3.fromRGB(40,31,66),
        SurfaceStroke=Color3.fromRGB(58,44,88),  Accent=Color3.fromRGB(138,85,214),
        AccentLight=Color3.fromRGB(172,122,247),  AccentDark=Color3.fromRGB(100,56,172),
        TextPrimary=Color3.fromRGB(238,232,255),  TextSecondary=Color3.fromRGB(158,144,190),
        TextMuted=Color3.fromRGB(92,80,118),      TextOnAccent=Color3.fromRGB(255,255,255),
        Success=Color3.fromRGB(72,199,116),       Warning=Color3.fromRGB(252,196,55),
        Error=Color3.fromRGB(230,74,74),          Fill=Color3.fromRGB(138,85,214),
        FillTrack=Color3.fromRGB(44,34,68),       ToggleOn=Color3.fromRGB(138,85,214),
        ToggleOff=Color3.fromRGB(44,34,68),       ToggleThumb=Color3.fromRGB(238,232,255),
        TabBar=Color3.fromRGB(16,12,28),          TabActive=Color3.fromRGB(30,22,52),
        TabIndicator=Color3.fromRGB(138,85,214),  PillBg=Color3.fromRGB(24,18,42),
        PillStroke=Color3.fromRGB(100,70,160),    NotifBg=Color3.fromRGB(26,20,44),
        NotifStroke=Color3.fromRGB(68,52,100),
    },
    Crimson = {
        Background=Color3.fromRGB(14,8,10),      Surface=Color3.fromRGB(24,14,17),
        Surface2=Color3.fromRGB(34,20,24),        Surface3=Color3.fromRGB(46,28,33),
        SurfaceStroke=Color3.fromRGB(80,40,48),   Accent=Color3.fromRGB(210,55,80),
        AccentLight=Color3.fromRGB(240,90,110),   AccentDark=Color3.fromRGB(160,30,55),
        TextPrimary=Color3.fromRGB(255,232,234),  TextSecondary=Color3.fromRGB(190,145,150),
        TextMuted=Color3.fromRGB(110,75,80),      TextOnAccent=Color3.fromRGB(255,255,255),
        Success=Color3.fromRGB(72,199,116),       Warning=Color3.fromRGB(252,196,55),
        Error=Color3.fromRGB(230,74,74),          Fill=Color3.fromRGB(210,55,80),
        FillTrack=Color3.fromRGB(60,24,30),       ToggleOn=Color3.fromRGB(210,55,80),
        ToggleOff=Color3.fromRGB(60,24,30),       ToggleThumb=Color3.fromRGB(255,232,234),
        TabBar=Color3.fromRGB(18,10,13),          TabActive=Color3.fromRGB(38,20,25),
        TabIndicator=Color3.fromRGB(210,55,80),   PillBg=Color3.fromRGB(28,14,18),
        PillStroke=Color3.fromRGB(160,60,80),     NotifBg=Color3.fromRGB(30,16,20),
        NotifStroke=Color3.fromRGB(80,40,50),
    },
    Ocean = {
        Background=Color3.fromRGB(8,14,22),       Surface=Color3.fromRGB(12,22,36),
        Surface2=Color3.fromRGB(18,32,52),         Surface3=Color3.fromRGB(26,44,70),
        SurfaceStroke=Color3.fromRGB(38,64,96),   Accent=Color3.fromRGB(56,189,248),
        AccentLight=Color3.fromRGB(125,211,252),  AccentDark=Color3.fromRGB(14,165,233),
        TextPrimary=Color3.fromRGB(224,242,254),  TextSecondary=Color3.fromRGB(147,197,253),
        TextMuted=Color3.fromRGB(71,120,178),     TextOnAccent=Color3.fromRGB(8,14,22),
        Success=Color3.fromRGB(72,199,116),       Warning=Color3.fromRGB(252,196,55),
        Error=Color3.fromRGB(230,74,74),          Fill=Color3.fromRGB(56,189,248),
        FillTrack=Color3.fromRGB(18,40,68),       ToggleOn=Color3.fromRGB(56,189,248),
        ToggleOff=Color3.fromRGB(18,40,68),       ToggleThumb=Color3.fromRGB(224,242,254),
        TabBar=Color3.fromRGB(10,18,30),          TabActive=Color3.fromRGB(18,32,52),
        TabIndicator=Color3.fromRGB(56,189,248),  PillBg=Color3.fromRGB(10,18,30),
        PillStroke=Color3.fromRGB(38,90,148),     NotifBg=Color3.fromRGB(10,20,34),
        NotifStroke=Color3.fromRGB(38,64,96),
    },
}

local Active   = Themes.Amethyst
local Registry = {}   -- [instance] = {prop=token}
local ThemeCBs = {}

local function T(token) return Active[token] or Color3.new(1,0,1) end

local function ThemeApply(inst,tags)
    Registry[inst]=tags
    for p,tok in pairs(tags) do local c=Active[tok];if c then (inst::any)[p]=c end end
end

local function SetTheme(name)
    local pal=Themes[name];if not pal then warn("[NexusUI] Unknown theme: "..tostring(name));return end
    Active=pal
    for inst,tags in pairs(Registry) do
        if inst and inst.Parent then for p,tok in pairs(tags) do local c=pal[tok];if c then (inst::any)[p]=c end end
        else Registry[inst]=nil end
    end
    for _,cb in ipairs(ThemeCBs) do task.spawn(cb,name) end
end

NexusUI.Flags = {}

------------------------------------------------------------------------
-- INSTANCE FACTORY
------------------------------------------------------------------------

local DEFS = {
    Frame={BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=0,BorderSizePixel=0},
    ScrollingFrame={BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=0,BorderSizePixel=0,ScrollBarThickness=3,CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollingDirection=Enum.ScrollingDirection.Y},
    TextLabel={BackgroundTransparency=1,BorderSizePixel=0,TextColor3=Color3.new(1,1,1),Font=Enum.Font.GothamMedium,TextSize=13,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center,RichText=true},
    TextButton={BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=0,BorderSizePixel=0,AutoButtonColor=false,TextColor3=Color3.new(1,1,1),Font=Enum.Font.GothamMedium,TextSize=13,Text="",RichText=true},
    TextBox={BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=0,BorderSizePixel=0,TextColor3=Color3.new(1,1,1),Font=Enum.Font.GothamMedium,TextSize=13,TextXAlignment=Enum.TextXAlignment.Left,ClearTextOnFocus=false},
    ImageLabel={BackgroundTransparency=1,BorderSizePixel=0,ScaleType=Enum.ScaleType.Fit},
    UIListLayout={SortOrder=Enum.SortOrder.LayoutOrder,FillDirection=Enum.FillDirection.Vertical},
    UIStroke={ApplyStrokeMode=Enum.ApplyStrokeMode.Border},
}

local function New(cls,props,kids)
    props=props or{};kids=kids or{}
    local i=Instance.new(cls)
    local d=DEFS[cls];if d then for k,v in pairs(d)do (i::any)[k]=v end end
    local tags=props.ThemeTags;local par=props.Parent;local nm=props.Name
    for k,v in pairs(props)do if k~="ThemeTags"and k~="Parent"and k~="Name"then (i::any)[k]=v end end
    for _,c in ipairs(kids)do if c then c.Parent=i end end
    if tags then ThemeApply(i,tags) end
    if nm  then i.Name=nm end
    if par then i.Parent=par end
    return i
end

local function Corner(r)    return New("UICorner",{CornerRadius=UDim.new(0,r)}) end
local function Pad(a,t,r,b,l) a=a or 0;return New("UIPadding",{PaddingTop=UDim.new(0,t or a),PaddingRight=UDim.new(0,r or a),PaddingBottom=UDim.new(0,b or a),PaddingLeft=UDim.new(0,l or a)}) end
local function List(gap)    return New("UIListLayout",{Padding=UDim.new(0,gap or 0),SortOrder=Enum.SortOrder.LayoutOrder,HorizontalAlignment=Enum.HorizontalAlignment.Left,VerticalAlignment=Enum.VerticalAlignment.Top}) end

------------------------------------------------------------------------
-- TWEEN HELPERS
------------------------------------------------------------------------

local I = {
    Snappy   =TweenInfo.new(0.14,Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
    Standard =TweenInfo.new(0.22,Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
    Back     =TweenInfo.new(0.28,Enum.EasingStyle.Back,  Enum.EasingDirection.Out),
    Notif    =TweenInfo.new(0.30,Enum.EasingStyle.Back,  Enum.EasingDirection.Out),
}

local function Tw(inst,info,g) if inst and inst.Parent then TweenService:Create(inst,info,g):Play() end end
local function TwSnap(inst,g)  Tw(inst,I.Snappy,g) end

------------------------------------------------------------------------
-- NOTIFICATIONS
------------------------------------------------------------------------

local notifActive={}
local notifQueue={}
local notifGui

local SEV={Info="Accent",Success="Success",Warning="Warning",Error="Error"}
local NW,NH,NP,NR,NT = 280,60,8,18,18

local function ensureNotifGui()
    if notifGui and notifGui.Parent then return notifGui end
    local old=PlayerGui:FindFirstChild("NexusUI_Notifs");if old then old:Destroy() end
    local sg=Instance.new("ScreenGui")
    sg.Name="NexusUI_Notifs";sg.ResetOnSpawn=false;sg.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
    sg.DisplayOrder=999;sg.IgnoreGuiInset=false;sg.Parent=PlayerGui
    notifGui=sg;return sg
end

local function spawnNotif(opts)
    local sg=ensureNotifGui()
    local sev=opts.Severity or"Info";local dur=opts.Duration or 4
    local yOff=NT
    for _ in pairs(notifActive)do yOff=yOff+NH+NP end

    local card=New("Frame",{Size=UDim2.fromOffset(NW,NH),AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,NW+30,0,yOff),ZIndex=100,Parent=sg,ThemeTags={BackgroundColor3="NotifBg"}},{Corner(8),New("UIStroke",{Thickness=1,ThemeTags={Color="NotifStroke"}})})
    New("Frame",{Size=UDim2.new(0,3,1,-10),Position=UDim2.fromOffset(6,5),BackgroundColor3=T(SEV[sev]or"Accent"),ZIndex=101,Parent=card},{Corner(2)})
    New("ImageLabel",{Size=UDim2.fromOffset(20,20),Position=UDim2.fromOffset(18,10),Image=opts.Icon or"rbxassetid://3926305904",ImageColor3=T(SEV[sev]or"Accent"),ZIndex=101,Parent=card})
    New("TextLabel",{Size=UDim2.new(1,-52,0,18),Position=UDim2.fromOffset(46,8),Text=opts.Title or"",TextSize=13,Font=Enum.Font.GothamBold,TextTruncate=Enum.TextTruncate.AtEnd,ZIndex=101,ThemeTags={TextColor3="TextPrimary"},Parent=card})
    if opts.Body and opts.Body~=""then New("TextLabel",{Size=UDim2.new(1,-52,0,16),Position=UDim2.fromOffset(46,28),Text=opts.Body,TextSize=11,Font=Enum.Font.Gotham,TextTruncate=Enum.TextTruncate.AtEnd,TextColor3=T("TextSecondary"),ZIndex=101,Parent=card})end
    local pbg=New("Frame",{Size=UDim2.new(1,-16,0,2),Position=UDim2.new(0,8,1,-5),BackgroundColor3=T("FillTrack"),ZIndex=101,Parent=card},{Corner(1)})
    local pf=New("Frame",{Size=UDim2.new(1,0,1,0),BackgroundColor3=T(SEV[sev]or"Accent"),ZIndex=102,Parent=pbg},{Corner(1)})

    Tw(card,I.Notif,{Position=UDim2.new(1,-NR,0,yOff)})
    TweenService:Create(pf,TweenInfo.new(dur,Enum.EasingStyle.Linear),{Size=UDim2.new(0,0,1,0)}):Play()

    local id=tostring(card);notifActive[id]={card=card,y=yOff}
    local gone=false
    local function dismiss()
        if gone then return end;gone=true;notifActive[id]=nil
        local i2=0;for _,e in pairs(notifActive)do Tw(e.card,TweenInfo.new(0.20,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{Position=UDim2.new(1,-NR,0,NT+i2*(NH+NP))});i2+=1 end
        local ex=TweenService:Create(card,TweenInfo.new(0.22,Enum.EasingStyle.Quint,Enum.EasingDirection.In),{Position=UDim2.new(1,NW+30,0,yOff)});ex:Play()
        ex.Completed:Connect(function()card:Destroy();if #notifQueue>0 then task.spawn(spawnNotif,table.remove(notifQueue,1))end end)
    end
    local hit=Instance.new("TextButton");hit.Size=UDim2.new(1,0,1,0);hit.BackgroundTransparency=1;hit.Text="";hit.ZIndex=103;hit.Parent=card;hit.MouseButton1Click:Connect(dismiss)
    task.delay(dur,dismiss)
end

local function Notify(opts)
    assert(opts and opts.Title,"[NexusUI] Notify: Title required")
    local n=0;for _ in pairs(notifActive)do n+=1 end
    if n>=5 then table.insert(notifQueue,opts) else task.spawn(spawnNotif,opts) end
end

------------------------------------------------------------------------
-- CONFIG
------------------------------------------------------------------------

local Config={}
local FOLDER="NexusUI_Config"

local function cfgFolder()
    local f=PlayerGui:FindFirstChild(FOLDER)
    if not f then f=Instance.new("Folder");f.Name=FOLDER;f.Parent=PlayerGui end
    return f
end
local function cfgSlot(name)
    local f=cfgFolder();local s=f:FindFirstChild(name)
    if not s then s=Instance.new("StringValue");s.Name=name;s.Parent=f end
    return s
end

function Config.Save(slot)
    slot=slot or"default";local safe={}
    for k,v in pairs(NexusUI.Flags)do local t=type(v);if t=="boolean"or t=="number"or t=="string"then safe[k]=v end end
    local ok,json=pcall(HttpService.JSONEncode,HttpService,safe)
    if ok then cfgSlot(slot).Value=json;return true end;return false
end
function Config.Load(slot)
    slot=slot or"default";local f=cfgFolder();local s=f:FindFirstChild(slot);if not s then return false end
    local ok,data=pcall(HttpService.JSONDecode,HttpService,(s::StringValue).Value)
    if not ok or type(data)~="table" then return false end
    for k,v in pairs(data)do if NexusUI.Flags[k]~=nil then NexusUI.Flags[k]=v end end
    return true
end
function Config.Reset() table.clear(NexusUI.Flags) end
function Config.AutoLoad(slot) local f=cfgFolder();if f:FindFirstChild(slot or"default")then return Config.Load(slot)end;return false end

NexusUI.Config=Config

------------------------------------------------------------------------
-- COMPONENTS
------------------------------------------------------------------------

-- Button
local function MakeButton(parent,opts)
    NexusUI.Flags[opts.Name]=false
    local row=New("Frame",{Size=UDim2.new(1,0,0,38),BackgroundTransparency=1,LayoutOrder=1,Parent=parent})
    local btn=New("TextButton",{Size=UDim2.new(1,-4,1,0),Position=UDim2.fromOffset(2,0),Text="",AutoButtonColor=false,ThemeTags={BackgroundColor3="Surface2"},Parent=row},{Corner(7),New("UIStroke",{Thickness=1,ThemeTags={Color="SurfaceStroke"}})})
    local off=12
    if opts.Icon then off=38;New("ImageLabel",{Size=UDim2.fromOffset(18,18),Position=UDim2.fromOffset(12,10),Image=opts.Icon,ImageColor3=T("Accent"),Parent=btn})end
    New("TextLabel",{Size=UDim2.new(1,-off-8,1,0),Position=UDim2.fromOffset(off,0),Text=opts.Text or"",TextSize=13,Font=Enum.Font.GothamMedium,TextXAlignment=Enum.TextXAlignment.Left,ThemeTags={TextColor3="TextPrimary"},Parent=btn})
    local nc,hc=T("Surface2"),T("Surface3")
    btn.MouseEnter:Connect(function() TwSnap(btn,{BackgroundColor3=hc}) end)
    btn.MouseLeave:Connect(function() TwSnap(btn,{BackgroundColor3=nc}) end)
    btn.MouseButton1Down:Connect(function() TwSnap(btn,{BackgroundColor3=T("AccentDark")}) end)
    btn.MouseButton1Up:Connect(function()   TwSnap(btn,{BackgroundColor3=hc}) end)
    btn.MouseButton1Click:Connect(function()
        NexusUI.Flags[opts.Name]=true
        if opts.Callback then task.spawn(opts.Callback) end
        task.delay(0.1,function()NexusUI.Flags[opts.Name]=false end)
    end)
    btn.TouchTap:Connect(function()
        TwSnap(btn,{BackgroundColor3=T("AccentDark")});task.delay(0.12,function()TwSnap(btn,{BackgroundColor3=nc})end)
        if opts.Callback then task.spawn(opts.Callback) end
    end)
    local api={}
    function api:SetText(t) btn:FindFirstChildWhichIsA("TextLabel").Text=t end
    function api:Destroy()  row:Destroy() end
    return api
end

-- Toggle
local TW,TH,TS,TP=40,22,16,3
local function MakeToggle(parent,opts)
    local val=opts.Default or false;NexusUI.Flags[opts.Name]=val
    local row=New("Frame",{Size=UDim2.new(1,0,0,40),BackgroundTransparency=1,LayoutOrder=1,Parent=parent})
    local off=12
    if opts.Icon then off=38;New("ImageLabel",{Size=UDim2.fromOffset(18,18),Position=UDim2.fromOffset(10,11),Image=opts.Icon,ImageColor3=T("TextSecondary"),Parent=row})end
    New("TextLabel",{Size=UDim2.new(1,-(off+TW+16),1,0),Position=UDim2.fromOffset(off,0),Text=opts.Label or"",TextSize=13,Font=Enum.Font.GothamMedium,TextXAlignment=Enum.TextXAlignment.Left,ThemeTags={TextColor3="TextPrimary"},Parent=row})
    local track=New("Frame",{Size=UDim2.fromOffset(TW,TH),AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-10,0.5,0),BackgroundColor3=T(val and"ToggleOn"or"ToggleOff"),Parent=row},{Corner(11)})
    local thumb=New("Frame",{Size=UDim2.fromOffset(TS,TS),Position=UDim2.fromOffset(val and(TW-TS-TP)or TP,TP),ThemeTags={BackgroundColor3="ToggleThumb"},Parent=track},{Corner(8)})
    local function applyVal(on)
        Tw(track,TweenInfo.new(0.20,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{BackgroundColor3=T(on and"ToggleOn"or"ToggleOff")})
        Tw(thumb,TweenInfo.new(0.18,Enum.EasingStyle.Back, Enum.EasingDirection.Out),{Position=UDim2.fromOffset(on and(TW-TS-TP)or TP,TP)})
    end
    local hit=New("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",ZIndex=2,Parent=row})
    local function toggle()
        val=not val;NexusUI.Flags[opts.Name]=val;applyVal(val)
        if opts.Callback then task.spawn(opts.Callback,val) end
    end
    hit.MouseButton1Click:Connect(toggle);hit.TouchTap:Connect(toggle)
    local api={}
    function api:SetValue(v) val=v;NexusUI.Flags[opts.Name]=v;applyVal(v);if opts.Callback then task.spawn(opts.Callback,v)end end
    function api:GetValue()  return val end
    function api:Destroy()   row:Destroy() end
    return api
end

-- Slider
local function MakeSlider(parent,opts)
    local mn=opts.Min or 0;local mx=opts.Max or 100;local stp=opts.Step or 1
    local sfx=opts.Suffix or"";local val=Clamp(opts.Default or mn,mn,mx);local drag=false
    NexusUI.Flags[opts.Name]=val
    local row=New("Frame",{Size=UDim2.new(1,0,0,58),BackgroundTransparency=1,LayoutOrder=1,Parent=parent})
    local off=12
    if opts.Icon then off=38;New("ImageLabel",{Size=UDim2.fromOffset(18,18),Position=UDim2.fromOffset(10,6),Image=opts.Icon,ImageColor3=T("TextSecondary"),Parent=row})end
    New("TextLabel",{Size=UDim2.new(0.7,-off,0,22),Position=UDim2.fromOffset(off,4),Text=opts.Label or"",TextSize=13,Font=Enum.Font.GothamMedium,TextXAlignment=Enum.TextXAlignment.Left,ThemeTags={TextColor3="TextPrimary"},Parent=row})
    local vl=New("TextLabel",{Size=UDim2.new(0.3,-10,0,22),AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-10,0,4),Text=tostring(val)..sfx,TextSize=12,Font=Enum.Font.GothamMedium,TextXAlignment=Enum.TextXAlignment.Right,ThemeTags={TextColor3="Accent"},Parent=row})
    local tbg=New("Frame",{Size=UDim2.new(1,-24,0,6),Position=UDim2.fromOffset(12,36),ThemeTags={BackgroundColor3="FillTrack"},Parent=row},{Corner(3)})
    local fill=New("Frame",{Size=UDim2.new(0,0,1,0),ThemeTags={BackgroundColor3="Fill"},Parent=tbg},{Corner(3)})
    local thumb=New("Frame",{Size=UDim2.fromOffset(16,16),AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromOffset(0,3),ZIndex=3,ThemeTags={BackgroundColor3="ToggleThumb"},Parent=tbg},{Corner(8),New("UIStroke",{Thickness=2,ThemeTags={Color="Accent"}})})
    local function updVis(v) local p=(v-mn)/(mx-mn);fill.Size=UDim2.new(p,0,1,0);thumb.Position=UDim2.new(p,0,0.5,0);vl.Text=tostring(Round(v,2))..sfx end
    updVis(val)
    local function fromX(x) local ap=tbg.AbsolutePosition;local as=tbg.AbsoluteSize;local r=Clamp((x-ap.X)/as.X,0,1);return Clamp(math.round((mn+r*(mx-mn))/stp)*stp,mn,mx) end
    local hit=New("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",ZIndex=5,Parent=row})
    hit.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then drag=true;val=fromX(i.Position.X);updVis(val);NexusUI.Flags[opts.Name]=val;if opts.Callback then task.spawn(opts.Callback,val)end end end)
    UserInputService.InputChanged:Connect(function(i) if not drag then return end;if i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch then local nv=fromX(i.Position.X);if nv~=val then val=nv;updVis(val);NexusUI.Flags[opts.Name]=val;if opts.Callback then task.spawn(opts.Callback,val)end end end end)
    UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then drag=false end end)
    local api={}
    function api:SetValue(v) val=Clamp(v,mn,mx);updVis(val);NexusUI.Flags[opts.Name]=val;if opts.Callback then task.spawn(opts.Callback,val)end end
    function api:GetValue()  return val end
    function api:Destroy()   row:Destroy() end
    return api
end

-- Dropdown
local function MakeDropdown(parent,opts)
    local options=opts.Options or{};local val=opts.Default or(options[1]or"");local open=false
    NexusUI.Flags[opts.Name]=val
    local ROWH=36;local MAXV=4;local CH=38
    local wrap=New("Frame",{Size=UDim2.new(1,0,0,CH+24),BackgroundTransparency=1,ClipsDescendants=false,LayoutOrder=1,Parent=parent})
    local off=12
    if opts.Icon then off=38;New("ImageLabel",{Size=UDim2.fromOffset(18,18),Position=UDim2.fromOffset(10,3),Image=opts.Icon,ImageColor3=T("TextSecondary"),Parent=wrap})end
    New("TextLabel",{Size=UDim2.new(1,-off-8,0,20),Position=UDim2.fromOffset(off,0),Text=opts.Label or"",TextSize=12,Font=Enum.Font.GothamMedium,TextXAlignment=Enum.TextXAlignment.Left,ThemeTags={TextColor3="TextSecondary"},Parent=wrap})
    local hdr=New("TextButton",{Size=UDim2.new(1,-4,0,CH),Position=UDim2.fromOffset(2,22),Text="",AutoButtonColor=false,ThemeTags={BackgroundColor3="Surface2"},Parent=wrap},{Corner(7),New("UIStroke",{Thickness=1,ThemeTags={Color="SurfaceStroke"}})})
    local sel=New("TextLabel",{Size=UDim2.new(1,-40,1,0),Position=UDim2.fromOffset(10,0),Text=val,TextSize=13,Font=Enum.Font.GothamMedium,TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd,ThemeTags={TextColor3="TextPrimary"},Parent=hdr})
    local arr=New("TextLabel",{Size=UDim2.fromOffset(20,20),AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-8,0.5,0),Text="▾",TextSize=14,Font=Enum.Font.GothamBold,BackgroundTransparency=1,TextXAlignment=Enum.TextXAlignment.Center,ThemeTags={TextColor3="TextSecondary"},Parent=hdr})
    local listH=math.min(#options,MAXV)*ROWH
    local list=New("ScrollingFrame",{Size=UDim2.new(1,-4,0,0),Position=UDim2.fromOffset(2,22+CH+2),ClipsDescendants=true,ZIndex=20,ScrollBarThickness=3,ThemeTags={BackgroundColor3="Surface2"},Parent=wrap},{Corner(7),List(0)})
    local function closeDD() open=false;TweenService:Create(list,I.Standard,{Size=UDim2.new(1,-4,0,0)}):Play();TweenService:Create(arr,I.Snappy,{Rotation=0}):Play();TweenService:Create(wrap,I.Standard,{Size=UDim2.new(1,0,0,CH+24)}):Play() end
    for _,opt in ipairs(options)do
        local r=New("TextButton",{Size=UDim2.new(1,0,0,ROWH),Text="",AutoButtonColor=false,BackgroundTransparency=1,ZIndex=21,Parent=list})
        New("TextLabel",{Size=UDim2.new(1,-20,1,0),Position=UDim2.fromOffset(10,0),Text=opt,TextSize=13,Font=Enum.Font.GothamMedium,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=22,ThemeTags={TextColor3="TextPrimary"},Parent=r})
        if opt~=options[#options]then New("Frame",{Size=UDim2.new(1,-20,0,1),Position=UDim2.new(0,10,1,-1),ZIndex=22,ThemeTags={BackgroundColor3="SurfaceStroke"},Parent=r})end
        r.MouseEnter:Connect(function() TwSnap(r,{BackgroundColor3=T("Surface3"),BackgroundTransparency=0}) end)
        r.MouseLeave:Connect(function() TwSnap(r,{BackgroundTransparency=1}) end)
        r.MouseButton1Click:Connect(function() val=opt;sel.Text=opt;NexusUI.Flags[opts.Name]=opt;if opts.Callback then task.spawn(opts.Callback,opt)end;closeDD() end)
    end
    hdr.MouseButton1Click:Connect(function()
        open=not open
        TweenService:Create(list,I.Standard,{Size=UDim2.new(1,-4,0,open and listH or 0)}):Play()
        TweenService:Create(arr,I.Snappy,{Rotation=open and 180 or 0}):Play()
        TweenService:Create(wrap,I.Standard,{Size=UDim2.new(1,0,0,CH+24+(open and listH+4 or 0))}):Play()
    end)
    local api={}
    function api:Select(v) val=v;sel.Text=v;NexusUI.Flags[opts.Name]=v end
    function api:GetValue() return val end
    function api:Destroy()  wrap:Destroy() end
    return api
end

-- Paragraph
local function MakeParagraph(parent,opts)
    local c=New("Frame",{Size=UDim2.new(1,0,0,10),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,LayoutOrder=1,Parent=parent},{List(4),Pad(nil,4,10,4,12)})
    if opts.Title and opts.Title~=""then New("TextLabel",{Size=UDim2.new(1,0,0,18),AutomaticSize=Enum.AutomaticSize.Y,Text=opts.Title,TextSize=13,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,ThemeTags={TextColor3="TextPrimary"},Parent=c})end
    New("TextLabel",{Size=UDim2.new(1,0,0,14),AutomaticSize=Enum.AutomaticSize.Y,Text=opts.Content or"",TextSize=12,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,LineHeight=1.4,ThemeTags={TextColor3="TextSecondary"},Parent=c})
    local api={}
    function api:Destroy() c:Destroy() end
    return api
end

-- Label
local function MakeLabel(parent,opts)
    local row=New("Frame",{Size=UDim2.new(1,0,0,32),BackgroundTransparency=1,LayoutOrder=1,Parent=parent})
    local off=12
    if opts.Icon then off=36;New("ImageLabel",{Size=UDim2.fromOffset(16,16),Position=UDim2.fromOffset(10,8),Image=opts.Icon,ImageColor3=T("TextMuted"),Parent=row})end
    New("TextLabel",{Size=UDim2.new(0.6,-off,1,0),Position=UDim2.fromOffset(off,0),Text=opts.Text or"",TextSize=12,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,ThemeTags={TextColor3=opts.Muted and"TextMuted"or"TextSecondary"},Parent=row})
    local vl;if opts.Value then vl=New("TextLabel",{Size=UDim2.new(0.4,-10,1,0),AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-10,0,0),Text=opts.Value,TextSize=12,Font=Enum.Font.GothamMedium,TextXAlignment=Enum.TextXAlignment.Right,ThemeTags={TextColor3="Accent"},Parent=row})end
    local api={}
    function api:SetValue(v) if vl then vl.Text=v end end
    function api:Destroy()   row:Destroy() end
    return api
end

-- Divider
local function MakeDivider(parent,opts)
    opts=opts or{}
    local c=New("Frame",{Size=UDim2.new(1,0,0,28),BackgroundTransparency=1,LayoutOrder=1,Parent=parent})
    New("Frame",{Size=UDim2.new(1,-20,0,1),AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.new(0.5,0,0.5,0),ZIndex=1,ThemeTags={BackgroundColor3="SurfaceStroke"},Parent=c})
    if opts.Label and opts.Label~=""then New("TextLabel",{Size=UDim2.new(0,0,0,14),AutomaticSize=Enum.AutomaticSize.X,AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.new(0.5,0,0.5,0),Text="  "..opts.Label.."  ",TextSize=11,Font=Enum.Font.GothamMedium,TextXAlignment=Enum.TextXAlignment.Center,ZIndex=2,ThemeTags={TextColor3="TextMuted",BackgroundColor3="Background"},BackgroundTransparency=0,Parent=c})end
    local api={}
    function api:Destroy() c:Destroy() end
    return api
end

-- Keybind
local function MakeKeybind(parent,opts)
    local bk=opts.Default or Enum.KeyCode.Unknown;local listening=false
    NexusUI.Flags[opts.Name]=bk
    local conns={}
    local function kName(k) if k==Enum.KeyCode.Unknown then return"None"end;return tostring(k):gsub("Enum%.KeyCode%.","")end
    local row=New("Frame",{Size=UDim2.new(1,0,0,40),BackgroundTransparency=1,LayoutOrder=1,Parent=parent})
    New("TextLabel",{Size=UDim2.new(0.6,-12,1,0),Position=UDim2.fromOffset(12,0),Text=opts.Label or"",TextSize=13,Font=Enum.Font.GothamMedium,TextXAlignment=Enum.TextXAlignment.Left,ThemeTags={TextColor3="TextPrimary"},Parent=row})
    local kb=New("TextButton",{Size=UDim2.fromOffset(80,26),AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-10,0.5,0),Text=kName(bk),TextSize=12,Font=Enum.Font.GothamMedium,AutoButtonColor=false,ThemeTags={BackgroundColor3="Surface3",TextColor3="TextPrimary"},Parent=row},{Corner(5),New("UIStroke",{Thickness=1,ThemeTags={Color="SurfaceStroke"}})})
    kb.MouseButton1Click:Connect(function() listening=true;kb.Text="...";TwSnap(kb,{BackgroundColor3=T("Accent")}) end)
    table.insert(conns,UserInputService.InputBegan:Connect(function(i)
        if not listening then return end
        if i.UserInputType~=Enum.UserInputType.Keyboard then return end
        listening=false
        if i.KeyCode~=Enum.KeyCode.Escape then bk=i.KeyCode;NexusUI.Flags[opts.Name]=bk;if opts.Callback then task.spawn(opts.Callback,bk)end end
        kb.Text=kName(bk);TwSnap(kb,{BackgroundColor3=T("Surface3")})
    end))
    local api={}
    function api:GetValue() return bk end
    function api:Destroy()  for _,c in ipairs(conns)do if c.Connected then c:Disconnect()end end;row:Destroy() end
    return api
end

-- Input
local function MakeInput(parent,opts)
    local val=opts.Default or"";NexusUI.Flags[opts.Name]=val;local conns={}
    local c=New("Frame",{Size=UDim2.new(1,0,0,60),BackgroundTransparency=1,LayoutOrder=1,Parent=parent})
    local off=12
    if opts.Icon then off=36;New("ImageLabel",{Size=UDim2.fromOffset(16,16),Position=UDim2.fromOffset(10,2),Image=opts.Icon,ImageColor3=T("TextSecondary"),Parent=c})end
    New("TextLabel",{Size=UDim2.new(1,-off-8,0,20),Position=UDim2.fromOffset(off,0),Text=opts.Label or"",TextSize=12,Font=Enum.Font.GothamMedium,TextXAlignment=Enum.TextXAlignment.Left,ThemeTags={TextColor3="TextSecondary"},Parent=c})
    local bf=New("Frame",{Size=UDim2.new(1,-4,0,34),Position=UDim2.fromOffset(2,22),ThemeTags={BackgroundColor3="Surface2"},Parent=c},{Corner(7)})
    local stroke=New("UIStroke",{Thickness=1,ThemeTags={Color="SurfaceStroke"},Parent=bf})
    local tb=New("TextBox",{Size=UDim2.new(1,-16,1,0),Position=UDim2.fromOffset(8,0),Text=val,PlaceholderText=opts.Placeholder or"",PlaceholderColor3=T("TextMuted"),TextSize=13,Font=Enum.Font.GothamMedium,TextXAlignment=Enum.TextXAlignment.Left,ClearTextOnFocus=false,ThemeTags={TextColor3="TextPrimary"},Parent=bf}) :: TextBox
    table.insert(conns,tb.Focused:Connect(function() TwSnap(stroke,{Color=T("Accent"),Thickness=1.5}) end))
    table.insert(conns,tb.FocusLost:Connect(function(enter)
        TwSnap(stroke,{Color=T("SurfaceStroke"),Thickness=1})
        local text=tb.Text;if opts.Numeric then local n=tonumber(text);text=n and tostring(n)or val;tb.Text=text end
        val=text;NexusUI.Flags[opts.Name]=text;if opts.Callback and enter then task.spawn(opts.Callback,text)end
    end))
    table.insert(conns,tb:GetPropertyChangedSignal("Text"):Connect(function()
        val=tb.Text;NexusUI.Flags[opts.Name]=tb.Text;if opts.Callback then task.spawn(opts.Callback,tb.Text)end
    end))
    local api={}
    function api:SetValue(v) val=v;tb.Text=v;NexusUI.Flags[opts.Name]=v end
    function api:GetValue()  return val end
    function api:Destroy()   for _,cn in ipairs(conns)do if cn.Connected then cn:Disconnect()end end;c:Destroy() end
    return api
end

------------------------------------------------------------------------
-- WINDOW
------------------------------------------------------------------------

local WIN_W=560;local WIN_H=380;local TITLE_H=44;local SIDEBAR_W=130
local TAB_H=38;local PILL_W=180;local PILL_H=36

function NexusUI:CreateWindow(opts)
    opts=opts or{}
    SetTheme(opts.Theme or"Amethyst")

    local old=PlayerGui:FindFirstChild("NexusUI_Window");if old then old:Destroy() end

    local sg=Instance.new("ScreenGui")
    sg.Name="NexusUI_Window";sg.ResetOnSpawn=false;sg.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
    sg.DisplayOrder=100;sg.IgnoreGuiInset=false;sg.Parent=PlayerGui
    local uisc=Instance.new("UIScale");uisc.Scale=GetUIScale();uisc.Parent=sg

    -- Shadow
    local shadow=New("Frame",{Size=UDim2.fromOffset(WIN_W+20,WIN_H+20),Position=UDim2.new(0.5,-(WIN_W+20)/2,0.5,-(WIN_H+20)/2),BackgroundColor3=Color3.fromRGB(0,0,0),BackgroundTransparency=0.72,ZIndex=1,Parent=sg},{Corner(14)})

    -- Main frame
    local win=New("Frame",{Size=UDim2.fromOffset(WIN_W,WIN_H),Position=UDim2.new(0.5,-WIN_W/2,0.5,-WIN_H/2),ZIndex=2,ClipsDescendants=true,ThemeTags={BackgroundColor3="Background"},Parent=sg},{Corner(10),New("UIStroke",{Thickness=1,ThemeTags={Color="SurfaceStroke"}})})

    -- Accent strip
    New("Frame",{Size=UDim2.new(1,0,0,3),ZIndex=5,ThemeTags={BackgroundColor3="Accent"},Parent=win})

    -- Titlebar
    local tb=New("Frame",{Size=UDim2.new(1,0,0,TITLE_H),Position=UDim2.fromOffset(0,3),ZIndex=3,ThemeTags={BackgroundColor3="Surface"},Parent=win},{New("Frame",{Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,1,-1),ZIndex=4,ThemeTags={BackgroundColor3="SurfaceStroke"}})})
    New("Frame",{Size=UDim2.fromOffset(8,8),Position=UDim2.fromOffset(14,18),ZIndex=5,ThemeTags={BackgroundColor3="Accent"},Parent=tb},{Corner(4)})
    New("TextLabel",{Size=UDim2.new(1,-100,1,0),Position=UDim2.fromOffset(28,0),Text=opts.Title or"NexusUI",TextSize=14,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=5,ThemeTags={TextColor3="TextPrimary"},Parent=tb})
    local minBtn=New("TextButton",{Size=UDim2.fromOffset(28,28),AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-42,0.5,0),Text="—",TextSize=14,Font=Enum.Font.GothamBold,AutoButtonColor=false,ZIndex=6,ThemeTags={BackgroundColor3="Surface2",TextColor3="TextSecondary"},Parent=tb},{Corner(6)})
    local closeBtn=New("TextButton",{Size=UDim2.fromOffset(28,28),AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-10,0.5,0),Text="✕",TextSize=12,Font=Enum.Font.GothamBold,AutoButtonColor=false,ZIndex=6,BackgroundColor3=Color3.fromRGB(180,50,55),ThemeTags={TextColor3="TextOnAccent"},Parent=tb},{Corner(6)})
    minBtn.MouseEnter:Connect(function()   TwSnap(minBtn,  {BackgroundColor3=T("Surface3")}) end)
    minBtn.MouseLeave:Connect(function()   TwSnap(minBtn,  {BackgroundColor3=T("Surface2")}) end)
    closeBtn.MouseEnter:Connect(function() TwSnap(closeBtn,{BackgroundColor3=Color3.fromRGB(220,70,75)}) end)
    closeBtn.MouseLeave:Connect(function() TwSnap(closeBtn,{BackgroundColor3=Color3.fromRGB(180,50,55)}) end)

    -- Sidebar
    local sidebar=New("Frame",{Size=UDim2.new(0,SIDEBAR_W,1,-(TITLE_H+3)),Position=UDim2.fromOffset(0,TITLE_H+3),ZIndex=3,ClipsDescendants=true,ThemeTags={BackgroundColor3="TabBar"},Parent=win},{New("Frame",{Size=UDim2.new(0,1,1,0),Position=UDim2.new(1,-1,0,0),ZIndex=4,ThemeTags={BackgroundColor3="SurfaceStroke"}})})
    local tabScroll=New("ScrollingFrame",{Size=UDim2.new(1,-1,1,-6),Position=UDim2.fromOffset(0,6),ScrollBarThickness=0,CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,ZIndex=4,BackgroundTransparency=1,Parent=sidebar},{List(2),Pad(nil,4,0,4,0)})

    -- Content
    local content=New("Frame",{Size=UDim2.new(1,-SIDEBAR_W,1,-(TITLE_H+3)),Position=UDim2.new(0,SIDEBAR_W,0,TITLE_H+3),ZIndex=3,ClipsDescendants=true,BackgroundTransparency=1,Parent=win})

    -- Pill
    local pill=New("Frame",{Size=UDim2.fromOffset(PILL_W,PILL_H),Position=UDim2.new(0.5,-PILL_W/2,0,20),Visible=false,ZIndex=10,ThemeTags={BackgroundColor3="PillBg"},Parent=sg},{Corner(18),New("UIStroke",{Thickness=1.5,ThemeTags={Color="PillStroke"}})})
    New("Frame",{Size=UDim2.fromOffset(6,6),Position=UDim2.fromOffset(10,15),ZIndex=11,ThemeTags={BackgroundColor3="Accent"},Parent=pill},{Corner(3)})
    New("TextLabel",{Size=UDim2.new(1,-60,1,0),Position=UDim2.fromOffset(22,0),Text=opts.Title or"NexusUI",TextSize=12,Font=Enum.Font.GothamMedium,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=11,ThemeTags={TextColor3="TextPrimary"},Parent=pill})
    local pillBtn=New("TextButton",{Size=UDim2.fromOffset(30,24),AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-4,0.5,0),Text="↑",TextSize=14,Font=Enum.Font.GothamBold,AutoButtonColor=false,ZIndex=12,ThemeTags={BackgroundColor3="Surface2",TextColor3="Accent"},Parent=pill},{Corner(6)})

    -- Drag
    local function makeDrag(handle,target)
        local drag,ds,sp=false,Vector2.new(),UDim2.new()
        handle.InputBegan:Connect(function(i)
            if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then drag=true;ds=i.Position;sp=target.Position end
        end)
        UserInputService.InputChanged:Connect(function(i)
            if not drag then return end
            if i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch then
                local d=i.Position-ds;target.Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y)
                if target==win then shadow.Position=UDim2.new(target.Position.X.Scale,target.Position.X.Offset-10,target.Position.Y.Scale,target.Position.Y.Offset-10)end
            end
        end)
        UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then drag=false end end)
    end
    makeDrag(tb,win);makeDrag(pill,pill)

    -- Minimize / Restore
    local minimized=false
    local function doMin()
        if minimized then return end;minimized=true
        local wp=win.AbsolutePosition;pill.Position=UDim2.fromOffset(wp.X,wp.Y+WIN_H-PILL_H-10)
        TweenService:Create(win,  TweenInfo.new(0.22,Enum.EasingStyle.Quint,Enum.EasingDirection.InOut),{Size=UDim2.fromOffset(WIN_W,0)}):Play()
        TweenService:Create(win,  TweenInfo.new(0.18),{BackgroundTransparency=1}):Play()
        TweenService:Create(shadow,TweenInfo.new(0.18),{BackgroundTransparency=1}):Play()
        task.delay(0.22,function()win.Visible=false;shadow.Visible=false end)
        pill.Size=UDim2.fromOffset(0,PILL_H);pill.Visible=true
        TweenService:Create(pill,TweenInfo.new(0.25,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=UDim2.fromOffset(PILL_W,PILL_H)}):Play()
    end
    local function doRes()
        if not minimized then return end;minimized=false
        TweenService:Create(pill,TweenInfo.new(0.18,Enum.EasingStyle.Quint,Enum.EasingDirection.In),{Size=UDim2.fromOffset(0,PILL_H)}):Play()
        task.delay(0.18,function()pill.Visible=false end)
        win.Visible=true;win.BackgroundTransparency=1;shadow.Visible=true;shadow.BackgroundTransparency=1
        TweenService:Create(win,  TweenInfo.new(0.28,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=UDim2.fromOffset(WIN_W,WIN_H),BackgroundTransparency=0}):Play()
        TweenService:Create(shadow,TweenInfo.new(0.28,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{BackgroundTransparency=0.72}):Play()
    end
    minBtn.MouseButton1Click:Connect(doMin)
    pillBtn.MouseButton1Click:Connect(doRes)
    pill.InputBegan:Connect(function(i)if i.UserInputType==Enum.UserInputType.Touch then doRes()end end)
    closeBtn.MouseButton1Click:Connect(function()
        TweenService:Create(win,  TweenInfo.new(0.20,Enum.EasingStyle.Quint,Enum.EasingDirection.In),{Size=UDim2.fromOffset(WIN_W,0),BackgroundTransparency=1}):Play()
        TweenService:Create(shadow,TweenInfo.new(0.20),{BackgroundTransparency=1}):Play()
        task.delay(0.22,function()sg:Destroy()end)
    end)

    -- Open animation
    win.Size=UDim2.fromOffset(WIN_W,0);win.BackgroundTransparency=1;shadow.BackgroundTransparency=1
    task.defer(function()
        TweenService:Create(win,  TweenInfo.new(0.30,Enum.EasingStyle.Back, Enum.EasingDirection.Out),{Size=UDim2.fromOffset(WIN_W,WIN_H),BackgroundTransparency=0}):Play()
        TweenService:Create(shadow,TweenInfo.new(0.30,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{BackgroundTransparency=0.72}):Play()
    end)

    -- Tab system
    local tabs={};local activeKey=nil

    local function switchTab(key)
        if activeKey==key then return end;activeKey=key
        for _,e in ipairs(tabs)do
            local on=e.key==key
            TweenService:Create(e.btn,TweenInfo.new(0.16,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{BackgroundColor3=T(on and"TabActive"or"TabBar"),BackgroundTransparency=on and 0 or 1}):Play()
            e.label.TextColor3=T(on and"TextPrimary"or"TextSecondary")
            TweenService:Create(e.ind,TweenInfo.new(0.18,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{BackgroundTransparency=on and 0 or 1,Size=UDim2.fromOffset(3,on and 20 or 0)}):Play()
            e.frame.Visible=on
        end
    end

    local function addTab(key,icon)
        local btn=New("TextButton",{Size=UDim2.new(1,-8,0,TAB_H),AutoButtonColor=false,Text="",ZIndex=5,BackgroundColor3=T("TabBar"),BackgroundTransparency=1,Parent=tabScroll},{Corner(6)})
        local ind=New("Frame",{Size=UDim2.fromOffset(3,0),Position=UDim2.fromOffset(0,TAB_H/2),AnchorPoint=Vector2.new(0,0.5),ZIndex=6,ThemeTags={BackgroundColor3="TabIndicator"},BackgroundTransparency=1,Parent=btn},{Corner(2)})
        local ioff=14
        if icon then ioff=36;New("ImageLabel",{Size=UDim2.fromOffset(16,16),Position=UDim2.fromOffset(14,(TAB_H-16)/2),Image=icon,ImageColor3=T("TextSecondary"),ZIndex=6,Parent=btn})end
        local lbl=New("TextLabel",{Size=UDim2.new(1,-(ioff+4),1,0),Position=UDim2.fromOffset(ioff,0),Text=key,TextSize=12,Font=Enum.Font.GothamMedium,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=6,ThemeTags={TextColor3="TextSecondary"},Parent=btn})
        local cf=New("ScrollingFrame",{Size=UDim2.new(1,-12,1,-8),Position=UDim2.fromOffset(6,4),ZIndex=3,Visible=false,ScrollBarThickness=3,CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,ThemeTags={BackgroundColor3="Background",ScrollBarImageColor3="Accent"},Parent=content},{List(4),Pad(nil,4,4,8,4)})
        local entry={key=key,btn=btn,label=lbl,ind=ind,frame=cf}
        table.insert(tabs,entry)
        btn.MouseButton1Click:Connect(function()switchTab(key)end)
        btn.MouseEnter:Connect(function()if activeKey~=key then TweenService:Create(btn,TweenInfo.new(0.14),{BackgroundColor3=T("Surface2"),BackgroundTransparency=0}):Play()end end)
        btn.MouseLeave:Connect(function()if activeKey~=key then TweenService:Create(btn,TweenInfo.new(0.14),{BackgroundTransparency=1}):Play()end end)
        return cf
    end

    local function wrapTab(cf)
        local api={}
        function api:AddButton(o)    return MakeButton(cf,o)    end
        function api:AddToggle(o)    return MakeToggle(cf,o)    end
        function api:AddSlider(o)    return MakeSlider(cf,o)    end
        function api:AddDropdown(o)  return MakeDropdown(cf,o)  end
        function api:AddParagraph(o) return MakeParagraph(cf,o) end
        function api:AddLabel(o)     return MakeLabel(cf,o)     end
        function api:AddDivider(o)   return MakeDivider(cf,o)   end
        function api:AddKeybind(o)   return MakeKeybind(cf,o)   end
        function api:AddInput(o)     return MakeInput(cf,o)     end
        return api
    end

    -- Window API
    local W={}
    function W:CreateTab(o)
        local cf=addTab(o.Name,o.Icon)
        if #tabs==1 then switchTab(o.Name) end
        return wrapTab(cf)
    end
    function W:SelectTab(name)  switchTab(name) end
    function W:SetTheme(name)   SetTheme(name) end
    function W:Notify(o)        Notify(o) end
    function W:GetConfig()      return Config end
    function W:Destroy()
        Registry={}
        if sg and sg.Parent then sg:Destroy() end
    end
    return W
end

------------------------------------------------------------------------
-- TOP-LEVEL API
------------------------------------------------------------------------

function NexusUI:Notify(o)   Notify(o) end
function NexusUI:SetTheme(n) SetTheme(n) end
function NexusUI:GetTheme()
    for k,v in pairs(Themes)do if v==Active then return k end end
end
function NexusUI:GetThemeNames()
    local n={};for k in pairs(Themes)do table.insert(n,k)end;return n
end
function NexusUI:GetFlag(k)  return NexusUI.Flags[k] end
function NexusUI:AddTheme(name,palette) Themes[name]=palette end

return NexusUI
