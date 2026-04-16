--!strict
local DirectorExecutor = {}
local Players        = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local function loadModule(path)
	local success, module = pcall(require, path)
	if not success then warn("❌ DirectorExecutor: No se pudo cargar módulo:", tostring(path), module) end
	return success and module or nil
end

local Effects      = loadModule(script.Parent.Parent.Parent.Modules.Effects)
local MutationCtrl = loadModule(script.Parent.Parent.Evolution.MutationController)
local CypherMgr    = loadModule(script.Parent.Parent.CypherManager)
local RelicsMgr    = loadModule(script.Parent.Parent.Economy.RelicsManager)
local DirectorMemory  = require(script.Parent.DirectorMemory)
local DirectorMonitor = require(script.Parent.DirectorMonitor)

-- Remote para mensajes al cliente
local function getDirectorRemote()
	local net = ReplicatedStorage:FindFirstChild("Networking")
	local ce  = net and net:FindFirstChild("ClientEvents")
	return ce and ce:FindFirstChild("DirectorMessage")
end

local function broadcast(msg: string, duration: number?)
	local remote = getDirectorRemote()
	if remote then
		remote:FireAllClients(msg, duration or 8)
	else
		local m = Instance.new("Message"); m.Text = msg; m.Parent = workspace
		task.delay(duration or 8, function() if m and m.Parent then m:Destroy() end end)
	end
end

local function rewardSurvivors(eventName: string, amount: number?)
	amount = amount or 1
	if not RelicsMgr then return end
	local survivors = {}
	for _, player in ipairs(Players:GetPlayers()) do
		local char = player.Character
		if char and char:FindFirstChildOfClass("Humanoid") and char:FindFirstChildOfClass("Humanoid").Health > 0 then
			table.insert(survivors, player)
		end
	end
	for _, survivor in ipairs(survivors) do
		pcall(function() RelicsMgr:giveRelic(survivor, "CarneComun", amount) end)
	end
	if #survivors > 0 then
		broadcast(string.format("💀 %d CARNICEROS SOBREVIVIERON A %s.", #survivors, eventName:upper()), 5)
	end
end

-- ============================================================
-- EVENTOS
-- ============================================================

function DirectorExecutor:kixEvent()
	broadcast("👁️ LOS KIX HAN LLEGADO. LA CARNE TIEMBLA.", 8)
	-- Debuff de velocidad a todos
	for _, player in ipairs(Players:GetPlayers()) do
		local char = player.Character
		if not char then continue end
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then
			local original = hum.WalkSpeed
			hum.WalkSpeed = math.max(4, hum.WalkSpeed * 0.6)
			player:SetAttribute("KixSlowed", true)
			task.delay(20, function()
				if player and player.Parent and char and char.Parent then
					hum.WalkSpeed = original
					player:SetAttribute("KixSlowed", nil)
				end
			end)
		end
	end
	task.delay(20, function()
		broadcast("👁️ LOS KIX SE RETIRAN... POR AHORA.", 5)
		rewardSurvivors("KixArrival", 2)
	end)
end

function DirectorExecutor:gravitalEvent()
	broadcast("🌀 PATRULLA GRAVITAL DETECTADA. CUIDADO CON LAS ALTURAS.", 8)
	-- Aumentar gravedad temporalmente
	local originalGrav = workspace.Gravity
	workspace.Gravity = originalGrav * 1.8
	task.delay(25, function()
		workspace.Gravity = originalGrav
		broadcast("🌀 LA GRAVEDAD VUELVE A LA NORMALIDAD.", 4)
		rewardSurvivors("GravitalPatrol", 1)
	end)
end

function DirectorExecutor:meatMeteor()
	broadcast("☄️ ¡METEORO DE CARNE EN CAMINO! CORRE.", 6)
	-- Seleccionar posición aleatoria en el mapa
	local players = Players:GetPlayers()
	if #players == 0 then return end
	local target = players[math.random(#players)]
	local targetChar = target and target.Character
	local targetRoot = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
	local impactPos = targetRoot and targetRoot.Position or Vector3.new(0, 100, 0)

	-- Crear meteoro cayendo
	local meteor = Instance.new("Part")
	meteor.Shape = Enum.PartType.Ball
	meteor.Size = Vector3.new(6, 6, 6)
	meteor.Color = Color3.fromRGB(180, 60, 20)
	meteor.Material = Enum.Material.Neon
	meteor.Anchored = true
	meteor.CanCollide = false
	meteor.Position = impactPos + Vector3.new(0, 150, 0)
	meteor.Parent = workspace

	-- Caída animada
	TweenService:Create(meteor, TweenInfo.new(2.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Position = impactPos + Vector3.new(0, 3, 0)
	}):Play()

	task.delay(2.5, function()
		-- Impacto: AoE damage en radio 12
		local impactRadius = 12
		for _, player in ipairs(Players:GetPlayers()) do
			local char = player.Character
			if not char then continue end
			local root = char:FindFirstChild("HumanoidRootPart")
			local hum = char:FindFirstChildOfClass("Humanoid")
			if root and hum and hum.Health > 0 then
				local dist = (root.Position - impactPos).Magnitude
				if dist <= impactRadius then
					local dmg = math.floor(60 * (1 - dist/impactRadius))
					hum:TakeDamage(math.max(10, dmg))
				end
			end
		end
		-- Explosión visual
		local explosion = Instance.new("Explosion")
		explosion.Position = impactPos
		explosion.BlastRadius = impactRadius
		explosion.BlastPressure = 0
		explosion.DestroyJointRadiusPercent = 0
		explosion.Parent = workspace
		meteor:Destroy()
		broadcast("☄️ IMPACTO. LA CARNE SE ESPARCE.", 5)
	end)
end

function DirectorExecutor:cypherStorm()
	broadcast("⚡ TORMENTA CYPHER. TODOS RECIBEN NUEVOS PODERES.", 6)
	if CypherMgr then
		pcall(function() CypherMgr.rotateAllPlayers() end)
	end
	-- Reducir cooldowns a la mitad por 30s
	for _, player in ipairs(Players:GetPlayers()) do
		player:SetAttribute("CypherStormActive", true)
		task.delay(30, function()
			if player and player.Parent then
				player:SetAttribute("CypherStormActive", nil)
			end
		end)
	end
	task.delay(30, function()
		broadcast("⚡ LA TORMENTA CYPHER AMAINA.", 4)
	end)
end

function DirectorExecutor:bountyOnTopPlayer()
	local metrics = DirectorMonitor:getCurrentMetrics()
	local topPlayer = metrics and metrics.topPlayer
	if not topPlayer or not topPlayer.Parent then return end
	broadcast(string.format("🎯 RECOMPENSA: ¡ELIMINA A %s! DOBLE KIX AL ASESINO.", topPlayer.Name:upper()), 10)
	topPlayer:SetAttribute("HasBounty", true)
	-- Escuchar muerte del bounty
	local char = topPlayer.Character
	if char then
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then
			local conn
			conn = hum.Died:Connect(function()
				conn:Disconnect()
				topPlayer:SetAttribute("HasBounty", nil)
				local killerName = topPlayer:GetAttribute("LastHitBy")
				local killer = killerName and Players:FindFirstChild(killerName)
				if killer and RelicsMgr then
					pcall(function() RelicsMgr:giveRelic(killer, "CarneComun", 5) end)
					broadcast(string.format("💀 %s COBRÓ LA RECOMPENSA.", killer.Name:upper()), 6)
				end
			end)
		end
	end
	-- Cancelar bounty después de 60s si sigue vivo
	task.delay(60, function()
		if topPlayer and topPlayer.Parent then
			topPlayer:SetAttribute("HasBounty", nil)
			broadcast("🎯 LA RECOMPENSA EXPIRÓ.", 4)
		end
	end)
end

function DirectorExecutor:silenceZone()
	broadcast("🔇 ZONA DE SILENCIO. LOS PODERES ESTÁN BLOQUEADOS POR 20 SEGUNDOS.", 8)
	for _, player in ipairs(Players:GetPlayers()) do
		player:SetAttribute("Silenced", true)
		task.delay(20, function()
			if player and player.Parent then
				player:SetAttribute("Silenced", nil)
			end
		end)
	end
	task.delay(20, function()
		broadcast("🔇 EL SILENCIO TERMINA. LA CARNE RESPIRA.", 4)
	end)
end

function DirectorExecutor:hunterParty()
	local metrics = DirectorMonitor:getCurrentMetrics()
	local topPlayer = metrics and metrics.topPlayer
	if not topPlayer or not topPlayer.Parent then return end
	broadcast(string.format("🏹 CACERÍA. TODOS CONTRA %s.", topPlayer.Name:upper()), 8)
	-- Marcar al top player como objetivo visible
	topPlayer:SetAttribute("HunterTarget", true)
	task.delay(45, function()
		if topPlayer and topPlayer.Parent then
			topPlayer:SetAttribute("HunterTarget", nil)
			broadcast("🏹 LA CACERÍA HA TERMINADO.", 4)
		end
	end)
end

function DirectorExecutor:meatRain()
	broadcast("🥩 ¡LLUVIA DE CARNE! RECOGE LAS RELIQUIAS.", 6)
	-- Dar reliquias aleatorias a todos los jugadores
	if RelicsMgr then
		for _, player in ipairs(Players:GetPlayers()) do
			pcall(function() RelicsMgr:dropRandom(player, math.random(1,3)) end)
		end
	end
	-- Efecto visual: partes cayendo del cielo
	for i = 1, 8 do
		task.delay(i * 0.4, function()
			local x = math.random(-50, 50)
			local z = math.random(-50, 50)
			local part = Instance.new("Part")
			part.Size = Vector3.new(1.5, 1.5, 1.5)
			part.Color = Color3.fromRGB(180, 40, 40)
			part.Material = Enum.Material.SmoothPlastic
			part.Position = Vector3.new(x, 80, z)
			part.Parent = workspace
			Debris:AddItem(part, 8)
		end)
	end
end

function DirectorExecutor:reverseGravity()
	broadcast("🔃 ¡GRAVEDAD INVERTIDA! CUIDADO CON EL CIELO.", 6)
	local original = workspace.Gravity
	workspace.Gravity = -original * 0.5
	task.delay(8, function()
		workspace.Gravity = original
		broadcast("🔃 LA GRAVEDAD SE NORMALIZA.", 4)
		rewardSurvivors("ReverseGravity", 1)
	end)
end

function DirectorExecutor:carnageRitual()
	broadcast("🩸 RITUAL DE CARNICERÍA. TODO EL DAÑO SE DUPLICA POR 30 SEGUNDOS.", 8)
	for _, player in ipairs(Players:GetPlayers()) do
		player:SetAttribute("CarnageRitual", true)
		task.delay(30, function()
			if player and player.Parent then
				player:SetAttribute("CarnageRitual", nil)
			end
		end)
	end
	task.delay(30, function()
		broadcast("🩸 EL RITUAL TERMINA. LA CARNE DESCANSA.", 4)
	end)
end

-- ============================================================
-- DISPATCH PRINCIPAL
-- ============================================================

function DirectorExecutor:execute(eventName: string)
	print("👁️ Director ejecutando:", eventName)
	workspace:SetAttribute("CurrentDirectorEvent", eventName)
	task.delay(120, function() workspace:SetAttribute("CurrentDirectorEvent", "") end)

	local ok, err = pcall(function()
		if eventName == "KixArrival"            then self:kixEvent()
		elseif eventName == "GravitalPatrol"    then self:gravitalEvent()
		elseif eventName == "MeatMeteor"        then self:meatMeteor()
		elseif eventName == "CypherStorm"       then self:cypherStorm()
		elseif eventName == "BountyOnTopPlayer" then self:bountyOnTopPlayer()
		elseif eventName == "SilenceZone"       then self:silenceZone()
		elseif eventName == "HunterParty"       then self:hunterParty()
		elseif eventName == "MeatRain"          then self:meatRain()
		elseif eventName == "ReverseGravity"    then self:reverseGravity()
		elseif eventName == "CarnageRitual"     then self:carnageRitual()
		else warn("DirectorExecutor: evento desconocido:", eventName)
		end
	end)

	if ok then
		DirectorMemory:remember(eventName, {})
	else
		warn("DirectorExecutor error en", eventName, ":", err)
	end
end

return DirectorExecutor
