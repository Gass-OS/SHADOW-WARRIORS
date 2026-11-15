using UnrealBuildTool;

public class ShadowWarriorsTunisia : ModuleRules
{
    public ShadowWarriorsTunisia(ReadOnlyTargetRules Target) : base(Target)
    {
        PCHUsage = PCHUsageMode.UseExplicitOrSharedPCHs;

        PublicDependencyModuleNames.AddRange(new string[]
        {
            "Core",
            "CoreUObject",
            "Engine",
            "InputCore",
            "EnhancedInput",
            "AIModule",
            "UMG",
            "Slate",
            "SlateCore"
        });
    }
}
