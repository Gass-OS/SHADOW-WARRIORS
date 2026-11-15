#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Character.h"
#include "Combat/SWCombatTypes.h"
#include "SWFighterCharacter.generated.h"

class USWCombatComponent;

UCLASS()
class SHADOWWARRIORSTUNISIA_API ASWFighterCharacter : public ACharacter
{
    GENERATED_BODY()

public:
    ASWFighterCharacter();

    virtual void BeginPlay() override;
    virtual void Tick(float DeltaTime) override;

    UFUNCTION(BlueprintCallable, Category = "Fighter")
    void SetOpponentActor(AActor* NewOpponent);

    UFUNCTION(BlueprintCallable, Category = "Fighter")
    void MoveAlongArenaAxis(float AxisValue);

    UFUNCTION(BlueprintPure, Category = "Fighter")
    USWCombatComponent* GetCombatComponent() const { return CombatComponent; }

    UFUNCTION(BlueprintPure, Category = "Fighter")
    USWFighterProfileAsset* GetFighterProfile() const { return FighterProfile; }

protected:
    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Components")
    TObjectPtr<USWCombatComponent> CombatComponent;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Fighter")
    TObjectPtr<USWFighterProfileAsset> FighterProfile;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Fighter|Arena")
    bool bLockFacingToOpponent = true;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Fighter|Arena")
    float FacingInterpSpeed = 14.0f;

private:
    UPROPERTY()
    TObjectPtr<AActor> OpponentActor;
};
