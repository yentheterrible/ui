--!strict

local Theme = {}

Theme.Colors = {
	Background = Color3.fromRGB(10, 10, 12),
	Container = Color3.fromRGB(20, 20, 24),
	Interactive = Color3.fromRGB(28, 28, 34),
	Accent = Color3.fromRGB(255, 255, 255),
	Border = Color3.fromRGB(50, 50, 58),
	Text = Color3.fromRGB(255, 255, 255),
	Muted = Color3.fromRGB(160, 160, 170),
	Success = Color3.fromRGB(220, 220, 226),
}

Theme.CornerRadius = UDim.new(0, 12)
Theme.Stroke = {
	Color = Theme.Colors.Border,
	Thickness = 1,
	Transparency = 0.4,
	ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
}
Theme.PanelTransparency = 0.35
Theme.HoverDuration = 0.12
Theme.PressScale = 0.96
Theme.OpenScale = 0.94
Theme.Padding = 16
Theme.Animation = {
	Hover = TweenInfo.new(Theme.HoverDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	Press = TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	Release = TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
	Open = TweenInfo.new(0.24, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
	Fade = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
}

local Elements = (function()
	local TweenService = game:GetService("TweenService")
	local UserInputService = game:GetService("UserInputService")
	local COLORS = Theme.Colors
	local componentElements = {}

	function componentElements.Make(className: string, properties: {[string]: any}, parent: Instance?): Instance
		local object = Instance.new(className)
		for key, value in pairs(properties) do
			(object :: any)[key] = value
		end
		object.Parent = parent
		return object
	end

	function componentElements.Corner(parent: Instance, _radius: number?)
		return componentElements.Make("UICorner", { CornerRadius = Theme.CornerRadius }, parent)
	end

	function componentElements.Stroke(parent: Instance, _transparency: number?)
		return componentElements.Make("UIStroke", Theme.Stroke, parent)
	end

	function componentElements.Padding(parent: Instance, amount: number?, verticalAmount: number?)
		local inset = amount or Theme.Padding
		local verticalInset = if verticalAmount == nil then inset else verticalAmount
		return componentElements.Make("UIPadding", {
			PaddingLeft = UDim.new(0, inset),
			PaddingRight = UDim.new(0, inset),
			PaddingTop = UDim.new(0, verticalInset),
			PaddingBottom = UDim.new(0, verticalInset),
		}, parent)
	end

	function componentElements.Tween(object: Instance, duration: number, properties: {[string]: any}, style: Enum.EasingStyle?)
		local animation = TweenService:Create(
			object,
			TweenInfo.new(duration, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			properties
		)
		animation:Play()
		return animation
	end

	function componentElements.AddPressFeedback(button: GuiButton, scaleTarget: GuiObject?)
		local scale = componentElements.Make("UIScale", { Scale = 1 }, scaleTarget or button)
		local baseColor = button.BackgroundColor3
		button.MouseEnter:Connect(function()
			componentElements.Tween(button, Theme.HoverDuration, {
				BackgroundColor3 = baseColor:Lerp(Color3.new(1, 1, 1), 0.08),
			})
		end)
		button.MouseLeave:Connect(function()
			componentElements.Tween(button, Theme.HoverDuration, { BackgroundColor3 = baseColor })
		end)
		button.MouseButton1Down:Connect(function()
			componentElements.Tween(scale, Theme.Animation.Press.Time, { Scale = Theme.PressScale }, Enum.EasingStyle.Quad)
		end)
		local function release()
			componentElements.Tween(scale, Theme.Animation.Release.Time, { Scale = 1 }, Enum.EasingStyle.Back)
		end
		button.MouseButton1Up:Connect(release)
		button.MouseButton1Click:Connect(release)
	end

	function componentElements.TextLabel(parent: Instance, text: string, size: number, color: Color3?, font: Enum.Font?)
		return componentElements.Make("TextLabel", {
			BackgroundTransparency = 1,
			Font = font or Enum.Font.Gotham,
			Text = text,
			TextColor3 = color or COLORS.Text,
			TextSize = size,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Center,
		}, parent)
	end

	function componentElements.Button(parent: Instance, text: string, size: UDim2, color: Color3?)
		local element = componentElements.Make("TextButton", {
			AutoButtonColor = false,
			BackgroundColor3 = color or COLORS.Interactive,
			BorderSizePixel = 0,
			Font = Enum.Font.GothamMedium,
			Size = size,
			Text = text,
			TextColor3 = COLORS.Text,
			TextSize = 13,
		}, parent) :: TextButton
		componentElements.Corner(element)
		componentElements.Stroke(element)
		componentElements.AddPressFeedback(element)
		return element
	end

	function componentElements.SetCanvasHeight(scroller: ScrollingFrame, layout: UIListLayout, bottomPadding: number?)
		local extra = bottomPadding or 12
		local function update()
			scroller.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + extra)
		end
		layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(update)
		update()
	end

	function componentElements.SafeCallback(owner: any, callback: any, ...)
		if type(callback) ~= "function" then
			return
		end
		local ok, err = xpcall(callback, debug.traceback, ...)
		if not ok then
			warn("[Havoc Lib] Callback failed:\n" .. tostring(err))
			if owner and owner.Notify then
				owner:Notify({
					Title = "callback error",
					Content = "a component callback failed. see the developer console.",
					Duration = 5,
				})
			end
		end
	end

	function componentElements.ActionButton(parent: Instance, options: {[string]: any}, owner: any)
		local backgroundColor = options.Color or COLORS.Accent
		local luminance = backgroundColor.R * 0.2126 + backgroundColor.G * 0.7152 + backgroundColor.B * 0.0722
		local textColor = options.TextColor or COLORS.Text
		if not options.TextColor and luminance > 0.55 then
			textColor = COLORS.Background
		end
		local size = options.Size or UDim2.new(1, 0, 0, options.Height or 38)
		local element = componentElements.Button(parent, options.Name, size, backgroundColor)
		element.BackgroundColor3 = backgroundColor
		element.TextColor3 = textColor
		componentElements.Make("UIGradient", {
			Color = ColorSequence.new(backgroundColor, backgroundColor:Lerp(Color3.new(0, 0, 0), 0.08)),
			Rotation = 90,
		}, element)
		element.TextXAlignment = Enum.TextXAlignment.Left
		componentElements.Padding(element, Theme.Padding, 0)
		element.MouseButton1Click:Connect(function()
			componentElements.SafeCallback(owner, options.Callback)
		end)
		return element
	end

	function componentElements.Paragraph(parent: Instance, options: {[string]: any})
		return componentElements.Make("TextLabel", {
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Font = Enum.Font.Gotham,
			LayoutOrder = options.LayoutOrder or 0,
			Size = UDim2.new(1, 0, 0, 0),
			Text = options.Content or "",
			TextColor3 = options.Color or COLORS.Muted,
			TextSize = options.TextSize or 12,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
		}, parent)
	end

	function componentElements.Toggle(parent: Instance, options: {[string]: any}, owner: any)
		local value = options.Default == true
		local row = componentElements.Make("Frame", {
			BackgroundColor3 = COLORS.Interactive,
			BorderSizePixel = 0,
			Size = options.Size or UDim2.new(1, 0, 0, 40),
		}, parent)
		componentElements.Corner(row)
		componentElements.Stroke(row)
		componentElements.Make("UIGradient", {
			Color = ColorSequence.new(Color3.fromRGB(34, 34, 40), COLORS.Interactive),
			Rotation = 90,
		}, row)
		local label = componentElements.TextLabel(row, options.Name, 12, COLORS.Text, Enum.Font.GothamMedium)
		label.Position = UDim2.fromOffset(14, 0)
		label.Size = UDim2.new(1, -62, 1, 0)
		local track = componentElements.Make("Frame", {
			AnchorPoint = Vector2.new(1, 0.5),
			BackgroundColor3 = value and COLORS.Accent or COLORS.Muted,
			BorderSizePixel = 0,
			Position = UDim2.new(1, -14, 0.5, 0),
			Size = UDim2.fromOffset(34, 19),
		}, row)
		componentElements.Corner(track)
		componentElements.Stroke(track)
		componentElements.Make("UIGradient", {
			Color = ColorSequence.new(value and COLORS.Accent or COLORS.Muted, COLORS.Interactive),
			Rotation = 90,
		}, track)
		local knob = componentElements.Make("Frame", {
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundColor3 = COLORS.Background,
			BorderSizePixel = 0,
			Position = value and UDim2.new(1, -17, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
			Size = UDim2.fromOffset(13, 13),
		}, track)
		componentElements.Corner(knob)
		componentElements.Stroke(knob)
		local hitbox = componentElements.Make("TextButton", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Text = "",
		}, row) :: TextButton
		componentElements.Corner(hitbox)
		componentElements.Stroke(hitbox)
		componentElements.AddPressFeedback(hitbox, row)
		local toggle = { Value = value, Frame = row }
		local function setValue(nextValue: boolean, fireCallback: boolean?)
			value = nextValue == true
			toggle.Value = value
			componentElements.Tween(track, Theme.HoverDuration, {
				BackgroundColor3 = value and COLORS.Accent or COLORS.Muted,
			})
			componentElements.Tween(knob, Theme.HoverDuration, {
				Position = value and UDim2.new(1, -17, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
			})
			if fireCallback ~= false then
				componentElements.SafeCallback(owner, options.Callback, value)
			end
		end
		toggle.Set = function(_, nextValue: boolean, fireCallback: boolean?)
			setValue(nextValue, fireCallback)
		end
		hitbox.MouseEnter:Connect(function()
			componentElements.Tween(row, Theme.HoverDuration, { BackgroundColor3 = Color3.fromRGB(38, 38, 44) })
		end)
		hitbox.MouseLeave:Connect(function()
			componentElements.Tween(row, Theme.HoverDuration, { BackgroundColor3 = COLORS.Interactive })
		end)
		hitbox.MouseButton1Click:Connect(function()
			setValue(not value)
		end)
		return toggle
	end

	function componentElements.Slider(parent: Instance, options: {[string]: any}, owner: any, connections: {RBXScriptConnection})
		local minimum = options.Min or 0
		local maximum = options.Max or 100
		local step = options.Step or 1
		assert(maximum > minimum and step > 0, "Slider requires Max > Min and Step > 0")
		local value = math.clamp(options.Default or minimum, minimum, maximum)
		local row = componentElements.Make("Frame", {
			BackgroundColor3 = COLORS.Interactive,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 62),
		}, parent)
		componentElements.Corner(row)
		componentElements.Stroke(row)
		componentElements.Make("UIGradient", {
			Color = ColorSequence.new(Color3.fromRGB(34, 34, 40), COLORS.Interactive),
			Rotation = 90,
		}, row)
		local name = componentElements.TextLabel(row, options.Name, 12, COLORS.Text, Enum.Font.GothamMedium)
		name.Position = UDim2.fromOffset(14, 4)
		name.Size = UDim2.new(1, -100, 0, 22)
		local valueBox = componentElements.Make("TextBox", {
			AnchorPoint = Vector2.new(1, 0),
			BackgroundColor3 = COLORS.Background,
			Font = Enum.Font.Gotham,
			Position = UDim2.new(1, -12, 0, 5),
			Size = UDim2.fromOffset(62, 22),
			Text = tostring(value),
			TextColor3 = COLORS.Text,
			TextSize = 11,
		}, row) :: TextBox
		componentElements.Corner(valueBox)
		componentElements.Stroke(valueBox)
		local bar = componentElements.Make("Frame", {
			BackgroundColor3 = COLORS.Background,
			BorderSizePixel = 0,
			Position = UDim2.new(0, 14, 0, 39),
			Size = UDim2.new(1, -28, 0, 8),
		}, row)
		componentElements.Corner(bar)
		componentElements.Stroke(bar)
		local fill = componentElements.Make("Frame", {
			BackgroundColor3 = COLORS.Accent,
			BorderSizePixel = 0,
			Size = UDim2.new((value - minimum) / (maximum - minimum), 0, 1, 0),
		}, bar)
		componentElements.Corner(fill)
		componentElements.Stroke(fill)
		local sliderButton = componentElements.Make("TextButton", {
			Active = true,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 28),
			Position = UDim2.new(0, 0, 0, 29),
			Text = "",
		}, row) :: TextButton
		componentElements.Corner(sliderButton)
		componentElements.Stroke(sliderButton)
		componentElements.AddPressFeedback(sliderButton, row)
		local slider = { Value = value, Frame = row }
		local function formatValue(number: number)
			local decimals = options.Decimals
			if decimals == nil then
				decimals = #((tostring(step):split(".")[2]) or "")
			end
			return string.format("%." .. tostring(math.clamp(decimals, 0, 6)) .. "f", number)
		end
		local function setValue(nextValue: number, fireCallback: boolean?)
			if nextValue ~= nextValue or math.abs(nextValue) == math.huge then
				return
			end
			local snapped = minimum + math.floor((math.clamp(nextValue, minimum, maximum) - minimum) / step + 0.5) * step
			value = math.clamp(snapped, minimum, maximum)
			slider.Value = value
			local alpha = (value - minimum) / (maximum - minimum)
			componentElements.Tween(fill, 0.08, { Size = UDim2.new(alpha, 0, 1, 0) })
			valueBox.Text = formatValue(value)
			if fireCallback ~= false then
				componentElements.SafeCallback(owner, options.Callback, value)
			end
		end
		slider.Set = function(_, nextValue: number, fireCallback: boolean?)
			setValue(nextValue, fireCallback)
		end
		local dragging = false
		local function update(input: InputObject)
			local width = math.max(bar.AbsoluteSize.X, 1)
			setValue(minimum + math.clamp((input.Position.X - bar.AbsolutePosition.X) / width, 0, 1) * (maximum - minimum))
		end
		sliderButton.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				update(input)
			end
		end)
		table.insert(connections, UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = false
			end
		end))
		table.insert(connections, UserInputService.InputChanged:Connect(function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				update(input)
			end
		end))
		valueBox.FocusLost:Connect(function()
			local parsed = tonumber(valueBox.Text)
			if parsed then
				setValue(parsed)
			else
				valueBox.Text = formatValue(value)
			end
		end)
		setValue(value, false)
		return slider
	end

	function componentElements.IconImage(parent: Instance, icon: any, size: number)
		if type(icon) == "number" or (type(icon) == "string" and icon:match("^%d+$")) then
			return componentElements.Make("ImageLabel", {
				BackgroundTransparency = 1,
				Image = "rbxassetid://" .. tostring(icon),
				ImageColor3 = COLORS.Muted,
				Size = UDim2.fromOffset(size, size),
			}, parent)
		end
		if type(icon) == "string" and (icon:match("^rbxassetid://%d+$") or icon:match("^https?://")) then
			return componentElements.Make("ImageLabel", {
				BackgroundTransparency = 1,
				Image = icon,
				ImageColor3 = COLORS.Muted,
				Size = UDim2.fromOffset(size, size),
			}, parent)
		end
		local normalizedIcon = if type(icon) == "string" then string.lower(icon) else ""
		if normalizedIcon == "home" or normalizedIcon == "main" then
			local homeIcon = componentElements.Make("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.fromOffset(size, size),
			}, parent)
			local iconSize = size * 0.84
			local drawing = componentElements.Make("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromOffset(iconSize, iconSize),
			}, homeIcon)
			local function line(x: number, y: number, width: number, height: number, rotation: number)
				return componentElements.Make("Frame", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundColor3 = COLORS.Muted,
					BorderSizePixel = 0,
					Name = "HavocIconPart",
					Position = UDim2.fromOffset(x, y),
					Rotation = rotation,
					Size = UDim2.fromOffset(width, height),
				}, drawing)
			end
			line(iconSize * 0.34, iconSize * 0.35, iconSize * 0.43, 1.3, -38)
			line(iconSize * 0.66, iconSize * 0.35, iconSize * 0.43, 1.3, 38)
			line(iconSize * 0.29, iconSize * 0.67, 1.3, iconSize * 0.36, 0)
			line(iconSize * 0.71, iconSize * 0.67, 1.3, iconSize * 0.36, 0)
			line(iconSize * 0.5, iconSize * 0.88, iconSize * 0.44, 1.3, 0)
			line(iconSize * 0.5, iconSize * 0.81, 1.2, iconSize * 0.2, 0)
			return homeIcon
		end
		if normalizedIcon == "aimbot" then
			local crosshair = componentElements.Make("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.fromOffset(size, size),
			}, parent)
			local ring = componentElements.Make("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromOffset(size * 0.46, size * 0.46),
			}, crosshair)
			componentElements.Corner(ring)
			componentElements.Make("UIStroke", {
				Color = COLORS.Muted,
				Thickness = 1.2,
				Transparency = 0,
			}, ring)
			local function tick(x: number, y: number, width: number, height: number)
				componentElements.Make("Frame", {
					BackgroundColor3 = COLORS.Muted,
					BorderSizePixel = 0,
					Name = "HavocIconPart",
					Position = UDim2.fromOffset(x, y),
					Size = UDim2.fromOffset(width, height),
				}, crosshair)
			end
			tick(size * 0.5 - 0.6, size * 0.08, 1.2, size * 0.18)
			tick(size * 0.5 - 0.6, size * 0.74, 1.2, size * 0.18)
			tick(size * 0.08, size * 0.5 - 0.6, size * 0.18, 1.2)
			tick(size * 0.74, size * 0.5 - 0.6, size * 0.18, 1.2)
			return crosshair
		end
		local namedIcons = {
			aim = "◎",
			bell = "♧",
			bolt = "ϟ",
			bookmark = "◇",
			combat = "◎",
			check = "✓",
			esp = "◈",
			exploits = "⚒",
			eye = "◉",
			general = "☷",
			info = "i",
			layers = "▤",
			lightning = "ϟ",
			list = "≡",
			movement = "↗",
			person = "♙",
			search = "⌕",
			settings = "⚙",
			shield = "⬡",
			sparkles = "✦",
			target = "◎",
			tune = "☷",
			user = "♙",
			visuals = "◉",
			welcome = "✦",
		}
		local iconText = ""
		if type(icon) == "string" then
			iconText = namedIcons[normalizedIcon] or (icon:match("^[%a%s_%-]+$") and "▤" or icon)
		end
		local label = componentElements.TextLabel(parent, iconText, size, COLORS.Muted, Enum.Font.GothamMedium)
		label.TextXAlignment = Enum.TextXAlignment.Center
		return label
	end

	return componentElements
end)()

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")
local Workspace = game:GetService("Workspace")

local HavocLib = {}
HavocLib.__index = HavocLib

local Window = {}
Window.__index = Window

local Tab = {}
Tab.__index = Tab

local Section = {}
Section.__index = Section

local COLORS = Theme.Colors
local make = Elements.Make
local corner = Elements.Corner
local stroke = Elements.Stroke
local padding = Elements.Padding
local tween = Elements.Tween
local addPressFeedback = Elements.AddPressFeedback
local textLabel = Elements.TextLabel
local button = Elements.Button
local setCanvasHeight = Elements.SetCanvasHeight
local safeCallback = Elements.SafeCallback
local iconImage = Elements.IconImage

function HavocLib.new(options: {[string]: any}?)
	local config = options or {}
	local player = Players.LocalPlayer
	assert(player, "Havoc Lib must be initialized on the client")
	local playerGui = player:WaitForChild("PlayerGui")

	local self = setmetatable({}, HavocLib)
	self._startedAt = os.clock()
	self._connections = {}
	self._notifications = {}
	self._destroyed = false

	local screen = make("ScreenGui", {
		Name = config.Name or "havoc lib",
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}, playerGui) :: ScreenGui
	self.ScreenGui = screen

	local window = setmetatable({
		_library = self,
		_tabs = {},
		_connections = {},
	}, Window)
	self.Window = window

	local root = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = COLORS.Background,
		BorderSizePixel = 0,
		Position = config.Position or UDim2.fromScale(0.5, 0.5),
		Size = config.Size or UDim2.fromOffset(460, 356),
	}, screen) :: Frame
	window.Root = root
	make("UISizeConstraint", {
		MaxSize = Vector2.new(760, 600),
	}, root)
	local responsiveScale = make("UIScale", { Scale = 1 }, root) :: UIScale
	local function updateResponsiveScale()
		local camera = Workspace.CurrentCamera
		if not camera then return end
		local viewport = camera.ViewportSize
		responsiveScale.Scale = math.max(0.1, math.min(1, (viewport.X - 24) / 460, (viewport.Y - 24) / 356))
	end
	updateResponsiveScale()
	local viewportConnection: RBXScriptConnection? = nil
	local function connectViewport()
		if viewportConnection then
			viewportConnection:Disconnect()
			local oldIndex = table.find(window._connections, viewportConnection)
			if oldIndex then
				table.remove(window._connections, oldIndex)
			end
			viewportConnection = nil
		end
		local camera = Workspace.CurrentCamera
		if camera then
			viewportConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateResponsiveScale)
			table.insert(window._connections, viewportConnection)
		end
		updateResponsiveScale()
	end
	local cameraConnection = Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		connectViewport()
	end)
	table.insert(window._connections, cameraConnection)
	connectViewport()
	corner(root)
	stroke(root)
	make("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(24, 24, 29)),
			ColorSequenceKeypoint.new(1, COLORS.Background),
		}),
		Rotation = 90,
	}, root)
	local rootScale = make("UIScale", { Scale = Theme.OpenScale }, root) :: UIScale
	window._scale = rootScale
	window._open = true

	local header = make("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0, 0),
		Size = UDim2.new(1, 0, 0, 40),
	}, root)
	window.Header = header
	padding(header, 14, 0)
	if config.Logo ~= nil then
		assert(
			(type(config.Logo) == "number" and config.Logo > 0)
				or (type(config.Logo) == "string" and config.Logo ~= ""),
			"Logo must be a positive asset ID or a non-empty image URL"
		)
		local logoImage = make("ImageLabel", {
			BackgroundColor3 = COLORS.Interactive,
			BorderSizePixel = 0,
			Image = type(config.Logo) == "number" and ("rbxassetid://" .. tostring(config.Logo)) or config.Logo,
			ScaleType = Enum.ScaleType.Crop,
			Size = UDim2.fromOffset(26, 26),
		}, header) :: ImageLabel
		corner(logoImage)
		stroke(logoImage)
	else
		local logo = make("Frame", {
			BackgroundColor3 = COLORS.Interactive,
			BorderSizePixel = 0,
			Size = UDim2.fromOffset(26, 26),
		}, header)
		corner(logo)
		stroke(logo)
		local monogram = textLabel(logo, "h", 16, COLORS.Text, Enum.Font.GothamBold)
		monogram.Size = UDim2.fromScale(1, 1)
		monogram.TextXAlignment = Enum.TextXAlignment.Center
	end
	local title = textLabel(header, config.Title or "havoc lib", 13, COLORS.Text, Enum.Font.GothamBold)
	title.Position = UDim2.fromOffset(34, 2)
	title.Size = UDim2.new(0.25, 0, 0, 16)
	local subtitle = textLabel(header, config.Subtitle or "made by convict", 8, COLORS.Muted)
	subtitle.Position = UDim2.fromOffset(34, 18)
	subtitle.Size = UDim2.new(0.25, 0, 0, 12)
	local version = textLabel(header, config.Version or "v0.1.0", 9, COLORS.Muted, Enum.Font.GothamMedium)
	version.AnchorPoint = Vector2.new(0, 0.5)
	version.Position = UDim2.new(0.3, 0, 0.5, 0)
	version.Size = UDim2.fromOffset(48, 20)
	version.BackgroundColor3 = COLORS.Interactive
	corner(version)
	stroke(version)
	version.TextXAlignment = Enum.TextXAlignment.Center

	local search = make("TextBox", {
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundColor3 = COLORS.Interactive,
		ClearTextOnFocus = false,
		Font = Enum.Font.Gotham,
		PlaceholderColor3 = COLORS.Muted,
		PlaceholderText = "search components...",
		Position = UDim2.new(1, -102, 0.5, 0),
		Size = UDim2.new(0.34, 0, 0, 26),
		Text = "",
		TextColor3 = COLORS.Text,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, header) :: TextBox
	search.Visible = config.SearchEnabled == true
	search.BackgroundTransparency = 0.08
	corner(search)
	stroke(search)
	padding(search, 10, 0)
	window.SearchBox = search

	local windowActions = make("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundTransparency = 1,
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.fromOffset(72, 24),
	}, header)
	local actionsLayout = make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		Padding = UDim.new(0, 3),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, windowActions)
	local minimizeButton = button(windowActions, "−", UDim2.fromOffset(21, 22), COLORS.Interactive)
	minimizeButton.TextSize = 14
	minimizeButton.LayoutOrder = 1
	local maximizeButton = button(windowActions, "□", UDim2.fromOffset(21, 22), COLORS.Interactive)
	maximizeButton.TextSize = 11
	maximizeButton.LayoutOrder = 2
	local closeButton = button(windowActions, "×", UDim2.fromOffset(21, 22), COLORS.Interactive)
	closeButton.TextSize = 14
	closeButton.LayoutOrder = 3
	window._expandedSize = root.Size
	window._expandedPosition = root.Position
	window._minimized = false
	window._maximized = false

	local body = make("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, 40),
		Size = UDim2.new(1, 0, 1, config.ShowMetrics == true and -70 or -40),
	}, root)
	window.Body = body
	local sidebar = make("Frame", {
		BackgroundColor3 = COLORS.Background,
		BackgroundTransparency = 0.12,
		BorderSizePixel = 0,
		Position = UDim2.fromScale(0, 0),
		Size = UDim2.new(0, 164, 1, 0),
	}, body)
	corner(sidebar)
	stroke(sidebar)
	make("UIGradient", {
		Color = ColorSequence.new(Color3.fromRGB(25, 25, 30), COLORS.Container),
		Rotation = 90,
	}, sidebar)
	local tabList = make("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(14, 14),
		Size = UDim2.new(1, -28, 1, -28),
	}, sidebar)
	local tabLayout = make("UIListLayout", {
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, tabList) :: UIListLayout
	window._tabList = tabList

	local content = make("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 164, 0, 0),
		Size = UDim2.new(1, -164, 1, 0),
	}, body)
	window.Content = content

	local status = make("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 1, -30),
		Size = UDim2.new(1, 0, 0, 30),
		Visible = config.ShowMetrics == true,
	}, root)
	local statusText = textLabel(status, "fps --  |  ping -- ms  |  runtime 0s", 10, COLORS.Muted)
	statusText.Position = UDim2.new(0, 14, 0, 0)
	statusText.Size = UDim2.new(1, -28, 1, 0)
	window._statusText = statusText
	window._status = status
	minimizeButton.MouseButton1Click:Connect(function()
		window._minimized = not window._minimized
		if window._minimized then
			window._expandedSize = root.Size
			window._wasMetricsVisible = status.Visible
			body.Visible = false
			status.Visible = false
			tween(root, Theme.HoverDuration, { Size = UDim2.new(root.Size.X.Scale, root.Size.X.Offset, 0, 46) })
			minimizeButton.Text = "+"
		else
			body.Visible = true
			status.Visible = window._wasMetricsVisible == true
			tween(root, Theme.HoverDuration, { Size = window._expandedSize })
			minimizeButton.Text = "−"
		end
	end)
	closeButton.MouseButton1Click:Connect(function()
		window:SetVisible(false)
	end)
	maximizeButton.MouseButton1Click:Connect(function()
		if window._maximized then
			window._maximized = false
			tween(root, Theme.HoverDuration, { Size = window._expandedSize, Position = window._expandedPosition })
			maximizeButton.Text = "□"
		else
			window._expandedSize = root.Size
			window._expandedPosition = root.Position
			window._maximized = true
			tween(root, Theme.HoverDuration, {
				Size = UDim2.new(0.9, 0, 0.88, 0),
				Position = UDim2.fromScale(0.5, 0.5),
			})
			maximizeButton.Text = "▢"
		end
	end)

	local dragStart: Vector2? = nil
	local startPosition: UDim2? = nil
	local dragVelocity = Vector2.zero
	local lastDragPosition = Vector2.zero
	local lastDragTime = 0
	header.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragStart = input.Position
			startPosition = root.Position
			lastDragPosition = input.Position
			lastDragTime = os.clock()
		end
	end)
	local dragEndConnection = UserInputService.InputChanged:Connect(function(input)
		if not dragStart or not startPosition then return end
		if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
		local delta = input.Position - dragStart
		root.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X, startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
		local now = os.clock()
		local elapsed = math.max(now - lastDragTime, 1 / 240)
		dragVelocity = (input.Position - lastDragPosition) / elapsed
		lastDragPosition = input.Position
		lastDragTime = now
	end)
	local dragStopConnection = UserInputService.InputEnded:Connect(function(input)
		if dragStart and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
			dragStart = nil
			startPosition = nil
		end
	end)
	table.insert(window._connections, dragEndConnection)
	table.insert(window._connections, dragStopConnection)

	local frameCounter = 0
	local elapsedFrame = 0
	local statusConnection = RunService.RenderStepped:Connect(function(dt)
		frameCounter += 1
		elapsedFrame += dt
		if elapsedFrame >= 0.5 then
			local fps = math.floor(frameCounter / elapsedFrame + 0.5)
			local ping = "--"
			local ok, result = pcall(function()
				return player:GetNetworkPing() * 1000
			end)
			if ok and type(result) == "number" then ping = tostring(math.floor(result + 0.5)) end
			statusText.Text = string.format("fps %d  |  ping %s ms  |  runtime %ds", fps, ping, math.floor(os.clock() - self._startedAt))
			frameCounter = 0
			elapsedFrame = 0
		end
		if not dragStart and dragVelocity.Magnitude > 8 then
			local position = root.Position
			local dtClamped = math.min(dt, 1 / 30)
			root.Position = UDim2.new(position.X.Scale, position.X.Offset + dragVelocity.X * dtClamped, position.Y.Scale, position.Y.Offset + dragVelocity.Y * dtClamped)
			dragVelocity *= math.exp(-8 * dtClamped)
		end
	end)
	table.insert(window._connections, statusConnection)

	window._applySearch = function()
		local query = string.lower(search.Text)
		for _, tab in ipairs(window._tabs) do
			local tabNameMatches = query == "" or string.find(string.lower(tab._name), query, 1, true) ~= nil
			for _, card in ipairs(tab._cards) do
				local visible = tabNameMatches or string.find(string.lower(card._searchText), query, 1, true) ~= nil
				card._frame.Visible = visible
			end
			tab._button.Visible = tabNameMatches or tab._matches(query)
		end
		if window._activeTab and not window._activeTab._button.Visible then
			for _, tab in ipairs(window._tabs) do
				if tab._button.Visible then
					window:SelectTab(tab)
					break
				end
			end
		end
		for _, tab in ipairs(window._tabs) do
			tab._page.Visible = tab == window._activeTab and tab._button.Visible
		end
	end
	search:GetPropertyChangedSignal("Text"):Connect(window._applySearch)

	tween(rootScale, Theme.Animation.Open.Time, { Scale = 1 }, Enum.EasingStyle.Back)
	root.BackgroundTransparency = 1
	tween(root, Theme.Animation.Fade.Time, { BackgroundTransparency = 0 })
	return window
end

function Window:Tab(options: {[string]: any})
	assert(type(options) == "table" and type(options.Name) == "string", "Tab requires a Name")
	local tab = setmetatable({
		_window = self,
		_name = options.Name,
		_cards = {},
		_sections = {},
	}, Tab)

	local tabButton = make("TextButton", {
		AutoButtonColor = false,
		BackgroundColor3 = COLORS.Container,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 36),
		Text = "",
	}, self._tabList) :: TextButton
	tab._button = tabButton
	tabButton.BackgroundTransparency = 0.35
	corner(tabButton)
	stroke(tabButton)
	addPressFeedback(tabButton)
	local icon = iconImage(tabButton, options.Icon or options.Name, 16)
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.Position = UDim2.new(0, 17, 0.5, 0)
	icon.Size = UDim2.fromOffset(16, 16)
	local label = textLabel(tabButton, string.lower(options.Name), 11, COLORS.Muted, Enum.Font.GothamMedium)
	label.Position = UDim2.fromOffset(34, 0)
	label.Size = UDim2.new(1, -61, 1, 0)
	local badge = textLabel(tabButton, "", 10, COLORS.Text, Enum.Font.GothamBold)
	badge.AnchorPoint = Vector2.new(1, 0.5)
	badge.Position = UDim2.new(1, -8, 0.5, 0)
	badge.Size = UDim2.fromOffset(22, 20)
	badge.BackgroundColor3 = COLORS.Accent
	badge.TextColor3 = COLORS.Background
	badge.Visible = false
	corner(badge)
	stroke(badge)
	tab.Badge = badge

	local indicator = make("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = COLORS.Accent,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.new(0, 3, 0, 0),
	}, tabButton)
	corner(indicator)
	tab._indicator = indicator

	local page = make("ScrollingFrame", {
		Active = true,
		AutomaticCanvasSize = Enum.AutomaticSize.None,
		BackgroundColor3 = COLORS.Container,
		BackgroundTransparency = Theme.PanelTransparency,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(),
		ScrollBarImageColor3 = COLORS.Accent,
		ScrollBarThickness = 3,
		Size = UDim2.fromScale(1, 1),
		Visible = false,
	}, self.Content) :: ScrollingFrame
	tab._page = page
	corner(page)
	stroke(page)
	padding(page, Theme.Padding)
	local pageLayout = make("UIListLayout", {
		Padding = UDim.new(0, 10),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, page) :: UIListLayout
	setCanvasHeight(page, pageLayout, 20)

	tab._matches = function(query: string)
		if string.find(string.lower(tab._name), query, 1, true) then return true end
		for _, card in ipairs(tab._cards) do
			if string.find(string.lower(card._searchText), query, 1, true) then return true end
		end
		return false
	end
	tabButton.MouseEnter:Connect(function()
		if self._activeTab ~= tab then tween(tabButton, Theme.HoverDuration, { BackgroundColor3 = COLORS.Interactive }) end
	end)
	tabButton.MouseLeave:Connect(function()
		if self._activeTab ~= tab then tween(tabButton, Theme.HoverDuration, { BackgroundColor3 = COLORS.Container }) end
	end)
	tabButton.MouseButton1Click:Connect(function()
		self:SelectTab(tab)
	end)
	tab:SetBadge(options.Badge)
	table.insert(self._tabs, tab)
	if #self._tabs == 1 then self:SelectTab(tab) end
	self._applySearch()
	return tab
end

function Window:SelectTab(tab: any)
	if self._activeTab == tab then return end
	self._activeTab = tab
	for _, item in ipairs(self._tabs) do
		local active = item == tab
		item._page.Visible = active
		tween(item._button, Theme.HoverDuration, { BackgroundColor3 = active and COLORS.Interactive or COLORS.Container })
		tween(item._indicator, 0.18, { Size = UDim2.new(0, 3, 0, active and 20 or 0) })
		for _, child in ipairs(item._button:GetDescendants()) do
			if child:IsA("TextLabel") and child ~= item.Badge then
				tween(child, Theme.HoverDuration, { TextColor3 = active and COLORS.Text or COLORS.Muted })
			elseif child:IsA("ImageLabel") then
				tween(child, Theme.HoverDuration, { ImageColor3 = active and COLORS.Accent or COLORS.Muted })
			elseif child:IsA("Frame") and child.Name == "HavocIconPart" then
				tween(child, Theme.HoverDuration, { BackgroundColor3 = active and COLORS.Text or COLORS.Muted })
			end
		end
	end
end

function Tab:SetBadge(value: any)
	if value == nil or value == false or value == "" or value == 0 then
		self.Badge.Visible = false
	else
		self.Badge.Text = tostring(value)
		self.Badge.Visible = true
	end
end

function Tab:Section(options: {[string]: any})
	local sectionOptions = if type(options) == "string" then { Name = options } else (options or {})
	local frame = make("Frame", {
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = COLORS.Container,
		BackgroundTransparency = Theme.PanelTransparency,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 0),
	}, self._page) :: Frame
	corner(frame)
	stroke(frame)
	padding(frame, Theme.Padding)
	make("UIGradient", {
		Color = ColorSequence.new(Color3.fromRGB(28, 28, 33), COLORS.Container),
		Rotation = 90,
	}, frame)
	local layout = make("UIListLayout", {
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, frame) :: UIListLayout
	local headingRow = make("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 26),
		LayoutOrder = -1,
	}, frame)
	local icon = iconImage(headingRow, sectionOptions.Icon or sectionOptions.Name or "layers", 16)
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.Position = UDim2.new(0, 8, 0.5, 0)
	icon.Size = UDim2.fromOffset(16, 16)
	local heading = textLabel(headingRow, string.lower(sectionOptions.Name or "Section"), 12, COLORS.Text, Enum.Font.GothamBold)
	heading.Position = UDim2.fromOffset(24, 0)
	heading.Size = UDim2.new(1, -24, 1, 0)
	local divider = make("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundColor3 = COLORS.Border,
		BackgroundTransparency = 0.35,
		BorderSizePixel = 0,
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.new(0.24, 0, 0, 1),
	}, headingRow)
	make("UIGradient", {
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(1, 1),
		}),
	}, divider)
	local section = setmetatable({
		_tab = self,
		_window = self._window,
		_frame = frame,
		_layout = layout,
		_title = sectionOptions.Name or "Section",
	}, Section)
	table.insert(self._sections, section)
	return section
end

function Section:_register(frame: Instance, searchText: string)
	table.insert(self._tab._cards, { _frame = frame, _searchText = self._title .. " " .. searchText })
	self._window._applySearch()
	return frame
end

function Section:Button(options: {[string]: any})
	assert(type(options) == "table" and type(options.Name) == "string", "Button requires a Name")
	local element = Elements.ActionButton(self._frame, options, self._window._library)
	self:_register(element, options.Name)
	return element
end

function Section:Paragraph(options: {[string]: any})
	assert(type(options) == "table" and type(options.Name) == "string", "Paragraph requires a Name")
	local paragraph = make("Frame", {
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
	}, self._frame)
	local title = textLabel(paragraph, options.Name, options.TitleSize or 14, COLORS.Text, Enum.Font.GothamMedium)
	title.Size = UDim2.new(1, 0, 0, 20)
	local content = Elements.Paragraph(paragraph, options)
	local paragraphLayout = make("UIListLayout", {
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, paragraph)
	title.LayoutOrder = 1
	content.LayoutOrder = 2
	paragraphLayout.Name = "ParagraphLayout"
	self:_register(paragraph, options.Name .. " " .. (options.Content or ""))
	return paragraph
end

function Section:Buttons(options: {[string]: any})
	assert(type(options) == "table" and type(options.Buttons) == "table", "Buttons requires a Buttons array")
	local items = options.Buttons
	assert(#items > 0, "Buttons requires at least one button")
	local gap = options.Gap or 8
	local row = make("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, options.Height or 38),
	}, self._frame)
	local layout = make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Left,
		Padding = UDim.new(0, gap),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, row)
	for index, item in ipairs(items) do
		assert(type(item) == "table" and type(item.Name) == "string", "Each button requires a Name")
		local widthScale = 1 / #items
		local buttonOptions = table.clone(item)
		buttonOptions.Size = UDim2.new(widthScale, -gap * (#items - 1) / #items, 0, options.Height or 38)
		Elements.ActionButton(row, buttonOptions, self._window._library).LayoutOrder = index
	end
	layout.Name = "ButtonLayout"
	self:_register(row, options.Name or table.concat((function()
		local names = {}
		for _, item in ipairs(items) do table.insert(names, item.Name) end
		return names
	end)(), " "))
	return row
end

function Section:Row(options: {[string]: any})
	assert(type(options) == "table" and type(options.Items) == "table", "Row requires an Items array")
	local items = options.Items
	assert(#items > 0, "Row requires at least one item")
	local columns = math.clamp(math.floor(options.Columns or #items), 1, #items)
	local gap = options.Gap or 8
	local itemHeight = options.Height or 40
	local row = make("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, itemHeight),
	}, self._frame)
	local grid = make("UIGridLayout", {
		CellPadding = UDim2.fromOffset(gap, gap),
		CellSize = UDim2.new(1 / columns, -gap * (columns - 1) / columns, 0, itemHeight),
		FillDirection = Enum.FillDirection.Horizontal,
		FillDirectionMaxCells = columns,
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, row) :: UIGridLayout
	local function updateRowHeight()
		row.Size = UDim2.new(1, 0, 0, grid.AbsoluteContentSize.Y)
	end
	grid:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateRowHeight)
	updateRowHeight()

	local searchTerms = {}
	for index, item in ipairs(items) do
		assert(type(item) == "table" and type(item.Type) == "string", "Each row item requires a Type")
		assert(type(item.Name) == "string", "Each row item requires a Name")
		local itemType = string.lower(item.Type)
		if itemType == "button" then
			local buttonOptions = table.clone(item)
			buttonOptions.Size = UDim2.new(1, 0, 0, itemHeight)
			Elements.ActionButton(row, buttonOptions, self._window._library).LayoutOrder = index
		elseif itemType == "toggle" then
			local toggleOptions = table.clone(item)
			toggleOptions.Size = UDim2.new(1, 0, 0, itemHeight)
			local toggle = Elements.Toggle(row, toggleOptions, self._window._library)
			toggle.Frame.LayoutOrder = index
		else
			error(string.format("Unsupported row item type %q; use Button or Toggle", item.Type), 2)
		end
		table.insert(searchTerms, item.Name)
	end
	self:_register(row, table.concat(searchTerms, " "))
	return row
end

function Section:Toggle(options: {[string]: any})
	assert(type(options) == "table" and type(options.Name) == "string", "Toggle requires a Name")
	local toggle = Elements.Toggle(self._frame, options, self._window._library)
	self:_register(toggle.Frame, options.Name)
	return toggle
end

function Section:Slider(options: {[string]: any})
	assert(type(options) == "table" and type(options.Name) == "string", "Slider requires a Name")
	local slider = Elements.Slider(self._frame, options, self._window._library, self._window._connections)
	self:_register(slider.Frame, options.Name)
	return slider
end

function Section:Dropdown(options: {[string]: any})
	assert(type(options) == "table" and type(options.Name) == "string", "Dropdown requires a Name")
	local choices = options.Options or {}
	local selected = options.Default
	local expanded = false
	local holder = make("Frame", {
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 36),
	}, self._frame)
	local head = button(holder, options.Name .. "   " .. (selected and tostring(selected) or "Select"), UDim2.new(1, 0, 0, 36))
	head.TextXAlignment = Enum.TextXAlignment.Left
	padding(head, 14, 0)
	local menu = make("Frame", {
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = COLORS.Background,
		BackgroundTransparency = 0.04,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Size = UDim2.new(1, 0, 0, 0),
		Visible = false,
	}, holder)
	menu.Position = UDim2.new(0, 0, 0, 40)
	corner(menu)
	stroke(menu)
	padding(menu, 14)
	local menuLayout = make("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, menu) :: UIListLayout
	local dropdown = { Value = selected, Frame = holder }
	local function setExpanded(state: boolean)
		expanded = state
		menu.Visible = expanded
		if expanded then
			holder.AutomaticSize = Enum.AutomaticSize.None
			local visibleChoices = math.min(#choices, options.MaxVisible or 5)
			local menuHeight = visibleChoices * 32 + 28
			tween(holder, Theme.HoverDuration, {
				Size = UDim2.new(1, 0, 0, 48 + menuHeight),
			})
			menu.Size = UDim2.new(1, 0, 0, menuHeight)
		else
			holder.AutomaticSize = Enum.AutomaticSize.Y
			tween(holder, Theme.HoverDuration, { Size = UDim2.new(1, 0, 0, 36) })
			menu.Size = UDim2.new(1, 0, 0, 0)
		end
	end
	local function setValue(nextValue: any, fireCallback: boolean?)
		selected = nextValue
		dropdown.Value = nextValue
		head.Text = options.Name .. "   " .. tostring(nextValue)
		setExpanded(false)
		if fireCallback ~= false then safeCallback(self._window._library, options.Callback, nextValue) end
	end
	dropdown.Set = function(_, nextValue: any, fireCallback: boolean?)
		setValue(nextValue, fireCallback)
	end
	for _, choice in ipairs(choices) do
		local choiceButton = button(menu, tostring(choice), UDim2.new(1, 0, 0, 28), COLORS.Interactive)
		choiceButton.TextXAlignment = Enum.TextXAlignment.Left
		padding(choiceButton, 12, 0)
		choiceButton.MouseButton1Click:Connect(function() setValue(choice) end)
	end
	head.MouseButton1Click:Connect(function() setExpanded(not expanded) end)
	self:_register(holder, options.Name .. " " .. table.concat((function()
		local strings = {}
		for _, option in ipairs(choices) do table.insert(strings, tostring(option)) end
		return strings
	end)(), " "))
	return dropdown
end

function Section:Keybind(options: {[string]: any})
	assert(type(options) == "table" and type(options.Name) == "string", "Keybind requires a Name")
	local key = options.Default or Enum.KeyCode.Unknown
	local listening = false
	local row = make("Frame", {
		BackgroundColor3 = COLORS.Interactive,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 40),
	}, self._frame)
	corner(row)
	stroke(row)
	local label = textLabel(row, options.Name, 12, COLORS.Text, Enum.Font.GothamMedium)
	label.Position = UDim2.fromOffset(10, 0)
	label.Size = UDim2.new(1, -98, 1, 0)
	local keyButton = button(row, key.Name, UDim2.fromOffset(76, 26))
	keyButton.AnchorPoint = Vector2.new(1, 0.5)
	keyButton.Position = UDim2.new(1, -7, 0.5, 0)
	local keybind = { Value = key, Frame = row }
	local function setKey(nextKey: Enum.KeyCode, fireCallback: boolean?)
		key = nextKey
		keybind.Value = key
		keyButton.Text = key.Name
		if fireCallback ~= false then safeCallback(self._window._library, options.Changed, key) end
	end
	keybind.Set = function(_, nextKey: Enum.KeyCode, fireCallback: boolean?)
		setKey(nextKey, fireCallback)
	end
	keyButton.MouseButton1Click:Connect(function()
		listening = true
		keyButton.Text = "..."
	end)
	local connection = UserInputService.InputBegan:Connect(function(input, processed)
		if listening then
			if input.UserInputType == Enum.UserInputType.Keyboard then
				listening = false
				setKey(input.KeyCode)
			end
			return
		end
		if not processed and input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == key and key ~= Enum.KeyCode.Unknown then
			safeCallback(self._window._library, options.Callback, key)
		end
	end)
	table.insert(self._window._connections, connection)
	self:_register(row, options.Name .. " " .. key.Name)
	return keybind
end

function Section:Input(options: {[string]: any})
	assert(type(options) == "table" and type(options.Name) == "string", "Input requires a Name")
	local multiline = options.Multiline == true
	local row = make("Frame", {
		BackgroundColor3 = COLORS.Interactive,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, multiline and 90 or 62),
	}, self._frame)
	corner(row)
	stroke(row)
	make("UIGradient", {
		Color = ColorSequence.new(Color3.fromRGB(34, 34, 40), COLORS.Interactive),
		Rotation = 90,
	}, row)
	local label = textLabel(row, options.Name, 12, COLORS.Text, Enum.Font.GothamMedium)
	label.Position = UDim2.fromOffset(10, 2)
	label.Size = UDim2.new(1, -20, 0, 22)
	local field = make("TextBox", {
		BackgroundColor3 = COLORS.Background,
		ClearTextOnFocus = false,
		Font = Enum.Font.Gotham,
		MultiLine = multiline,
		PlaceholderColor3 = COLORS.Muted,
		PlaceholderText = options.Placeholder or "Type here...",
		Position = UDim2.new(0, 8, 0, 27),
		Size = UDim2.new(1, -16, 0, multiline and 54 or 27),
		Text = options.Default or "",
		TextColor3 = COLORS.Text,
		TextSize = 11,
		TextWrapped = multiline,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = multiline and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center,
	}, row) :: TextBox
	corner(field)
	stroke(field)
	padding(field, 8, 0)
	field.FocusLost:Connect(function(enterPressed)
		safeCallback(self._window._library, options.Callback, field.Text, enterPressed)
	end)
	local input = { Value = field.Text, Frame = row, TextBox = field }
	field:GetPropertyChangedSignal("Text"):Connect(function()
		input.Value = field.Text
		if multiline then
			local availableWidth = math.max(field.AbsoluteSize.X - 16, 1)
			local measured = TextService:GetTextSize(field.Text, field.TextSize, field.Font, Vector2.new(availableWidth, 1000))
			local height = math.clamp(measured.Y + 16, 54, 240)
			field.Size = UDim2.new(1, -16, 0, height)
			row.Size = UDim2.new(1, 0, 0, height + 36)
		end
	end)
	input.Set = function(_, value: string)
		field.Text = value
	end
	self:_register(row, options.Name .. " " .. (options.Placeholder or ""))
	return input
end

function Section:ColorPicker(options: {[string]: any})
	assert(type(options) == "table" and type(options.Name) == "string", "ColorPicker requires a Name")
	local color = options.Default or COLORS.Accent
	local hue, saturation, brightness = color:ToHSV()
	local expanded = false
	local holder = make("Frame", {
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 36),
	}, self._frame)
	local head = button(holder, options.Name, UDim2.new(1, 0, 0, 36))
	head.TextXAlignment = Enum.TextXAlignment.Left
	padding(head, 14, 0)
	local preview = make("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(22, 18),
	}, head)
	corner(preview)
	stroke(preview)
	local picker = make("Frame", {
		BackgroundColor3 = COLORS.Background,
		BackgroundTransparency = 0.04,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Position = UDim2.new(0, 0, 0, 40),
		Size = UDim2.new(1, 0, 0, 124),
		Visible = false,
	}, holder)
	corner(picker)
	stroke(picker)
	padding(picker, 14)
	local saturationCanvas = make("TextButton", {
		AutoButtonColor = false,
		BackgroundColor3 = Color3.fromHSV(hue, 1, 1),
		BorderSizePixel = 0,
		Size = UDim2.new(1, -26, 1, -16),
		Text = "",
	}, picker) :: TextButton
	corner(saturationCanvas)
	stroke(saturationCanvas)
	make("UIGradient", {
		Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromHSV(hue, 1, 1)),
	}, saturationCanvas)
	local whiteOverlay = make("Frame", {
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
	}, saturationCanvas)
	corner(whiteOverlay)
	make("UIGradient", {
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Rotation = 0,
	}, whiteOverlay)
	local blackOverlay = make("Frame", {
		BackgroundColor3 = Color3.new(0, 0, 0),
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
	}, saturationCanvas)
	corner(blackOverlay)
	make("UIGradient", {
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(1, 0),
		}),
		Rotation = 90,
	}, blackOverlay)
	local selector = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(saturation, 1 - brightness),
		Size = UDim2.fromOffset(10, 10),
	}, saturationCanvas)
	corner(selector)
	stroke(selector)
	local hueBar = make("TextButton", {
		AutoButtonColor = false,
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		Position = UDim2.new(1, -18, 0, 0),
		Size = UDim2.new(0, 10, 1, -16),
		Text = "",
	}, picker) :: TextButton
	corner(hueBar)
	stroke(hueBar)
	make("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
			ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
			ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
			ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
			ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
		}),
		Rotation = 90,
	}, hueBar)
	local hueMarker = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		Position = UDim2.new(0.5, 0, hue, 0),
		Size = UDim2.new(1, 4, 0, 3),
	}, hueBar)
	corner(hueMarker)
	local colorPicker = { Value = color, Frame = holder }
	local function setColor(nextColor: Color3, fireCallback: boolean?)
		color = nextColor
		hue, saturation, brightness = color:ToHSV()
		colorPicker.Value = color
		preview.BackgroundColor3 = color
		saturationCanvas.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
		(saturationCanvas:FindFirstChildOfClass("UIGradient") :: UIGradient).Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromHSV(hue, 1, 1))
		selector.Position = UDim2.fromScale(saturation, 1 - brightness)
		hueMarker.Position = UDim2.new(0.5, 0, hue, 0)
		if fireCallback ~= false then safeCallback(self._window._library, options.Callback, color) end
	end
	colorPicker.Set = function(_, nextColor: Color3, fireCallback: boolean?)
		setColor(nextColor, fireCallback)
	end
	local satDragging = false
	local hueDragging = false
	local function setSaturationAt(input: InputObject)
		local position = saturationCanvas.AbsolutePosition
		local size = saturationCanvas.AbsoluteSize
		saturation = math.clamp((input.Position.X - position.X) / math.max(size.X, 1), 0, 1)
		brightness = 1 - math.clamp((input.Position.Y - position.Y) / math.max(size.Y, 1), 0, 1)
		setColor(Color3.fromHSV(hue, saturation, brightness))
	end
	local function setHueAt(input: InputObject)
		local position = hueBar.AbsolutePosition
		hue = math.clamp((input.Position.Y - position.Y) / math.max(hueBar.AbsoluteSize.Y, 1), 0, 1)
		setColor(Color3.fromHSV(hue, saturation, brightness))
	end
	saturationCanvas.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			satDragging = true
			setSaturationAt(input)
		end
	end)
	hueBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			hueDragging = true
			setHueAt(input)
		end
	end)
	local inputChanged = UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			if satDragging then setSaturationAt(input) elseif hueDragging then setHueAt(input) end
		end
	end)
	local inputEnded = UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			satDragging = false
			hueDragging = false
		end
	end)
	table.insert(self._window._connections, inputChanged)
	table.insert(self._window._connections, inputEnded)
	head.MouseButton1Click:Connect(function()
		expanded = not expanded
		picker.Visible = expanded
		if expanded then
			holder.AutomaticSize = Enum.AutomaticSize.None
			tween(holder, Theme.HoverDuration, { Size = UDim2.new(1, 0, 0, 168) })
		else
			holder.AutomaticSize = Enum.AutomaticSize.Y
			tween(holder, Theme.HoverDuration, { Size = UDim2.new(1, 0, 0, 36) })
		end
	end)
	setColor(color, false)
	self:_register(holder, options.Name)
	return colorPicker
end

function Window:Notify(options: {[string]: any})
	return self._library:Notify(options)
end

function Window:SetVisible(visible: boolean)
	if visible then
		self.Root.Visible = true
		self._scale.Scale = Theme.OpenScale
		self.Root.BackgroundTransparency = 1
		tween(self._scale, Theme.Animation.Open.Time, { Scale = 1 }, Enum.EasingStyle.Back)
		tween(self.Root, Theme.Animation.Fade.Time, { BackgroundTransparency = 0 })
	else
		tween(self._scale, Theme.HoverDuration, { Scale = Theme.OpenScale })
		local fade = tween(self.Root, Theme.Animation.Fade.Time, { BackgroundTransparency = 1 })
		fade.Completed:Once(function()
			self.Root.Visible = false
		end)
	end
end

function HavocLib:Notify(options: {[string]: any})
	assert(type(options) == "table", "Notify requires an options table")
	local title = options.Title or "notification"
	local content = options.Content or ""
	local duration = math.max(tonumber(options.Duration) or 4, 0.5)
	local host = self._notificationHost
	if not host then
		host = make("Frame", {
			AnchorPoint = Vector2.new(1, 1),
			BackgroundTransparency = 1,
			Position = UDim2.new(1, -18, 1, -18),
			Size = UDim2.new(0, 310, 1, -36),
		}, self.ScreenGui)
		self._notificationHost = host
		make("UIListLayout", {
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
			Padding = UDim.new(0, 8),
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Bottom,
		}, host)
	end
	local wrapper = make("Frame", {
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Size = UDim2.new(1, 0, 0, 76),
	}, host)
	local toast = make("Frame", {
		BackgroundColor3 = COLORS.Container,
		BackgroundTransparency = Theme.PanelTransparency,
		BorderSizePixel = 0,
		Position = UDim2.new(1, 20, 0, 0),
		Size = UDim2.fromScale(1, 1),
	}, wrapper)
	corner(toast)
	stroke(toast)
	local accent = make("Frame", {
		BackgroundColor3 = options.Color or COLORS.Accent,
		BorderSizePixel = 0,
		Size = UDim2.new(0, 3, 1, 0),
	}, toast)
	corner(accent)
	stroke(accent)
	local toastTitle = textLabel(toast, tostring(title), 13, COLORS.Text, Enum.Font.GothamBold)
	toastTitle.Position = UDim2.fromOffset(13, 9)
	toastTitle.Size = UDim2.new(1, -24, 0, 20)
	local toastContent = textLabel(toast, tostring(content), 11, COLORS.Muted)
	toastContent.Position = UDim2.fromOffset(13, 30)
	toastContent.Size = UDim2.new(1, -24, 0, 30)
	toastContent.TextWrapped = true
	toastContent.TextYAlignment = Enum.TextYAlignment.Top
	local progress = make("Frame", {
		BackgroundColor3 = options.Color or COLORS.Accent,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 1, -3),
		Size = UDim2.new(1, 0, 0, 3),
	}, toast)
	corner(progress)
	stroke(progress)
	tween(toast, 0.22, { Position = UDim2.fromScale(0, 0) }, Enum.EasingStyle.Quint)
	tween(progress, duration, { Size = UDim2.new(0, 0, 0, 3) }, Enum.EasingStyle.Linear)
	task.delay(duration, function()
		if toast.Parent then
			tween(toast, 0.18, { BackgroundTransparency = 1, Position = UDim2.new(1, 20, 0, 0) })
			for _, child in ipairs(toast:GetDescendants()) do
				if child:IsA("TextLabel") then tween(child, 0.16, { TextTransparency = 1 }) end
				if child:IsA("Frame") then tween(child, 0.16, { BackgroundTransparency = 1 }) end
				if child:IsA("UIStroke") then tween(child, 0.16, { Transparency = 1 }) end
			end
			task.delay(0.2, function()
				if wrapper.Parent then wrapper:Destroy() end
			end)
		end
	end)
	table.insert(self._notifications, wrapper)
	return toast
end

function Window:Destroy()
	self._library:Destroy()
end

function HavocLib:Destroy()
	if self._destroyed then return end
	self._destroyed = true
	for _, connection in ipairs(self.Window._connections) do
		connection:Disconnect()
	end
	self.ScreenGui:Destroy()
end

HavocLib.Colors = COLORS
HavocLib.Theme = Theme
return HavocLib
