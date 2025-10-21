--Server 
local Http = game:GetService("HttpService")

local EffectReplicator = {}


local function CreateSignal()
	local Signal = Instance.new("BindableEvent")
	Signal.Name = "Shadow"
	return Signal
end

function EffectReplicator.New(Self,LivingObject) -- when characrter joins / get created it creates a shell that will store the effects

	local Shell = {}
	Shell.Being = LivingObject
	Shell.Effects = {}
	Shell.Container = LivingObject
	Shell.EffectAdded = CreateSignal()
	Shell.EffectRemoved = CreateSignal()


	--using meta tables to confuse infinity yield users... jk jk

	setmetatable(Shell , EffectReplicator)
	EffectReplicator.__index = EffectReplicator

	return Shell	

end

-- im calling from other scripts with : so its sends it self first argument
--  i just find it more readable than just using self normally
function EffectReplicator.CreateEffect(Self, EffectName, Arguments)

	if not Arguments then Arguments = {} end

	local NewEffect = {}
	NewEffect.Owner = EffectReplicator.Container
	NewEffect.Class = EffectName
	NewEffect.Value = Arguments.Value or true 
	NewEffect.Tags = Arguments.Tags or {}
	NewEffect.ID =  Http:GenerateGUID()
	NewEffect.Domain =  "Server"
	NewEffect.Disabled = Arguments.Disabled or false

	--creates a new effect with a unique id
	--and gets the domain


	-- meta tables to treat every effect as an object 
	-- makes it easier to edit it on the run in game 
	-- with just destory / edit the debris time
	local Shell = {
		Index = NewEffect	
	}

	function Shell.Destroy(Effect)
		Self.EffectRemoved:Fire(Effect)

		Self.Effects[Effect.ID] = nil

	end

	function Shell.Debris(Self,Time,Update)
		if not Time then Time = 0 end

		Self.DebrisTime = Time


		local T = Time
		task.delay(Time,function()
			if Self then
				if T == Self.DebrisTime then
					Self:Destroy()
				end
			end

		end)

	end

	Self.Effects[NewEffect.ID] = NewEffect

	setmetatable(NewEffect,{__index = Shell})

	-- now for i recreated collectionservice methods to make it easeir to use

	if Self.EffectAdded then
		Self.EffectAdded:Fire(NewEffect)
	end
	return NewEffect
end

--gets effects

function EffectReplicator.GetEffects(Self)
	return Self.Effects
end

-- gets minimal data for the effects

function EffectReplicator.GetStrippedEffects(Self)

	local ShellEffects = Self.Effects 
	local ToGive = {}

	for i , EffectData in ShellEffects do
		table.insert(ToGive,{
			Class = EffectData.Class,
			Disabled = EffectData.Disabled or nil,
			Tags = EffectData.Tags or nil,
			Domain = EffectData.Domain,
			ID = EffectData.ID,
			Value = EffectData.Value or nil,
			DebrisTime = EffectData.DebrisTime or nil,	
		})

	end
	return ToGive
end

-- find effect based on name (class)
function EffectReplicator.FindEffect(Self,Class)
	for i ,Effect in Self.Effects do

		if Effect.Class == Class then
			if not Effect.Disabled then
				return Effect
			end
		end

	end
	return nil
end

-- clears an entire class 
--so if i have multiple slow effects and i get a cc immune potion i can just clear all slows

function EffectReplicator.ClearClass(Self,Class,IgnoreDisabled)
	for i ,Effect in Self.Effects do
		if Effect.Class == Class then
			if IgnoreDisabled then
				if not Effect.Disabled then
					Effect:Destroy()
				end
			else
				Effect:Destroy()
			end
		end

	end
end

-- effects can store values like slow = -16
-- and tags , tags is like values but another way to store information primarly used for strings
function EffectReplicator.GetEffectsWithTag(Self,tag)
	local effectsArray = {}

	for _, effect in next, Self.Effects do
		if (effect.Tags[tag]) then
			table.insert(effectsArray, effect)
		end
	end

	return effectsArray
end




return EffectReplicator

--Client Side
local Http = game:GetService("HttpService")

local EffectReplicator = {

	Effects = {},
	Container = nil,

}


function EffectReplicator.CreateEffect(Self, EffectName, Arguments)

	if not Arguments then Arguments = {} end

	local NewEffect = {}
	NewEffect.Owner = EffectReplicator.Container
	NewEffect.Class = EffectName
	NewEffect.Value = Arguments.Value or true
	NewEffect.Tags = Arguments.Tags or {}
	NewEffect.ID = Arguments.ID or Http:GenerateGUID()
	NewEffect.Domain = Arguments.Domain or "Client"
	NewEffect.Disabled = Arguments.Disabled or false


	local Shell = {
		Index = NewEffect	
	}

	function Shell.Destroy()

		if Self.EffectRemoved and Self.EffectRemoved.Shadow then
			Self.EffectRemoved.Shadow:Fire(NewEffect)
		end



		Self.Effects[NewEffect.ID] = nil

	end

	function Shell.Debris(Self,Time)
		if not Time then Time = 0 end

		NewEffect.DebrisTime = Time


		delay(Time,function()
			if NewEffect then
				NewEffect:Destroy()
			end

		end)

	end



	setmetatable(NewEffect,{__index = Shell})

	Self.Effects[NewEffect.ID] = NewEffect

	--[[print(NewEffect.Class)
	print(EffectReplicator.Effects)
	print(Self.Effects)]]

	if Self.EffectAdded and Self.EffectAdded.Shadow then
		Self.EffectAdded.Shadow:Fire(NewEffect)
	end
	return NewEffect
end


function EffectReplicator.FindEffectByID(Self,EffectID)
	return Self.Effects[EffectID]
end

function EffectReplicator:GetEffect(Effect)
	return EffectReplicator.Effects[Effect.ID or Effect]
end

function EffectReplicator.GetStrippedEffects(Self)

	local ShellEffects = Self.Effects
	local ToGive = {}


	for i , EffectData in ShellEffects do
		table.insert(ToGive,{
			Class = EffectData.Class,
			Disabled = EffectData.Disabled or nil,
			Tags = EffectData.Tags or nil,
			Domain = EffectData.Domain,
			ID = EffectData.ID,
			Value = EffectData.Value or nil,
			DebrisTime = EffectData.DebrisTime or nil,	
		})

	end
	return ToGive
end

function EffectReplicator.FindEffect(Self,Class)
	for i ,Effect in Self.Effects do
		if Effect.Class == Class then
			if not Effect.Disabled then
				return Effect
			end
		end

	end
	return nil
end

function EffectReplicator.GetEffects(Self)
	return Self.Effects
end

function EffectReplicator.ClearClass(Self,Class,IgnoreDisabled)
	for i ,Effect in Self.Effects do
		if Effect.Class == Class then
			if IgnoreDisabled then
				if not Effect.Disabled then
					Effect:Destroy()
				end
			else
				Effect:Destroy()
			end
		end

	end
end

function EffectReplicator.GetEffectsWithTag(Self,tag)
	local effectsArray = {}

	for _, effect in next, Self.Effects do
		if (effect.Tags[tag]) then
			table.insert(effectsArray, effect)
		end
	end

	return effectsArray
end

function EffectReplicator.WaitForContainer(Self)
	while EffectReplicator.Container == nil do
		print(EffectReplicator.Container)
		task.wait()
	end
	return Self
end


local Connector = {

	Connect = function(Self,CallBack)

		if type(CallBack) ~= "function" then
			return
		end
		local Shadow = Self.Shadow
		if not Shadow then
			Shadow = Instance.new("BindableEvent")
			Shadow.Name = "ContainerShadowBindable"
			Self.Shadow = Shadow
		end
		return Shadow.Event:connect(function(Effect)
			local ToGive = EffectReplicator:GetEffect(Effect)
			if not ToGive then
				return
			end
			CallBack(ToGive)
		end)


	end,


}

-- really just a diffrent way instead of using bindables really make it easier while typing and 
-- im pretty sure its faster cause of the callback method havnt tested preformace tho



local EffectAdded = {}
local EffectRemoved = {}
setmetatable(EffectAdded, {
	__index = Connector
})
setmetatable(EffectRemoved, {
	__index = Connector
})
EffectReplicator.EffectAdded = EffectAdded
EffectReplicator.EffectRemoved = EffectRemoved

game.ReplicatedStorage.Requests.EffectReplication:WaitForChild("_update").OnClientEvent:connect(function(Arguments)
	if not Arguments.Type then return end

	local Type = Arguments.Type
	local Effects , EffectID , Container = Arguments.Effects or nil , Arguments.EffectID or nil , Arguments.Container or nil


	if Type == "Update" then
		for _ , Effect in Effects do

			local ClientEffect = EffectReplicator:GetEffect(Effect.ID)

			if ClientEffect then



				ClientEffect.Value = Effect.Value
				ClientEffect.DebrisTime = Effect.DebrisTime
				if Effect.Disabled ~= nil then
					ClientEffect.Disabled = Effect.Disabled
				end
				if Effect.Tags ~= nil then
					ClientEffect.Tags = Effect.Tags
				end



			else

				local NewEffect = EffectReplicator:CreateEffect(Effect.Class,
					{Value = Effect.Value ,
						Tags = Effect.Tags,
						Doamin = Effect.Domain,
						ID = Effect.ID
					})
				if Effect.DebrisTime then
					NewEffect:Debris(Effect.DebrisTime or 0,true)
				end



			end



		end

	elseif Type == "Remove" then
		local ToRemove = EffectReplicator:FindEffectByID(EffectID)

		if ToRemove then
			ToRemove:Destroy()
		end

	elseif Type == "SetContainer" then
		if Container then
			EffectReplicator.Container = Container
			print("Hello contianer set")
			print(EffectReplicator.Container)
		end
	end


end)




return EffectReplicator