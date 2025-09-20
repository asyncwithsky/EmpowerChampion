local _G = _G or getfenv(0)
local EmpowerChampion = _G.EmpowerChampion or {}
_G.EmpowerChampion = EmpowerChampion

if UnitClass("player") ~= "Priest" then return end

EmpowerChampion.proclaimChampion 	= 	{id=45562, name="Proclaim Champion", icon="Spell_Holy_ProclaimChampion_02", dur=nil}
EmpowerChampion.championsGrace 		= 	{id=45563, name="Champion's Grace", icon="Spell_Holy_ChampionsGrace", dur=1800}
EmpowerChampion.championsBond 		= 	{id=45564, name="Champion's Bond", icon="Spell_Holy_ChampionsBond", dur=600}
EmpowerChampion.empowerChampion 	= 	{id=45565, name="Empower Champion", icon="Spell_Holy_EmpowerChampion", dur=600}
EmpowerChampion.spellMap = {
	[EmpowerChampion.proclaimChampion.id] 	= EmpowerChampion.proclaimChampion,
	[EmpowerChampion.championsGrace.id] 	= EmpowerChampion.championsGrace,
	[EmpowerChampion.championsBond.id] 		= EmpowerChampion.championsBond,
	[EmpowerChampion.empowerChampion.id] 	= EmpowerChampion.empowerChampion
}

EmpowerChampion.lastUpdate = GetTime()
EmpowerChampion.buff = nil
EmpowerChampion.champion = nil
EmpowerChampion.buff_tracking = {}
EmpowerChampion.Frame = CreateFrame("GameTooltip")
EmpowerChampion.Frame:SetScript("OnEvent", function(...)
	EmpowerChampion.Frame[event](this,arg1,arg2,arg3,arg4,arg5,arg6,arg7,arg8,arg9,arg10)
end)
EmpowerChampion.Frame:SetScript("OnUpdate", EmpowerChampion.OnUpdate)
EmpowerChampion.Frame:RegisterEvent("UNIT_CASTEVENT")
EmpowerChampion.Frame:RegisterEvent("PLAYER_LOGIN")
EmpowerChampion.Frame:RegisterEvent("CHAT_MSG_SPELL_FAILED_LOCALPLAYER")
EmpowerChampion.Frame:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_PARTY")

SLASH_EMPOWERCHAMPION1 = "/empower"
SlashCmdList["EMPOWERCHAMPION"] = function(cmd)
	empower()
end


function EmpowerChampion.OnUpdate(self)
    local time = GetTime()
    if (time - EmpowerChampion.lastUpdate) < 5 then return end
    EmpowerChampion.lastUpdate = time

    for guid,buff in EmpowerChampion.buff_tracking do
        if time > buff.expires then
            EmpowerChampion.buff_tracking[guid] = nil
        end
    end
end

function EmpowerChampion.Frame:Print(msg)
	DEFAULT_CHAT_FRAME:AddMessage(string.format("[|cFFe81515Emp|r|cFF5e34b2Champ|r] %s", msg))
end

function EmpowerChampion.Frame:PLAYER_LOGIN()
	self:Print("|cFFe81515Empower|r Your |cFF5e34b2Champion|r and then Use |cFFe497a9/empower|r for maintaining the buff for proclaimed players.")
end

function EmpowerChampion.Frame:UNIT_CASTEVENT(caster, target, action, spell_id, cast_time)
    if action == "MAINHAND" or action == "OFFHAND" then return end
    
    local _, guid = UnitExists("player")
    local isPlayer = caster == guid
    if isPlayer and action == "CAST" then 
		local spell = EmpowerChampion.spellMap[spell_id]
		if not spell then return end
		
		local shouldSetChampion = (spell_id == EmpowerChampion.proclaimChampion.id) or
								 (EmpowerChampion.champion == nil and 
								  (spell_id == EmpowerChampion.championsBond.id or 
								   spell_id == EmpowerChampion.championsGrace.id or 
								   spell_id == EmpowerChampion.empowerChampion.id))
		
		if shouldSetChampion then
			-- self:Print("Champion set for %s", UnitName(target))
			EmpowerChampion.champion = target
		end
		
		if spell_id ~= EmpowerChampion.proclaimChampion.id then
			EmpowerChampion.buff = spell
			-- Print(EmpowerChampion.buff.name)
			if spell.dur then
				EmpowerChampion.buff_tracking[target] = {
					buff = spell,
					expires = GetTime() + spell.dur,
					type = action
				}
			end
		end
	elseif EmpowerChampion.champion ~= nil and target == EmpowerChampion.champion and action == "CAST" and spell_id == EmpowerChampion.proclaimChampion.id then
		self:Print(string.format("That priest <|cFFe497a9%s|r> has overridden your |cff2596beProclaim Champion|r from <|cFFe497a9%s|r>.", UnitName(caster), UnitName(target)))
		EmpowerChampion.champion = nil
	end
end

function EmpowerChampion.Frame:CHAT_MSG_SPELL_FAILED_LOCALPLAYER(arg1)
	if string.find(arg1, "You haven't sel") then
		self:Print("Your last |cff2596beProclaim Champion|r probably was expired or has been overridden by other priest.")
		EmpowerChampion.champion = nil
	end
end

function EmpowerChampion.Frame:CHAT_MSG_SPELL_AURA_GONE_PARTY(arg1)
	local _, _, spellName, _ = string.find(arg1, "(.+) fades from .+\.")
	local _, _, playerName, _ = string.find(arg1, ".+ fades from (.+)\.")
	-- Print(spellName, playerName)
	if EmpowerChampion.buff ~= nil and EmpowerChampion.champion ~= nil and spellName == EmpowerChampion.buff.name and playerName == UnitName(EmpowerChampion.champion) then
		-- Print('champ buff is off')
		EmpowerChampion.buff_tracking[EmpowerChampion.champion] = nil
	end
end

function checkBuff(buff, target)
	-- Put type check for buff variable
	for i=1,32 do
		local texture, stack, spell_id = UnitBuff(target, i)
		if spell_id == buff.id then
			return true
		end
	end
	return false
end


function castEmpower(target)
	local _, guid = UnitExists(target)
	if target ~= guid then
		-- Print('Cannot buff proclaimed champion')
		return
	end
	local targetWasChanged = false
	local AutoSelfCast = GetCVar("autoSelfCast");
    SetCVar("autoSelfCast", 0);
	
	if UnitName('target') ~= nil and UnitName(target) ~= UnitName('target') then
		targetWasChanged = true
		ClearTarget()
	end
	
    if SpellIsTargeting() then
        SpellStopTargeting()
    end
	CastSpellByName(EmpowerChampion.buff.name)
	if SpellCanTargetUnit(target) then
		SpellTargetUnit(target)
	else
		SpellStopTargeting()
	end
	
	if targetWasChanged then
		TargetLastTarget()
	end
    SetCVar("autoSelfCast", AutoSelfCast);
end

function empower()
	if EmpowerChampion.champion == nil or EmpowerChampion.buff == nil then return end
	local buffed = checkBuff(EmpowerChampion.buff, EmpowerChampion.champion)
	local readyForUpdate = false
	if buffed and EmpowerChampion.buff_tracking[EmpowerChampion.champion] ~= nil then
		local remaining_time = EmpowerChampion.buff_tracking[EmpowerChampion.champion].expires-GetTime()
		-- If less than half of duration for empower buff we should update current buff
		if EmpowerChampion.buff.dur / 2 > remaining_time then
			readyForUpdate = true
		end
	end
	if not buffed or (readyForUpdate and not UnitAffectingCombat("player") and not UnitAffectingCombat(EmpowerChampion.champion)) then
		castEmpower(EmpowerChampion.champion)
	end
end

_G["EmpowerChampion"] = EmpowerChampion