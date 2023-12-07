<#
    .SYNOPSIS
    Gets the size of the specified file in bytes.

    .DESCRIPTION
    Gets the size of the specified file in bytes.

    .NOTES
    Author:         Jonathan Panning <jpann [at] impostr-labs.com>
    Version:        1.0
    Last updated:   12-06-2023

    .PARAMETER Path
    Specifies the full path to the file.

    .INPUTS
    System.String. The full path to the file.

    .OUTPUTS
    System.Object. The file's FullName and Size in bytes.

    .EXAMPLE
    PS>./Get-FileSize.ps1 -Path $HOME\test\two.csv

    FullName                               Size
    --------                               ----
    C:\Users\MyUser\test\two.csv           8805091

    .EXAMPLE
    .PS> Get-ChildItem -File -Path $HOME\test\*.* | ./Get-FileSize.ps1 | Format-Table

    FullName                                 Size
    --------                                 ----
    C:\Users\MyUser\test\one.sql             19598
    C:\Users\MyUser\test\three.csv           2944075
    C:\Users\MyUser\test\two.csv             8805091
#>
[CmdletBinding()]
[OutputType([System.Object[]])]
Param(
    [parameter(Mandatory=$true,
        ValueFromPipeline = $true,
        ValueFromPipelineByPropertyName = $true,
        HelpMessage = 'Enter the path to the file.')]
    [ValidateNotNullOrEmpty()]
    [Alias('FullName')]
    [Alias('f')]
    [string]
    $Path
)
process {
    if (-not(Test-Path $Path -PathType Leaf)) {
        Write-Error "File $Path does not exist."
        exit 1
    }

    (Get-Item -Path $Path).Length | Select @{Name="FullName";Expression={ $Path }}, @{Name="Size";Expression={ $_ }} | Write-Output
}
