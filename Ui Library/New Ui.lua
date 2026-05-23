--// XGEN FRAMEWORK (Rebrand of Fluent GOD/Omega)

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")

local XGen = {}
XGen.__index = XGen

--////////////////////////////////////////////////////
-- UTIL
--////////////////////////////////////////////////////

local function Create(class, props)
    local obj = Instance.new(class)
    for i,v in pairs(props) do obj[i] = v end
    return obj
end

local function Tween(obj, t, props)
    TweenService:Create(obj, TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
end

--////////////////////////////////////////////////////
-- EVENT BUS
--////////////////////////////////////////////////////

XGen.Bus = {events = {}}

function XGen.Bus:Connect(name, fn)
    self.events[name] = self.events[name] or {}
    table.insert(self.events[name], fn)
end

function XGen.Bus:Fire(name, ...)
    if self.events[name] then
        for _,fn in ipairs(self.events[name]) do
            fn(...)
        end
    end
end

--////////////////////////////////////////////////////
-- STATE ENGINE
--////////////////////////////////////////////////////

XGen.State = {}
XGen.State.__index = XGen.State

function XGen.State.new()
    return setmetatable({data = {}}, XGen.State)
end

function XGen.State:set(k,v)
    self.data[k]=v
    XGen.Bus:Fire("stateChanged",k,v)
end

function XGen.State:get(k)
    return self.data[k]
end

XGen.GlobalState = XGen.State.new()

--////////////////////////////////////////////////////
-- THEME
--////////////////////////////////////////////////////

XGen.Theme = {
    Accent = Color3.fromRGB(0,170,255),
    Background = Color3.fromRGB(18,18,18),
    Element = Color3.fromRGB(30,30,30)
}

function XGen:SetTheme(t)
    for i,v in pairs(t) do
        XGen.Theme[i]=v
    end
end

--////////////////////////////////////////////////////
-- CONFIG SYSTEM
--////////////////////////////////////////////////////

XGen.Config = {}

function XGen.Config:Save()
    writefile("XGenConfig.json", HttpService:JSONEncode(XGen.GlobalState.data))
end

function XGen.Config:Load()
    if isfile("XGenConfig.json") then
        local data = HttpService:JSONDecode(readfile("XGenConfig.json"))
        for i,v in pairs(data) do
            XGen.GlobalState:set(i,v)
        end
    end
end

--////////////////////////////////////////////////////
-- NOTIFY
--////////////////////////////////////////////////////

local function Notify(text)

    local gui = Create("ScreenGui",{Parent=CoreGui})

    local frame = Create("Frame",{
        Parent=gui,
        Size=UDim2.fromOffset(240,40),
        Position=UDim2.new(1,-260,1,-90),
        BackgroundColor3=XGen.Theme.Background,
        BorderSizePixel=0
    })

    Create("UICorner",{Parent=frame,CornerRadius=UDim.new(0,6)})

    Create("TextLabel",{
        Parent=frame,
        Size=UDim2.new(1,0,1,0),
        BackgroundTransparency=1,
        Text=text,
        TextColor3=Color3.new(1,1,1),
        Font=Enum.Font.Gotham,
        TextSize=13
    })

    Tween(frame,0.2,{Position=UDim2.new(1,-260,1,-120)})

    task.delay(2,function()
        gui:Destroy()
    end)
end

--////////////////////////////////////////////////////
-- WINDOW ENGINE
--////////////////////////////////////////////////////

function XGen:Window(opt)

    local Window = {}

    local ScreenGui = Create("ScreenGui",{
        Parent=CoreGui,
        Name="XGenUI",
        ResetOnSpawn=false
    })

    local Main = Create("Frame",{
        Parent=ScreenGui,
        Size=UDim2.fromOffset(620,380),
        Position=UDim2.fromScale(0.5,0.5),
        AnchorPoint=Vector2.new(0.5,0.5),
        BackgroundColor3=XGen.Theme.Background,
        BorderSizePixel=0
    })

    Create("UICorner",{Parent=Main,CornerRadius=UDim.new(0,8)})

    -- TOPBAR
    local Topbar = Create("Frame",{
        Parent=Main,
        Size=UDim2.new(1,0,0,35),
        BackgroundColor3=Color3.fromRGB(25,25,25)
    })

    Create("TextLabel",{
        Parent=Topbar,
        Size=UDim2.new(1,0,1,0),
        BackgroundTransparency=1,
        Text=opt.Title or "XGen Framework",
        TextColor3=Color3.new(1,1,1),
        Font=Enum.Font.GothamBold,
        TextSize=14
    })

    -- SIDEBAR + CONTENT
    local Sidebar = Create("Frame",{
        Parent=Main,
        Position=UDim2.fromOffset(0,35),
        Size=UDim2.fromOffset(150,345),
        BackgroundColor3=Color3.fromRGB(22,22,22)
    })

    local Content = Create("Frame",{
        Parent=Main,
        Position=UDim2.fromOffset(155,40),
        Size=UDim2.fromOffset(460,330),
        BackgroundTransparency=1
    })

    -- DRAG
    do
        local drag,start,pos

        Topbar.InputBegan:Connect(function(i)
            if i.UserInputType==Enum.UserInputType.MouseButton1 then
                drag=true
                start=i.Position
                pos=Main.Position
            end
        end)

        UserInputService.InputEnded:Connect(function(i)
            if i.UserInputType==Enum.UserInputType.MouseButton1 then
                drag=false
            end
        end)

        UserInputService.InputChanged:Connect(function(i)
            if drag and i.UserInputType==Enum.UserInputType.MouseMovement then
                local d=i.Position-start
                Main.Position=UDim2.new(pos.X.Scale,pos.X.Offset+d.X,pos.Y.Scale,pos.Y.Offset+d.Y)
            end
        end)
    end

    --////////////////////////////////////////////////////
    -- TAB SYSTEM
    --////////////////////////////////////////////////////

    local Current

    function Window:Tab(name)

        local Tab = {}

        local TabBtn = Create("TextButton",{
            Parent=Sidebar,
            Size=UDim2.new(1,-10,0,30),
            BackgroundColor3=XGen.Theme.Element,
            Text=name,
            TextColor3=Color3.new(1,1,1)
        })

        Create("UICorner",{Parent=TabBtn,CornerRadius=UDim.new(0,6)})

        local Page = Create("ScrollingFrame",{
            Parent=Content,
            Size=UDim2.new(1,0,1,0),
            BackgroundTransparency=1,
            Visible=false
        })

        local Layout = Create("UIListLayout",{
            Parent=Page,
            Padding=UDim.new(0,6)
        })

        Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            Page.CanvasSize=UDim2.fromOffset(0,Layout.AbsoluteContentSize.Y+10)
        end)

        local function select()
            for _,v in pairs(Content:GetChildren()) do
                if v:IsA("ScrollingFrame") then v.Visible=false end
            end

            Page.Visible=true

            if Current then
                Tween(Current,0.15,{BackgroundColor3=XGen.Theme.Element})
            end

            Tween(TabBtn,0.15,{BackgroundColor3=XGen.Theme.Accent})
            Current=TabBtn

            XGen.Bus:Fire("tabChanged",name)
        end

        TabBtn.MouseButton1Click:Connect(function()
            select()
            Notify(name)
        end)

        if not Current then task.wait(); select() end

        --////////////////////////////////////////////////////
        -- ELEMENTS
        --////////////////////////////////////////////////////

        function Tab:Button(cfg)
            local b=Create("TextButton",{
                Parent=Page,
                Size=UDim2.new(1,-5,0,32),
                BackgroundColor3=XGen.Theme.Element,
                Text=cfg.Title,
                TextColor3=Color3.new(1,1,1)
            })

            Create("UICorner",{Parent=b,CornerRadius=UDim.new(0,6)})

            b.MouseButton1Click:Connect(function()
                Notify(cfg.Title)
                if cfg.Callback then cfg.Callback() end
            end)
        end

        function Tab:Toggle(cfg)

            XGen.GlobalState:set(cfg.Title,cfg.Default or false)

            local b=Create("TextButton",{
                Parent=Page,
                Size=UDim2.new(1,-5,0,32),
                BackgroundColor3=XGen.Theme.Element,
                Text=""
            })

            Create("UICorner",{Parent=b,CornerRadius=UDim.new(0,6)})

            local dot=Create("Frame",{
                Parent=b,
                Size=UDim2.fromOffset(10,10),
                Position=UDim2.new(1,-20,0.5,-5),
                BackgroundColor3=Color3.fromRGB(80,80,80)
            })

            Create("UICorner",{Parent=dot,CornerRadius=UDim.new(1,0)})

            local function update()
                Tween(dot,0.15,{
                    BackgroundColor3=XGen.GlobalState:get(cfg.Title)
                    and XGen.Theme.Accent
                    or Color3.fromRGB(80,80,80)
                })
            end

            update()

            b.MouseButton1Click:Connect(function()
                XGen.GlobalState:set(cfg.Title,not XGen.GlobalState:get(cfg.Title))
                update()
            end)
        end

        return Tab
    end

    return Window
end

return XGen
