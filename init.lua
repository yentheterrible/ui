--!strict
-- Havoc UI — standalone LocalScript.
-- This file contains both the library and the screenshot-matching demo window.

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")
local Workspace = game:GetService("Workspace")

local Theme = {}

Theme.Colors = {
	Background = Color3.fromRGB(17, 17, 18),
	Container = Color3.fromRGB(34, 34, 36),
	Interactive = Color3.fromRGB(40, 40, 42),
	Accent = Color3.fromRGB(231, 231, 233),
	Primary = Color3.fromRGB(219, 219, 223),
	ToggleOn = Color3.fromRGB(218, 218, 222),
	Border = Color3.fromRGB(72, 72, 76),
	Text = Color3.fromRGB(243, 243, 245),
	Muted = Color3.fromRGB(192, 192, 196),
	Icon = Color3.fromRGB(164, 164, 168),
	Success = Color3.fromRGB(220, 220, 226),
}

Theme.CornerRadius = UDim.new(0, 14)
Theme.Stroke = {
	Color = Color3.fromRGB(255, 255, 255),
	Thickness = 1.15,
	Transparency = 0.89,
	ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	LineJoinMode = Enum.LineJoinMode.Round,
}
Theme.PanelTransparency = 0.04
Theme.HoverDuration = 0.18
Theme.PressScale = 0.975
Theme.OpenScale = 0.97
Theme.Padding = 16
Theme.Animation = {
	Hover = TweenInfo.new(Theme.HoverDuration, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
	Press = TweenInfo.new(0.12, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
	Release = TweenInfo.new(0.24, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
	Open = TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
	Fade = TweenInfo.new(0.26, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
}

local Elements = (function()
	local TweenService = game:GetService("TweenService")
	local UserInputService = game:GetService("UserInputService")
	local COLORS = Theme.Colors
	local componentElements = {}

	function componentElements.Make(className: string, properties: {[string]: any}, parent: Instance?): Instance
		local object = Instance.new(className)
		if object:IsA("GuiObject") then
			object.BorderSizePixel = 0
		end
		for key, value in pairs(properties) do
			(object :: any)[key] = value
		end
		object.Parent = parent
		return object
	end

	function componentElements.GradientTint(baseColor: Color3, targetColor: Color3): Color3
		local function channel(target: number, base: number): number
			if base == 0 then
				return 1
			end
			return math.clamp(target / base, 0, 1)
		end
		return Color3.new(
			channel(targetColor.R, baseColor.R),
			channel(targetColor.G, baseColor.G),
			channel(targetColor.B, baseColor.B)
		)
	end

	function componentElements.Gradient(parent: Instance, baseColor: Color3, targetColor: Color3, rotation: number?)
		return componentElements.Make("UIGradient", {
			Color = ColorSequence.new(
				Color3.new(1, 1, 1),
				componentElements.GradientTint(baseColor, targetColor)
			),
			Rotation = rotation or 90,
		}, parent)
	end

	function componentElements.Corner(parent: Instance, radius: number?)
		return componentElements.Make("UICorner", {
			CornerRadius = UDim.new(0, radius or Theme.CornerRadius.Offset),
		}, parent)
	end

	function componentElements.Stroke(parent: Instance, transparency: number?)
		local properties = table.clone(Theme.Stroke)
		if transparency ~= nil then
			properties.Transparency = transparency
		end
		return componentElements.Make("UIStroke", properties, parent)
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
			TweenInfo.new(duration, style or Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
			properties
		)
		animation:Play()
		return animation
	end

	function componentElements.AddPressFeedback(button: GuiButton, scaleTarget: GuiObject?)
		local scale = componentElements.Make("UIScale", { Scale = 1 }, scaleTarget or button)
		local baseColor = button.BackgroundColor3
		local buttonStroke = button:FindFirstChildOfClass("UIStroke")
		local baseStrokeColor = if buttonStroke then buttonStroke.Color else COLORS.Border
		button.MouseEnter:Connect(function()
			componentElements.Tween(button, Theme.HoverDuration, {
				BackgroundColor3 = baseColor:Lerp(Color3.new(1, 1, 1), 0.08),
			})
			if buttonStroke then
				componentElements.Tween(buttonStroke, Theme.HoverDuration, {
					Color = baseStrokeColor:Lerp(Color3.new(1, 1, 1), 0.18),
					Transparency = 0.84,
				})
			end
		end)
		button.MouseLeave:Connect(function()
			componentElements.Tween(button, Theme.HoverDuration, { BackgroundColor3 = baseColor })
			if buttonStroke then
				componentElements.Tween(buttonStroke, Theme.HoverDuration, {
					Color = baseStrokeColor,
					Transparency = Theme.Stroke.Transparency,
				})
			end
		end)
		button.MouseButton1Down:Connect(function()
			componentElements.Tween(scale, Theme.Animation.Press.Time, { Scale = Theme.PressScale }, Enum.EasingStyle.Quint)
		end)
		local function release()
			componentElements.Tween(scale, Theme.Animation.Release.Time, { Scale = 1 }, Enum.EasingStyle.Quint)
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
			TextSize = 12,
		}, parent) :: TextButton
		componentElements.Corner(element, 10)
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
			textColor = Color3.fromRGB(27, 27, 29)
		end
		local size = options.Size or UDim2.new(1, 0, 0, options.Height or 34)
		local element = componentElements.Button(parent, options.Name, size, backgroundColor)
		element.BackgroundColor3 = backgroundColor
		element.TextColor3 = textColor
		element.Font = Enum.Font.GothamBold
		element.TextSize = 12
		local gradientShade = if luminance > 0.55 then 0.08 else 0.23
		componentElements.Gradient(element, backgroundColor, backgroundColor:Lerp(Color3.new(0, 0, 0), gradientShade))
		element.TextXAlignment = Enum.TextXAlignment.Center
		element.MouseButton1Click:Connect(function()
			componentElements.SafeCallback(owner, options.Callback)
		end)
		return element
	end

	function componentElements.Paragraph(parent: Instance, options: {[string]: any})
		local content = componentElements.Make("TextLabel", {
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Font = Enum.Font.Gotham,
			LayoutOrder = options.LayoutOrder or 0,
			Size = UDim2.new(1, 0, 0, 0),
			Text = options.Content or "",
			TextColor3 = options.Color or Color3.fromRGB(202, 202, 206),
			TextSize = options.TextSize or 14,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
		}, parent)
		return content
	end

	function componentElements.Toggle(parent: Instance, options: {[string]: any}, owner: any)
		local value = options.Default == true
		local row = componentElements.Make("Frame", {
			BackgroundColor3 = COLORS.Interactive,
			BorderSizePixel = 0,
			Size = options.Size or UDim2.new(1, 0, 0, 50),
		}, parent)
		componentElements.Corner(row, 12)
		local rowStroke = componentElements.Stroke(row, 0.93)
		componentElements.Gradient(row, COLORS.Interactive, Color3.fromRGB(34, 34, 36))
		local label = componentElements.TextLabel(row, options.Name, 13, Color3.fromRGB(213, 213, 216), Enum.Font.GothamMedium)
		label.Position = UDim2.fromOffset(14, 0)
		label.Size = UDim2.new(1, -76, 1, 0)
		local track = componentElements.Make("Frame", {
			AnchorPoint = Vector2.new(1, 0.5),
			BackgroundColor3 = value and COLORS.ToggleOn or Color3.fromRGB(69, 69, 73),
			BorderSizePixel = 0,
			Position = UDim2.new(1, -17, 0.5, 0),
			Size = UDim2.fromOffset(44, 26),
		}, row)
		componentElements.Corner(track, 13)
		local trackStroke = componentElements.Stroke(track, 0)
		trackStroke.Color = Color3.fromRGB(74, 74, 77)
		componentElements.Gradient(track, Color3.fromRGB(69, 69, 73), Color3.fromRGB(60, 60, 63))
		local onTrack = componentElements.Make("Frame", {
			BackgroundColor3 = COLORS.ToggleOn,
			BackgroundTransparency = value and 0 or 1,
			BorderSizePixel = 0,
			Size = UDim2.fromScale(1, 1),
		}, track)
		componentElements.Corner(onTrack, 13)
		componentElements.Gradient(onTrack, COLORS.ToggleOn, Color3.fromRGB(192, 192, 196))
		local knob = componentElements.Make("Frame", {
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundColor3 = Color3.fromRGB(238, 238, 240),
			BorderSizePixel = 0,
			Position = value and UDim2.new(1, -17, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
			Size = UDim2.fromOffset(12, 12),
		}, track)
		componentElements.Corner(knob, 6)
		componentElements.Stroke(knob, 0.94)
		local hitbox = componentElements.Make("TextButton", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Text = "",
		}, row) :: TextButton
		componentElements.Corner(hitbox)
		componentElements.AddPressFeedback(hitbox, row)
		local toggle = { Value = value, Frame = row }
		local function setValue(nextValue: boolean, fireCallback: boolean?)
			value = nextValue == true
			toggle.Value = value
			componentElements.Tween(onTrack, Theme.HoverDuration, {
				BackgroundTransparency = value and 0 or 1,
			})
			componentElements.Tween(trackStroke, Theme.HoverDuration, {
				Color = value and Color3.fromRGB(190, 190, 194) or Color3.fromRGB(74, 74, 77),
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
			componentElements.Tween(row, Theme.HoverDuration, { BackgroundColor3 = Color3.fromRGB(43, 43, 45) })
			componentElements.Tween(rowStroke, Theme.HoverDuration, { Transparency = 0.89 })
		end)
		hitbox.MouseLeave:Connect(function()
			componentElements.Tween(row, Theme.HoverDuration, { BackgroundColor3 = COLORS.Interactive })
			componentElements.Tween(rowStroke, Theme.HoverDuration, { Transparency = Theme.Stroke.Transparency })
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
			Size = UDim2.new(1, 0, 0, 56),
		}, parent)
		componentElements.Corner(row, 10)
		componentElements.Stroke(row)
		componentElements.Gradient(row, COLORS.Interactive, Color3.fromRGB(39, 39, 42))
		local name = componentElements.TextLabel(row, options.Name, 11, COLORS.Text, Enum.Font.GothamMedium)
		name.Position = UDim2.fromOffset(14, 4)
		name.Size = UDim2.new(1, -100, 0, 22)
		local valueBox = componentElements.Make("TextBox", {
			AnchorPoint = Vector2.new(1, 0),
			BackgroundColor3 = COLORS.Background,
			Font = Enum.Font.Gotham,
			Position = UDim2.new(1, -12, 0, 5),
			Size = UDim2.fromOffset(56, 20),
			Text = tostring(value),
			TextColor3 = COLORS.Text,
			TextSize = 12,
		}, row) :: TextBox
		componentElements.Corner(valueBox, 20)
		componentElements.Stroke(valueBox)
		local bar = componentElements.Make("Frame", {
			BackgroundColor3 = COLORS.Background,
			BorderSizePixel = 0,
			Position = UDim2.new(0, 12, 0, 36),
			Size = UDim2.new(1, -24, 0, 5),
		}, row)
		componentElements.Corner(bar, 20)
		componentElements.Stroke(bar)
		local fill = componentElements.Make("Frame", {
			BackgroundColor3 = COLORS.Primary,
			BorderSizePixel = 0,
			Size = UDim2.new((value - minimum) / (maximum - minimum), 0, 1, 0),
		}, bar)
		componentElements.Corner(fill, 20)
		local thumb = componentElements.Make("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(248, 248, 249),
			BorderSizePixel = 0,
			Position = UDim2.new(1, 0, 0.5, 0),
			Size = UDim2.fromOffset(14, 14),
			ZIndex = bar.ZIndex + 2,
		}, fill)
		componentElements.Corner(thumb, 7)
		componentElements.Stroke(thumb, 0.9)
		local sliderButton = componentElements.Make("TextButton", {
			Active = true,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 28),
			Position = UDim2.new(0, 0, 0, 29),
			Text = "",
		}, row) :: TextButton
		componentElements.Corner(sliderButton)
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
			componentElements.Tween(fill, 0.18, { Size = UDim2.new(alpha, 0, 1, 0) }, Enum.EasingStyle.Quint)
			thumb.Position = UDim2.new(1, 0, 0.5, 0)
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
		if type(icon) == "string" and icon:match("^https?://") then
			error("Icon image URLs must be uploaded to Roblox and passed as an asset ID", 2)
		end
		if type(icon) == "string" and icon:match("^rbxassetid://%d+$") then
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
				local segment = componentElements.Make("Frame", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundColor3 = COLORS.Icon,
					BorderSizePixel = 0,
					Name = "HavocIconPart",
					Position = UDim2.fromOffset(x, y),
					Rotation = rotation,
					Size = UDim2.fromOffset(width, height),
				}, drawing)
				componentElements.Corner(segment, math.min(width, height) / 2)
				return segment
			end
			line(iconSize * 0.34, iconSize * 0.35, iconSize * 0.43, 1.3, -38)
			line(iconSize * 0.66, iconSize * 0.35, iconSize * 0.43, 1.3, 38)
			line(iconSize * 0.29, iconSize * 0.67, 1.3, iconSize * 0.36, 0)
			line(iconSize * 0.71, iconSize * 0.67, 1.3, iconSize * 0.36, 0)
			line(iconSize * 0.5, iconSize * 0.88, iconSize * 0.44, 1.3, 0)
			line(iconSize * 0.5, iconSize * 0.81, 1.2, iconSize * 0.2, 0)
			return homeIcon
		end
		if normalizedIcon == "aimbot" or normalizedIcon == "silent"
			or normalizedIcon == "aim" or normalizedIcon == "target" or normalizedIcon == "combat" then
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
				local segment = componentElements.Make("Frame", {
					BackgroundColor3 = COLORS.Icon,
					BorderSizePixel = 0,
					Name = "HavocIconPart",
					Position = UDim2.fromOffset(x, y),
					Size = UDim2.fromOffset(width, height),
				}, crosshair)
				componentElements.Corner(segment, math.min(width, height) / 2)
			end
			tick(size * 0.5 - 0.6, size * 0.08, 1.2, size * 0.18)
			tick(size * 0.5 - 0.6, size * 0.74, 1.2, size * 0.18)
			tick(size * 0.08, size * 0.5 - 0.6, size * 0.18, 1.2)
			tick(size * 0.74, size * 0.5 - 0.6, size * 0.18, 1.2)
			return crosshair
		end
		if normalizedIcon == "settings" or normalizedIcon == "general" or normalizedIcon == "exploits"
			or normalizedIcon == "movement" or normalizedIcon == "esp"
			or normalizedIcon == "sparkles" or normalizedIcon == "custom" then
			local iconRoot = componentElements.Make("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.fromOffset(size, size),
			}, parent)
			local function part(width: number, height: number, x: number, y: number, rotation: number?)
				local segment = componentElements.Make("Frame", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundColor3 = COLORS.Icon,
					BorderSizePixel = 0,
					Name = "HavocIconPart",
					Position = UDim2.fromScale(x, y),
					Rotation = rotation or 0,
					Size = UDim2.fromOffset(width, height),
				}, iconRoot)
				componentElements.Corner(segment, math.min(width, height) / 2)
				return segment
			end
			if normalizedIcon == "settings" or normalizedIcon == "general" then
				local ring = componentElements.Make("Frame", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundTransparency = 1,
					Position = UDim2.fromScale(0.5, 0.5),
					Size = UDim2.fromOffset(size * 0.48, size * 0.48),
				}, iconRoot)
				componentElements.Corner(ring, size)
				componentElements.Make("UIStroke", {
					Color = COLORS.Muted,
					Thickness = 1.3,
				}, ring)
				part(size * 0.16, size * 0.16, 0.5, 0.5)
				part(size * 0.13, size * 0.2, 0.5, 0.1)
				part(size * 0.13, size * 0.2, 0.5, 0.9)
				part(size * 0.2, size * 0.13, 0.1, 0.5)
				part(size * 0.2, size * 0.13, 0.9, 0.5)
				part(size * 0.13, size * 0.2, 0.23, 0.23, 45)
				part(size * 0.13, size * 0.2, 0.77, 0.23, -45)
				part(size * 0.13, size * 0.2, 0.23, 0.77, -45)
				part(size * 0.13, size * 0.2, 0.77, 0.77, 45)
			elseif normalizedIcon == "exploits" then
				part(size * 0.78, 1.5, 0.5, 0.5, 45)
				part(size * 0.78, 1.5, 0.5, 0.5, -45)
				part(size * 0.18, 2, 0.19, 0.19, 45)
				part(size * 0.18, 2, 0.81, 0.19, -45)
			elseif normalizedIcon == "movement" then
				part(size * 0.62, 2, 0.42, 0.58, -45)
				part(size * 0.3, 2, 0.68, 0.29, 45)
				part(size * 0.3, 2, 0.79, 0.4, -45)
			elseif normalizedIcon == "esp" then
				local diamond = part(size * 0.52, size * 0.52, 0.5, 0.5, 45)
				diamond.BackgroundTransparency = 1
				componentElements.Make("UIStroke", {
					Color = COLORS.Muted,
					Thickness = 1.2,
				}, diamond)
				part(size * 0.14, size * 0.14, 0.5, 0.5)
			else
				part(1.4, size * 0.76, 0.5, 0.5)
				part(size * 0.76, 1.4, 0.5, 0.5)
				part(size * 0.12, size * 0.12, 0.15, 0.2)
				part(size * 0.12, size * 0.12, 0.85, 0.8)
			end
			return iconRoot
		end
		if normalizedIcon == "info" then
			local infoIcon = componentElements.Make("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.fromOffset(size, size),
			}, parent)
			local ring = componentElements.Make("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromOffset(size * 0.78, size * 0.78),
			}, infoIcon)
			componentElements.Corner(ring, size)
			componentElements.Make("UIStroke", {
				Color = COLORS.Muted,
				Thickness = 1.2,
			}, ring)
			local dot = componentElements.Make("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = COLORS.Muted,
				BorderSizePixel = 0,
				Name = "HavocIconPart",
				Position = UDim2.fromScale(0.5, 0.3),
				Size = UDim2.fromOffset(1.5, 1.5),
			}, infoIcon)
			componentElements.Corner(dot, 1)
			local stem = componentElements.Make("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = COLORS.Muted,
				BorderSizePixel = 0,
				Name = "HavocIconPart",
				Position = UDim2.fromScale(0.5, 0.6),
				Size = UDim2.fromOffset(1.5, size * 0.28),
			}, infoIcon)
			componentElements.Corner(stem, 1)
			return infoIcon
		end
		local namedIcons = {
			aim = "◎",
			bell = "♧",
			bolt = "ϟ",
			bookmark = "◇",
			combat = "◎",
			check = "✓",
			esp = "◈",
			exploits = "×",
			eye = "◉",
			general = "☷",
			info = "i",
			layers = "▤",
			lightning = "ϟ",
			list = "≡",
			movement = "↗",
			person = "♙",
			search = "⌕",
			settings = "○",
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
			iconText = namedIcons[normalizedIcon] or (icon:match("^[%a%s_%-]+$") and "" or icon)
		end
		local label = componentElements.TextLabel(parent, iconText, size, COLORS.Muted, Enum.Font.GothamMedium)
		label.TextXAlignment = Enum.TextXAlignment.Center
		return label
	end

	return componentElements
end)()

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

local function encodeConfigValue(value: any): any
	local valueType = typeof(value)
	if valueType == "Color3" then
		return {
			__havocType = "Color3",
			R = value.R,
			G = value.G,
			B = value.B,
		}
	elseif valueType == "EnumItem" and value.EnumType == Enum.KeyCode then
		return {
			__havocType = "KeyCode",
			Name = value.Name,
		}
	elseif valueType == "string" or valueType == "number" or valueType == "boolean" then
		return value
	end
	error("Unsupported configuration value type: " .. valueType, 2)
end

local function decodeConfigValue(value: any, expectedType: string): any
	if expectedType == "Color3" then
		assert(type(value) == "table" and value.__havocType == "Color3", "Invalid saved Color3 value")
		assert(type(value.R) == "number" and type(value.G) == "number" and type(value.B) == "number", "Invalid saved Color3 channels")
		return Color3.new(value.R, value.G, value.B)
	elseif expectedType == "EnumItem" then
		assert(type(value) == "table" and value.__havocType == "KeyCode", "Invalid saved keybind value")
		assert(type(value.Name) == "string", "Invalid saved keybind name")
		local keyCode = Enum.KeyCode[value.Name]
		assert(keyCode ~= nil, "Unknown saved keybind: " .. value.Name)
		return keyCode
	end
	assert(typeof(value) == expectedType, "Saved value type does not match control type")
	return value
end

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
	self._settings = {}
	self._configurationSaving = config.ConfigurationSaving or { Enabled = false }
	if self._configurationSaving.Enabled then
		local store = self._configurationSaving.Store
		assert(type(store) == "table", "ConfigurationSaving.Store is required when configuration saving is enabled")
		assert(type(store.Save) == "function", "ConfigurationSaving.Store.Save must be a function")
		assert(type(store.Load) == "function", "ConfigurationSaving.Store.Load must be a function")
	end

	local screen = make("ScreenGui", {
		Name = config.Name or "havoc lib",
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}, playerGui) :: ScreenGui
	self.ScreenGui = screen

	local backdrop = make("Frame", {
		Active = false,
		BackgroundColor3 = Color3.fromRGB(8, 8, 9),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
	}, screen) :: Frame

	local window = setmetatable({
		_library = self,
		_tabs = {},
		_connections = {},
		_visible = true,
	}, Window)
	self.Window = window
	window.Backdrop = backdrop

	local requestedWindowSize = config.Size or UDim2.fromOffset(640, 496)
	local root = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = COLORS.Background,
		BorderSizePixel = 0,
		Position = config.Position or UDim2.fromScale(0.5, 0.5),
		Size = requestedWindowSize,
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
		local requestedWidth = requestedWindowSize.X.Scale * viewport.X + requestedWindowSize.X.Offset
		local requestedHeight = requestedWindowSize.Y.Scale * viewport.Y + requestedWindowSize.Y.Offset
		local maxWidth = math.min(760, math.max(1, viewport.X - 12))
		local maxHeight = math.min(600, math.max(1, viewport.Y - 12))
		root.Size = UDim2.fromOffset(
			math.clamp(requestedWidth, 1, maxWidth),
			math.clamp(requestedHeight, 1, maxHeight)
		)
		responsiveScale.Scale = 1
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
	root.ClipsDescendants = true
	corner(root, 18)
	local rootStroke = stroke(root, 0)
	rootStroke.Color = Color3.fromRGB(48, 48, 51)
	rootStroke.Transparency = 1
	window._stroke = rootStroke
	Elements.Gradient(root, COLORS.Background, Color3.fromRGB(12, 12, 13), 145)
	local rootScale = make("UIScale", { Scale = Theme.OpenScale }, root) :: UIScale
	window._scale = rootScale
	window._open = true

	local header = make("Frame", {
		BackgroundColor3 = Color3.fromRGB(22, 22, 23),
		ClipsDescendants = true,
		Position = UDim2.fromScale(0, 0),
		Size = UDim2.new(1, 0, 0, 55),
	}, root)
	window.Header = header
	corner(header, 18)
	padding(header, 12, 0)
	Elements.Gradient(header, Color3.fromRGB(22, 22, 23), Color3.fromRGB(17, 17, 18))
	make("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.93,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 1, 0),
		Size = UDim2.new(1, 0, 0, 1),
	}, header)
	local configuredLogo = if config.Logo == nil then 81325599465401 else config.Logo
	if configuredLogo ~= nil then
		local logoAsset: string?
		if type(configuredLogo) == "number" and configuredLogo > 0 and configuredLogo % 1 == 0 then
			logoAsset = "rbxassetid://" .. tostring(configuredLogo)
		elseif type(configuredLogo) == "string" then
			local numericId = string.match(configuredLogo, "^%d+$")
			local assetUri = string.match(configuredLogo, "^rbxassetid://%d+$")
			logoAsset = numericId and ("rbxassetid://" .. numericId) or assetUri
		end
		assert(logoAsset, "Logo must be a positive Roblox asset ID or rbxassetid:// URI")
		local logoImage = make("ImageLabel", {
			BackgroundColor3 = COLORS.Interactive,
			BorderSizePixel = 0,
			Image = logoAsset,
			ScaleType = Enum.ScaleType.Crop,
			Size = UDim2.fromOffset(28, 28),
		}, header) :: ImageLabel
		logoImage.AnchorPoint = Vector2.new(0, 0.5)
		logoImage.Position = UDim2.new(0, 12, 0.5, 0)
		corner(logoImage)
		local logoCorner = logoImage:FindFirstChildOfClass("UICorner")
		if logoCorner then logoCorner.CornerRadius = UDim.new(0, 6) end
		stroke(logoImage)
	else
		local logo = make("Frame", {
			BackgroundColor3 = COLORS.Interactive,
			BorderSizePixel = 0,
			Size = UDim2.fromOffset(28, 28),
		}, header)
		logo.AnchorPoint = Vector2.new(0, 0.5)
		logo.Position = UDim2.new(0, 12, 0.5, 0)
		corner(logo, 6)
		stroke(logo)
		local monogram = textLabel(logo, "h", 18, COLORS.Text, Enum.Font.GothamBold)
		monogram.Size = UDim2.fromScale(1, 1)
		monogram.TextXAlignment = Enum.TextXAlignment.Center
	end
	local title = textLabel(header, config.Title or "havoc lib", 16, COLORS.Text, Enum.Font.GothamBold)
	title.Position = UDim2.fromOffset(50, 7)
	title.Size = UDim2.new(0.25, 0, 0, 19)
	local subtitle = textLabel(header, config.Subtitle or "made by convict", 11, Color3.fromRGB(194, 194, 198))
	subtitle.Position = UDim2.fromOffset(50, 27)
	subtitle.Size = UDim2.new(0.25, 0, 0, 15)
	local version = textLabel(header, config.Version or "v0.1.0", 11, COLORS.Muted, Enum.Font.GothamMedium)
	version.AnchorPoint = Vector2.new(0, 0.5)
	version.Position = UDim2.new(0, 170, 0.5, 0)
	version.Size = UDim2.fromOffset(58, 28)
	version.BackgroundColor3 = COLORS.Interactive
	version.TextColor3 = Color3.fromRGB(232, 232, 235)
	corner(version)
	stroke(version, 0.78)
	Elements.Gradient(version, Color3.fromRGB(45, 45, 48), Color3.fromRGB(37, 37, 39), 90)
	version.TextXAlignment = Enum.TextXAlignment.Center
	version.Font = Enum.Font.GothamMedium

	local search = make("TextBox", {
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundColor3 = COLORS.Interactive,
		ClearTextOnFocus = false,
		Font = Enum.Font.Gotham,
		PlaceholderColor3 = COLORS.Muted,
		PlaceholderText = "search components...",
		Position = UDim2.new(1, -102, 0.5, 0),
		Size = UDim2.new(0.34, 0, 0, 30),
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
	Position = UDim2.new(1, -12, 0.5, 0),
		Size = UDim2.fromOffset(82, 26),
	}, header)
	local actionsLayout = make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, windowActions)
	local minimizeButton = button(windowActions, "−", UDim2.fromOffset(24, 26), COLORS.Interactive)
	minimizeButton.TextSize = 16
	minimizeButton.LayoutOrder = 1
	local maximizeButton = button(windowActions, "□", UDim2.fromOffset(24, 26), COLORS.Interactive)
	maximizeButton.Text = ""
	maximizeButton.LayoutOrder = 2
	local maximizeGlyph = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(9, 9),
	}, maximizeButton)
	corner(maximizeGlyph, 2)
	stroke(maximizeGlyph, 0.22)
	local closeButton = button(windowActions, "×", UDim2.fromOffset(24, 26), COLORS.Interactive)
	closeButton.TextSize = 16
	closeButton.LayoutOrder = 3
	for _, actionButton in ipairs({ minimizeButton, maximizeButton, closeButton }) do
		actionButton.BackgroundTransparency = 1
		actionButton.TextColor3 = Color3.fromRGB(228, 228, 231)
		local actionStroke = actionButton:FindFirstChildOfClass("UIStroke")
		if actionStroke then actionStroke.Transparency = 1 end
		local actionCorner = actionButton:FindFirstChildOfClass("UICorner")
		if actionCorner then actionCorner.CornerRadius = UDim.new(0, 9) end
		actionButton.MouseEnter:Connect(function()
			tween(actionButton, Theme.HoverDuration, {
				BackgroundColor3 = Color3.fromRGB(48, 48, 51),
				BackgroundTransparency = 0,
				TextColor3 = COLORS.Text,
			})
			if actionStroke then
				tween(actionStroke, Theme.HoverDuration, { Transparency = 0.93 })
			end
		end)
		actionButton.MouseLeave:Connect(function()
			tween(actionButton, Theme.HoverDuration, { BackgroundTransparency = 1 })
			if actionStroke then
				tween(actionStroke, Theme.HoverDuration, { Transparency = 1 })
			end
		end)
	end
	window._expandedSize = root.Size
	window._expandedPosition = root.Position
	window._minimized = false
	window._maximized = false

	local body = make("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, 55),
		Size = UDim2.new(1, 0, 1, config.ShowMetrics == true and -85 or -55),
	}, root)
	window.Body = body
	local sidebar = make("Frame", {
		BackgroundColor3 = Color3.fromRGB(17, 17, 18),
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		Position = UDim2.fromScale(0, 0),
		Size = UDim2.new(0.356, 0, 1, 0),
	}, body)
	Elements.Gradient(sidebar, Color3.fromRGB(17, 17, 18), Color3.fromRGB(15, 15, 16), 90)
	local tabList = make("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(10, 13),
		Size = UDim2.new(1, -20, 1, -26),
	}, sidebar)
	local tabLayout = make("UIListLayout", {
		Padding = UDim.new(0, 1),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, tabList) :: UIListLayout
	window._tabList = tabList

	local content = make("Frame", {
		BackgroundColor3 = Color3.fromRGB(27, 27, 28),
		BackgroundTransparency = 0,
		Position = UDim2.new(0.356, 0, 0, 0),
		Size = UDim2.new(0.644, 0, 1, 0),
	}, body)
	Elements.Gradient(content, Color3.fromRGB(27, 27, 28), Color3.fromRGB(25, 25, 26), 145)
	window.Content = content
	make("Frame", {
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.93,
		BorderSizePixel = 0,
		Position = UDim2.new(0.356, -1, 0, 0),
		Size = UDim2.new(0, 1, 1, 0),
	}, body)

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
	backdrop.BackgroundTransparency = 1
	tween(backdrop, Theme.Animation.Fade.Time, { BackgroundTransparency = 0.42 })
	minimizeButton.MouseButton1Click:Connect(function()
		window._minimized = not window._minimized
		if window._minimized then
			window._expandedSize = root.Size
			window._wasMetricsVisible = status.Visible
			body.Visible = false
			status.Visible = false
			tween(root, Theme.HoverDuration, { Size = UDim2.new(root.Size.X.Scale, root.Size.X.Offset, 0, 55) })
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
			maximizeGlyph.Size = UDim2.fromOffset(9, 9)
		else
			window._expandedSize = root.Size
			window._expandedPosition = root.Position
			window._maximized = true
			tween(root, Theme.HoverDuration, {
				Size = UDim2.new(0.9, 0, 0.88, 0),
				Position = UDim2.fromScale(0.5, 0.5),
			})
			maximizeGlyph.Size = UDim2.fromOffset(8, 8)
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
		for index, tab in ipairs(window._tabs) do
			if tab._caption then
				local groupHasVisibleTab = false
				for candidateIndex = index, #window._tabs do
					local candidate = window._tabs[candidateIndex]
					if candidateIndex > index and candidate._caption then
						break
					end
					if candidate._button.Visible then
						groupHasVisibleTab = true
						break
					end
				end
				tab._caption.Visible = groupHasVisibleTab
			end
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
			if tab._emptyState then
				tab._emptyState.Visible = tab._page.Visible and #tab._cards == 0
			end
		end
	end
	search:GetPropertyChangedSignal("Text"):Connect(window._applySearch)

	if self._configurationSaving.Enabled then
		window:_CreateConfigManager(self._configurationSaving)
	end

	tween(rootScale, Theme.Animation.Open.Time, { Scale = 1 }, Enum.EasingStyle.Quint)
	root.BackgroundTransparency = 1
	tween(root, Theme.Animation.Fade.Time, { BackgroundTransparency = 0 })
	tween(rootStroke, Theme.Animation.Fade.Time, { Transparency = 0 })
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
	if type(options.CaptionBefore) == "string" and options.CaptionBefore ~= "" then
		local caption = make("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 40),
		}, self._tabList) :: Frame
		local captionLabel = textLabel(caption, options.CaptionBefore, 12, Color3.fromRGB(164, 164, 168))
		captionLabel.Position = UDim2.new(0, 10, 0, 11)
		captionLabel.Size = UDim2.new(1, -16, 0, 16)
		tab._caption = caption
	end

	local tabButton = make("TextButton", {
		AutoButtonColor = false,
		BackgroundColor3 = COLORS.Container,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 42),
		Text = "",
	}, self._tabList) :: TextButton
	tab._button = tabButton
	tabButton.BackgroundColor3 = Color3.fromRGB(32, 32, 34)
	tabButton.BackgroundTransparency = 1
	Elements.Gradient(tabButton, Color3.fromRGB(41, 41, 44), Color3.fromRGB(35, 35, 38), 100)
	local tabScale = make("UIScale", { Scale = 1 }, tabButton)
	tabButton.MouseButton1Down:Connect(function()
		tween(tabScale, Theme.Animation.Press.Time, { Scale = Theme.PressScale }, Enum.EasingStyle.Quint)
	end)
	local function releaseTabPress()
		tween(tabScale, Theme.Animation.Release.Time, { Scale = 1 }, Enum.EasingStyle.Quint)
	end
	tabButton.MouseButton1Up:Connect(releaseTabPress)
	tabButton.MouseButton1Click:Connect(releaseTabPress)
	corner(tabButton)
	local tabCorner = tabButton:FindFirstChildOfClass("UICorner")
		if tabCorner then tabCorner.CornerRadius = UDim.new(0, 12) end
	local tabStroke = stroke(tabButton)
	tabStroke.Transparency = 1
	local icon = iconImage(tabButton, options.Icon or options.Name, 18)
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
		icon.Position = UDim2.new(0, 20, 0.5, 0)
		icon.Size = UDim2.fromOffset(18, 18)
		local label = textLabel(tabButton, string.lower(options.Name), 14, COLORS.Muted, Enum.Font.GothamMedium)
		label.Position = UDim2.fromOffset(44, 0)
	label.Size = UDim2.new(1, -65, 1, 0)
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
	indicator.Visible = false
	tab._indicator = indicator

	local page = make("ScrollingFrame", {
		Active = true,
		AutomaticCanvasSize = Enum.AutomaticSize.None,
		BackgroundColor3 = Color3.fromRGB(27, 27, 28),
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(),
		ScrollBarImageColor3 = Color3.fromRGB(70, 70, 73),
		ScrollBarThickness = 3,
		Size = UDim2.fromScale(1, 1),
		Visible = false,
	}, self.Content) :: ScrollingFrame
	tab._page = page
	Elements.Gradient(page, Color3.fromRGB(27, 27, 28), Color3.fromRGB(25, 25, 26), 145)
	if type(options.EmptyText) == "string" and options.EmptyText ~= "" then
		local emptyState = make("Frame", {
			Active = false,
			BackgroundTransparency = 1,
			Position = page.Position,
			Size = page.Size,
			Visible = false,
			ZIndex = page.ZIndex + 1,
		}, self.Content) :: Frame
		local emptyLabel = textLabel(emptyState, options.EmptyText, 11, Color3.fromRGB(171, 171, 176))
		emptyLabel.ZIndex = emptyState.ZIndex + 1
		emptyLabel.AnchorPoint = Vector2.new(0.5, 0.5)
		emptyLabel.Position = UDim2.fromScale(0.5, 0.5)
		emptyLabel.Size = UDim2.new(1, -32, 0, 24)
		emptyLabel.TextXAlignment = Enum.TextXAlignment.Center
		tab._emptyState = emptyState
	end
	local pageInsets = padding(page, 26, 43) :: UIPadding
	pageInsets.PaddingLeft = UDim.new(0.063, 0)
	pageInsets.PaddingRight = UDim.new(0.063, 0)
	pageInsets.PaddingTop = UDim.new(0.098, 0)
	pageInsets.PaddingBottom = UDim.new(0.06, 0)
	local pageLayout = make("UIListLayout", {
		Padding = UDim.new(0, 20),
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
		if self._activeTab ~= tab then
			tween(tabButton, Theme.HoverDuration, { BackgroundTransparency = 0.15 })
		end
	end)
	tabButton.MouseLeave:Connect(function()
		if self._activeTab ~= tab then
			tween(tabButton, Theme.HoverDuration, { BackgroundTransparency = 1 })
		end
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
		item._page.Position = active and UDim2.new(0, 7, 0, 0) or UDim2.fromOffset(0, 0)
		if active then
			tween(item._page, 0.22, { Position = UDim2.fromOffset(0, 0) })
		end
		if item._emptyState then
			item._emptyState.Visible = active and #item._cards == 0
		end
		tween(item._button, Theme.HoverDuration, {
			BackgroundColor3 = active and Color3.fromRGB(43, 43, 45) or Color3.fromRGB(32, 32, 34),
			BackgroundTransparency = active and 0 or 1,
		})
		local itemStroke = item._button:FindFirstChildOfClass("UIStroke")
		if itemStroke then itemStroke.Transparency = active and 0.87 or 1 end
		tween(item._indicator, 0.24, { Size = UDim2.new(0, 3, 0, active and 22 or 0) })
		for _, child in ipairs(item._button:GetDescendants()) do
			if child:IsA("TextLabel") and child ~= item.Badge then
				tween(child, Theme.HoverDuration, { TextColor3 = active and COLORS.Text or COLORS.Muted })
			elseif child:IsA("ImageLabel") then
				tween(child, Theme.HoverDuration, { ImageColor3 = active and COLORS.Text or COLORS.Icon })
			elseif child:IsA("Frame") and child.Name == "HavocIconPart" then
				tween(child, Theme.HoverDuration, { BackgroundColor3 = active and COLORS.Text or COLORS.Icon })
			elseif child:IsA("UIStroke") then
				tween(child, Theme.HoverDuration, { Color = active and COLORS.Text or COLORS.Icon })
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
		BackgroundColor3 = sectionOptions.BackgroundColor or COLORS.Container,
		BackgroundTransparency = Theme.PanelTransparency,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 0),
	}, self._page) :: Frame
	corner(frame, 16)
	local sectionStroke = stroke(frame, 0.86)
	padding(frame, 18)
	local sectionColor = sectionOptions.BackgroundColor or COLORS.Container
	local sectionGradient = sectionOptions.GradientColor or Color3.fromRGB(29, 29, 31)
	Elements.Gradient(frame, sectionColor, sectionGradient)
	frame.MouseEnter:Connect(function()
		tween(sectionStroke, Theme.HoverDuration, { Transparency = 0.76 })
	end)
	frame.MouseLeave:Connect(function()
		tween(sectionStroke, Theme.HoverDuration, { Transparency = 0.86 })
	end)
	local layout = make("UIListLayout", {
		Padding = UDim.new(0, 13),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, frame) :: UIListLayout
	local headingRow = make("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 24),
		LayoutOrder = -1,
	}, frame)
	local icon = iconImage(headingRow, sectionOptions.Icon or sectionOptions.Name or "layers", 16)
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.Position = UDim2.new(0, 12, 0.5, 0)
	icon.Size = UDim2.fromOffset(16, 16)
	local headingIconColor = Color3.fromRGB(237, 237, 238)
	if icon:IsA("ImageLabel") then
		icon.ImageColor3 = headingIconColor
	elseif icon:IsA("TextLabel") then
		icon.TextColor3 = headingIconColor
	end
	for _, iconPart in ipairs(icon:GetDescendants()) do
		if iconPart:IsA("ImageLabel") then
			iconPart.ImageColor3 = headingIconColor
		elseif iconPart:IsA("TextLabel") then
			iconPart.TextColor3 = headingIconColor
		elseif iconPart:IsA("Frame") and iconPart.Name == "HavocIconPart" then
			iconPart.BackgroundColor3 = headingIconColor
		elseif iconPart:IsA("UIStroke") then
			iconPart.Color = headingIconColor
		end
	end
	local headingText = string.lower(sectionOptions.Name or "Section")
	local headingWidth = TextService:GetTextSize(
		headingText,
		16,
		Enum.Font.GothamBold,
		Vector2.new(1000, 24)
	).X
	local heading = textLabel(headingRow, headingText, 16, COLORS.Text, Enum.Font.GothamBold)
	heading.Position = UDim2.fromOffset(33, 0)
	heading.Size = UDim2.new(0, headingWidth + 4, 1, 0)
	local divider = make("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = Color3.fromRGB(82, 82, 86),
		BackgroundTransparency = 0.22,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 42 + headingWidth, 0.5, 0),
		Size = UDim2.new(1, -(42 + headingWidth), 0, 1),
		ZIndex = headingRow.ZIndex + 1,
	}, headingRow)
	corner(divider, 1)
	local dividerGradient = Elements.Gradient(divider, Color3.fromRGB(82, 82, 86), Color3.fromRGB(50, 50, 53), 0) :: UIGradient
	dividerGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 0.8),
	})
	local function updateDivider()
		local dividerStart = 42 + headingWidth
		divider.Position = UDim2.new(0, dividerStart, 0.5, 0)
		divider.Size = UDim2.new(1, -dividerStart, 0, 1)
	end
	headingRow:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateDivider)
	updateDivider()
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
	if self._tab._emptyState then
		self._tab._emptyState.Visible = false
	end
	self._window._applySearch()
	return frame
end

function Section:_registerSetting(options: {[string]: any}, control: any)
	local flag = options.Flag
	if flag == nil then
		return
	end
	assert(type(flag) == "string" and flag ~= "", "Configurable controls require a non-empty string Flag")
	local settings = self._window._library._settings
	assert(settings[flag] == nil, "Duplicate configuration Flag: " .. flag)
	settings[flag] = {
		Control = control,
		ValueType = typeof(control.Value),
	}
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
	padding(paragraph, 0, 8)
	local title
	if options.HideTitle ~= true then
		title = textLabel(paragraph, options.Name, options.TitleSize or 14, COLORS.Text, Enum.Font.GothamMedium)
		title.Size = UDim2.new(1, 0, 0, 20)
	end
	local content = Elements.Paragraph(paragraph, options)
	local paragraphLayout = make("UIListLayout", {
		Padding = UDim.new(0, title and 4 or 0),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, paragraph)
	if title then
		title.LayoutOrder = 1
		content.LayoutOrder = 2
	else
		content.LayoutOrder = 1
	end
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
		Size = UDim2.new(1, 0, 0, options.Height or 47),
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
		buttonOptions.Size = UDim2.new(widthScale, -gap * (#items - 1) / #items, 0, options.Height or 47)
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
	local itemHeight = options.Height or 50
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
			self:_registerSetting(item, toggle)
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
	self:_registerSetting(options, toggle)
	return toggle
end

function Section:Slider(options: {[string]: any})
	assert(type(options) == "table" and type(options.Name) == "string", "Slider requires a Name")
	local slider = Elements.Slider(self._frame, options, self._window._library, self._window._connections)
	self:_register(slider.Frame, options.Name)
	self:_registerSetting(options, slider)
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
		if expanded then
			menu.Visible = true
			menu.AutomaticSize = Enum.AutomaticSize.None
			menu.Size = UDim2.new(1, 0, 0, 0)
			holder.AutomaticSize = Enum.AutomaticSize.None
			local visibleChoices = math.min(#choices, options.MaxVisible or 5)
			local menuHeight = visibleChoices * 32 + 28
			tween(holder, Theme.Animation.Fade.Time, {
				Size = UDim2.new(1, 0, 0, 48 + menuHeight),
			})
			tween(menu, Theme.Animation.Fade.Time, {
				Size = UDim2.new(1, 0, 0, menuHeight),
			})
		else
			tween(holder, Theme.Animation.Fade.Time, { Size = UDim2.new(1, 0, 0, 36) })
			local closeAnimation = tween(menu, Theme.Animation.Fade.Time, { Size = UDim2.new(1, 0, 0, 0) })
			closeAnimation.Completed:Once(function()
				if not expanded then
					menu.Visible = false
					holder.AutomaticSize = Enum.AutomaticSize.Y
				end
			end)
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
	self:_registerSetting(options, dropdown)
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
	self:_registerSetting(options, keybind)
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
	Elements.Gradient(row, COLORS.Interactive, Color3.fromRGB(39, 39, 42))
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
	input.Set = function(_, value: string, fireCallback: boolean?)
		field.Text = value
		if fireCallback ~= false then
			safeCallback(self._window._library, options.Callback, value, false)
		end
	end
	self:_register(row, options.Name .. " " .. (options.Placeholder or ""))
	self:_registerSetting(options, input)
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
		ClipsDescendants = true,
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
		Position = UDim2.new(0, 0, 0, 39),
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
		if expanded then
			picker.Visible = true
			picker.Size = UDim2.new(1, 0, 0, 0)
			holder.AutomaticSize = Enum.AutomaticSize.None
			tween(holder, Theme.Animation.Fade.Time, { Size = UDim2.new(1, 0, 0, 168) })
			tween(picker, Theme.Animation.Fade.Time, { Size = UDim2.new(1, 0, 0, 124) })
		else
			tween(holder, Theme.Animation.Fade.Time, { Size = UDim2.new(1, 0, 0, 36) })
			local closeAnimation = tween(picker, Theme.Animation.Fade.Time, { Size = UDim2.new(1, 0, 0, 0) })
			closeAnimation.Completed:Once(function()
				if not expanded then
					picker.Visible = false
					holder.AutomaticSize = Enum.AutomaticSize.Y
				end
			end)
		end
	end)
	setColor(color, false)
	self:_register(holder, options.Name)
	self:_registerSetting(options, colorPicker)
	return colorPicker
end

function Window:Notify(options: {[string]: any})
	return self._library:Notify(options)
end

function Window:SetVisible(visible: boolean)
	if visible then
		self._visible = true
		self.Root.Visible = true
		self.Backdrop.Visible = true
		self.Backdrop.BackgroundTransparency = 1
		tween(self.Backdrop, Theme.Animation.Fade.Time, { BackgroundTransparency = 0.42 })
		self._scale.Scale = Theme.OpenScale
		self.Root.BackgroundTransparency = 1
		tween(self._scale, Theme.Animation.Open.Time, { Scale = 1 }, Enum.EasingStyle.Quint)
		tween(self.Root, Theme.Animation.Fade.Time, { BackgroundTransparency = 0 })
		tween(self._stroke, Theme.Animation.Fade.Time, { Transparency = 0 })
	else
		self._visible = false
		tween(self._scale, Theme.HoverDuration, { Scale = Theme.OpenScale })
		tween(self.Backdrop, Theme.Animation.Fade.Time, { BackgroundTransparency = 1 })
		tween(self._stroke, Theme.Animation.Fade.Time, { Transparency = 1 })
		local fade = tween(self.Root, Theme.Animation.Fade.Time, { BackgroundTransparency = 1 })
		fade.Completed:Once(function()
			if not self._visible then
				self.Root.Visible = false
				self.Backdrop.Visible = false
			end
		end)
	end
end

local function validateConfigName(name: any): (boolean, string)
	if type(name) ~= "string" then
		return false, "config name must be text."
	end
	name = string.match(name, "^%s*(.-)%s*$")
	if name == "" then
		return false, "enter a config name first."
	end
	if #name > 40 then
		return false, "config names must be 40 characters or fewer."
	end
	if string.find(name, "[^%w _%-]") then
		return false, "use only letters, numbers, spaces, underscores, and hyphens."
	end
	return true, name
end

function Window:SaveConfig(name: string): (boolean, string?)
	local library = self._library
	if not library._configurationSaving.Enabled then
		return false, "configuration saving is disabled."
	end
	local valid, normalizedName = validateConfigName(name)
	if not valid then
		return false, normalizedName
	end
	local store = library._configurationSaving.Store
	local values = {}
	for flag, setting in pairs(library._settings) do
		local value = setting.Control.Value
		if value ~= nil then
			values[flag] = encodeConfigValue(value)
		end
	end
	local ok, result, message = pcall(store.Save, normalizedName, values)
	if not ok then
		warn("[Havoc Lib] Config save failed:", result)
		return false, "config save failed; see the developer console."
	end
	if result ~= true then
		return false, tostring(message or "config store must return true after saving.")
	end
	return true
end

function Window:CreateConfig(name: string): (boolean, string?)
	return self:SaveConfig(name)
end

function Window:LoadConfig(name: string): (boolean, string?)
	local library = self._library
	if not library._configurationSaving.Enabled then
		return false, "configuration saving is disabled."
	end
	local valid, normalizedName = validateConfigName(name)
	if not valid then
		return false, normalizedName
	end
	local store = library._configurationSaving.Store
	local ok, values, message = pcall(store.Load, normalizedName)
	if not ok then
		warn("[Havoc Lib] Config load failed:", values)
		return false, "config load failed; see the developer console."
	end
	if type(values) ~= "table" then
		return false, tostring(message or "config was not found or returned invalid data.")
	end

	local pending = {}
	for flag, value in pairs(values) do
		local setting = library._settings[flag]
		if setting then
			local decodeOk, decoded = pcall(decodeConfigValue, value, setting.ValueType)
			if not decodeOk then
				warn("[Havoc Lib] Invalid value for config flag " .. tostring(flag) .. ":", decoded)
				return false, "config contains an invalid setting; no values were applied."
			end
			table.insert(pending, { Control = setting.Control, Value = decoded })
		else
			warn("[Havoc Lib] Ignoring unknown config flag:", flag)
		end
	end
	for _, item in ipairs(pending) do
		item.Control:Set(item.Value)
	end
	return true
end

function Window:ListConfigs(): (boolean, {string}?, string?)
	if not self._library._configurationSaving.Enabled then
		return false, nil, "configuration saving is disabled."
	end
	local store = self._library._configurationSaving.Store
	if type(store.List) ~= "function" then
		return false, nil, "config listing is not supported by the configured store."
	end
	local ok, names, message = pcall(store.List)
	if not ok then
		warn("[Havoc Lib] Config listing failed:", names)
		return false, nil, "config listing failed; see the developer console."
	end
	if type(names) ~= "table" then
		return false, nil, tostring(message or "config store returned an invalid list.")
	end
	local result = {}
	for _, name in ipairs(names) do
		if type(name) == "string" then
			table.insert(result, name)
		end
	end
	table.sort(result, function(a, b)
		return string.lower(a) < string.lower(b)
	end)
	return true, result
end

function Window:DeleteConfig(name: string): (boolean, string?)
	if not self._library._configurationSaving.Enabled then
		return false, "configuration saving is disabled."
	end
	local valid, normalizedName = validateConfigName(name)
	if not valid then
		return false, normalizedName
	end
	local store = self._library._configurationSaving.Store
	if type(store.Delete) ~= "function" then
		return false, "config deletion is not supported by the configured store."
	end
	local ok, result, message = pcall(store.Delete, normalizedName)
	if not ok then
		warn("[Havoc Lib] Config delete failed:", result)
		return false, "config deletion failed; see the developer console."
	end
	if result ~= true then
		return false, tostring(message or "config store must return true after deleting.")
	end
	return true
end

function Window:_CreateConfigManager(options: {[string]: any})
	local tab = self:Tab({
		Name = options.TabName or "configs",
		Icon = options.Icon or "bookmark",
	})
	local section = tab:Section({
		Name = options.SectionName or "configuration manager",
		Icon = "settings",
	})
	local nameInput = section:Input({
		Name = "config name",
		Placeholder = "enter a name",
		Default = options.DefaultConfig or "",
	})
	local function report(success: boolean, message: string?, action: string)
		self:Notify({
			Title = success and "config " .. action or "config error",
			Content = success and (action .. " completed.") or tostring(message or "operation failed."),
			Duration = 4,
		})
	end
	local buttons = {
		{
			Name = "create / save",
			Callback = function()
				local success, message = self:CreateConfig(nameInput.Value)
				report(success, message, "saved")
			end,
		},
		{
			Name = "load",
			Callback = function()
				local success, message = self:LoadConfig(nameInput.Value)
				report(success, message, "loaded")
			end,
		},
	}
	if type(options.Store.List) == "function" then
		table.insert(buttons, {
			Name = "list",
			Callback = function()
				local success, names, message = self:ListConfigs()
				if not success then
					report(false, message, "listed")
					return
				end
				self:Notify({
					Title = "saved configs",
					Content = if #names == 0 then "no configs saved." else table.concat(names, ", "),
					Duration = 6,
				})
			end,
		})
	end
	if type(options.Store.Delete) == "function" then
		table.insert(buttons, {
			Name = "delete",
			Callback = function()
				local success, message = self:DeleteConfig(nameInput.Value)
				report(success, message, "deleted")
			end,
		})
	end
	section:Buttons({ Buttons = buttons, Height = 34, Gap = 6 })
end

function HavocLib:Notify(options: {[string]: any})
	assert(type(options) == "table", "Notify requires an options table")
	local title = options.Title or "notification"
	local content = options.Content or ""
	local duration = math.max(tonumber(options.Duration) or 4, 0.5)
	local host = self._notificationHost
	if not host then
		host = make("Frame", {
			AnchorPoint = Vector2.new(0.5, 1),
			BackgroundTransparency = 1,
			Position = UDim2.new(0.5, 0, 1, -15),
			Size = UDim2.new(0, 310, 0, 190),
		}, self.ScreenGui)
		self._notificationHost = host
		make("UIListLayout", {
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
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

-- Standalone demo window. The button callbacks are safe examples to replace
-- with your own code; the library itself remains local to this single file.
local ui = HavocLib.new({
	Title = "havoc lib",
	Subtitle = "made by convict",
	Version = "v0.1.0",
	Logo = 81325599465401,
})

local main = ui:Tab({
	Name = "main",
	Icon = "home",
})

local movement = main:Section({
	Name = "movement",
	Icon = "movement",
})

local markersToggle: any = nil

movement:Buttons({
	Height = 47,
	Gap = 10,
	Buttons = {
		{
			Name = "quick action",
			Color = Color3.fromRGB(231, 231, 233),
			Callback = function()
				ui:Notify({
					Title = "quick action",
					Content = "Replace this callback with your action.",
					Duration = 3,
				})
			end,
		},
		{
			Name = "reset demo",
			Color = Color3.fromRGB(54, 54, 57),
			Callback = function()
				if markersToggle then
					markersToggle:Set(false)
				end
				ui:Notify({
					Title = "demo reset",
					Content = "The demo toggle is off.",
					Duration = 2,
				})
			end,
		},
	},
})

markersToggle = movement:Toggle({
	Name = "show markers",
	Default = false,
})

local general = main:Section({
	Name = "general",
	Icon = "settings",
})

general:Paragraph({
	Name = "general",
	HideTitle = true,
	Content = "controls can be arranged vertically or grouped into compact rows.",
})

ui:Tab({
	Name = "exploits",
	Icon = "exploits",
	CaptionBefore = "silent",
})

ui:Tab({
	Name = "aimbot",
	Icon = "aimbot",
})

ui:Tab({
	Name = "esp",
	Icon = "esp",
})

ui:Tab({
	Name = "info",
	Icon = "info",
})

ui:Tab({
	Name = "custom",
	Icon = "sparkles",
	CaptionBefore = "custom empty page tab",
	EmptyText = "this page is empty for now",
})
