<#
    .SYNOPSIS
    Find files in the specified path that have non-ASCII characters in filenames.

    .DESCRIPTION
    Find files in the specified path that have non-ASCII characters in filenames.

    .NOTES
    Author:         Jonathan Panning <jpann [at] impostr-labs.com>
    Created on:   	12-06-2023
    Version:        1.0
    Last updated:   12-06-2023

    .INPUTS
    System.String. Accepts objects piped with the property Path or Directory.

    .OUTPUTS
    System.String[]. Returns an array containing the paths of files that
    contain non-ASCII characters in their filenames.

    .EXAMPLE
    PS> .\Get-Non-ASCII-Files.ps1 -Path 'C:\temp'
    C:\temp\Some Value®.txt
#>


[CmdletBinding()]
[OutputType([System.Management.Automation.PSCustomObject[]])]
Param(
    [parameter(Mandatory=$true,
        ValueFromPipeline = $true,
        ValueFromPipelineByPropertyName = $true)]
    [ValidateNotNullOrEmpty()]
    [Alias('Directory')]
    [string]
    $Path
)
PROCESS {
    $files = [System.IO.Directory]::EnumerateFiles($Path, '*', [System.IO.SearchOption]::AllDirectories)

    $files | Where-Object {$_ -cmatch '[^\x20-\x7F]'} | Write-Output
}
