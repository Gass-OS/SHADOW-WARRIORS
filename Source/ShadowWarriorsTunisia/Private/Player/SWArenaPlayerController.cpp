#include "Player/SWArenaPlayerController.h"
#include "Characters/SWFighterCharacter.h"
#include "Combat/SWCombatComponent.h"
#include "GameFramework/GameUserSettings.h"
#include "Internationalization/Internationalization.h"

void ASWArenaPlayerController::ApplyGraphicsPreset(ESWGraphicsTier Tier, int32 TargetFPS)
{
    UGameUserSettings* Settings = UGameUserSettings::GetGameUserSettings();
    if (!Settings)
    {
        return;
    }

    const int32 ScalabilityLevel = static_cast<int32>(Tier);
    Settings->SetOverallScalabilityLevel(ScalabilityLevel);
    Settings->SetFrameRateLimit(TargetFPS >= 60 ? 60.0f : 30.0f);

    float ResolutionScale = 100.0f;
    switch (Tier)
    {
    case ESWGraphicsTier::Low:    ResolutionScale = 65.0f; break;
    case ESWGraphicsTier::Medium: ResolutionScale = 80.0f; break;
    case ESWGraphicsTier::High:   ResolutionScale = 90.0f; break;
    case ESWGraphicsTier::Ultra:  ResolutionScale = 100.0f; break;
    }

    Settings->SetResolutionScaleNormalized(ResolutionScale / 100.0f);
    Settings->ApplySettings(false);
}

void ASWArenaPlayerController::SetGameLanguage(const FString& CultureCode)
{
    FInternationalization::Get().SetCurrentLanguageAndLocale(CultureCode);
}

void ASWArenaPlayerController::TouchMoveAxis(float AxisValue)
{
    if (ASWFighterCharacter* Fighter = Cast<ASWFighterCharacter>(GetPawn()))
    {
        Fighter->MoveAlongArenaAxis(AxisValue);
    }
}

void ASWArenaPlayerController::TouchLightAttack()
{
    if (ASWFighterCharacter* Fighter = Cast<ASWFighterCharacter>(GetPawn()))
    {
        Fighter->GetCombatComponent()->RequestAttack(ESWAttackInput::Light);
    }
}

void ASWArenaPlayerController::TouchHeavyAttack()
{
    if (ASWFighterCharacter* Fighter = Cast<ASWFighterCharacter>(GetPawn()))
    {
        Fighter->GetCombatComponent()->RequestAttack(ESWAttackInput::Heavy);
    }
}

void ASWArenaPlayerController::TouchBlockPressed(bool bPressed)
{
    if (ASWFighterCharacter* Fighter = Cast<ASWFighterCharacter>(GetPawn()))
    {
        Fighter->GetCombatComponent()->SetBlocking(bPressed);
    }
}

void ASWArenaPlayerController::TouchDodge(float DirectionSign)
{
    if (ASWFighterCharacter* Fighter = Cast<ASWFighterCharacter>(GetPawn()))
    {
        Fighter->GetCombatComponent()->RequestDodge(DirectionSign);
    }
}

void ASWArenaPlayerController::TouchSpecial()
{
    if (ASWFighterCharacter* Fighter = Cast<ASWFighterCharacter>(GetPawn()))
    {
        Fighter->GetCombatComponent()->RequestAttack(ESWAttackInput::Special);
    }
}

void ASWArenaPlayerController::TouchUltimate()
{
    if (ASWFighterCharacter* Fighter = Cast<ASWFighterCharacter>(GetPawn()))
    {
        Fighter->GetCombatComponent()->RequestAttack(ESWAttackInput::Ultimate);
    }
}
