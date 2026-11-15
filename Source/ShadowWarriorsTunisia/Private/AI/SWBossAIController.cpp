#include "AI/SWBossAIController.h"
#include "Characters/SWFighterCharacter.h"
#include "Combat/SWCombatComponent.h"
#include "Kismet/GameplayStatics.h"

void ASWBossAIController::OnPossess(APawn* InPawn)
{
    Super::OnPossess(InPawn);
    BossFighter = Cast<ASWFighterCharacter>(InPawn);
    TargetPlayer = Cast<ASWFighterCharacter>(UGameplayStatics::GetPlayerCharacter(GetWorld(), 0));

    if (BossFighter && TargetPlayer)
    {
        BossFighter->SetOpponentActor(TargetPlayer);
        TargetPlayer->SetOpponentActor(BossFighter);
    }
}

void ASWBossAIController::Tick(float DeltaTime)
{
    Super::Tick(DeltaTime);

    if (!BossFighter || !TargetPlayer)
    {
        return;
    }

    USWCombatComponent* BossCombat = BossFighter->GetCombatComponent();
    if (!BossCombat || !BossCombat->IsAlive())
    {
        return;
    }

    EvaluatePhase();

    const float Dist = FVector::Dist2D(BossFighter->GetActorLocation(), TargetPlayer->GetActorLocation());
    if (Dist > OptimalMeleeRange)
    {
        BossCombat->SetBlocking(false);
        BossFighter->MoveAlongArenaAxis(1.0f);
    }

    DecisionTimer += DeltaTime;
    const float EffectiveInterval = (CurrentPhase == ESWBossPhase::Phase3_Enraged) ? DecisionInterval * 0.65f : DecisionInterval;
    if (DecisionTimer >= EffectiveInterval)
    {
        DecisionTimer = 0.0f;
        ExecuteDecision();
    }
}

void ASWBossAIController::EvaluatePhase()
{
    const float HealthPct = BossFighter->GetCombatComponent()->GetHealthPercent();
    if (HealthPct <= 0.25f)
    {
        CurrentPhase = ESWBossPhase::Phase3_Enraged;
    }
    else if (HealthPct <= 0.60f)
    {
        CurrentPhase = ESWBossPhase::Phase2_Aggressive;
    }
    else
    {
        CurrentPhase = ESWBossPhase::Phase1_Measured;
    }
}

void ASWBossAIController::ExecuteDecision()
{
    USWCombatComponent* BossCombat = BossFighter->GetCombatComponent();
    USWCombatComponent* PlayerCombat = TargetPlayer->GetCombatComponent();
    if (!BossCombat || !PlayerCombat || !PlayerCombat->IsAlive())
    {
        return;
    }

    const float Dist = FVector::Dist2D(BossFighter->GetActorLocation(), TargetPlayer->GetActorLocation());

    if (PlayerCombat->GetCombatState() == ESWCombatState::Attacking && Dist <= OptimalMeleeRange + 40.f)
    {
        const float Roll = FMath::FRand();
        if (Roll < 0.45f)
        {
            BossCombat->SetBlocking(true);
            return;
        }
        if (Roll < 0.65f)
        {
            BossCombat->RequestDodge(-1.0f);
            return;
        }
    }

    BossCombat->SetBlocking(false);

    if (Dist <= OptimalMeleeRange)
    {
        if (BossCombat->GetEnergyPercent() >= 1.0f && CurrentPhase == ESWBossPhase::Phase3_Enraged)
        {
            BossCombat->RequestAttack(ESWAttackInput::Ultimate);
            return;
        }

        if (BossCombat->GetEnergyPercent() >= 0.5f && CurrentPhase != ESWBossPhase::Phase1_Measured && FMath::FRand() < 0.35f)
        {
            BossCombat->RequestAttack(ESWAttackInput::Special);
            return;
        }

        const float AttackRoll = FMath::FRand();
        BossCombat->RequestAttack(AttackRoll < 0.62f ? ESWAttackInput::Light : ESWAttackInput::Heavy);
    }
}
