#include "Combat/SWCombatComponent.h"
#include "Characters/SWFighterCharacter.h"
#include "Animation/AnimInstance.h"
#include "Components/SkeletalMeshComponent.h"
#include "Engine/World.h"
#include "TimerManager.h"

USWCombatComponent::USWCombatComponent()
{
    PrimaryComponentTick.bCanEverTick = true;
}

void USWCombatComponent::BeginPlay()
{
    Super::BeginPlay();
    OwnerFighter = Cast<ASWFighterCharacter>(GetOwner());
}

void USWCombatComponent::InitializeFromProfile(USWFighterProfileAsset* Profile)
{
    FighterProfile = Profile;
    if (!FighterProfile)
    {
        return;
    }

    MaxHealth = FighterProfile->MaxHealth;
    CurrentHealth = MaxHealth;
    MaxEnergy = FighterProfile->MaxEnergy;
    CurrentEnergy = 0.0f;

    OnHealthChanged.Broadcast(CurrentHealth, MaxHealth);
    OnEnergyChanged.Broadcast(CurrentEnergy, MaxEnergy);
}

void USWCombatComponent::TickComponent(float DeltaTime, ELevelTick TickType, FActorComponentTickFunction* ThisTickFunction)
{
    Super::TickComponent(DeltaTime, TickType, ThisTickFunction);

    if (CurrentState == ESWCombatState::PerfectParryWindow)
    {
        ParryElapsed += DeltaTime;
        if (ParryElapsed >= PerfectParryDuration)
        {
            SetCombatState(ESWCombatState::Blocking);
        }
    }

    if (bWeaponHitboxActive && CurrentState == ESWCombatState::Attacking)
    {
        PerformWeaponSweep();
    }
}

void USWCombatComponent::SetCombatState(ESWCombatState NewState)
{
    if (CurrentState == NewState)
    {
        return;
    }
    const ESWCombatState OldState = CurrentState;
    CurrentState = NewState;
    OnCombatStateChanged.Broadcast(NewState, OldState);
}

void USWCombatComponent::RequestAttack(ESWAttackInput InputType)
{
    if (!FighterProfile || !IsAlive())
    {
        return;
    }

    if (CurrentState == ESWCombatState::HitStun ||
        CurrentState == ESWCombatState::KnockedDown ||
        CurrentState == ESWCombatState::Dodging)
    {
        return;
    }

    if (CurrentState == ESWCombatState::Attacking)
    {
        if (bComboWindowOpen)
        {
            bHasBufferedInput = true;
            BufferedInput = InputType;
        }
        return;
    }

    FSWAttackMoveData ChosenMove;
    bool bFoundMove = false;

    switch (InputType)
    {
    case ESWAttackInput::Light:
        if (FighterProfile->LightComboChain.Num() > 0)
        {
            ChosenMove = FighterProfile->LightComboChain[LightComboIndex % FighterProfile->LightComboChain.Num()];
            LightComboIndex++;
            HeavyComboIndex = 0;
            bFoundMove = true;
        }
        break;

    case ESWAttackInput::Heavy:
        if (FighterProfile->HeavyComboChain.Num() > 0)
        {
            ChosenMove = FighterProfile->HeavyComboChain[HeavyComboIndex % FighterProfile->HeavyComboChain.Num()];
            HeavyComboIndex++;
            LightComboIndex = 0;
            bFoundMove = true;
        }
        break;

    case ESWAttackInput::Special:
        if (CurrentEnergy >= FighterProfile->SpecialMove.EnergyCost)
        {
            ChosenMove = FighterProfile->SpecialMove;
            bFoundMove = true;
        }
        break;

    case ESWAttackInput::Ultimate:
        if (CurrentEnergy >= FighterProfile->UltimateMove.EnergyCost)
        {
            ChosenMove = FighterProfile->UltimateMove;
            bFoundMove = true;
        }
        break;
    }

    if (bFoundMove)
    {
        ExecuteMove(ChosenMove);
    }
}

void USWCombatComponent::ExecuteMove(const FSWAttackMoveData& MoveData)
{
    if (!OwnerFighter)
    {
        return;
    }

    ActiveMoveData = MoveData;
    HitActorsThisSwing.Empty();
    bComboWindowOpen = false;
    bHasBufferedInput = false;

    if (MoveData.EnergyCost > 0.0f)
    {
        ApplyEnergyDelta(-MoveData.EnergyCost);
    }

    SetCombatState(ESWCombatState::Attacking);

    if (UAnimInstance* AnimInst = OwnerFighter->GetMesh()->GetAnimInstance())
    {
        if (MoveData.Montage)
        {
            AnimInst->Montage_Play(MoveData.Montage, 1.0f);
        }
        else
        {
            PerformWeaponSweep();
            EndCurrentAttack();
        }
    }
}

void USWCombatComponent::SetWeaponHitboxActive(bool bActive)
{
    bWeaponHitboxActive = bActive;
    if (bActive)
    {
        HitActorsThisSwing.Empty();
    }
}

void USWCombatComponent::OpenComboWindow(bool bOpen)
{
    bComboWindowOpen = bOpen;
    if (bOpen && bHasBufferedInput)
    {
        const ESWAttackInput NextInput = BufferedInput;
        bHasBufferedInput = false;
        CurrentState = ESWCombatState::Idle;
        RequestAttack(NextInput);
    }
}

void USWCombatComponent::EndCurrentAttack()
{
    bWeaponHitboxActive = false;
    bComboWindowOpen = false;

    if (bHasBufferedInput)
    {
        const ESWAttackInput NextInput = BufferedInput;
        bHasBufferedInput = false;
        CurrentState = ESWCombatState::Idle;
        RequestAttack(NextInput);
        return;
    }

    LightComboIndex = 0;
    HeavyComboIndex = 0;
    if (IsAlive())
    {
        SetCombatState(ESWCombatState::Idle);
    }
}

void USWCombatComponent::PerformWeaponSweep()
{
    if (!OwnerFighter || !OwnerFighter->GetMesh())
    {
        return;
    }

    const USkeletalMeshComponent* MeshComp = OwnerFighter->GetMesh();
    const FVector StartLoc = MeshComp->DoesSocketExist(WeaponStartSocket)
        ? MeshComp->GetSocketLocation(WeaponStartSocket)
        : OwnerFighter->GetActorLocation() + OwnerFighter->GetActorForwardVector() * 40.f;
    const FVector EndLoc = MeshComp->DoesSocketExist(WeaponTipSocket)
        ? MeshComp->GetSocketLocation(WeaponTipSocket)
        : OwnerFighter->GetActorLocation() + OwnerFighter->GetActorForwardVector() * 145.f;

    TArray<FHitResult> HitResults;
    FCollisionQueryParams QueryParams(SCENE_QUERY_STAT(SWWeaponSweep), false, OwnerFighter);

    const bool bHit = GetWorld()->SweepMultiByChannel(
        HitResults,
        StartLoc,
        EndLoc,
        FQuat::Identity,
        ECC_Pawn,
        FCollisionShape::MakeSphere(ActiveMoveData.WeaponTraceRadius),
        QueryParams);

    if (!bHit)
    {
        return;
    }

    for (const FHitResult& Hit : HitResults)
    {
        AActor* HitActor = Hit.GetActor();
        if (!HitActor || HitActor == OwnerFighter || HitActorsThisSwing.Contains(HitActor))
        {
            continue;
        }

        if (ASWFighterCharacter* TargetFighter = Cast<ASWFighterCharacter>(HitActor))
        {
            HitActorsThisSwing.Add(HitActor);
            if (USWCombatComponent* TargetCombat = TargetFighter->GetCombatComponent())
            {
                const bool bWasBlocking =
                    TargetCombat->GetCombatState() == ESWCombatState::Blocking ||
                    TargetCombat->GetCombatState() == ESWCombatState::PerfectParryWindow;

                TargetCombat->ReceiveAttackHit(OwnerFighter, ActiveMoveData, Hit.ImpactPoint);
                ApplyEnergyDelta(ActiveMoveData.EnergyGain);
                OnHitConfirmed.Broadcast(TargetFighter, ActiveMoveData, bWasBlocking && !ActiveMoveData.bUnblockable);
            }
        }
    }
}

void USWCombatComponent::SetBlocking(bool bShouldBlock)
{
    if (!IsAlive())
    {
        return;
    }

    if (bShouldBlock)
    {
        if (CurrentState == ESWCombatState::Idle || CurrentState == ESWCombatState::Moving)
        {
            ParryElapsed = 0.0f;
            SetCombatState(ESWCombatState::PerfectParryWindow);
        }
    }
    else
    {
        if (CurrentState == ESWCombatState::Blocking || CurrentState == ESWCombatState::PerfectParryWindow)
        {
            SetCombatState(ESWCombatState::Idle);
        }
    }
}

void USWCombatComponent::RequestDodge(float DirectionSign)
{
    if (!OwnerFighter || !FighterProfile || !IsAlive())
    {
        return;
    }

    if (CurrentState != ESWCombatState::Idle && CurrentState != ESWCombatState::Moving &&
        CurrentState != ESWCombatState::Blocking && CurrentState != ESWCombatState::PerfectParryWindow)
    {
        return;
    }

    SetCombatState(ESWCombatState::Dodging);
    bInvulnerable = true;

    const float SignedDir = FMath::Abs(DirectionSign) > 0.1f ? FMath::Sign(DirectionSign) : -1.0f;
    const FVector DashVec = OwnerFighter->GetActorForwardVector() * SignedDir * DodgeImpulse;
    OwnerFighter->LaunchCharacter(FVector(DashVec.X, DashVec.Y, 60.0f), true, false);

    UAnimMontage* DodgeMontage = SignedDir > 0.f ? FighterProfile->DodgeForwardMontage : FighterProfile->DodgeBackMontage;
    if (DodgeMontage && OwnerFighter->GetMesh()->GetAnimInstance())
    {
        OwnerFighter->GetMesh()->GetAnimInstance()->Montage_Play(DodgeMontage);
    }

    GetWorld()->GetTimerManager().SetTimer(IFrameTimerHandle, [this]() { bInvulnerable = false; }, DodgeIFrameDuration, false);
    GetWorld()->GetTimerManager().SetTimer(DodgeTimerHandle, this, &USWCombatComponent::EndDodge, DodgeDuration, false);
}

void USWCombatComponent::EndDodge()
{
    bInvulnerable = false;
    if (IsAlive() && CurrentState == ESWCombatState::Dodging)
    {
        SetCombatState(ESWCombatState::Idle);
    }
}

void USWCombatComponent::ReceiveAttackHit(AActor* Attacker, const FSWAttackMoveData& MoveData, const FVector& HitLocation)
{
    if (!IsAlive() || bInvulnerable)
    {
        return;
    }

    if (CurrentState == ESWCombatState::PerfectParryWindow && !MoveData.bUnblockable)
    {
        ApplyEnergyDelta(20.0f);
        OnPerfectParry.Broadcast(Attacker);

        if (ASWFighterCharacter* AttackerFighter = Cast<ASWFighterCharacter>(Attacker))
        {
            if (USWCombatComponent* AttackerCombat = AttackerFighter->GetCombatComponent())
            {
                FSWAttackMoveData StaggerData;
                StaggerData.Damage = 0.0f;
                StaggerData.HitStunDuration = 0.75f;
                StaggerData.KnockbackImpulse = 220.0f;
                AttackerCombat->ReceiveAttackHit(OwnerFighter, StaggerData, HitLocation);
            }
        }
        return;
    }

    const bool bBlocked = (CurrentState == ESWCombatState::Blocking) && !MoveData.bUnblockable;
    const float FinalDamage = bBlocked ? MoveData.Damage * MoveData.ChipDamageRatio : MoveData.Damage;

    CurrentHealth = FMath::Max(0.0f, CurrentHealth - FinalDamage);
    OnHealthChanged.Broadcast(CurrentHealth, MaxHealth);

    if (CurrentHealth <= 0.0f)
    {
        bWeaponHitboxActive = false;
        SetCombatState(ESWCombatState::Dead);
        OnFighterDefeated.Broadcast();
        return;
    }

    if (OwnerFighter && Attacker)
    {
        const FVector PushDir = (OwnerFighter->GetActorLocation() - Attacker->GetActorLocation()).GetSafeNormal2D();
        const float PushStrength = bBlocked ? MoveData.KnockbackImpulse * 0.35f : MoveData.KnockbackImpulse;
        const float VerticalLift = (!bBlocked && MoveData.bLaunchesTarget) ? 380.0f : 0.0f;
        OwnerFighter->LaunchCharacter(PushDir * PushStrength + FVector(0.f, 0.f, VerticalLift), true, false);
    }

    if (!bBlocked && MoveData.HitStunDuration > 0.0f)
    {
        bWeaponHitboxActive = false;
        SetCombatState(ESWCombatState::HitStun);
        if (FighterProfile && FighterProfile->HitReactMontage && OwnerFighter && OwnerFighter->GetMesh()->GetAnimInstance())
        {
            OwnerFighter->GetMesh()->GetAnimInstance()->Montage_Play(FighterProfile->HitReactMontage);
        }
        GetWorld()->GetTimerManager().SetTimer(HitStunTimerHandle, this, &USWCombatComponent::RecoverFromHitStun, MoveData.HitStunDuration, false);
    }
}

void USWCombatComponent::RecoverFromHitStun()
{
    if (IsAlive() && CurrentState == ESWCombatState::HitStun)
    {
        SetCombatState(ESWCombatState::Idle);
    }
}

void USWCombatComponent::ApplyEnergyDelta(float Delta)
{
    CurrentEnergy = FMath::Clamp(CurrentEnergy + Delta, 0.0f, MaxEnergy);
    OnEnergyChanged.Broadcast(CurrentEnergy, MaxEnergy);
}
