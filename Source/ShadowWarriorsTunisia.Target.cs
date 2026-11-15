using UnrealBuildTool;

public class ShadowWarriorsTunisiaTarget : TargetRules
{
    public ShadowWarriorsTunisiaTarget(TargetInfo Target) : base(Target)
    {
        Type = TargetType.Game;
        DefaultBuildSettings = BuildSettingsVersion.Latest;
        IncludeOrderVersion = EngineIncludeOrderVersion.Latest;
        ExtraModuleNames.Add("ShadowWarriorsTunisia");
    }
}
