<#
.SYNOPSIS
    Gets the specified lines from a text file.

.DESCRIPTION
    Gets the specified lines from a text file.

.NOTES
    Author:         Jonathan Panning <jpann [at] impostr-labs.com>
    Filename:     	Get-Lines.ps1
    Created on:   	12-06-2023
    Version:        1.0
    Last updated:   12-06-2023

.PARAMETER Path
    The path to the file to read.

.PARAMETER Lines
    An array containing each line number to get. The header row counts as a lineIf -ExcludeHeader is

.PARAMETER ExcludeHeader
    Excludes the first line in the file.

.PARAMETER IncludeNextLineOnly
    Only outputs the line following each specified line number.

.PARAMETER IncludeNextLine
    Outputs the specified lines as well as the line following.

.INPUTS
    System.String. Get-Lines accepts objects piped with the property Path or FullName.

.OUTPUTS
    System.Object[]. Get-Lines returns a object array containing the lines harvested from the file.

.EXAMPLE
    PS> .\Get-Lines.ps1 -Path '..\..\MockData\MOCK_COLORS.csv' -Lines 2,10,20

    Line
    ----
    1,5/3/1971,Mauv
    9,7/9/1974,Fuscia
    19,10/31/2017,Orange

.EXAMPLE
    PS> .\Get-Lines.ps1 -Path '..\..\MockData\MOCK_COLORS.csv -Lines 2,10,20 -IncludeNextLine

    Line
    ----
    1,5/3/1971,Mauv
    2,6/3/2010,Maroon
    9,7/9/1974,Fuscia
    10,4/9/1984,Aquamarine
    19,10/31/2017,Orange
    20,10/25/1992,Fuscia

.EXAMPLE
    PS> .\Get-Lines.ps1 -Path '..\..\MockData\MOCK_COLORS.csv' -Lines 2,10,20 -IncludeNextLineOnly

    Line
    ----
    2,6/3/2010,Maroon
    10,4/9/1984,Aquamarine
    20,10/25/1992,Fuscia
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
    $Path,

    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [Alias('l')]
    [int[]]
    $Lines,

    [parameter(Mandatory=$false)]
    [alias("xh")]
    [switch]
    $ExcludeHeader,

    [parameter(Mandatory=$false)]
    [alias("nl")]
    [switch]
    $IncludeNextLineOnly,

    [parameter(Mandatory=$false)]
    [alias("inl")]
    [switch]
    $IncludeNextLine
)
if (-not(Test-Path $Path -PathType Leaf)) {
    Write-Error "Path does not exist."
    exit 1
}

# Get only the next lines ...
if ($IncludeNextLineOnly) {
    $Lines = $Lines | ForEach-Object { $_ += 1; $_ }
}

# Get maximum line from the Lines parameter
$maxLine = ($Lines | Measure -Maximum).Maximum
Write-Verbose "MaxLines: $maxLine"

$header = Get-Content $Path | Select -First 1
Write-Verbose "Header: $header"

if ($IncludeNextLine) {
    $maxLine = $maxLine + 1
}

# If ExcludeHeader is specified, then skip the first line in the file
if ($ExcludeHeader -eq $true) {
    $text = Get-Content $Path -TotalCount $maxLine | Select -Skip 1
}
else {
    $text = Get-Content $Path -TotalCount $maxLine
}

# Get specific lines
$file_lines = @()

if ($ExcludeHeader -eq $false) {

    $line_text += [PSCustomObject]@{Line=$header}
}

foreach ($fileLineNo in $Lines) {
    # The zero indexed "line" number
    $lineNo = ($fileLineNo - 1)

    $line = $text[$lineNo]
    #$file_lines += $line
    $file_lines += [PSCustomObject]@{Line=$line}

    Write-Verbose "Line: $fileLineNo ($lineNo); Line: $line"

    if ($IncludeNextLine -and $IncludeNextLineOnly -eq $false) {
        $nextLineNo = $lineNo + 1
        $nextFileLineNo = $fileLineNo + 1
        $nextLine = $text[$nextLineNo];
        #$file_lines += $nextLine
        $file_lines += [PSCustomObject]@{Line=$nextLine}

        Write-Verbose "Next Line: $($nextFileLineNo) ($nextLineNo); Line: $($nextLine)"
    }
}

$file_lines | ForEach {[PSCustomObject]$_} | Format-Table -AutoSize | Write-Output
