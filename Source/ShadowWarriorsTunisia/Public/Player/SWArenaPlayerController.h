#pragma once

#include "CoreMinimal.h"
#include "GameFramework/PlayerController.h"
#include "Combat/SWCombatTypes.h"
#include "SWArenaPlayerController.generated.h"

UCLASS()
class SHADOWWARRIORSTUNISIA_API ASWArenaPlayerController : public APlayerController
{
    GENERATED_BODY()

public:
    UFUNCTION(BlueprintCallable, Category = "Settings|Mobile")
    void ApplyGraphicsPreset(ESWGraphicsTier Tier, int32 TargetFPS);

    UFUNCTION(BlueprintCallable, Category = "Settings|Localization")
    void SetGameLanguage(const FString& CultureCode);

    UFUNCTION(BlueprintCallable, Category = "Mobile|Touch")
    void TouchMoveAxis(float AxisValue);

    UFUNCTION(BlueprintCallable, Category = "Mobile|Touch")
    void TouchLightAttack();

    UFUNCTION(BlueprintCallable, Category = "Mobile|Touch")
    void TouchHeavyAttack();

    UFUNCTION(BlueprintCallable, Category = "Mobile|Touch")
    void TouchBlockPressed(bool bPressed);

    UFUNCTION(BlueprintCallable, Category = "Mobile|Touch")
    void TouchDodge(float DirectionSign);

    UFUNCTION(BlueprintCallable, Category = "Mobile|Touch")
    void TouchSpecial();

    UFUNCTION(BlueprintCallable, Category = "Mobile|Touch")
    void TouchUltimate();
};
