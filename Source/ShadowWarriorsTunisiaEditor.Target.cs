using UnrealBuildTool;

public class ShadowWarriorsTunisiaEditorTarget : TargetRules
{
    public ShadowWarriorsTunisiaEditorTarget(TargetInfo Target) : base(Target)
    {
        Type = TargetType.Editor;
        DefaultBuildSettings = BuildSettingsVersion.Latest;
        IncludeOrderVersion = EngineIncludeOrderVersion.Latest;
        ExtraModuleNames.Add("ShadowWarriorsTunisia");
    }
}
