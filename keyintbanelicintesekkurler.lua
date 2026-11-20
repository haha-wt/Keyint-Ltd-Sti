if getgenv().WTHub_Unload then pcall(getgenv().WTHub_Unload) end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")


local LP = Players.LocalPlayer
local conns = {}
local unloaded = false


local Fluent, SaveManager, InterfaceManager = (function()
	local TS = game:GetService("TweenService")
	local UIS = game:GetService("UserInputService")
	local HS = game:GetService("HttpService")
	local CG = game:GetService("CoreGui")
	local F = { Options = {}, Unloaded = false }
	local conns, binds, listening = {}, {}, nil
	local gui, modal, main, toasts, menuOpen, pageTitle, status
	local tabsByIndex, tabN = {}, 0
	local T = {
		bg = Color3.fromRGB(10, 12, 15), side = Color3.fromRGB(13, 16, 20), panel = Color3.fromRGB(17, 21, 27),
		hover = Color3.fromRGB(23, 29, 37), line = Color3.fromRGB(33, 41, 52), off = Color3.fromRGB(48, 57, 70),
		accent = Color3.fromRGB(61, 255, 143), accent2 = Color3.fromRGB(46, 214, 255), accentDim = Color3.fromRGB(13, 52, 34),
		text = Color3.fromRGB(201, 209, 217), mut = Color3.fromRGB(110, 118, 129),
		red = Color3.fromRGB(255, 95, 86), yel = Color3.fromRGB(255, 189, 46), grn = Color3.fromRGB(39, 201, 63),
	}
	local FONT = Enum.Font.Code
	local function tr(c) conns[#conns + 1] = c return c end
	local function new(cl, pr, par)
		local i = Instance.new(cl)
		for k, v in pairs(pr) do i[k] = v end
		i.Parent = par
		return i
	end
	local function tw(o, t, p) TS:Create(o, TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), p):Play() end
	local function corner(p, r) new("UICorner", { CornerRadius = UDim.new(0, r or 4) }, p) end
	local function stroke(p, col, th) return new("UIStroke", { Color = col, Thickness = th or 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, p) end
	local function lbl(par, txt, sz, pos, col, al, ts, rich)
		return new("TextLabel", { Size = sz, Position = pos, BackgroundTransparency = 1, Text = txt, TextColor3 = col or T.text, Font = FONT,
			TextSize = ts or 13, TextXAlignment = al or Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, RichText = rich or false }, par)
	end
	local function isPtr(i, mv)
		local t = i.UserInputType
		return t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch or (mv and t == Enum.UserInputType.MouseMovement)
	end


	local function makeObj(id, cfg, value)
		local o = { Value = value, _cb = {}, _cfg = cfg, _id = id }
		function o:OnChanged(fn) self._cb[#self._cb + 1] = fn end
		function o:_fire()
			if self._cfg.Callback then pcall(self._cfg.Callback, self.Value) end
			for _, fn in ipairs(self._cb) do pcall(fn, self.Value) end
		end
		F.Options[id] = o
		return o
	end


	function F:Notify(cfg)
		if not toasts then return end
		local f = new("Frame", { Size = UDim2.fromOffset(330, 44), BackgroundColor3 = T.side, BackgroundTransparency = 1, BorderSizePixel = 0 }, toasts)
		corner(f, 4)
		local s = new("UIStroke", { Color = T.accent, Thickness = 1, Transparency = 1 }, f)
		local a = lbl(f, tostring(cfg.Title or ""), UDim2.new(1, -16, 0, 20), UDim2.fromOffset(10, 3), T.accent, nil, 12)
		local b = lbl(f, tostring(cfg.Content or ""), UDim2.new(1, -16, 0, 18), UDim2.fromOffset(10, 22), T.text, nil, 12)
		a.TextTransparency, b.TextTransparency = 1, 1
		tw(f, 0.15, { BackgroundTransparency = 0.05 }) tw(s, 0.15, { Transparency = 0.5 }) tw(a, 0.15, { TextTransparency = 0 }) tw(b, 0.15, { TextTransparency = 0 })
		task.delay(cfg.Duration or 3, function()
			if f.Parent then
				tw(f, 0.2, { BackgroundTransparency = 1 }) tw(s, 0.2, { Transparency = 1 }) tw(a, 0.2, { TextTransparency = 1 }) tw(b, 0.2, { TextTransparency = 1 })
				task.wait(0.25)
				f:Destroy()
			end
		end)
	end


	local TabM = {}
	TabM.__index = TabM
	local function row(tab, h)
		tab.n += 1
		local r = new("Frame", { Size = UDim2.new(1, 0, 0, h), BackgroundColor3 = T.panel, BorderSizePixel = 0, LayoutOrder = tab.n, ClipsDescendants = true }, tab.Page)
		corner(r, 4)
		return r, stroke(r, T.line, 1)
	end
	local function hov(r, st, b)
		tr(b.MouseEnter:Connect(function() tw(r, 0.1, { BackgroundColor3 = T.hover }) tw(st, 0.1, { Color = T.accentDim }) end))
		tr(b.MouseLeave:Connect(function() tw(r, 0.1, { BackgroundColor3 = T.panel }) tw(st, 0.1, { Color = T.line }) end))
	end
	local function head(r, cfg, w)
		local d = cfg.Description
		lbl(r, tostring(cfg.Title or ""), UDim2.new(1, -w, 0, d and 22 or 36), UDim2.fromOffset(12, d and 5 or 0), T.text, nil, 13)
		if d then lbl(r, tostring(d), UDim2.new(1, -w, 0, 16), UDim2.fromOffset(12, 26), T.mut, nil, 11) end
	end

	function TabM:AddSection(text)
		self.n += 1
		local l = lbl(self.Page, '<font color="#3dff8f">//</font> ' .. string.lower(tostring(text)), UDim2.new(1, 0, 0, 20), UDim2.new(), T.mut, nil, 12, true)
		l.LayoutOrder = self.n
	end
	function TabM:AddParagraph(cfg)
		local r = row(self, 52)
		lbl(r, tostring(cfg.Title or ""), UDim2.new(1, -24, 0, 20), UDim2.fromOffset(12, 4), T.text, nil, 13)
		local c = lbl(r, tostring(cfg.Content or ""), UDim2.new(1, -24, 0, 26), UDim2.fromOffset(12, 24), T.mut, nil, 11)
		c.TextWrapped, c.TextTruncate, c.TextYAlignment = true, Enum.TextTruncate.None, Enum.TextYAlignment.Top
	end
	function TabM:AddButton(cfg)
		local r, st = row(self, cfg.Description and 48 or 36)
		lbl(r, '<font color="#3dff8f">$</font> ' .. tostring(cfg.Title or ""), UDim2.new(1, -40, 0, cfg.Description and 22 or 36), UDim2.fromOffset(12, cfg.Description and 5 or 0), T.text, nil, 13, true)
		if cfg.Description then lbl(r, tostring(cfg.Description), UDim2.new(1, -40, 0, 16), UDim2.fromOffset(26, 26), T.mut, nil, 11) end
		local b = new("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "" }, r)
		hov(r, st, b)
		tr(b.MouseButton1Click:Connect(function() if cfg.Callback then task.spawn(cfg.Callback) end end))
		return r
	end
	function TabM:AddToggle(id, cfg)
		local r, st = row(self, cfg.Description and 48 or 36)
		head(r, cfg, 80)
		local o = makeObj(id, cfg, cfg.Default == true)
		local tag = new("TextLabel", { Size = UDim2.fromOffset(40, 20), Position = UDim2.new(1, -52, 0.5, -10), BackgroundColor3 = T.bg, Text = "OFF", TextColor3 = T.mut, Font = FONT, TextSize = 12, BorderSizePixel = 0 }, r)
		corner(tag, 3)
		local tst = stroke(tag, T.line, 1)
		local function rd(anim)
			local on = o.Value
			tag.Text = on and "ON" or "OFF"
			local p1 = { BackgroundColor3 = on and T.accentDim or T.bg, TextColor3 = on and T.accent or T.mut }
			if anim then tw(tag, 0.12, p1) tw(tst, 0.12, { Color = on and T.accent or T.line })
			else tag.BackgroundColor3, tag.TextColor3, tst.Color = p1.BackgroundColor3, p1.TextColor3, (on and T.accent or T.line) end
		end
		rd(false)
		function o:SetValue(v) v = v == true if v == self.Value then return end self.Value = v rd(true) self:_fire() end
		local b = new("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "" }, r)
		hov(r, st, b)
		tr(b.MouseButton1Click:Connect(function() o:SetValue(not o.Value) end))
		return o
	end
	function TabM:AddSlider(id, cfg)
		local r, rst = row(self, 52)
		lbl(r, tostring(cfg.Title or ""), UDim2.new(1, -150, 0, 22), UDim2.fromOffset(12, 5), T.text, nil, 13)
		local mn, mx, rnd = cfg.Min or 0, cfg.Max or 100, cfg.Rounding or 0
		local o = makeObj(id, cfg, math.clamp(cfg.Default or mn, mn, mx))
		local v = lbl(r, "", UDim2.fromOffset(130, 22), UDim2.new(1, -142, 0, 5), T.accent, Enum.TextXAlignment.Right, 12)
		local bar = new("TextButton", { Size = UDim2.new(1, -24, 0, 4), Position = UDim2.fromOffset(12, 36), BackgroundColor3 = T.off, Text = "", AutoButtonColor = false, BorderSizePixel = 0 }, r)
		local f = new("Frame", { BackgroundColor3 = T.accent, BorderSizePixel = 0 }, bar)
		new("UIGradient", { Color = ColorSequence.new(T.accent, T.accent2) }, f)
		local k = new("Frame", { Size = UDim2.fromOffset(8, 12), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = T.text, BorderSizePixel = 0 }, bar)
		corner(k, 2)
		local function rd()
			local a = (o.Value - mn) / (mx - mn)
			f.Size, k.Position = UDim2.new(a, 0, 1, 0), UDim2.new(a, 0, 0.5, 0)
			v.Text = "[ " .. (rnd > 0 and ("%." .. rnd .. "f"):format(o.Value) or ("%d"):format(o.Value)) .. " ]"
		end
		rd()
		function o:SetValue(x)
			x = tonumber(x) if not x then return end
			local m = 10 ^ rnd
			x = math.clamp(math.floor(x * m + 0.5) / m, mn, mx)
			if x == self.Value then return end
			self.Value = x rd() self:_fire()
		end
		local function setPx(px) o:SetValue(mn + math.clamp((px - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1) * (mx - mn)) end
		local d
		tr(bar.InputBegan:Connect(function(i) if isPtr(i) then d = true setPx(i.Position.X) end end))
		tr(UIS.InputChanged:Connect(function(i) if d and isPtr(i, true) then setPx(i.Position.X) end end))
		tr(UIS.InputEnded:Connect(function(i) if isPtr(i) then d = false end end))
		if cfg.Description then lbl(r, tostring(cfg.Description), UDim2.new(1, -150, 0, 14), UDim2.fromOffset(12, 21), T.mut, nil, 10) end
		return o
	end
	function TabM:AddDropdown(id, cfg)
		local r = row(self, 36)
		lbl(r, tostring(cfg.Title or ""), UDim2.new(1, -190, 1, 0), UDim2.fromOffset(12, 0), T.text, nil, 13)
		local vals = cfg.Values or {}
		local def = type(cfg.Default) == "number" and vals[cfg.Default] or cfg.Default or vals[1]
		local o = makeObj(id, cfg, def)
		local b = new("TextButton", { Size = UDim2.fromOffset(150, 22), Position = UDim2.new(1, -162, 0.5, -11), BackgroundColor3 = T.bg, Text = "< " .. tostring(def) .. " >", TextColor3 = T.accent, Font = FONT, TextSize = 12, AutoButtonColor = false, BorderSizePixel = 0 }, r)
		corner(b, 3)
		local bst = stroke(b, T.line, 1)
		tr(b.MouseEnter:Connect(function() tw(bst, 0.1, { Color = T.accent }) end))
		tr(b.MouseLeave:Connect(function() tw(bst, 0.1, { Color = T.line }) end))
		function o:SetValue(v)
			if not table.find(vals, v) or v == self.Value then return end
			self.Value = v b.Text = "< " .. tostring(v) .. " >" self:_fire()
		end
		tr(b.MouseButton1Click:Connect(function() o:SetValue(vals[(table.find(vals, o.Value) or 0) % #vals + 1]) end))
		return o
	end
	function TabM:AddColorpicker(id, cfg)
		local r, st = row(self, 36)
		lbl(r, tostring(cfg.Title or ""), UDim2.new(1, -90, 0, 36), UDim2.fromOffset(12, 0), T.text, nil, 13)
		local o = makeObj(id, cfg, cfg.Default or Color3.new(1, 1, 1))
		local sw = new("TextButton", { Size = UDim2.fromOffset(44, 20), Position = UDim2.new(1, -56, 0, 8), BackgroundColor3 = o.Value, Text = "", AutoButtonColor = false, BorderSizePixel = 0 }, r)
		corner(sw, 3)
		stroke(sw, T.line, 1)
		local open, sliders = false, {}
		local chans = { { "R", "R" }, { "G", "G" }, { "B", "B" } }
		for i, c in ipairs(chans) do
			local y = 44 + (i - 1) * 22
			local nm = lbl(r, c[1], UDim2.fromOffset(16, 16), UDim2.fromOffset(12, y - 2), T.mut, nil, 12)
			local bar = new("TextButton", { Size = UDim2.new(1, -60, 0, 4), Position = UDim2.fromOffset(32, y + 6), BackgroundColor3 = T.off, Text = "", AutoButtonColor = false, BorderSizePixel = 0 }, r)
			local fill = new("Frame", { BackgroundColor3 = T[c[1] == "R" and "red" or c[1] == "G" and "grn" or "accent2"], BorderSizePixel = 0 }, bar)
			sliders[i] = { bar = bar, fill = fill, ch = c[1], nm = nm }
		end
		local function render()
			sw.BackgroundColor3 = o.Value
			local vv = { o.Value.R, o.Value.G, o.Value.B }
			for i, s in ipairs(sliders) do s.fill.Size = UDim2.new(vv[i], 0, 1, 0) end
		end
		render()
		function o:SetValue(c)
			if typeof(c) ~= "Color3" then return end
			self.Value = c render() self:_fire()
		end
		for i, s in ipairs(sliders) do
			local function setPx(px)
				local a = math.clamp((px - s.bar.AbsolutePosition.X) / s.bar.AbsoluteSize.X, 0, 1)
				local v = o.Value
				local rgb = { v.R, v.G, v.B }
				rgb[i] = a
				o:SetValue(Color3.new(rgb[1], rgb[2], rgb[3]))
			end
			local d
			tr(s.bar.InputBegan:Connect(function(inp) if isPtr(inp) then d = true setPx(inp.Position.X) end end))
			tr(UIS.InputChanged:Connect(function(inp) if d and isPtr(inp, true) then setPx(inp.Position.X) end end))
			tr(UIS.InputEnded:Connect(function(inp) if isPtr(inp) then d = false end end))
		end
		tr(sw.MouseButton1Click:Connect(function() open = not open tw(r, 0.15, { Size = UDim2.new(1, 0, 0, open and 114 or 36) }) end))
		hov(r, st, new("Frame", { Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1 }, r))
		return o
	end
	function TabM:AddInput(id, cfg)
		local r = row(self, 36)
		lbl(r, ">", UDim2.fromOffset(16, 36), UDim2.fromOffset(12, 0), T.accent, nil, 13)
		local o = makeObj(id, cfg, tostring(cfg.Default or ""))
		local t = new("TextBox", { Size = UDim2.new(1, -44, 1, 0), Position = UDim2.fromOffset(30, 0), BackgroundTransparency = 1, PlaceholderText = tostring(cfg.Placeholder or cfg.Title or ""),
			Text = o.Value, TextColor3 = T.text, PlaceholderColor3 = T.mut, Font = FONT, TextSize = 13, ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left }, r)
		tr(t:GetPropertyChangedSignal("Text"):Connect(function() o.Value = t.Text o:_fire() end))
		function o:SetValue(v) t.Text = tostring(v) end
		return o
	end
	function TabM:AddKeybind(id, cfg)
		local r = row(self, 36)
		lbl(r, tostring(cfg.Title or ""), UDim2.new(1, -140, 1, 0), UDim2.fromOffset(12, 0), T.text, nil, 13)
		local o = makeObj(id, cfg, tostring(cfg.Default or "None"))
		o.Mode, o._state, o._click = cfg.Mode or "Toggle", false, {}
		local b = new("TextButton", { Size = UDim2.fromOffset(110, 22), Position = UDim2.new(1, -122, 0.5, -11), BackgroundColor3 = T.bg, Text = "[ " .. o.Value .. " ]", TextColor3 = T.accent, Font = FONT, TextSize = 12, AutoButtonColor = false, BorderSizePixel = 0 }, r)
		corner(b, 3)
		stroke(b, T.line, 1)
		function o:OnClick(fn) self._click[#self._click + 1] = fn end
		function o:GetState() return self._state end
		function o:SetValue(v) self.Value = tostring(v) b.Text = "[ " .. self.Value .. " ]" end
		o._btn = b
		tr(b.MouseButton1Click:Connect(function() listening = o b.Text = "[ press a key ]" end))
		binds[#binds + 1] = o
		return o
	end


	local function specOf(s)
		if type(s) == "string" and s:sub(1, 2) == "MB" then return { mouse = Enum.UserInputType["MouseButton" .. (tonumber(s:sub(3)) or 1)] } end
		local ok, kc = pcall(function() return Enum.KeyCode[s] end)
		return { key = ok and kc or nil }
	end
	local function matches(o, i)
		local sp = specOf(o.Value)
		if sp.mouse then return i.UserInputType == sp.mouse end
		return sp.key ~= nil and i.KeyCode == sp.key
	end


	local menuKey = Enum.KeyCode.RightShift
	local function setMenu(v)
		menuOpen = v
		if modal then modal.Modal = v end
		if v then main.Visible = true tw(main, 0.15, { GroupTransparency = 0 })
		else tw(main, 0.15, { GroupTransparency = 1 }) task.delay(0.16, function() if not menuOpen and main then main.Visible = false end end) end
	end
	function F:CreateWindow(cfg)
		cfg = cfg or {}
		menuKey = cfg.MinimizeKey or menuKey
		local W = math.max(cfg.Size and cfg.Size.X.Offset or 680, 640)
		local H = math.max(cfg.Size and cfg.Size.Y.Offset or 470, 440)
		local root = CG
		pcall(function() if gethui then root = gethui() end end)
		gui = new("ScreenGui", { Name = HS:GenerateGUID(false), ResetOnSpawn = false, DisplayOrder = 999, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, root)
		modal = new("TextButton", { Size = UDim2.fromOffset(0, 0), BackgroundTransparency = 1, Text = "", Modal = true }, gui)
		menuOpen = true
		main = new("CanvasGroup", { Size = UDim2.fromOffset(W, H), Position = UDim2.new(0.5, -W / 2, 0.5, -H / 2), BackgroundColor3 = T.bg, BorderSizePixel = 0 }, gui)
		corner(main, 6)
		stroke(main, T.line, 1)
		local tb = new("Frame", { Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = T.side, BorderSizePixel = 0 }, main)
		local function dotBtn(x, col, cb)
			local d = new("TextButton", { Size = UDim2.fromOffset(11, 11), Position = UDim2.fromOffset(x, 12), BackgroundColor3 = col, Text = "", AutoButtonColor = false, BorderSizePixel = 0 }, tb)
			corner(d, 6)
			tr(d.MouseButton1Click:Connect(cb))
		end
		dotBtn(14, T.red, function() F.Unloaded = true end)
		dotBtn(32, T.yel, function() setMenu(false) end)
		dotBtn(50, T.grn, function() end)
		lbl(tb, ('<font color="#6e7681">~/</font>%s<font color="#3dff8f"> %s</font>  <font color="#6e7681">by</font> <font color="#3dff8f">LRX</font>'):format(tostring(cfg.Title or "hub"):gsub("%s+", "_"):lower(), tostring(cfg.SubTitle or "")), UDim2.fromOffset(360, 34), UDim2.fromOffset(76, 0), T.text, nil, 13, true)
		local tline = new("Frame", { Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1), BackgroundColor3 = T.accent, BorderSizePixel = 0 }, tb)
		new("UIGradient", { Color = ColorSequence.new(T.accent, T.accent2) }, tline)
		local dr, ds, sp
		tr(tb.InputBegan:Connect(function(i) if isPtr(i) then dr, ds, sp = true, i.Position, main.Position end end))
		tr(UIS.InputChanged:Connect(function(i)
			if dr and isPtr(i, true) then
				local d = i.Position - ds
				main.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
			end
		end))
		tr(UIS.InputEnded:Connect(function(i) if isPtr(i) then dr = false end end))
		local sbar = new("Frame", { Size = UDim2.new(1, 0, 0, 22), Position = UDim2.new(0, 0, 1, -22), BackgroundColor3 = T.side, BorderSizePixel = 0 }, main)
		new("Frame", { Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = T.line, BorderSizePixel = 0 }, sbar)
		status = lbl(sbar, '<font color="#3dff8f">[*]</font> ready', UDim2.new(0.6, 0, 1, 0), UDim2.fromOffset(12, 0), T.mut, nil, 11, true)
		lbl(sbar, string.lower(menuKey.Name) .. ": menu", UDim2.new(0.4, -12, 1, 0), UDim2.new(0.6, 0, 0, 0), T.mut, Enum.TextXAlignment.Right, 11)
		local side = new("Frame", { Size = UDim2.new(0, 168, 1, -56), Position = UDim2.fromOffset(0, 34), BackgroundColor3 = T.side, BorderSizePixel = 0 }, main)
		new("Frame", { Size = UDim2.new(0, 1, 1, 0), Position = UDim2.new(1, -1, 0, 0), BackgroundColor3 = T.line, BorderSizePixel = 0 }, side)
		lbl(side, '<font color="#3dff8f">//</font> modules', UDim2.new(1, -16, 0, 22), UDim2.fromOffset(12, 10), T.mut, nil, 11, true)
		local tabList = new("ScrollingFrame", { Size = UDim2.new(1, -2, 1, -40), Position = UDim2.fromOffset(0, 34), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 0, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new() }, side)
		new("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, tabList)
		new("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6) }, tabList)
		local content = new("Frame", { Size = UDim2.new(1, -168, 1, -56), Position = UDim2.fromOffset(168, 34), BackgroundTransparency = 1 }, main)
		pageTitle = lbl(content, "", UDim2.new(1, -24, 0, 26), UDim2.fromOffset(16, 10), T.text, nil, 15, true)
		toasts = new("Frame", { Size = UDim2.fromOffset(340, 240), Position = UDim2.new(1, -356, 1, -256), BackgroundTransparency = 1 }, gui)
		new("UIListLayout", { VerticalAlignment = Enum.VerticalAlignment.Bottom, HorizontalAlignment = Enum.HorizontalAlignment.Right, Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder }, toasts)

		local Window = {}
		local function tabText(i, n, on)
			return ('<font color="%s">%02d</font>  <font color="%s">%s</font>'):format(on and "#3dff8f" or "#6e7681", i, on and "#c9d1d9" or "#6e7681", string.lower(n))
		end
		function Window:SelectTab(i)
			for k, t in ipairs(tabsByIndex) do
				local on = k == i
				t.Page.Visible = on
				tw(t.bar, 0.12, { BackgroundTransparency = on and 0 or 1 })
				tw(t.btn, 0.12, { BackgroundColor3 = on and T.panel or T.side })
				t.txt.Text = tabText(k, t.name, on)
				if on then pageTitle.Text = '<font color="#3dff8f">~/</font>' .. string.lower(t.name) end
			end
		end
		function Window:AddTab(tcfg)
			tabN += 1
			local i, name = tabN, tostring(tcfg.Title or "tab")
			local btn = new("TextButton", { Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = T.side, Text = "", AutoButtonColor = false, BorderSizePixel = 0, LayoutOrder = i }, tabList)
			corner(btn, 4)
			local bar = new("Frame", { Size = UDim2.fromOffset(2, 16), Position = UDim2.new(0, 0, 0.5, -8), BackgroundColor3 = T.accent, BackgroundTransparency = 1, BorderSizePixel = 0 }, btn)
			local txt = lbl(btn, tabText(i, name, false), UDim2.new(1, -16, 1, 0), UDim2.fromOffset(12, 0), T.text, nil, 13, true)
			local p = new("ScrollingFrame", { Size = UDim2.new(1, -24, 1, -50), Position = UDim2.fromOffset(12, 44), BackgroundTransparency = 1, BorderSizePixel = 0,
				ScrollBarThickness = 2, ScrollBarImageColor3 = T.off, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), Visible = false }, content)
			new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, p)
			new("UIPadding", { PaddingRight = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8) }, p)
			local tab = setmetatable({ Page = p, n = 0, btn = btn, bar = bar, txt = txt, name = name }, TabM)
			tabsByIndex[i] = tab
			tr(btn.MouseButton1Click:Connect(function() Window:SelectTab(i) end))
			return tab
		end
		task.defer(function() F:Notify({ Title = "by LRX", Content = tostring(menuKey.Name) .. " = menu", Duration = 4 }) end)
		return Window
	end


	tr(UIS.InputBegan:Connect(function(i, gp)
		if listening then
			local o = listening
			if i.UserInputType == Enum.UserInputType.Keyboard then
				listening = nil
				o:SetValue(i.KeyCode == Enum.KeyCode.Escape and "None" or i.KeyCode.Name)
			elseif i.UserInputType.Name:find("MouseButton") then
				listening = nil
				o:SetValue("MB" .. i.UserInputType.Name:match("%d"))
			end
			return
		end
		if i.KeyCode == menuKey and not gp then setMenu(not menuOpen) return end
		for _, o in ipairs(binds) do
			local isMouse = i.UserInputType ~= Enum.UserInputType.Keyboard
			if matches(o, i) and (isMouse or not gp) then
				o._state = (o.Mode == "Hold") and true or not o._state
				if o._cfg.Callback then pcall(o._cfg.Callback, o._state) end
				for _, fn in ipairs(o._click) do pcall(fn) end
				for _, fn in ipairs(o._cb) do pcall(fn, o._state) end
			end
		end
	end))
	tr(UIS.InputEnded:Connect(function(i)
		for _, o in ipairs(binds) do
			if o.Mode == "Hold" and o._state and matches(o, i) then o._state = false end
		end
	end))

	function F:SetTheme() end
	function F:Dialog() end
	function F:Destroy()
		F.Unloaded = true
		for _, c in ipairs(conns) do pcall(c.Disconnect, c) end
		if gui then pcall(function() gui:Destroy() end) end
	end


	local SM = { _ignore = {}, _folder = "KeintWarTycoon/config" }
	function SM:SetLibrary(lib) self._lib = lib end
	function SM:IgnoreThemeSettings() end
	function SM:SetIgnoreIndexes(list) for _, k in ipairs(list) do self._ignore[k] = true end end
	function SM:SetFolder(path)
		self._folder = path
		pcall(function()
			local acc = ""
			for part in path:gmatch("[^/]+") do
				acc = acc == "" and part or (acc .. "/" .. part)
				if not isfolder(acc) then makefolder(acc) end
			end
		end)
	end
	local function encode(v)
		if typeof(v) == "Color3" then return { __c = { v.R, v.G, v.B } } end
		return v
	end
	local function decode(v)
		if type(v) == "table" and v.__c then return Color3.new(v.__c[1], v.__c[2], v.__c[3]) end
		return v
	end
	function SM:Snapshot()
		local t = {}
		for id, o in pairs(F.Options) do
			if not self._ignore[id] and id:sub(1, 1) ~= "_" and (typeof(o.Value) == "boolean" or typeof(o.Value) == "number" or typeof(o.Value) == "string" or typeof(o.Value) == "Color3") then
				t[id] = encode(o.Value)
			end
		end
		return t
	end
	function SM:Apply(t)
		local n = 0
		for id, v in pairs(t) do
			local o = F.Options[id]
			if o and not self._ignore[id] and o.SetValue then o:SetValue(decode(v)) n += 1 end
		end
		return n
	end
	function SM:BuildConfigSection(tab)
		local folder = self._folder
		local rows, cname, dmode = {}, "", false
		local function path(n) return folder .. "/" .. n .. ".json" end
		local function clean(s) s = tostring(s or ""):gsub("[^%w%-_ ]", ""):gsub("^%s+", ""):gsub("%s+$", "") return s:sub(1, 32) end
		local function load(n)
			local ok, raw = pcall(readfile, path(n))
			local ok2, d = false, nil
			if ok then ok2, d = pcall(HS.JSONDecode, HS, raw) end
			if ok2 and type(d) == "table" then
				F:Notify({ Title = "Config", Content = ("loaded %s (%d settings)"):format(n, self:Apply(d)), Duration = 3 })
				pcall(writefile, folder .. "/autoload_last.txt", n)
			else
				F:Notify({ Title = "Config", Content = "cannot read " .. n, Duration = 3 })
			end
		end
		local addRow
		local function save(n)
			n = clean(n)
			if n == "" then F:Notify({ Title = "Config", Content = "type a name first", Duration = 3 }) return end
			pcall(writefile, path(n), HS:JSONEncode(self:Snapshot()))
			pcall(writefile, folder .. "/autoload_last.txt", n)
			if not rows[n] then addRow(n) end
			F:Notify({ Title = "Config", Content = "saved " .. n, Duration = 3 })
		end
		addRow = function(n)
			rows[n] = tab:AddButton({ Title = n, Description = "click to load", Callback = function()
				if dmode then
					pcall(delfile, path(n))
					if rows[n] then rows[n]:Destroy() rows[n] = nil end
				else
					load(n)
				end
			end })
		end
		tab:AddSection("configs")
		local inp = tab:AddInput("_cfgName", { Title = "config name", Placeholder = "config name..." })
		tab:AddButton({ Title = "save config", Description = "writes every setting to " .. folder, Callback = function() save(inp.Value) end })
		local del = tab:AddToggle("_cfgDelete", { Title = "delete mode", Description = "click a config to delete it", Default = false })
		del:OnChanged(function(v) dmode = v end)
		local auto = tab:AddToggle("_cfgAuto", { Title = "autoload last config", Description = "applies the last used config on start", Default = false })
		auto:OnChanged(function(v) pcall(writefile, folder .. "/autoload_on.txt", v and "1" or "0") end)
		tab:AddSection("saved configs")
		pcall(function()
			local names = {}
			for _, f in ipairs(listfiles(folder)) do
				local n = tostring(f):match("([^/\\]+)%.json$")
				if n then names[#names + 1] = n end
			end
			table.sort(names)
			for _, n in ipairs(names) do addRow(n) end
		end)
		pcall(function()
			if isfile(folder .. "/autoload_on.txt") and readfile(folder .. "/autoload_on.txt") == "1" then
				auto.Value = true
				local last = isfile(folder .. "/autoload_last.txt") and readfile(folder .. "/autoload_last.txt")
				if last and isfile(path(last)) then task.defer(function() task.wait(1) load(last) end) end
			end
		end)
	end

	function SM:LoadAutoloadConfig() end
	function SM:SetTheme() end
	local IM = {}
	function IM:SetLibrary() end
	function IM:SetFolder() end
	function IM:BuildInterfaceSection(tab)
		tab:AddSection("interface")
		tab:AddParagraph({ Title = "Menu key", Content = "Press " .. menuKey.Name .. " to hide or show the menu." })
	end
	return F, SM, IM
end)()

local Window = Fluent:CreateWindow({
    Title = "War Tycoon",
    SubTitle = "Keyint",
    TabWidth = 150,
    Size = UDim2.fromOffset(600, 520),
    Acrylic = false,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.RightShift,
})

local Tabs = {
    ESP = Window:AddTab({ Title = "ESP", Icon = "eye" }),
    Aim = Window:AddTab({ Title = "Aim", Icon = "crosshair" }),
    Vehicle = Window:AddTab({ Title = "Vehicle", Icon = "car" }),
    Weapon = Window:AddTab({ Title = "Weapon", Icon = "target" }),
    Move = Window:AddTab({ Title = "Movement", Icon = "move" }),
    Visual = Window:AddTab({ Title = "Visuals", Icon = "sun" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" }),
}
local Options = Fluent.Options


local function getChar() return LP.Character end
local function getHum()
    local c = LP.Character
    return c and c:FindFirstChildOfClass("Humanoid")
end
local function getRoot()
    local c = LP.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function isEnemy(plr)
    if LP.Team == nil or plr.Team == nil then return true end
    return plr.Team ~= LP.Team
end


Tabs.ESP:AddSection("Players")
Tabs.ESP:AddToggle("PlayerESP", { Title = "Player ESP", Default = true })
Tabs.ESP:AddToggle("EnemiesOnly", { Title = "Enemies only", Description = "Other team (Player.Team)", Default = false })
Tabs.ESP:AddSlider("PlayerESPDist", { Title = "Max distance", Default = 5000, Min = 100, Max = 5000, Rounding = 0 })
Tabs.ESP:AddColorpicker("EnemyColor", { Title = "Enemy color", Default = Color3.fromRGB(255, 70, 70) })
Tabs.ESP:AddColorpicker("AllyColor", { Title = "Ally color", Default = Color3.fromRGB(70, 255, 120) })
Tabs.ESP:AddSection("Vehicles")
Tabs.ESP:AddToggle("VehicleESP", { Title = "Vehicle ESP", Description = "Tanks, planes, helicopters, boats, gunships, etc.", Default = true })
Tabs.ESP:AddSlider("VehicleESPDist", { Title = "Max distance", Default = 6000, Min = 100, Max = 6000, Rounding = 0 })
Tabs.ESP:AddSlider("VehicleESPCount", { Title = "Max count", Description = "Roblox Highlight limit is ~31 total, shared with players", Default = 16, Min = 1, Max = 20, Rounding = 0 })
Tabs.ESP:AddColorpicker("VehicleColor", { Title = "Vehicle color", Default = Color3.fromRGB(255, 170, 40) })


Tabs.Aim:AddSection("Silent Aim (guns)")
Tabs.Aim:AddToggle("SilentAim", { Title = "Silent Aim", Description = "Bullets fly at the target inside the FOV circle, no matter where you look", Default = true })
Tabs.Aim:AddSlider("SilentHitChance", { Title = "Hit chance %", Default = 100, Min = 1, Max = 100, Rounding = 0 })
Tabs.Aim:AddSection("Camera Aimbot")
Tabs.Aim:AddToggle("CamAim", { Title = "Camera Aimbot", Description = "Hold the key to lock your camera onto the target", Default = true })
local aimKey = Tabs.Aim:AddKeybind("AimKey", { Title = "Aim key (hold)", Mode = "Hold", Default = "LeftAlt", Callback = function() end })
Tabs.Aim:AddSlider("CamSmooth", { Title = "Smoothness", Description = "Higher = faster lock (100 = instant)", Default = 100, Min = 1, Max = 100, Rounding = 0 })
Tabs.Aim:AddSection("Targeting (shared with Vehicle aim)")
Tabs.Aim:AddDropdown("AimPart", { Title = "Target part (players)", Values = { "Head", "Torso", "HumanoidRootPart" }, Multi = false, Default = 1 })
Tabs.Aim:AddSlider("AimFov", { Title = "FOV radius (px)", Default = 150, Min = 30, Max = 800, Rounding = 0 })
Tabs.Aim:AddToggle("ShowFov", { Title = "Show FOV circle", Default = false })
Tabs.Aim:AddColorpicker("FovColor", { Title = "FOV circle color", Default = Color3.fromRGB(255, 255, 255) })
Tabs.Aim:AddToggle("AimTeamCheck", { Title = "Team check", Description = "Ignore teammates", Default = false })
Tabs.Aim:AddToggle("AimVisCheck", { Title = "Visibility check", Description = "Only target what you can see", Default = true })
Tabs.Aim:AddToggle("AimIgnoreFF", { Title = "Ignore spawn protection", Description = "Skip players with a ForceField", Default = true })
Tabs.Aim:AddToggle("AimPredict", { Title = "Bullet prediction", Description = "Lead moving targets and compensate bullet drop", Default = true })


Tabs.Vehicle:AddSection("Vehicle Silent Aim (turrets / guns of any vehicle)")
Tabs.Vehicle:AddToggle("VehAim", { Title = "Vehicle Silent Aim", Description = "While you sit in a vehicle, its turrets aim at the target inside the FOV circle", Default = false })
Tabs.Vehicle:AddDropdown("VehTargets", { Title = "Targets", Values = { "Both", "Players", "Vehicles" }, Multi = false, Default = 1 })
Tabs.Vehicle:AddToggle("VehLead", { Title = "Lead moving targets", Default = true })
Tabs.Vehicle:AddSlider("VehProjSpeed", { Title = "Projectile speed (studs/s)", Description = "Used for target leading", Default = 2500, Min = 200, Max = 6000, Rounding = 0 })
Tabs.Vehicle:AddSection("Lock-On (Stinger, Javelin, vehicle missiles)")
Tabs.Vehicle:AddToggle("Lock360", { Title = "360° lock-on", Description = "Removes the lock-on view cone, lock targets in every direction", Default = false })
Tabs.Vehicle:AddSlider("LockRange", { Title = "Lock-on max distance", Default = 4000, Min = 500, Max = 8000, Rounding = 0 })
Tabs.Vehicle:AddToggle("FastLock", { Title = "Instant lock", Description = "Skips the lock-on spool time", Default = false })
Tabs.Vehicle:AddToggle("LockAllTypes", { Title = "Lock all vehicle types", Description = "Lets air-only launchers (Stinger) lock ground, boats, etc.", Default = false })


Tabs.Weapon:AddParagraph({ Title = "ACS weapons", Content = "Applies instantly to the gun you are holding and to every gun you equip later." })
Tabs.Weapon:AddToggle("InfAmmo", { Title = "Infinite Ammo", Description = "Magazine never runs out, no reloading needed", Default = false })
Tabs.Weapon:AddToggle("NoCooldown", { Title = "No Cooldown (Stinger / Javelin)", Description = "Removes the launcher cooldown and keeps it loaded", Default = false })
Tabs.Weapon:AddToggle("NoRecoil", { Title = "No Recoil", Description = "Removes camera kick and weapon punch", Default = true })
Tabs.Weapon:AddToggle("NoSpread", { Title = "No Spread", Description = "Perfect accuracy: hip fire and moving included", Default = true })


Tabs.Move:AddSection("Speed / Jump")
Tabs.Move:AddToggle("SpeedToggle", { Title = "WalkSpeed", Default = false })
Tabs.Move:AddSlider("SpeedValue", { Title = "Speed", Default = 40, Min = 16, Max = 150, Rounding = 0 })
Tabs.Move:AddToggle("JumpToggle", { Title = "JumpPower", Default = false })
Tabs.Move:AddSlider("JumpValue", { Title = "Jump power", Default = 80, Min = 50, Max = 250, Rounding = 0 })
Tabs.Move:AddToggle("InfJump", { Title = "Infinite jump", Default = false })
Tabs.Move:AddSection("Fly / Noclip")
Tabs.Move:AddToggle("Fly", { Title = "Fly", Description = "WASD to move, Space up, LeftShift down", Default = false })
Tabs.Move:AddSlider("FlySpeed", { Title = "Fly speed", Default = 80, Min = 10, Max = 300, Rounding = 0 })
local flyKey = Tabs.Move:AddKeybind("FlyKey", { Title = "Fly key", Mode = "Toggle", Default = "KeypadMinus", Callback = function() end })
flyKey:OnClick(function() Options.Fly:SetValue(not Options.Fly.Value) end)
Tabs.Move:AddToggle("Noclip", { Title = "Noclip", Default = false })
local ncKey = Tabs.Move:AddKeybind("NoclipKey", { Title = "Noclip key", Mode = "Toggle", Default = "KeypadMultiply", Callback = function() end })
ncKey:OnClick(function() Options.Noclip:SetValue(not Options.Noclip.Value) end)


Tabs.Visual:AddToggle("FovToggle", { Title = "Change FOV", Default = false })
Tabs.Visual:AddSlider("FovValue", { Title = "FOV", Default = 90, Min = 40, Max = 120, Rounding = 0 })
Tabs.Visual:AddToggle("Fullbright", { Title = "Fullbright", Default = true })
Tabs.Visual:AddToggle("NoFog", { Title = "No fog", Default = true })

-- ============================================================
--  ESP
-- ============================================================
local guiParent = (gethui and gethui()) or CoreGui
local espFolder = Instance.new("Folder")
espFolder.Name = "WT_ESP"
espFolder.Parent = guiParent

local esp = {}

local function destroyEsp(key)
    local e = esp[key]
    if e then
        pcall(function() e.hl:Destroy() end)
        pcall(function() e.bb:Destroy() end)
        esp[key] = nil
    end
end

local function ensureEsp(key, target, part)
    local e = esp[key]
    if e and (e.target ~= target or e.part ~= part) then
        destroyEsp(key)
        e = nil
    end
    if not e then
        local hl = Instance.new("Highlight")
        hl.Adornee = target
        hl.FillTransparency = 0.65
        hl.OutlineTransparency = 0
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Parent = espFolder

        local bb = Instance.new("BillboardGui")
        bb.Adornee = part
        bb.AlwaysOnTop = true
        bb.Size = UDim2.fromOffset(200, 34)
        bb.StudsOffset = Vector3.new(0, 3.5, 0)
        bb.Parent = espFolder

        local lbl = Instance.new("TextLabel")
        lbl.BackgroundTransparency = 1
        lbl.Size = UDim2.fromScale(1, 1)
        lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = 13
        lbl.TextStrokeTransparency = 0.4
        lbl.TextColor3 = Color3.new(1, 1, 1)
        lbl.Parent = bb

        e = { hl = hl, bb = bb, lbl = lbl, target = target, part = part }
        esp[key] = e
    end
    if e and e.lbl then
        e.lbl.RichText = true
    end
    return e
end

local VEH_FOLDERS = {
    "Vehicle Workspace", "Tank Workspace", "Helicopter Workspace", "Plane Workspace",
    "Boat Workspace", "Hovercraft Workspace", "Submarine Workspace", "Drone Workspace",
    "Gunship Workspace", "RC Workspace",
}

local function collectVehicles(origin, maxDist, limit)
    local list = {}
    local gs = Workspace:FindFirstChild("Game Systems")
    if not gs then return list end
    for _, fname in ipairs(VEH_FOLDERS) do
        local f = gs:FindFirstChild(fname)
        if f then
            local kind = (fname:gsub(" Workspace", ""))
            for _, m in ipairs(f:GetChildren()) do
                if m:IsA("Model") and not m.Name:find("EjectionGroup") and not m.Name:find("ClickVisual") then
                    local part = m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart", true)
                    if part then
                        local d = (part.Position - origin).Magnitude
                        if d <= maxDist then
                            list[#list + 1] = { model = m, part = part, d = d, kind = kind }
                        end
                    end
                end
            end
        end
    end
    table.sort(list, function(a, b) return a.d < b.d end)
    while #list > limit do table.remove(list) end
    return list
end

local function espStep()
    local seen = {}
    local root = getRoot()
    local cam = Workspace.CurrentCamera
    local origin = root and root.Position or (cam and cam.CFrame.Position) or Vector3.zero

    local occupied = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        local char = plr.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local seat = hum and hum.SeatPart
        local veh = seat and seat:FindFirstAncestorOfClass("Model")
        if veh then occupied[veh] = true end
    end

    if Options.PlayerESP.Value then
        local maxD = Options.PlayerESPDist.Value
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LP then
                local char = plr.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if hrp and hum and hum.Health > 0 then
                    local enemy = isEnemy(plr)
                    local dist = (hrp.Position - origin).Magnitude
                    if dist <= maxD and (enemy or not Options.EnemiesOnly.Value) then
                        local key = plr
                        seen[key] = true
                        local e = ensureEsp(key, char, hrp)
                        local col = enemy and Options.EnemyColor.Value or Options.AllyColor.Value
                        e.hl.FillColor = col
                        e.hl.OutlineColor = col
                        
                        local function hex(c)
                            return string.format("#%02X%02X%02X",
                                math.floor(c.R * 255 + 0.5),
                                math.floor(c.G * 255 + 0.5),
                                math.floor(c.B * 255 + 0.5))
                        end
                        local playerHex = hex(col)
                        local vehicleHex = hex(Options.VehicleColor.Value)

                        local team = plr.Team and (" [" .. plr.Team.Name .. "]") or ""
                        local line1 = string.format("%s%s", plr.DisplayName, team)

                        local vehModel, vehPart
                        local seat = hum.SeatPart
                        if seat then
                            vehModel = seat:FindFirstAncestorOfClass("Model")
                            if vehModel then vehPart = seat end
                        end

                        if vehModel and vehPart then
                            local kind = "Vehicle"
                            local gs = Workspace:FindFirstChild("Game Systems")
                            if gs then
                                for _, fname in ipairs(VEH_FOLDERS) do
                                    local f = gs:FindFirstChild(fname)
                                    if f and vehModel:IsDescendantOf(f) then
                                        kind = fname:gsub(" Workspace", "")
                                        break
                                    end
                                end
                            end
                            
                            local line2 = string.format("%s: %s", kind, vehModel.Name)
                            
                            e.lbl.Text = string.format(
                                '<font color="%s">%s</font>\n<font color="%s">%s</font>\n<font color="%s">%dm | %dhp</font>',
                                playerHex, line1,
                                vehicleHex, line2,
                                playerHex, math.floor(dist), math.floor(hum.Health)
                            )
                            e.bb.StudsOffset = Vector3.new(0, 4.5, 0)
                            e.bb.Size = UDim2.fromOffset(200, 50)
                        else
                            e.lbl.Text = string.format(
                                '<font color="%s">%s</font>\n<font color="%s">%dm | %dhp</font>',
                                playerHex, line1,
                                playerHex, math.floor(dist), math.floor(hum.Health)
                            )
                            e.bb.StudsOffset = Vector3.new(0, 3.5, 0)
                            e.bb.Size = UDim2.fromOffset(200, 34)
                        end
                    end
                end
            end
        end
    end

    if Options.VehicleESP.Value then
        local list = collectVehicles(origin, Options.VehicleESPDist.Value, Options.VehicleESPCount.Value)
        for _, v in ipairs(list) do
            if not occupied[v.model] and not v.model.Name:find("EjectionGroup") and not v.model.Name:find("ClickVisual") then
                seen[v.model] = true
                local e = ensureEsp(v.model, v.model, v.part)
                local col = Options.VehicleColor.Value
                e.hl.FillColor = col
                e.hl.OutlineColor = col
                e.lbl.TextColor3 = col
                e.lbl.Text = string.format("%s: %s\n%dm", v.kind, v.model.Name, math.floor(v.d))
                e.bb.StudsOffset = Vector3.new(0, 3.5, 0)
                e.bb.Size = UDim2.fromOffset(200, 34)
            else
                if esp[v.model] then
                    destroyEsp(v.model)
                end
            end
        end
    end

    for key in pairs(esp) do
        if not seen[key] then destroyEsp(key) end
    end
end


local saved = setmetatable({}, { __mode = "k" })

local function moveStep()
    local h = getHum()
    if not h then return end
    local s = saved[h]
    if not s then s = {}; saved[h] = s end

    if Options.SpeedToggle.Value then
        if s.ws == nil then s.ws = h.WalkSpeed end
        h.WalkSpeed = Options.SpeedValue.Value
    elseif s.ws ~= nil then
        h.WalkSpeed = s.ws
        s.ws = nil
    end

    if Options.JumpToggle.Value then
        if s.jp == nil then s.jp = h.JumpPower; s.ujp = h.UseJumpPower end
        h.UseJumpPower = true
        h.JumpPower = Options.JumpValue.Value
    elseif s.jp ~= nil then
        h.UseJumpPower = s.ujp
        h.JumpPower = s.jp
        s.jp = nil
    end
end

local function moveRestore()
    local h = getHum()
    local s = h and saved[h]
    if s then
        if s.ws ~= nil then h.WalkSpeed = s.ws; s.ws = nil end
        if s.jp ~= nil then h.UseJumpPower = s.ujp; h.JumpPower = s.jp; s.jp = nil end
    end
end

table.insert(conns, UserInputService.JumpRequest:Connect(function()
    if Options.InfJump.Value then
        local h = getHum()
        if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end))

local function noclipStep()
    if not Options.Noclip.Value then return end
    local c = getChar()
    if not c then return end
    for _, p in ipairs(c:GetDescendants()) do
        if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
    end
end

local flyBV, flyBG, flyActive
local function flyStop()
    if flyBV then pcall(function() flyBV:Destroy() end); flyBV = nil end
    if flyBG then pcall(function() flyBG:Destroy() end); flyBG = nil end
    if flyActive then
        local h = getHum()
        if h then h.PlatformStand = false end
    end
    flyActive = false
end

local function flyStep()
    if not Options.Fly.Value then
        if flyActive then flyStop() end
        return
    end
    local hrp, h, cam = getRoot(), getHum(), Workspace.CurrentCamera
    if not hrp or not h or not cam or h.Health <= 0 then return end
    if h.SeatPart then
        if flyActive then flyStop() end
        return
    end
    flyActive = true
    if not flyBV or flyBV.Parent ~= hrp then
        if flyBV then flyBV:Destroy() end
        flyBV = Instance.new("BodyVelocity")
        flyBV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        flyBV.Velocity = Vector3.zero
        flyBV.Parent = hrp
    end
    if not flyBG or flyBG.Parent ~= hrp then
        if flyBG then flyBG:Destroy() end
        flyBG = Instance.new("BodyGyro")
        flyBG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        flyBG.P = 9e4
        flyBG.Parent = hrp
    end
    h.PlatformStand = true

    local cf = cam.CFrame
    local dir = Vector3.zero
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += cf.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= cf.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += cf.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= cf.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.yAxis end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir -= Vector3.yAxis end

    flyBV.Velocity = dir.Magnitude > 0 and dir.Unit * Options.FlySpeed.Value or Vector3.zero
    local flat = Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z)
    if flat.Magnitude > 0.01 then
        flyBG.CFrame = CFrame.lookAt(hrp.Position, hrp.Position + flat)
    end
end


local origFov, fovApplied
local lightOrig, fogOrig

local function lightRestore()
    if lightOrig then
        for k, v in pairs(lightOrig) do pcall(function() Lighting[k] = v end) end
        lightOrig = nil
    end
end
local function fogRestore()
    if fogOrig then
        pcall(function()
            Lighting.FogStart = fogOrig.FogStart
            Lighting.FogEnd = fogOrig.FogEnd
            if fogOrig.atm then
                fogOrig.atm.Density = fogOrig.density
                fogOrig.atm.Haze = fogOrig.haze
            end
        end)
        fogOrig = nil
    end
end

local function visualStep()
    local cam = Workspace.CurrentCamera
    if Options.FovToggle.Value and cam then
        if not fovApplied then origFov = cam.FieldOfView; fovApplied = true end
        cam.FieldOfView = Options.FovValue.Value
    elseif fovApplied then
        if cam and origFov then cam.FieldOfView = origFov end
        fovApplied = false
    end

    if Options.Fullbright.Value then
        if not lightOrig then
            lightOrig = {
                Brightness = Lighting.Brightness, ClockTime = Lighting.ClockTime,
                GlobalShadows = Lighting.GlobalShadows, Ambient = Lighting.Ambient,
                OutdoorAmbient = Lighting.OutdoorAmbient,
            }
        end
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.GlobalShadows = false
        Lighting.Ambient = Color3.fromRGB(178, 178, 178)
        Lighting.OutdoorAmbient = Color3.fromRGB(178, 178, 178)
    else
        lightRestore()
    end

    if Options.NoFog.Value then
        if not fogOrig then
            local atm = Lighting:FindFirstChildOfClass("Atmosphere")
            fogOrig = {
                FogStart = Lighting.FogStart, FogEnd = Lighting.FogEnd,
                atm = atm, density = atm and atm.Density, haze = atm and atm.Haze,
            }
        end
        Lighting.FogStart = 1e8
        Lighting.FogEnd = 1e9
        if fogOrig.atm then
            fogOrig.atm.Density = 0
            fogOrig.atm.Haze = 0
        end
    else
        fogRestore()
    end
end


local ACS_Guns do
    local cfg = ReplicatedStorage:FindFirstChild("Configurations")
    ACS_Guns = cfg and cfg:FindFirstChild("ACS_Guns")
end

local allSettings = {}
local settingsOrig = {}
local attrOrig = {}
local patched = { recoil = false, spread = false, cooldown = false }

local GROUPS = {
    recoil = {
        nums = { "MinRecoilPower", "MaxRecoilPower", "RecoilPowerStepAmount", "VPunchBase", "HPunchBase", "DPunchBase", "RecoilPunch" },
        tbls = { "VRecoil", "HRecoil" },
        attrs = { "VRecoil", "HRecoil" },
    },
    spread = {
        nums = { "MinSpread", "MaxSpread", "AimInaccuracyStepAmount", "HipfireSpreadMuitpler", "WalkMultiplier" },
        tbls = {},
        attrs = { "MinSpread", "MaxSpread" },
    },
    cooldown = {
        nums = { "Cooldown" },
        tbls = {},
        attrs = {},
        value = false,
    },
}

local function collectSettings()
    if not ACS_Guns then return end
    for _, g in ipairs(ACS_Guns:GetChildren()) do
        if not allSettings[g.Name] then
            local m = g:FindFirstChild("Settings")
            if m and m:IsA("ModuleScript") then
                local ok, S = pcall(require, m)
                if ok and type(S) == "table" then allSettings[g.Name] = S end
            end
        end
    end
end

local function setGroup(group, on)
    local g = GROUPS[group]
    local val = g.value
    if val == nil then val = 0 end
    for _, S in pairs(allSettings) do
        local o = settingsOrig[S]
        if not o then o = {}; settingsOrig[S] = o end
        for _, k in ipairs(g.nums) do
            if on then
                if type(S[k]) == "number" then
                    if o[k] == nil then o[k] = S[k] end
                    S[k] = val
                end
            elseif o[k] ~= nil then
                S[k] = o[k]
                o[k] = nil
            end
        end
        for _, k in ipairs(g.tbls) do
            if on then
                if type(S[k]) == "table" then
                    if o[k] == nil then o[k] = S[k] end
                    S[k] = { 0, 0 }
                end
            elseif o[k] ~= nil then
                S[k] = o[k]
                o[k] = nil
            end
        end
    end
    if #g.attrs == 0 then return end
    if on then
        local tools = {}
        for _, c in ipairs(LP.Backpack:GetChildren()) do tools[#tools + 1] = c end
        local ch = LP.Character
        if ch then for _, c in ipairs(ch:GetChildren()) do tools[#tools + 1] = c end end
        for _, tool in ipairs(tools) do
            if tool:IsA("Tool") then
                for _, a in ipairs(g.attrs) do
                    local cur = tool:GetAttribute(a)
                    if cur ~= nil then
                        local o = attrOrig[tool]
                        if not o then o = {}; attrOrig[tool] = o end
                        if o[a] == nil then o[a] = cur end
                        local zero = 0
                        if typeof(cur) == "Vector2" then zero = Vector2.zero
                        elseif typeof(cur) == "Vector3" then zero = Vector3.zero end
                        if cur ~= zero then tool:SetAttribute(a, zero) end
                    end
                end
            end
        end
    else
        for tool, o in pairs(attrOrig) do
            for _, a in ipairs(g.attrs) do
                if o[a] ~= nil then
                    pcall(function() tool:SetAttribute(a, o[a]) end)
                    o[a] = nil
                end
            end
        end
    end
end


local function clearCooldownAttrs()
    local function scan(container)
        for _, t in ipairs(container:GetChildren()) do
            if t:IsA("Tool") and t:GetAttribute("Cooldown") ~= nil then
                t:SetAttribute("Cooldown", nil)
            end
        end
    end
    scan(LP.Backpack)
    local ch = LP.Character
    if ch then scan(ch) end
end

local acsCache, lastFind, hookOk, hookTool, hookFail = nil, 0, false, nil, 0

local function getAcs()
    local char = LP.Character
    local acs = char and char:FindFirstChild("ACS_Client")
    if not acs then return nil end
    if acsCache and acsCache.script == acs and acs.Parent then return acsCache end
    if os.clock() - lastFind < 5 then return nil end
    lastFind = os.clock()

    local fg
    for _, f in ipairs(getgc(false)) do
        if typeof(f) == "function" then
            local ok, name = pcall(debug.info, f, "n")
            if ok and name == "fireGun" then
                local okE, env = pcall(getfenv, f)
                if okE and type(env) == "table" and env.script == acs then fg = f; break end
            end
        end
    end
    if not fg then return nil end

    local ups = debug.getupvalues(fg)
    local rec = ups[24]
    if type(ups[8]) ~= "table" or typeof(rec) ~= "function" or type(ups[9]) ~= "table" or ups[9][1] ~= "RPG" then
        return nil
    end
    local gd = ups[22]
    local gdOk = false
    if typeof(gd) == "function" then
        local ok, n = pcall(debug.info, gd, "n")
        gdOk = ok and n == "GetDir"
    end
    acsCache = { script = acs, fireGun = fg, recoil = rec, ammo = ups[8], getDir = gdOk and gd or nil, hooked = false }
    hookOk, hookTool = false, nil
    Fluent:Notify({ Title = "Weapon", Content = "Gun hooks ready.", Duration = 3 })
    return acsCache
end

local RECOIL_IDX = { 3, 4, 7, 8, 9, 15 }

local function weaponHooks(c, recOn, sprOn)
    local tool = LP.Character and LP.Character:FindFirstChildOfClass("Tool")
    if tool ~= hookTool then hookTool = tool; hookOk = false end
    if not tool then return end
    if not hookOk then
        if os.clock() - hookFail < 0.25 then return end
        local ups = debug.getupvalues(c.fireGun)
        local rups = debug.getupvalues(c.recoil)
        local good = type(ups[1]) == "table" and type(ups[23]) == "number" and type(ups[27]) == "number" and rups[6] == ups[1]
        if good then
            for _, i in ipairs(RECOIL_IDX) do
                if type(rups[i]) ~= "number" then good = false end
            end
        end
        if good then hookOk = true else hookFail = os.clock(); return end
    end
    if sprOn then pcall(debug.setupvalue, c.fireGun, 23, 0) end
    if recOn then
        pcall(debug.setupvalue, c.fireGun, 27, 0)
        for _, i in ipairs(RECOIL_IDX) do pcall(debug.setupvalue, c.recoil, i, 0) end
    end
end

local function weaponAmmo(c, onlyCooldownGuns)
    local ammo = c.ammo
    for tool, n in pairs(ammo) do
        if typeof(tool) == "Instance" and type(n) == "number" then
            local S = allSettings[tool.Name]
            local allowed = true
            if onlyCooldownGuns then
                local o = S and settingsOrig[S]
                allowed = o ~= nil and o.Cooldown ~= nil
            end
            if allowed then
                local mag = tool:GetAttribute("Ammo") or (S and S.Ammo)
                if type(mag) == "number" and n < mag then ammo[tool] = mag end
            end
        end
    end
end


local function aimCenter()
    local cam = Workspace.CurrentCamera
    local vp = cam and cam.ViewportSize or Vector2.new(1920, 1080)
    local h = getHum()
    if h and h.SeatPart and UserInputService.MouseBehavior ~= Enum.MouseBehavior.LockCenter then
        return UserInputService:GetMouseLocation(), true
    end
    return Vector2.new(vp.X / 2, vp.Y / 2), false
end

local function targetVisible(part, root)
    local cam = Workspace.CurrentCamera
    local ignore = { cam }
    if LP.Character then ignore[#ignore + 1] = LP.Character end
    local h = getHum()
    local seat = h and h.SeatPart
    local myVeh = seat and seat:FindFirstAncestorOfClass("Model")
    if myVeh then ignore[#ignore + 1] = myVeh end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = ignore
    local origin = cam.CFrame.Position
    local dir = part.Position - origin
    for _ = 1, 8 do
        local r = Workspace:Raycast(origin, dir, params)
        if not r then return true end
        local inst = r.Instance
        if inst:IsDescendantOf(root) then return true end
        if inst.Transparency >= 0.95 or not inst.CanCollide then
            ignore[#ignore + 1] = inst
            params.FilterDescendantsInstances = ignore
        else
            return false
        end
    end
    return false
end


local function vehicleTargetPart(m)
    local body, func, seats = m:FindFirstChild("Body"), m:FindFirstChild("Functionality"), m:FindFirstChild("Seats")
    local p = body and body:FindFirstChild("TargetPart")
        or func and func:FindFirstChild("TargetPart")
        or func and func:FindFirstChild("Engine")
        or seats and seats:FindFirstChild("DriversSeat")
        or m:FindFirstChild("MainPart")
        or m:FindFirstChild("TargetPart")
        or m:FindFirstChild("BoatPivot")
        or m:FindFirstChild("DriveSeat", true)
        or m:FindFirstChild("PilotSeat", true)
        or m.PrimaryPart
        or m:FindFirstChildWhichIsA("BasePart", true)
    if p and p:IsA("BasePart") then return p end
    return nil
end

local function getTarget(mode)
    mode = mode or "Players"
    local cam = Workspace.CurrentCamera
    if not cam then return nil end
    local center = aimCenter()
    local fov = Options.AimFov.Value
    local best, bestD

    local function consider(part, root, plr)
        local sp, onScreen = cam:WorldToViewportPoint(part.Position)
        if not onScreen then return end
        local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
        if d <= fov and (not bestD or d < bestD) then
            if not Options.AimVisCheck.Value or targetVisible(part, root) then
                best, bestD = { plr = plr, part = part }, d
            end
        end
    end

    if mode ~= "Vehicles" then
        local partName = Options.AimPart.Value
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LP and (not Options.AimTeamCheck.Value or isEnemy(plr)) then
                local char = plr.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                local part = char and char:FindFirstChild(partName)
                if part and hum and hum.Health > 0
                    and not (Options.AimIgnoreFF.Value and char:FindFirstChildOfClass("ForceField")) then
                    consider(part, char, plr)
                end
            end
        end
    end

    if mode ~= "Players" then
        local gs = Workspace:FindFirstChild("Game Systems")
        local h = getHum()
        local seat = h and h.SeatPart
        local myVeh = seat and seat:FindFirstAncestorOfClass("Model")
        if gs then
            for _, fname in ipairs(VEH_FOLDERS) do
                local f = gs:FindFirstChild(fname)
                if f then
                    for _, m in ipairs(f:GetChildren()) do
                        if m:IsA("Model") and m ~= myVeh then
                            local ownerName = m:GetAttribute("Owner") or m:GetAttribute("Pilot")
                            ownerName = ownerName and tostring(ownerName) or nil
                            local owner = ownerName and Players:FindFirstChild(ownerName)
                            local hp = m:FindFirstChild("Health")
                            local alive = not (hp and hp:IsA("ValueBase") and hp.Value == 0)
                            if owner and owner ~= LP and alive
                                and (not Options.AimTeamCheck.Value or isEnemy(owner))
                                and not m:GetAttribute("StealthActive") and not m:GetAttribute("Removing") then
                                local part = vehicleTargetPart(m)
                                if part then consider(part, m, owner) end
                            end
                        end
                    end
                end
            end
        end
    end
    return best
end


local function solveShot(O, P, V, speed, drop)
    local g = Vector3.new(0, -Workspace.Gravity * drop, 0)
    local t = (P - O).Magnitude / speed
    for _ = 1, 6 do
        local T = P + V * t
        t = (T - O - g * (0.5 * t * t)).Magnitude / speed
    end
    local T = P + V * t
    local d = T - O - g * (0.5 * t * t)
    return d.Unit, T, t, g
end

local function targetVelocity(part)
    local V = part.AssemblyLinearVelocity
    if V.Magnitude > 150 then V = V.Unit * 150 end
    return V
end

local function currentGunSettings()
    local char = LP.Character
    local tool = char and char:FindFirstChildOfClass("Tool")
    if not tool then return nil, nil end
    local S = allSettings[tool.Name]
    if not S then collectSettings(); S = allSettings[tool.Name] end
    return tool, S
end

local silentOld = nil
local function silentDirection()
    if Options.SilentHitChance.Value < 100 and math.random(1, 100) > Options.SilentHitChance.Value then return nil end
    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local cam = Workspace.CurrentCamera
    local tool, S = currentGunSettings()
    if not (hrp and cam and tool) then return nil end
    local tgt = getTarget("Players")
    if not tgt then return nil end

    local O = cam.CFrame.Position
    local gm = cam:FindFirstChild(tool.Name)
    gm = gm and gm:FindFirstChild(tool.Name)
    local smoke = gm and gm:FindFirstChild("SmokePart")
    if smoke then
        O = (smoke.CFrame * CFrame.new(0, 0, (smoke.CFrame:ToObjectSpace(hrp.CFrame)).Z + 0.5)).Position
            + hrp.AssemblyLinearVelocity * 0.035
    end

    local P = tgt.part.Position
    if S and type(S.Distance) == "number" and (P - O).Magnitude > S.Distance then return nil end
    if Options.AimPredict.Value and S and type(S.BSpeed) == "number" and S.BSpeed > 0 then
        local d = solveShot(O, P, targetVelocity(tgt.part), S.BSpeed, S.BDrop or 0)
        return d
    end
    return (P - O).Unit
end

local function installSilent(c)
    if c.hooked or c.hookFailed or not c.getDir then return end
    c.hooked = true
    local ok = pcall(function()
        silentOld = hookfunction(c.getDir, function(...)
            if unloaded or not Options.SilentAim.Value then return silentOld(...) end
            local okS, dir = pcall(silentDirection)
            if okS and typeof(dir) == "Vector3" and dir.Magnitude > 0.5 then return dir end
            return silentOld(...)
        end)
    end)
    if ok then
        Fluent:Notify({ Title = "Aim", Content = "Silent Aim hook installed.", Duration = 3 })
    else
        c.hooked = false
        c.hookFailed = true
        Fluent:Notify({ Title = "Aim", Content = "Silent Aim hook failed on this executor.", Duration = 6 })
    end
end


local TurretController = ReplicatedStorage:FindFirstChild("TurretSystem")
TurretController = TurretController and TurretController:FindFirstChild("TurretController")

local AimMod, origRot, origAnch
local LockMod, origLockNew

local vcache = { t = 0, part = nil }
local function vehicleAimPoint()
    if os.clock() - vcache.t > 0.08 then
        vcache.t = os.clock()
        local t = getTarget(Options.VehTargets.Value)
        vcache.part = t and t.part
    end
    local part = vcache.part
    if not part or not part.Parent then return nil end
    local P = part.Position
    if Options.VehLead.Value then
        local cam = Workspace.CurrentCamera
        local O = cam and cam.CFrame.Position or P
        local V = part.AssemblyLinearVelocity
        if V.Magnitude > 300 then V = V.Unit * 300 end
        P = P + V * ((P - O).Magnitude / Options.VehProjSpeed.Value)
    end
    return P
end

local function wrapAim(orig)
    return function(a1, a2)
        local r = orig(a1, a2)
        if unloaded or not Options.VehAim.Value then return r end
        local ok, pt = pcall(vehicleAimPoint)
        if ok and typeof(pt) == "Vector3" then return pt end
        return r
    end
end

local ALL_TARGETS = { "GroundVehicles", "Tanks", "Helicopters", "Planes", "Boats", "Hovercrafts", "Gunships", "Drones", "Submarines", "RCs" }

if TurretController then
    local okA, A = pcall(require, TurretController:FindFirstChild("AimController"))
    if okA and type(A) == "table" and type(A.RotatingTurretAim) == "function" and type(A.AnchoredTurretAim) == "function" then
        AimMod, origRot, origAnch = A, A.RotatingTurretAim, A.AnchoredTurretAim
        A.RotatingTurretAim = wrapAim(origRot)
        A.AnchoredTurretAim = wrapAim(origAnch)
    end

    local okL, L = pcall(require, TurretController:FindFirstChild("LockOnControl"))
    if okL and type(L) == "table" and type(L.new) == "function" then
        LockMod, origLockNew = L, L.new
        L.new = function(plr, vehicle, weapon, settings, seeker, rayParams)
            local s = settings
            if not unloaded and type(settings) == "table" then
                local ov, any = {}, false
                if Options.Lock360.Value then
                    ov.ViewRadius = 360
                    ov.TargetMaxDistance = Options.LockRange.Value
                    any = true
                end
                if Options.FastLock.Value then ov.LockOnTime = 0.05; any = true end
                if Options.LockAllTypes.Value then ov.LockOnTargets = ALL_TARGETS; any = true end
                if any then s = setmetatable(ov, { __index = settings }) end
            end
            return origLockNew(plr, vehicle, weapon, s, seeker, rayParams)
        end
    end
end


local function reequipLockTool()
    task.spawn(function()
        local char = LP.Character
        local h = getHum()
        local tool = char and char:FindFirstChildOfClass("Tool")
        if tool and h and (tool.Name == "Stinger" or tool.Name == "Javelin") then
            h:UnequipTools()
            task.wait(0.2)
            if not unloaded then h:EquipTool(tool) end
        end
    end)
end
Options.Lock360:OnChanged(reequipLockTool)
Options.FastLock:OnChanged(reequipLockTool)
Options.LockAllTypes:OnChanged(reequipLockTool)

local wAcc = 0
local function weaponStep(dt)
    local ammoOn, recOn, sprOn, silOn, cdOn =
        Options.InfAmmo.Value, Options.NoRecoil.Value, Options.NoSpread.Value, Options.SilentAim.Value, Options.NoCooldown.Value

    wAcc += dt
    if wAcc >= 0.5 then
        wAcc = 0
        if recOn or sprOn or cdOn or patched.recoil or patched.spread or patched.cooldown then collectSettings() end
        if recOn or patched.recoil then setGroup("recoil", recOn); patched.recoil = recOn end
        if sprOn or patched.spread then setGroup("spread", sprOn); patched.spread = sprOn end
        if cdOn or patched.cooldown then setGroup("cooldown", cdOn); patched.cooldown = cdOn end
    end

    if cdOn then pcall(clearCooldownAttrs) end

    if not (ammoOn or recOn or sprOn or silOn or cdOn) then return end
    local c = getAcs()
    if not c then return end
    if ammoOn then weaponAmmo(c, false) elseif cdOn then weaponAmmo(c, true) end
    if recOn or sprOn then weaponHooks(c, recOn, sprOn) end
    if silOn then installSilent(c) end
end

local function weaponRestore()
    setGroup("recoil", false)
    setGroup("spread", false)
    setGroup("cooldown", false)
    patched.recoil, patched.spread, patched.cooldown = false, false, false
end


local fovGui = Instance.new("ScreenGui")
fovGui.Name = "WT_FOV"
fovGui.IgnoreGuiInset = true
fovGui.ResetOnSpawn = false
fovGui.Parent = guiParent
local circle = Instance.new("Frame")
circle.AnchorPoint = Vector2.new(0.5, 0.5)
circle.Position = UDim2.fromScale(0.5, 0.5)
circle.BackgroundTransparency = 1
circle.Visible = false
circle.Parent = fovGui
do
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = circle
    local stroke = Instance.new("UIStroke")
    stroke.Name = "Stroke"
    stroke.Thickness = 1.5
    stroke.Parent = circle
end

local function camAimStep()
    local anyAim = Options.SilentAim.Value or Options.CamAim.Value or Options.VehAim.Value
    circle.Visible = anyAim and Options.ShowFov.Value
    if circle.Visible then
        local r = Options.AimFov.Value
        circle.Size = UDim2.fromOffset(r * 2, r * 2)
        circle.Stroke.Color = Options.FovColor.Value
        local c, isMouse = aimCenter()
        if isMouse then
            circle.Position = UDim2.fromOffset(c.X, c.Y)
        else
            circle.Position = UDim2.fromScale(0.5, 0.5)
        end
    end

    if not Options.CamAim.Value or not Options.AimKey:GetState() then return end
    local h = getHum()
    if h and h.SeatPart then return end
    local cam = Workspace.CurrentCamera
    if not cam then return end
    local tgt = getTarget("Players")
    if not tgt then return end

    local O = cam.CFrame.Position
    local P = tgt.part.Position
    local aimPoint = P
    local _, S = currentGunSettings()
    if Options.AimPredict.Value and S and type(S.BSpeed) == "number" and S.BSpeed > 0 then
        local _, T, t, g = solveShot(O, P, targetVelocity(tgt.part), S.BSpeed, S.BDrop or 0)
        aimPoint = T - g * (0.5 * t * t) -- aim above the target so the bullet drops onto it
    end
    local alpha = math.clamp(Options.CamSmooth.Value / 100, 0.01, 1)
    cam.CFrame = cam.CFrame:Lerp(CFrame.lookAt(O, aimPoint), alpha)
end

RunService:BindToRenderStep("WT_Aim", Enum.RenderPriority.Camera.Value + 1, function()
    if unloaded then return end
    pcall(camAimStep)
end)


local acc = 0
table.insert(conns, RunService.Heartbeat:Connect(function(dt)
    if unloaded then return end
    pcall(moveStep)
    pcall(weaponStep, dt)
    acc += dt
    if acc >= 0.1 then
        acc = 0
        pcall(espStep)
    end
end))
table.insert(conns, RunService.Stepped:Connect(function()
    if unloaded then return end
    pcall(noclipStep)
end))
table.insert(conns, RunService.RenderStepped:Connect(function()
    if unloaded then return end
    pcall(flyStep)
    pcall(visualStep)
end))
table.insert(conns, Players.PlayerRemoving:Connect(function(plr)
    destroyEsp(plr)
end))


local function unload()
    if unloaded then return end
    unloaded = true
    for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
    pcall(function() RunService:UnbindFromRenderStep("WT_Aim") end)
    for key in pairs(esp) do destroyEsp(key) end
    pcall(moveRestore)
    pcall(flyStop)
    pcall(lightRestore)
    pcall(fogRestore)
    pcall(weaponRestore)
    if AimMod then
        pcall(function() AimMod.RotatingTurretAim = origRot; AimMod.AnchoredTurretAim = origAnch end)
    end
    if LockMod then
        pcall(function() LockMod.new = origLockNew end)
    end
    local cam = Workspace.CurrentCamera
    if fovApplied and cam and origFov then cam.FieldOfView = origFov end
    pcall(function() espFolder:Destroy() end)
    pcall(function() fovGui:Destroy() end)
    pcall(function() Fluent:Destroy() end)
    getgenv().WTHub_Unload = nil
end
getgenv().WTHub_Unload = unload

Tabs.Settings:AddButton({
    Title = "Unload script",
    Description = "Reverts all changes and closes the menu",
    Callback = unload,
})

task.spawn(function()
    while not unloaded do
        task.wait(0.5)
        if Fluent.Unloaded then unload() end
    end
end)

SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "FlyKey", "NoclipKey", "AimKey" })
InterfaceManager:SetFolder("KeintWarTycoon")
SaveManager:SetFolder("KeintWarTycoon/config")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

Window:SelectTab(1)
Fluent:Notify({
    Title = "Keint | War Tycoon",
    Content = "Loaded! RightShift toggles the menu.",
    Duration = 6,
})
