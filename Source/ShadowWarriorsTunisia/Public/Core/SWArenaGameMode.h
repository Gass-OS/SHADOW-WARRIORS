#pragma once

#include "CoreMinimal.h"
#include "GameFramework/GameModeBase.h"
#include "Combat/SWCombatTypes.h"
#include "SWArenaGameMode.generated.h"

class ASWFighterCharacter;

DECLARE_DYNAMIC_MULTICAST_DELEGATE_OneParam(FOnMatchEndedSignature, bool, bPlayerWon);

UCLASS()
class SHADOWWARRIORSTUNISIA_API ASWArenaGameMode : public AGameModeBase
{
    GENERATED_BODY()

public:
    virtual void BeginPlay() override;

    UFUNCTION(BlueprintCallable, Category = "Match")
    void RegisterMatchFighters(ASWFighterCharacter* PlayerFighter, ASWFighterCharacter* EnemyFighter);

    UPROPERTY(BlueprintAssignable, Category = "Match")
    FOnMatchEndedSignature OnMatchEnded;

protected:
    UPROPERTY(EditDefaultsOnly, Category = "Match")
    float RoundDurationSeconds = 99.0f;

private:
    UFUNCTION()
    void HandlePlayerDefeated();

    UFUNCTION()
    void HandleEnemyDefeated();

    bool bMatchConcluded = false;
};
