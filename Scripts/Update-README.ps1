<#
.SYNOPSIS
    Updates the scripts list in README.md.

.DESCRIPTION
    Updates the scripts list in README.md from scripts.csv.

.NOTES
    Author:         Jonathan Panning <jpann [at] impostr-labs.com>
    Filename:     	Update-README.ps1
    Created on:   	12-06-2023
    Version:        1.0
    Last updated:   12-06-2023

.INPUTS
    None. Does not accept any input.

.OUTPUTS
    None. Does not output.

.EXAMPLE
    PS> .\Update-README.ps1
#>
[CmdletBinding()]
[OutputType([System.Object[]])]
Param(
    [parameter(Mandatory=$false)]
    [switch]
    $WhatIf
)
begin {
    function List-Scripts([string]$Path) {
        $files = Get-ChildItem -Recurse -Depth 1 -Path "$Path/*.ps1" -Attributes !Directory

        $parentPath = Split-Path $Path -Parent

        [int]$scriptNumber = 1
        foreach ($file in $files) {
            $help = Get-Help $file -Full

            $scriptSubPath = $file.FullName.Replace($parentPath, "").SubString(1)

            New-Object PSObject -Property @{
                'No' = $scriptNumber++
                'Script' = $file.Name
                'Path' = $scriptSubPath.Replace("\", "/")
                'Description' = $help.Synopsis
            }
        }
    }
}
process {
    cd $PSScriptRoot

    $templateBlock =
@"
| Script                                               | Description                                                                                     |
| ---------------------------------------------------- | ----------------------------------------------------------------------------------------------- |
| [Test.ps1](Scripts/Test/Test.ps1)                         | Test script. [Read more...](Scripts/Test/Test.md)                  |
%SCRIPT_LINE%
"@

    $templateLine = "| [%FILENAME%](%FILE_SUBPATH%)                         | %FILE_DESC% [Read more...](%FILE_DOC_LINK%)                  |"

    #$scripts = Import-Csv -Path "../Data/scripts.csv"

    $scripts = List-Scripts -Path $pwd

    $text = Get-Content -Path '../README.md' -Raw

    $lineStart = "<!-- ScriptStart -->"
    $lineEnd = "<!-- ScriptEnd -->"

    $newScriptsBlock = $templateBlock
    $scriptLines = @()

    foreach ($script in $scripts) {
        $scriptLine = $templateLine

        # Examples:
        # %FILENAME% = 'Test.ps1'
        # %FILE_DOC_LINK% = 'Scripts/Test/Test.md'
        # %FILE_SUBPATH% = 'Scripts/Test/Test.ps1'
        # %FILE_DESC% = ' Test script.'
        $scriptLine = $scriptLine.Replace("%FILENAME%", $script.Script)
        $scriptLine = $scriptLine.Replace("%FILE_DOC_LINK%", $script.Path.Replace(".ps1", ".md"))
        $scriptLine = $scriptLine.Replace("%FILE_SUBPATH%", $script.Path)
        $scriptLine = $scriptLine.Replace("%FILE_DESC%", $script.Description)

        $scriptLines += $scriptLine
    }

    $scriptLinesBlock = $scriptLines -Join "`r`n" | Out-String
    $newScriptBlock = $templateBlock
    $newScriptBlock = $newScriptsBlock.Replace("%SCRIPT_LINE%", $scriptLinesBlock)

    $Pattern = "(?s)(?<=$($lineStart)\r?\n).*?(?=$($lineEnd))"

    $text = ($text -Replace $Pattern, $newScriptBlock)

    if ($WhatIf -eq $false) {
        $text | Set-Content '../README.md'
    } else {
        $text | Write-Output
    }
}