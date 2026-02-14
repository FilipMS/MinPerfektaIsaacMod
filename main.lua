local mod = RegisterMod("MinPerfektaIsaacMod", 1)

local damagePotion = Isaac.GetItemIdByName("Damage Potion")
local damagePotionDamage = 1

function mod:EvaluateCache(player, cacheFlags)
    if cacheFlags & CacheFlag.CACHE_DAMAGE == CacheFlag.CACHE_DAMAGE then
        local itemCount = player:GetCollectibleNum(damagePotion)
        local damageToAdd = damagePotionDamage * itemCount
        player.Damage = player.Damage + damageToAdd
    end
end

mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, mod.EvaluateCache)


local bigRedButton = Isaac.GetItemIdByName("Big Red Button")

function mod:RedButtonUse()
    local roomEntities = Isaac.GetRoomEntities()
    for _, entity in ipairs(roomEntities) do
        if entity:IsActiveEnemy() and entity:IsVulnerableEnemy() then
            entity:Kill()
        end
    end

    return {
        Discharge = true,
        Remove = false,
        ShowAnim = true
    }
end

mod:AddCallback(ModCallbacks.MC_USE_ITEM, mod.RedButtonUse, bigRedButton)


local POLLEN_ITEM_ID = Isaac.GetItemIdByName("Pollen")
local POLLEN_POISON_CHANCE = 0.4
local POLLEN_POISON_LENGTH = 3
local ONE_INTERVAL_OF_POISON = 20

local game = Game()

function mod:PollenNewRoom()
    local playerCount = game:GetNumPlayers()

    for playerIndex = 0, playerCount - 1 do
        local player = Isaac.GetPlayer(playerIndex)
        local copyCount = player:GetCollectibleNum(POLLEN_ITEM_ID)

        if copyCount > 0 then
            local rng = player:GetCollectibleRNG(POLLEN_ITEM_ID)

            local entities = Isaac.GetRoomEntities()
            for _, entity in ipairs(entities) do
                if entity:IsActiveEnemy() and entity:IsVulnerableEnemy() then
                    if rng:RandomFloat() < POLLEN_POISON_CHANCE then
                        entity:AddPoison(
                            EntityRef(player),
                            POLLEN_POISON_LENGTH + (ONE_INTERVAL_OF_POISON * copyCount),
                            player.Damage
                        )
                    end
                end
            end
        end
    end
end

mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, mod.PollenNewRoom)

local suikaType = Isaac.GetPlayerTypeByName("Suika", false) -- Exactly as in the xml. The second argument is if you want the Tainted variant.
local hairCostume = Isaac.GetCostumeIdByPath("gfx/characters/suika_hair.anm2") -- Exact path, with the "resources" folder as the root
local stolesCostume = Isaac.GetCostumeIdByPath("gfx/characters/suika_stoles.anm2") -- Exact path, with the "resources" folder as the root
local SUIKAS_SHAPES_ID = Isaac.GetItemIdByName("Suika's Shapes")
local MINIS_ID = Isaac.GetItemIdByName("Minis!!")


function mod:SuikaInit(player)
    if player:GetPlayerType() ~= suikaType then
        return -- End the function early. The below code doesn't run, as long as the player isn't Gabriel.
    end

    player:AddNullCostume(hairCostume)
    player:AddNullCostume(stolesCostume)
    player:AddCollectible(SUIKAS_SHAPES_ID, 0, false)
    player:AddCollectible(MINIS_ID, 3, false)
end

mod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, mod.SuikaInit)

local SUIKAS_SHAPES_ID = Isaac.GetItemIdByName("Suika's Shapes")
TearVariant.TETRAEDER = Isaac.GetEntityVariantByName("Tetraeder")
TearVariant.KUB = Isaac.GetEntityVariantByName("Kub")
TearVariant.KLOT = Isaac.GetEntityVariantByName("Klot")


function mod:SuikaTears(tear)
    local player = tear.SpawnerEntity and tear.SpawnerEntity:ToPlayer()
    if not player then return end

    if player:HasCollectible(SUIKAS_SHAPES_ID) then
        local rng = player:GetCollectibleRNG(POLLEN_ITEM_ID)
        local randomFloat = rng:RandomFloat()
        if randomFloat < 0.2  then
            tear:ChangeVariant(TearVariant.TETRAEDER)
            tear.TearFlags = tear.TearFlags | TearFlags.TEAR_POISON
        end
        if randomFloat > 0.2 and randomFloat < 0.4  then
            tear:ChangeVariant(TearVariant.KUB)
            tear.TearFlags = tear.TearFlags | TearFlags.TEAR_POISON
        end
        if randomFloat > 0.4 and randomFloat < 0.6  then
            tear:ChangeVariant(TearVariant.KLOT)
            tear.TearFlags = tear.TearFlags | TearFlags.TEAR_POISON
        end
    end
end

mod:AddCallback(ModCallbacks.MC_POST_FIRE_TEAR, mod.SuikaTears)

function mod:onDamage(entity, amt, flag, source, countdown)
    if source.Type == EntityType.ENTITY_TEAR and source.Variant == TearVariant.TETRAEDER then
        game:Fart(entity.Position, 50, nil, 1, 0)
    end
end

mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.onDamage)
