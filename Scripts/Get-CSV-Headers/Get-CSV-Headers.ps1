<#
.SYNOPSIS
    Gets the header information of the specified CSV file.

.DESCRIPTION
    Gets the header information of the specified CSV file.

.NOTES
    Author: Jonathan Panning <jpann [at] impostr-labs.com>
    Version: 1.0
    Date Updated: 12-06-2023

.LINK
	https://github.com/jpann/PowerShell

.PARAMETER Path
    The path to the CSV file.

.PARAMETER Delimiter
    The field delimiter. Default ','.

.INPUTS
    System.String. Accepts objects piped with the property Path or FullName.

.OUTPUTS
    Returns an object containing the file's header information.

.EXAMPLE
    PS> .\Get-CSV-Headers.ps1 -Path "..\..\MockData\MOCK_PEOPLE_DATA.csv"

    ColumnCount Columns                     Header                                     File
    ----------- -------                     ------                                     ----
    5 {id, first_name, last_name, email...} id,first_name,last_name,email,description  MOCK_PEOPLE_DATA.csv

.EXAMPLE
    PS> Get-ChildItem -Path '..\..\MockData\*.csv' | .\Get-CSV-Headers.ps1
#>
[CmdletBinding()]
[OutputType([System.Management.Automation.PSCustomObject[]])]
Param(
    [parameter(Mandatory=$true,
        ValueFromPipeline = $true,
        ValueFromPipelineByPropertyName = $true,
        HelpMessage = 'Enter the path to CSV file.')]
    [ValidateNotNullOrEmpty()]
    [Alias('FullName')]
    [string]
    $Path,

    [parameter(Mandatory=$false)]
    [string]
    $Delimiter = ","
)
cd $PSScriptRoot

$header = Get-Content $Path -TotalCount 1 | Select -First 1
$headerColumns = $header.Split($Delimiter)

$headerData = New-Object PSObject -Property @{
	'File' = Split-Path $Path -Leaf;
	'ColumnCount' = $headerColumns.Count
	'Header' = $header
    'Columns' = $headerColumns
}

$headerData | ForEach {[PSCustomObject]$_} | Format-Table -AutoSize | Write-Output
