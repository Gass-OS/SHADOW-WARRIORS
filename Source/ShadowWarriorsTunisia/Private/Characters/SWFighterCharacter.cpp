#include "Characters/SWFighterCharacter.h"
#include "Combat/SWCombatComponent.h"
#include "GameFramework/CharacterMovementComponent.h"

ASWFighterCharacter::ASWFighterCharacter()
{
    PrimaryActorTick.bCanEverTick = true;

    CombatComponent = CreateDefaultSubobject<USWCombatComponent>(TEXT("CombatComponent"));

    bUseControllerRotationYaw = false;
    GetCharacterMovement()->bOrientRotationToMovement = false;
    GetCharacterMovement()->GravityScale = 1.6f;
    GetCharacterMovement()->JumpZVelocity = 620.0f;
}

void ASWFighterCharacter::BeginPlay()
{
    Super::BeginPlay();

    if (FighterProfile)
    {
        GetCharacterMovement()->MaxWalkSpeed = FighterProfile->MoveSpeed;
        CombatComponent->InitializeFromProfile(FighterProfile);
    }
}

void ASWFighterCharacter::Tick(float DeltaTime)
{
    Super::Tick(DeltaTime);

    if (bLockFacingToOpponent && OpponentActor && CombatComponent && CombatComponent->IsAlive())
    {
        const ESWCombatState State = CombatComponent->GetCombatState();
        if (State == ESWCombatState::Idle || State == ESWCombatState::Moving || State == ESWCombatState::Blocking)
        {
            FVector ToOpponent = OpponentActor->GetActorLocation() - GetActorLocation();
            ToOpponent.Z = 0.0f;
            if (!ToOpponent.IsNearlyZero())
            {
                const FRotator TargetRot = ToOpponent.Rotation();
                const FRotator SmoothedRot = FMath::RInterpTo(GetActorRotation(), TargetRot, DeltaTime, FacingInterpSpeed);
                SetActorRotation(SmoothedRot);
            }
        }
    }
}

void ASWFighterCharacter::SetOpponentActor(AActor* NewOpponent)
{
    OpponentActor = NewOpponent;
}

void ASWFighterCharacter::MoveAlongArenaAxis(float AxisValue)
{
    if (!CombatComponent || !CombatComponent->IsAlive())
    {
        return;
    }

    const ESWCombatState State = CombatComponent->GetCombatState();
    if (State != ESWCombatState::Idle && State != ESWCombatState::Moving)
    {
        return;
    }

    if (FMath::Abs(AxisValue) > 0.05f)
    {
        AddMovementInput(GetActorForwardVector(), AxisValue);
    }
}
