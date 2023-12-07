<#
    .SYNOPSIS
    Check if value contains non-ASCII characters.

    .DESCRIPTION
    Check if value contains non-ASCII characters.

    .NOTES
    Author:         Jonathan Panning <jpann [at] impostr-labs.com>
    Created on:   	12-06-2023
    Version:        1.0
    Last updated:   12-06-2023

    .INPUTS
    System.String. Accepts objects piped with the property Value, Path or FullName.

    .OUTPUTS
    System.String. Returns the value if it contains non-ASCII characters.

    .EXAMPLE
    PS> .\Test-Non-ASCII.ps1 -Value 'Some Value®'
    Some Value®

    .EXAMPLE
    PS> Get-ChildItem -Path $HOME | .\Test-Non-ASCII.ps1
    C:\Users\MyUser\Some Folder®
    C:\Users\MyUser\Some Value®.txt

    .EXAMPLE
    PS> Get-ChildItem -Path $HOME -File | .\Test-Non-ASCII.ps1
    C:\Users\MyUser\Some Value®.txt
#>

[CmdletBinding()]
[OutputType([System.Management.Automation.PSCustomObject])]
Param(
    [parameter(Mandatory=$true,
        ValueFromPipeline = $true,
        ValueFromPipelineByPropertyName = $true)]
    [ValidateNotNullOrEmpty()]
    [Alias('FullName')]
    [Alias('Path')]
    [string]
    $Value
)
PROCESS {
    $result = ($Value -cmatch '[^\x20-\x7F]')

    if ($result -eq $true)
    {
        Write-Output $Value
    }
}
