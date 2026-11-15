#pragma once

#include "CoreMinimal.h"
#include "AIController.h"
#include "SWBossAIController.generated.h"

class ASWFighterCharacter;

UENUM(BlueprintType)
enum class ESWBossPhase : uint8
{
    Phase1_Measured,
    Phase2_Aggressive,
    Phase3_Enraged
};

UCLASS()
class SHADOWWARRIORSTUNISIA_API ASWBossAIController : public AAIController
{
    GENERATED_BODY()

public:
    virtual void OnPossess(APawn* InPawn) override;
    virtual void Tick(float DeltaTime) override;

protected:
    UPROPERTY(EditDefaultsOnly, Category = "Boss AI")
    float OptimalMeleeRange = 175.0f;

    UPROPERTY(EditDefaultsOnly, Category = "Boss AI")
    float DecisionInterval = 0.28f;

private:
    void EvaluatePhase();
    void ExecuteDecision();

    UPROPERTY()
    TObjectPtr<ASWFighterCharacter> BossFighter;

    UPROPERTY()
    TObjectPtr<ASWFighterCharacter> TargetPlayer;

    ESWBossPhase CurrentPhase = ESWBossPhase::Phase1_Measured;
    float DecisionTimer = 0.0f;
};
