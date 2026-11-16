-- CLASSIC ROUND SYSTEM - interface (client)
-- Edit the TIPS list below to change the tips shown at the bottom.

local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local StatusValue = RS:WaitForChild("RoundStatus")
local TimerValue = RS:WaitForChild("RoundTimer")
local MapValue = RS:WaitForChild("RoundMap")
local AliveValue = RS:WaitForChild("RoundAlive")

local TIPS = {
	"A new map is picked at random every round, so stay ready!",
	"You spawn at a random point of the map.",
	"Keep an eye on the timer in the top panel.",
	"If you fall, you go back to the lobby until the next round.",
	"Stay away from the edges of the map.",
	"Team up with your friends and have fun!",
	"Learn the map layout before the timer gets low.",
	"Watch the alive counter to know how the round is going.",
	"Try different maps to discover new routes.",
	"Use the intermission to get ready for the next round.",
	"Stay alert: the next map can be completely different!",
	"Spread out when the round starts so everyone has room.",
	"Survive until the timer ends to become a round survivor.",
}
local TIP_INTERVAL = 8

local FONT = Enum.Font.Arial
local FONT_BOLD = Enum.Font.ArialBold
local WHITE = Color3.new(1, 1, 1)
local RED = Color3.fromRGB(255, 90, 90)

local gui = script.Parent

local function makeBox(size, pos, anchor)
	local f = Instance.new("Frame")
	f.Size = size
	f.Position = pos
	f.AnchorPoint = anchor
	f.BackgroundColor3 = Color3.new(0, 0, 0)
	f.BackgroundTransparency = 0.4
	f.BorderSizePixel = 2
	f.BorderColor3 = WHITE
	f.Parent = gui
	return f
end

local function makeLabel(parent, size, pos, font, maxText)
	local l = Instance.new("TextLabel")
	l.Size = size
	l.Position = pos
	l.BackgroundTransparency = 1
	l.TextColor3 = WHITE
	l.TextStrokeTransparency = 0.5
	l.Font = font
	l.TextScaled = true
	l.Text = ""
	l.Parent = parent

	local c = Instance.new("UITextSizeConstraint")
	c.MaxTextSize = maxText
	c.Parent = l
	return l
end

-- top panel: status + map / time / alive
local top = makeBox(UDim2.new(0.6, 0, 0, 64), UDim2.new(0.5, 0, 0, 8), Vector2.new(0.5, 0))
local topLimit = Instance.new("UISizeConstraint")
topLimit.MinSize = Vector2.new(240, 64)
topLimit.MaxSize = Vector2.new(380, 64)
topLimit.Parent = top

local statusLabel = makeLabel(top, UDim2.new(1, -8, 0.5, -2), UDim2.new(0, 4, 0, 2), FONT_BOLD, 20)
local infoLabel = makeLabel(top, UDim2.new(1, -8, 0.5, -4), UDim2.new(0.5, 0, 0.5, 0), FONT, 16)
infoLabel.AnchorPoint = Vector2.new(0.5, 0)
infoLabel.Position = UDim2.new(0.5, 0, 0.5, 0)

-- bottom bar: tips
local tipBox = makeBox(UDim2.new(0.8, 0, 0, 30), UDim2.new(0.5, 0, 1, -10), Vector2.new(0.5, 1))
local tipLimit = Instance.new("UISizeConstraint")
tipLimit.MinSize = Vector2.new(240, 30)
tipLimit.MaxSize = Vector2.new(520, 30)
tipLimit.Parent = tipBox
local tipLabel = makeLabel(tipBox, UDim2.new(1, -8, 1, -4), UDim2.new(0, 4, 0, 2), FONT, 16)

local function fmt(t)
	return string.format("%d:%02d", math.floor(t / 60), t % 60)
end

local function refresh()
	statusLabel.Text = StatusValue.Value

	local inRound = MapValue.Value ~= ""
	local parts = {}
	if inRound then
		table.insert(parts, "Map: " .. MapValue.Value)
	end
	table.insert(parts, "Time: " .. fmt(TimerValue.Value))
	if inRound then
		table.insert(parts, "Alive: " .. AliveValue.Value)
	end
	infoLabel.Text = table.concat(parts, "  |  ")

	local urgent = inRound and TimerValue.Value > 0 and TimerValue.Value <= 10
	infoLabel.TextColor3 = urgent and RED or WHITE
end

StatusValue.Changed:Connect(refresh)
TimerValue.Changed:Connect(refresh)
MapValue.Changed:Connect(refresh)
AliveValue.Changed:Connect(refresh)
refresh()

-- rotating tips (random order, never the same twice in a row)
task.spawn(function()
	local last = 0
	while true do
		local idx = math.random(#TIPS)
		if #TIPS > 1 then
			while idx == last do
				idx = math.random(#TIPS)
			end
		end
		last = idx

		tipLabel.Text = "Tips: " .. TIPS[idx]
		tipLabel.TextTransparency = 1
		TweenService:Create(tipLabel, TweenInfo.new(0.4), { TextTransparency = 0 }):Play()
		task.wait(TIP_INTERVAL)
	end
end)
