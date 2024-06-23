require('NPCs/MainCreationMethods');

local function tableContains(t, e)
	for _, value in pairs(t) do
		if value == e then
			return true
		end
	end
	return false
end

local function randomInjury(iterations)
	local player = getPlayer();
	local bodydamage = player:getBodyDamage();
	for i = 1, iterations do
		local randompart = ZombRand(0, 16);
		local b = bodydamage:getBodyPart(BodyPartType.FromIndex(randompart));
		local skip = false;
		if b:HasInjury() then
			iterations = iterations + 1;
			skip = true;
		end
		if skip == false then
			b:setScratched(true, true);
		end
        end
end

local function onZombieDeath(_zombie)
	local player = getPlayer()
	local stats = player:getStats()
	local anger = stats:getAnger()
	local val = 0.025
	if player:HasTrait("Berserk") then 
		val = val * -1
		if player:HasTrait("Calm") then val = val * 0.70 
		elseif player:HasTrait("Irritable") then val = val * 1.30 end
	end
	stats:setAnger(anger-val)
end
Events.OnZombieDead.Add(onZombieDeath);

local function onHit(_actor, _target, _weapon, _damage)
	if _target:isZombie() then
		local player = getPlayer()
		local stats = player:getStats()
		local anger = stats:getAnger()
		local endurance = stats:getEndurance()
		local val = 0.0075
		if player:HasTrait("Berserk") then 
			val = val * -1 
		end
		if player:HasTrait("Calm") then val = val * 0.70 
		elseif player:HasTrait("Irritable") then val = val * 1.30 end
		stats:setAnger(anger-val)
		if player:HasTrait("Pacifist")  or _weapon:isRanged() then return end
		local newdmg = _damage * anger * 0.5
		if _weapon:getType() == "BareHands" then newdmg = newdmg*0.25 end
		_target:setHealth(_target:getHealth() - newdmg)
		if _target:getHealth() <= 0 then
			_target:update()
		end
		if _weapon:getType() == "BareHands" then 
			stats:setEndurance(endurance - 0.003*anger)
			return 
		end
		
		local emod = _weapon:getEnduranceMod()
		local weight = _weapon:getEquippedWeight()
		stats:setEndurance(endurance - (weight*emod*anger*0.01))
	
		local condition = _weapon:getCondition()
		local mul = 100 + player:getPerkLevel(Perks.Maintenance)
		if player:HasTrait("Lucky") then mul = mul + 25 end
		if player:HasTrait("Unlucky") then mul = mul - 25 end
		if  ZombRand(mul) < (anger*anger)* _weapon:getConditionLowerChance()  then
			_weapon:setCondition(condition-1)
		end
		if _weapon:getCondition() <= 0 then
			local anger = stats:getAnger()
			local val = 0.15
			if player:HasTrait("Calm") then val = val * 0.70 
			elseif player:HasTrait("Irritable") then val = val * 1.30 end
			stats:setAnger(anger+val)
		end
	end
end
Events.OnWeaponHitCharacter.Add(onHit)

local function EveryOneMinute()
	local player = getPlayer()
	if player:HasTrait("Peace") or player:HasTrait("Desensitized") then return end
	local bd = player:getBodyDamage()
	local stats = player:getStats();
	local head = bd:getBodyPart(BodyPartType.Head)
	local hpain = head:getAdditionalPain()
	local tpain = stats:getPain()
	local posMul = 1
	local negMul = 1
	local inc = hpain > 25 and (hpain-25)*-0.0004 or 0
	--player:SayShout("HPain: " .. hpain)
	--player:SayShout("Pain: " .. tpain)
	local pain = tpain*0.01
	if player:HasTrait("Pacifist") then 
		posMul = 1.10
	elseif player:HasTrait("Calm") then 
		posMul = 1.30
		if stats:getAnger()*0.70 > pain then pain = 0 end
	elseif player:HasTrait("Irritable") then 
		negMul = 1.30 
		if stats:getAnger()*negMul > pain then pain = 0 end
	end
	inc = inc + (pain*0.033*negMul)
	
	if  player:isKnockedDown() or player:isBumped() then inc = inc + (0.1*negMul)
	elseif player:isReading() then inc = inc - (0.01*posMul)
	elseif player:isSneaking() or player:isSitOnGround() or player:isAsleep() or player:isbOnBed() then inc = inc - (0.01*posMul) end
	if player:getSpottedList():size() == 0 then inc = inc - (0.01*posMul) end
	
	local hunger = stats:getHunger()  
	if hunger == 0 then inc = inc - (0.02*posMul) 
	elseif hunger > 0.5 then inc = inc + (0.0025*negMul) end
	local drunk = toInt((stats:getDrunkenness()+0.25)*0.25)
	if drunk > 0 and player:HasTrait("Irritable") then drunk = drunk + 1 end
	if ZombRand(350)+1 <= drunk then inc = inc + (0.15*posMul) end
	
	local anger = stats:getAnger() + inc
	local intAnger = toInt(anger*100)
	if player:isInTrees() and player:isPlayerMoving() and ZombRand(100) < 20 then
		anger = anger + 0.075*negMul
	end
	if anger > 1 then anger = 1 end
	stats:setAnger(anger)
	--player:SayShout("Anger: " .. anger)
	
	if player:isAsleep() then return end
	
	local stress = stats:getStress()
	if stress < anger then
		stats:setStress(stress + 0.003)
	end
	
	if anger > 0.5 then
		local unhappiness = bd:getUnhappynessLevel()
		bd:setUnhappynessLevel(unhappiness+anger*0.25)
	end
	if anger > 0.75 then
		--local head = bd:getBodyPart(BodyPartType.Head)
		--[[
		if head:getHealth() > 80 then
			local mul = 0.4
			if player:HasTrait("FastHealer") then mul = mul - 0.05 end
			if player:HasTrait("Resilient") then mul = mul - 0.05 end
			if player:HasTrait("SlowHealer") then mul = mul + 0.05 end
			if player:HasTrait("ProneToIllness") then mul = mul + 0.05 end
			head:AddDamage(anger*mul)
		end--]]
		if hpain < 35 then head:setAdditionalPain(hpain+1) end
		
		if player:isInTrees() and player:isPlayerMoving() and ZombRand(350) <= intAnger then
			randomInjury(1)
			if player:HasTrait("Irritable") then
				stats:setAnger(anger + 0.5)
			elseif player:HasTrait("Calm") then
				stats:setAnger(anger - 0.5)
			end
		end
	end
end
Events.EveryOneMinute.Add(EveryOneMinute);

local function MainPlayerUpdate()
	local player = getPlayer()
	local stats = player:getStats()
	if player:HasTrait("Peace") or player:HasTrait("Desensitized") then
		stats:setAnger(0)
	end
	
	local anger = stats:getAnger()
	if anger > 0 and player:hasTimedActions() then
		local actions = player:getCharacterActions()
		local action = actions:get(0);
		local mtype = action:getMetaType();
		local delta = action:getJobDelta();
		
		if (mtype == "ISDestroyStuffAction" or mtype == "ISFitnessAction") and delta > 0 then
			stats:setAnger(anger - 0.00075)
			return
		end
		
		if anger > 0.75 and mtype == "ISReadABook" and delta < 0.95 and ZombRand(300) == 0 then
			player:SayShout("Je ne peux pas me concentrer.")
			action:forceStop()
			return
		end
		
		local list = { "ISCraftAction", "ISLoadBulletsInMagazine", "ISPlaceCarBatteryChargerAction","ISPlaceTrap","ISReadABook","ISRemoveBullet","ISRepairClothing" ,"ISUpgradeWeapon","ISDismantleAction","ISFixGenerator","ISFixAction"}
		if tableContains(list, mtype) and delta > 0 and delta < 0.95 then
			action:setCurrentTime(action:getCurrentTime() - 0.25);
			return
		end
		
		
	end
end
Events.OnPlayerUpdate.Add(MainPlayerUpdate);
