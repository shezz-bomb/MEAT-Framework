-- DirectorMemory — MEAT Project (versión ÑAM corregida)
-- Memoria persistente, estadísticas, días especiales y sabores únicos.

local DirectorMemory = {}

-- ==================== CONFIGURACIÓN ====================
local MEMORY_DURATION = 3600  -- 1 hora en segundos
local MAX_HISTORY = 200       -- Máximo de entradas en memoria

-- Días de la semana con efectos específicos (0 = domingo, 1 = lunes, ..., 6 = sábado)
local DAY_EFFECTS = {
	[0] = { name = "DOMINGO_SANGRIENTO", chaosMultiplier = 1.5,  description = "LA CARNE DESCANSA, PERO LA SANGRE NO" },
	[1] = { name = "LUNES_DE_LAMENTOS",   chaosMultiplier = 1.2,  description = "EL GANADO LLORA. EL DIRECTOR SONRÍE" },
	[2] = { name = "MARTES_DE_CARNE",     chaosMultiplier = 3.0,  description = "LA CARNE ES LEY. NO HAY PIEDAD" },
	[3] = { name = "MIÉRCOLES_MUDO",      chaosMultiplier = 1.0,  description = "SILENCIO. LOS QU ESCUCHAN" },
	[4] = { name = "JUEVES_DE_GLOTONES",  chaosMultiplier = 1.8,  description = "LOS QU TIENEN HAMBRE. TODOS SON PRESA" },
	[5] = { name = "VIERNES_DE_VISCERAS", chaosMultiplier = 2.0,  description = "LAS TRIPAS BRILLAN. EL CAOS AUMENTA" },
	[6] = { name = "SABADO_DEL_CIFRADO",  chaosMultiplier = 3.0,  description = "LOS CIPHERS GRITAN. EL DIRECTOR OBSERVA" },
}

-- ==================== ESTADO INTERNO ====================
local memory = {}           -- Array de eventos: {type, time, data}
local eventCounters = {}    -- { [eventType] = cantidadTotal }
local lastEventOfType = {}  -- { [eventType] = timestamp }
local streakCounter = {}    -- { currentEventType, count }

-- ==================== MÉTODOS PÚBLICOS ====================

-- Registrar un evento en la memoria
function DirectorMemory:remember(eventType, data)
	-- Limpiar memoria antigua si es necesario
	self:cleanup()

	-- Actualizar contadores
	eventCounters[eventType] = (eventCounters[eventType] or 0) + 1
	lastEventOfType[eventType] = tick()

	-- Detectar racha (mismo evento seguido)
	if streakCounter.current == eventType then
		streakCounter.count = (streakCounter.count or 0) + 1
	else
		streakCounter.current = eventType
		streakCounter.count = 1
	end

	-- Guardar en memoria
	table.insert(memory, {
		type = eventType,
		time = tick(),
		data = data or {}
	})

	-- Limitar tamaño de memoria
	while #memory > MAX_HISTORY do
		table.remove(memory, 1)
	end
end

-- Limpiar entradas más viejas que MEMORY_DURATION
function DirectorMemory:cleanup()
	local cutoff = tick() - MEMORY_DURATION
	for i = #memory, 1, -1 do
		if memory[i].time < cutoff then
			table.remove(memory, i)
		end
	end
end

-- Verificar si un evento ha ocurrido recientemente (en los últimos X minutos)
function DirectorMemory:hasHappenedRecently(eventType, minutes)
	local cutoff = tick() - minutes * 60
	for _, entry in ipairs(memory) do
		if entry.type == eventType and entry.time > cutoff then
			return true
		end
	end
	return false
end

-- Verificar si un evento ha ocurrido en los últimos X segundos (más preciso)
function DirectorMemory:hasHappenedRecentlySeconds(eventType, seconds)
	local cutoff = tick() - seconds
	for _, entry in ipairs(memory) do
		if entry.type == eventType and entry.time > cutoff then
			return true
		end
	end
	return false
end

-- Obtener el día actual con su efecto
function DirectorMemory:getCurrentDay()
	local weekday = tonumber(os.date("%w"))  -- 0=domingo
	local effect = DAY_EFFECTS[weekday] or DAY_EFFECTS[0]
	return effect.name
end

-- Verificar si hoy es un día santo (tiene multiplicador > 1.5 o es especial)
function DirectorMemory:isHolyDay()
	local weekday = tonumber(os.date("%w"))
	local effect = DAY_EFFECTS[weekday]
	return effect ~= nil and effect.chaosMultiplier >= 2.0
end

-- Obtener multiplicador de caos del día actual
function DirectorMemory:getChaosMultiplier()
	local weekday = tonumber(os.date("%w"))
	local effect = DAY_EFFECTS[weekday] or DAY_EFFECTS[0]
	return effect.chaosMultiplier
end

-- Obtener descripción del día actual (para broadcast o UI)
function DirectorMemory:getDayDescription()
	local weekday = tonumber(os.date("%w"))
	local effect = DAY_EFFECTS[weekday] or DAY_EFFECTS[0]
	return effect.description
end

-- ==================== MÉTODOS NUEVOS (ÑAM) ====================

-- Obtener cuántas veces ha ocurrido un evento en total (desde inicio de partida)
function DirectorMemory:getEventCount(eventType)
	return eventCounters[eventType] or 0
end

-- Obtener el tiempo transcurrido desde la última vez que ocurrió un evento (en segundos)
function DirectorMemory:timeSinceLastEvent(eventType)
	local last = lastEventOfType[eventType]
	if not last then return math.huge end
	return tick() - last
end

-- Verificar si el mismo evento se ha repetido X veces seguidas
function DirectorMemory:isOnStreak(eventType, minCount)
	return streakCounter.current == eventType and (streakCounter.count or 0) >= minCount
end

-- Obtener la racha actual (evento y número de repeticiones)
function DirectorMemory:getCurrentStreak()
	return streakCounter.current, streakCounter.count or 0
end

-- Recomendar si se debe evitar un evento (para evitar repeticiones molestas)
-- Devuelve true si el evento ha ocurrido en los últimos N segundos O está en racha >= 2
function DirectorMemory:shouldAvoidEvent(eventType, avoidSeconds)
	if self:hasHappenedRecentlySeconds(eventType, avoidSeconds) then
		return true, "ocurrió hace muy poco"
	end
	if self:isOnStreak(eventType, 2) then
		return true, "está en racha repetida"
	end
	return false
end

-- Obtener los últimos N eventos (para depuración o narrativa)
function DirectorMemory:getLastEvents(n)
	n = math.min(n, #memory)
	local result = {}
	for i = #memory - n + 1, #memory do
		if memory[i] then
			table.insert(result, memory[i])
		end
	end
	return result
end

-- Obtener estadísticas completas (para debugging o UI de administrador)
function DirectorMemory:getStats()
	local stats = {
		totalEvents = #memory,
		eventCounts = eventCounters,
		lastEvent = memory[#memory],
		currentStreak = { event = streakCounter.current, count = streakCounter.count },
		currentDay = self:getCurrentDay(),
		chaosMultiplier = self:getChaosMultiplier(),
		dayDescription = self:getDayDescription(),
	}
	return stats
end

-- Resetear memoria (útil para reinicios de servidor o testing)
function DirectorMemory:reset()
	memory = {}
	eventCounters = {}
	lastEventOfType = {}
	streakCounter = {}
	print("🧠 DirectorMemory: MEMORIA REINICIADA. LOS QU OLVIDAN... POR AHORA.")
end

-- ==================== INICIALIZACIÓN SEGURA ====================
-- Mostrar el día actual al arrancar (llamada segura después de definir el módulo)
local function init()
	print(string.format("📅 DirectorMemory: %s | %s (caos x%.1f)", 
		DirectorMemory:getCurrentDay(), 
		DirectorMemory:getDayDescription(), 
		DirectorMemory:getChaosMultiplier()))
end
init()

return DirectorMemory
