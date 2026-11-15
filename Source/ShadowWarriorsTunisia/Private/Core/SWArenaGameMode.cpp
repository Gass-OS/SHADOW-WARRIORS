#include "Core/SWArenaGameMode.h"
#include "Characters/SWFighterCharacter.h"
#include "Combat/SWCombatComponent.h"

void ASWArenaGameMode::BeginPlay()
{
    Super::BeginPlay();
}

void ASWArenaGameMode::RegisterMatchFighters(ASWFighterCharacter* PlayerFighter, ASWFighterCharacter* EnemyFighter)
{
    if (!PlayerFighter || !EnemyFighter)
    {
        return;
    }

    PlayerFighter->SetOpponentActor(EnemyFighter);
    EnemyFighter->SetOpponentActor(PlayerFighter);

    if (USWCombatComponent* PlayerCombat = PlayerFighter->GetCombatComponent())
    {
        PlayerCombat->OnFighterDefeated.AddDynamic(this, &ASWArenaGameMode::HandlePlayerDefeated);
    }

    if (USWCombatComponent* EnemyCombat = EnemyFighter->GetCombatComponent())
    {
        EnemyCombat->OnFighterDefeated.AddDynamic(this, &ASWArenaGameMode::HandleEnemyDefeated);
    }
}

void ASWArenaGameMode::HandlePlayerDefeated()
{
    if (!bMatchConcluded)
    {
        bMatchConcluded = true;
        OnMatchEnded.Broadcast(false);
    }
}

void ASWArenaGameMode::HandleEnemyDefeated()
{
    if (!bMatchConcluded)
    {
        bMatchConcluded = true;
        OnMatchEnded.Broadcast(true);
    }
}
