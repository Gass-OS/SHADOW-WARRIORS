#pragma once

#include "CoreMinimal.h"
#include "Engine/DataAsset.h"
#include "SWCombatTypes.generated.h"

class UAnimMontage;

UENUM(BlueprintType)
enum class ESWFighterId : uint8
{
    KasseriniWarrior    UMETA(DisplayName = "The Kasserini Warrior"),
    MedinaAssassin      UMETA(DisplayName = "The Medina Assassin"),
    DesertGuardian      UMETA(DisplayName = "The Desert Guardian"),
    MountainExecutioner UMETA(DisplayName = "Boss: The Mountain Executioner")
};

UENUM(BlueprintType)
enum class ESWCombatState : uint8
{
    Idle,
    Moving,
    Attacking,
    Blocking,
    PerfectParryWindow,
    Dodging,
    HitStun,
    KnockedDown,
    Dead
};

UENUM(BlueprintType)
enum class ESWAttackInput : uint8
{
    Light,
    Heavy,
    Special,
    Ultimate
};

UENUM(BlueprintType)
enum class ESWGraphicsTier : uint8
{
    Low,
    Medium,
    High,
    Ultra
};

USTRUCT(BlueprintType)
struct FSWAttackMoveData
{
    GENERATED_BODY()

    UPROPERTY(EditAnywhere, BlueprintReadWrite)
    FName MoveName = NAME_None;

    UPROPERTY(EditAnywhere, BlueprintReadWrite)
    ESWAttackInput InputType = ESWAttackInput::Light;

    UPROPERTY(EditAnywhere, BlueprintReadWrite)
    TObjectPtr<UAnimMontage> Montage = nullptr;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, meta = (ClampMin = "0.0"))
    float Damage = 12.0f;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, meta = (ClampMin = "0.0"))
    float ChipDamageRatio = 0.15f;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, meta = (ClampMin = "0.0"))
    float EnergyGain = 10.0f;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, meta = (ClampMin = "0.0"))
    float EnergyCost = 0.0f;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, meta = (ClampMin = "0.0"))
    float HitStunDuration = 0.35f;

    UPROPERTY(EditAnywhere, BlueprintReadWrite)
    float KnockbackImpulse = 380.0f;

    UPROPERTY(EditAnywhere, BlueprintReadWrite)
    bool bUnblockable = false;

    UPROPERTY(EditAnywhere, BlueprintReadWrite)
    bool bLaunchesTarget = false;

    UPROPERTY(EditAnywhere, BlueprintReadWrite)
    float WeaponTraceRadius = 26.0f;
};

UCLASS(BlueprintType)
class SHADOWWARRIORSTUNISIA_API USWFighterProfileAsset : public UPrimaryDataAsset
{
    GENERATED_BODY()

public:
    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Identity")
    ESWFighterId FighterId = ESWFighterId::KasseriniWarrior;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Identity")
    FText DisplayName;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Identity")
    FText RegionTitle;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Stats")
    float MaxHealth = 200.0f;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Stats")
    float MaxEnergy = 100.0f;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Stats")
    float MoveSpeed = 420.0f;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Combat")
    TArray<FSWAttackMoveData> LightComboChain;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Combat")
    TArray<FSWAttackMoveData> HeavyComboChain;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Combat")
    FSWAttackMoveData SpecialMove;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Combat")
    FSWAttackMoveData UltimateMove;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Combat")
    TObjectPtr<UAnimMontage> HitReactMontage = nullptr;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Combat")
    TObjectPtr<UAnimMontage> ParryStaggerMontage = nullptr;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Combat")
    TObjectPtr<UAnimMontage> DodgeForwardMontage = nullptr;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Combat")
    TObjectPtr<UAnimMontage> DodgeBackMontage = nullptr;
};
