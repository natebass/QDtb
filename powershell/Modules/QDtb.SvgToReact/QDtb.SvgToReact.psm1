<#
    The module manifest (.psd1) defines this file as the entry point or root of the module.
    Ensure that all of the module functionality is loaded directly from this file.
#>

# load classes
# ⚠️ Note on Classes: While dot-sourcing classes in a loop works for internal module use, it can sometimes cause issues with inheritance or type renewal if the module is reloaded. For complex modules, many developers prefer to use the ScriptsToProcess field in the .psd1 manifest or explicitly structure classes in a specific compilation order.
foreach ($classFile in (Get-ChildItem -Path "$PSScriptRoot\Classes" -Recurse -Include "*.ps1")) {
    . $classFile
}

# load functions

foreach ($functionFile in (Get-ChildItem -Path "$PSScriptRoot\Functions" -Recurse -Include "*.ps1")) {
    . $functionFile
}
