#pragma once

#include "CoreMinimal.h"
#include "Components/ActorComponent.h"
#include "Combat/SWCombatTypes.h"
#include "SWCombatComponent.generated.h"

class ASWFighterCharacter;

DECLARE_DYNAMIC_MULTICAST_DELEGATE_TwoParams(FOnStatChangedSignature, float, CurrentValue, float, MaxValue);
DECLARE_DYNAMIC_MULTICAST_DELEGATE_TwoParams(FOnCombatStateChangedSignature, ESWCombatState, NewState, ESWCombatState, OldState);
DECLARE_DYNAMIC_MULTICAST_DELEGATE_ThreeParams(FOnHitConfirmedSignature, AActor*, TargetActor, const FSWAttackMoveData&, MoveData, bool, bWasBlocked);
DECLARE_DYNAMIC_MULTICAST_DELEGATE_OneParam(FOnPerfectParrySignature, AActor*, AttackerActor);
DECLARE_DYNAMIC_MULTICAST_DELEGATE(FOnFighterDefeatedSignature);

UCLASS(ClassGroup = (Combat), meta = (BlueprintSpawnableComponent))
class SHADOWWARRIORSTUNISIA_API USWCombatComponent : public UActorComponent
{
    GENERATED_BODY()

public:
    USWCombatComponent();

    virtual void BeginPlay() override;
    virtual void TickComponent(float DeltaTime, ELevelTick TickType, FActorComponentTickFunction* ThisTickFunction) override;

    UFUNCTION(BlueprintCallable, Category = "Combat")
    void InitializeFromProfile(USWFighterProfileAsset* Profile);

    UFUNCTION(BlueprintCallable, Category = "Combat|Input")
    void RequestAttack(ESWAttackInput InputType);

    UFUNCTION(BlueprintCallable, Category = "Combat|Input")
    void SetBlocking(bool bShouldBlock);

    UFUNCTION(BlueprintCallable, Category = "Combat|Input")
    void RequestDodge(float DirectionSign);

    UFUNCTION(BlueprintCallable, Category = "Combat|AnimNotify")
    void SetWeaponHitboxActive(bool bActive);

    UFUNCTION(BlueprintCallable, Category = "Combat|AnimNotify")
    void OpenComboWindow(bool bOpen);

    UFUNCTION(BlueprintCallable, Category = "Combat|AnimNotify")
    void EndCurrentAttack();

    UFUNCTION(BlueprintCallable, Category = "Combat")
    void ReceiveAttackHit(AActor* Attacker, const FSWAttackMoveData& MoveData, const FVector& HitLocation);

    UFUNCTION(BlueprintPure, Category = "Combat")
    ESWCombatState GetCombatState() const { return CurrentState; }

    UFUNCTION(BlueprintPure, Category = "Combat")
    float GetHealthPercent() const { return MaxHealth > 0.f ? CurrentHealth / MaxHealth : 0.f; }

    UFUNCTION(BlueprintPure, Category = "Combat")
    float GetEnergyPercent() const { return MaxEnergy > 0.f ? CurrentEnergy / MaxEnergy : 0.f; }

    UFUNCTION(BlueprintPure, Category = "Combat")
    bool IsAlive() const { return CurrentState != ESWCombatState::Dead && CurrentHealth > 0.f; }

    UPROPERTY(BlueprintAssignable, Category = "Combat|Events")
    FOnStatChangedSignature OnHealthChanged;

    UPROPERTY(BlueprintAssignable, Category = "Combat|Events")
    FOnStatChangedSignature OnEnergyChanged;

    UPROPERTY(BlueprintAssignable, Category = "Combat|Events")
    FOnCombatStateChangedSignature OnCombatStateChanged;

    UPROPERTY(BlueprintAssignable, Category = "Combat|Events")
    FOnHitConfirmedSignature OnHitConfirmed;

    UPROPERTY(BlueprintAssignable, Category = "Combat|Events")
    FOnPerfectParrySignature OnPerfectParry;

    UPROPERTY(BlueprintAssignable, Category = "Combat|Events")
    FOnFighterDefeatedSignature OnFighterDefeated;

protected:
    UPROPERTY(EditDefaultsOnly, Category = "Combat|Sockets")
    FName WeaponStartSocket = TEXT("Weapon_Base");

    UPROPERTY(EditDefaultsOnly, Category = "Combat|Sockets")
    FName WeaponTipSocket = TEXT("Weapon_Tip");

    UPROPERTY(EditDefaultsOnly, Category = "Combat|Timing")
    float PerfectParryDuration = 0.18f;

    UPROPERTY(EditDefaultsOnly, Category = "Combat|Timing")
    float DodgeDuration = 0.36f;

    UPROPERTY(EditDefaultsOnly, Category = "Combat|Timing")
    float DodgeIFrameDuration = 0.24f;

    UPROPERTY(EditDefaultsOnly, Category = "Combat|Timing")
    float DodgeImpulse = 780.0f;

private:
    void SetCombatState(ESWCombatState NewState);
    void ExecuteMove(const FSWAttackMoveData& MoveData);
    void PerformWeaponSweep();
    void ApplyEnergyDelta(float Delta);
    void RecoverFromHitStun();
    void EndDodge();

    UPROPERTY()
    TObjectPtr<ASWFighterCharacter> OwnerFighter;

    UPROPERTY()
    TObjectPtr<USWFighterProfileAsset> FighterProfile;

    ESWCombatState CurrentState = ESWCombatState::Idle;
    float CurrentHealth = 200.0f;
    float MaxHealth = 200.0f;
    float CurrentEnergy = 0.0f;
    float MaxEnergy = 100.0f;

    int32 LightComboIndex = 0;
    int32 HeavyComboIndex = 0;
    bool bComboWindowOpen = false;
    bool bHasBufferedInput = false;
    ESWAttackInput BufferedInput = ESWAttackInput::Light;

    bool bWeaponHitboxActive = false;
    bool bInvulnerable = false;
    float ParryElapsed = 0.0f;
    FSWAttackMoveData ActiveMoveData;

    UPROPERTY()
    TArray<TObjectPtr<AActor>> HitActorsThisSwing;

    FTimerHandle HitStunTimerHandle;
    FTimerHandle DodgeTimerHandle;
    FTimerHandle IFrameTimerHandle;
};
