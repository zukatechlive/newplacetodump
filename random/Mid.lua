--[[RegisterCommand({
	Name = "raknet",
	Aliases = { "rsync" },
	Description = "",
	ArgsDesc = {},
	Permissions = {},
}, function(args, speaker)]]



--[[ This is what a shit dsync looks like. idk who made this. shoutout to whoever made this dookie ]]


	local uis = game:GetService("UserInputService")
	local players = game:GetService("Players")
	local rs = game:GetService("RunService")
	local lp = players.LocalPlayer
	local hooked = false
	local toggle = Enum.KeyCode.End
	local ghostModel = nil
	local groundParts = {}
	local attachments = {}
	local vfxConn = nil

	local PI2 = math.pi * 2
	local OUTER_RADIUS = 3.2
	local INNER_RADIUS = 1.8
	local OUTER_SPEED = 2.5
	local INNER_SPEED = -3.5
	local GROUND_OFFSET = 3.1
	local SPARK_INTERVAL = 0.05

	local lightningColor = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(100, 180, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 40, 200)),
	})

	local sparkSize = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.18),
		NumberSequenceKeypoint.new(0.5, 0.08),
		NumberSequenceKeypoint.new(1, 0),
	})

	local ringSizeOuter = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(1, 0),
	})

	local ringSizeInner = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.07),
		NumberSequenceKeypoint.new(1, 0),
	})

	local function removeGhost()
		if vfxConn then
			vfxConn:Disconnect()
			vfxConn = nil
		end
		for _, p in ipairs(groundParts) do
			if p.dot and p.dot.Parent then
				p.dot:Destroy()
			end
		end
		groundParts = {}
		attachments = {}
		if ghostModel then
			ghostModel:Destroy()
			ghostModel = nil
		end
	end

	local function rakhook(packet)
		if packet.PacketId == 0x1B then
			local buf = packet.AsBuffer
			buffer.writeu32(buf, 1, 0xFFFFFFFF)
			packet:SetData(buf)
		end
	end

	local function makeSparks(parent)
		local att = Instance.new("Attachment")
		att.Parent = parent
		local sparks = Instance.new("ParticleEmitter")
		sparks.Color = lightningColor
		sparks.LightEmission = 1
		sparks.LightInfluence = 0
		sparks.Size = sparkSize
		sparks.Lifetime = NumberRange.new(0.1, 0.3)
		sparks.Rate = 0
		sparks.Speed = NumberRange.new(5, 20)
		sparks.SpreadAngle = Vector2.new(180, 180)
		sparks.RotSpeed = NumberRange.new(-360, 360)
		sparks.Rotation = NumberRange.new(0, 360)
		sparks.Parent = att
		return att
	end

	local function makeRingDot(px, py, pz, sz, col, sparksSize)
		local dot = Instance.new("Part")
		dot.Anchored = true
		dot.CanCollide = false
		dot.CanTouch = false
		dot.CanQuery = false
		dot.CastShadow = false
		dot.Size = Vector3.new(sz, sz, sz)
		dot.Shape = Enum.PartType.Ball
		dot.Material = Enum.Material.Neon
		dot.Color = col
		dot.Transparency = 0
		dot.CFrame = CFrame.new(px, py, pz)
		dot.Parent = workspace
		local att = Instance.new("Attachment")
		att.Parent = dot
		local em = Instance.new("ParticleEmitter")
		em.Color = lightningColor
		em.LightEmission = 1
		em.LightInfluence = 0
		em.Size = sparksSize
		em.Lifetime = NumberRange.new(0.1, 0.2)
		em.Rate = 10
		em.Speed = NumberRange.new(1, 5)
		em.SpreadAngle = Vector2.new(180, 180)
		em.Parent = att
		return dot
	end

	local function createGhost(pos)
		removeGhost()

		local char = lp.Character
		if not char then
			return
		end
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if not hrp then
			return
		end

		local offset = pos - hrp.Position

		char.Archivable = true
		local ghost = char:Clone()
		char.Archivable = false
		if not ghost then
			return
		end

		ghost.Name = "GhostMarker"

		for _, v in ipairs(ghost:GetDescendants()) do
			pcall(function()
				if
					v:IsA("Script")
					or v:IsA("LocalScript")
					or v:IsA("ModuleScript")
					or v:IsA("Animator")
					or v:IsA("AnimationController")
				then
					v:Destroy()
				end
			end)
		end

		local hum = ghost:FindFirstChildOfClass("Humanoid")
		if hum then
			hum:Destroy()
		end

		for _, v in ipairs(ghost:GetDescendants()) do
			pcall(function()
				if v:IsA("BasePart") then
					v.Anchored = true
					v.CanCollide = false
					v.CanTouch = false
					v.CanQuery = false
					v.CastShadow = false
					v.Transparency = 0
					v.Material = Enum.Material.SmoothPlastic
					v.Color = Color3.fromRGB(0, 20, 80)
					v.CFrame = v.CFrame + offset
					if v.Name ~= "HumanoidRootPart" then
						for e = 1, 3 do
							local att = makeSparks(v)
							table.insert(attachments, att)
						end
					end
				end
			end)
		end

		local ghostHRP = ghost:FindFirstChild("HumanoidRootPart")
		if ghostHRP then
			ghostHRP.Transparency = 1
			ghostHRP.CFrame = CFrame.new(pos) * (hrp.CFrame - hrp.CFrame.Position)
		end

		local hl = Instance.new("Highlight")
		hl.FillColor = Color3.fromRGB(0, 60, 180)
		hl.FillTransparency = 0
		hl.OutlineColor = Color3.fromRGB(0, 120, 255)
		hl.OutlineTransparency = 0
		hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		hl.Adornee = ghost
		hl.Parent = ghost

		ghost.Parent = workspace
		ghostModel = ghost

		for _, v in ipairs(ghost:GetDescendants()) do
			if v:IsA("BasePart") then
				v.CanCollide = false
				v.CanTouch = false
				v.CanQuery = false
			end
		end
		for _, v in ipairs(ghost:GetChildren()) do
			if v:IsA("BasePart") then
				v.CanCollide = false
				v.CanTouch = false
				v.CanQuery = false
			end
		end

		local rCount = 32
		local iCount = 20
		local gy = pos.Y - GROUND_OFFSET
		local outerCol = Color3.fromRGB(0, 100, 255)
		local innerCol = Color3.fromRGB(150, 210, 255)

		for i = 1, rCount do
			local a = (i / rCount) * PI2
			local dot = makeRingDot(
				pos.X + math.cos(a) * OUTER_RADIUS,
				gy,
				pos.Z + math.sin(a) * OUTER_RADIUS,
				0.25,
				outerCol,
				ringSizeOuter
			)
			table.insert(groundParts, { dot = dot, baseAngle = a, isOuter = true })
		end

		for i = 1, iCount do
			local a = (i / iCount) * PI2
			local dot = makeRingDot(
				pos.X + math.cos(a) * INNER_RADIUS,
				gy,
				pos.Z + math.sin(a) * INNER_RADIUS,
				0.15,
				innerCol,
				ringSizeInner
			)
			table.insert(groundParts, { dot = dot, baseAngle = a, isOuter = false })
		end

		local sparkTimer = 0

		vfxConn = rs.Heartbeat:Connect(function(dt)
			if not ghostModel or not ghostModel.Parent then
				return
			end
			local t = tick()
			local pulse = math.abs(math.sin(t * 2))
			local fillG = math.floor(40 + pulse * 30)
			local fillB = math.floor(160 + pulse * 60)
			local outG = math.floor(100 + pulse * 60)

			hl.FillColor = Color3.fromRGB(0, fillG, fillB)
			hl.OutlineColor = Color3.fromRGB(0, outG, 255)
			hl.OutlineTransparency = pulse * 0.3

			for _, entry in ipairs(groundParts) do
				if entry.dot and entry.dot.Parent then
					local radius = entry.isOuter and OUTER_RADIUS or INNER_RADIUS
					local speed = entry.isOuter and OUTER_SPEED or INNER_SPEED
					local a = entry.baseAngle + t * speed
					local wave = math.abs(math.sin(t * 5 + entry.baseAngle)) * 0.2
					local bright = math.abs(math.sin(t * 6 + entry.baseAngle)) * 0.4
					entry.dot.CFrame = CFrame.new(pos.X + math.cos(a) * radius, gy + wave, pos.Z + math.sin(a) * radius)
					entry.dot.Transparency = bright
					if entry.isOuter then
						local r = math.floor(80 + pulse * 60)
						entry.dot.Color = Color3.fromRGB(0, r, 255)
					else
						local r = math.floor(120 + pulse * 60)
						local g = math.floor(180 + pulse * 40)
						entry.dot.Color = Color3.fromRGB(r, g, 255)
					end
				end
			end

			sparkTimer = sparkTimer + dt
			if sparkTimer >= SPARK_INTERVAL then
				sparkTimer = 0
				local numAtts = #attachments
				if numAtts > 0 then
					local bursts = math.random(2, 5)
					for b = 1, bursts do
						local pick = attachments[math.random(1, numAtts)]
						if pick and pick.Parent then
							local emitter = pick:FindFirstChildOfClass("ParticleEmitter")
							if emitter then
								emitter:Emit(math.random(8, 25))
							end
						end
					end
				end
				for _, v in ipairs(ghostModel:GetDescendants()) do
					if v:IsA("BasePart") then
						v.CanCollide = false
						v.CanTouch = false
						v.CanQuery = false
						v.Anchored = true
					end
				end
			end
		end)
	end

	uis.InputBegan:Connect(function(obj)
		if obj.KeyCode ~= toggle then
			return
		end
		if hooked then
			raknet.remove_send_hook(rakhook)
			removeGhost()
		else
			local char = lp.Character
			if not char then
				return
			end
			local hrp = char:FindFirstChild("HumanoidRootPart")
			if not hrp then
				return
			end
			createGhost(hrp.Position)
			raknet.add_send_hook(rakhook)
		end
		hooked = not hooked
	end)
--end)
