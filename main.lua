local mod = RegisterMod("MinPerfektaIsaacMod", 1)


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
    player:AddCollectible(MINIS_ID, 4, false)
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
        if randomFloat < 0.1  then
            tear:ChangeVariant(TearVariant.TETRAEDER)
            tear.TearFlags = tear.TearFlags  | TearFlags.TEAR_BOOMERANG | TearFlags.TEAR_SPECTRAL | TearFlags.TEAR_PIERCING
            tear.Velocity = tear.Velocity * 1.2
            tear.FallingSpeed = tear.FallingSpeed - 10
            tear.FallingAcceleration = tear.FallingAcceleration * 0.6
        end
        if randomFloat > 0.1 and randomFloat < 0.2  then
            tear:ChangeVariant(TearVariant.KUB)
            tear.TearFlags = tear.TearFlags
        end
        if randomFloat > 0.2 and randomFloat < 0.3  then
            tear:ChangeVariant(TearVariant.KLOT)
            tear.TearFlags = tear.TearFlags | TearFlags.TEAR_BOUNCE | TearFlags.TEAR_POP
            tear.Velocity = tear.Velocity * 2
        end
    end
end

mod:AddCallback(ModCallbacks.MC_POST_FIRE_TEAR, mod.SuikaTears)

function mod:OnTearCollision(tear, collider, low)
        if tear.Variant == TearVariant.KUB then
            local npc = collider:ToNPC()
            if npc and npc:IsVulnerableEnemy() then

                while npc.Parent do
                    npc = npc.Parent:ToNPC()
                end

                mod:ApplyAnimaSolaEffect(npc, tear)
                tear:Remove()
            end
        end
        
end
mod:AddCallback(ModCallbacks.MC_PRE_TEAR_COLLISION, mod.OnTearCollision)

function mod:ApplyAnimaSolaEffect(npc, tear)
    local player = tear.SpawnerEntity and tear.SpawnerEntity:ToPlayer()
    if not player then return end

    local chain = Isaac.Spawn(
        EntityType.ENTITY_EFFECT,
        EffectVariant.ANIMA_CHAIN,
        0,
        npc.Position,
        Vector.Zero,
        player
    ):ToEffect()

    chain.Parent = npc
    chain.Target = npc
    chain.Timeout = 30

    chain.SpawnerEntity = player

    npc:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
end

local MINI_SUIKAS_ID = Isaac.GetItemIdByName("Minis!!")

function mod:MiniSuikasUse(_, _, player)
    local mini = player:AddMinisaac(player.Position, false)
    mini:GetData().IsSuika = true

    local mini2 = player:AddMinisaac(player.Position, false)
    mini2:GetData().IsSuika = true

    return {
        Discharge = true,
        Remove = false,
        ShowAnim = true
    }
end

mod:AddCallback(ModCallbacks.MC_USE_ITEM, mod.MiniSuikasUse, MINI_SUIKAS_ID)

function mod:UpdateMini(familiar)
    local data = familiar:GetData()
    if not data.IsSuika then return end
    if data.Init then return end
    data.Init = true

    local sprite = familiar:GetSprite()
    sprite:ReplaceSpritesheet(0, "gfx/familiar/suika_minisaac.png")
    sprite:ReplaceSpritesheet(1, "gfx/familiar/suika_minisaac.png")
    sprite:LoadGraphics()
end

mod:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, mod.UpdateMini, FamiliarVariant.MINISAAC)

