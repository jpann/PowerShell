<#
.SYNOPSIS
    Gets the max length of each column in the specified CSV file.

.DESCRIPTION
    This gets the maximum column length of each column in the specified CSV file.

.NOTES
    Author: Jonathan Panning <jpann [at] impostr-labs.com>
    Version: 1.0
    Date Updated: 12-06-2023

    Version History:
        - 1.0: Initial version.
        
.LINK
	https://github.com/jpann/PowerShell

.PARAMETER Path
    The path to the CSV file.

.PARAMETER Delimiter
    The field delimiter. Default ','.

.INPUTS
    System.String. Accepts objects piped with the property Path or FullName.

.OUTPUTS
    Hashtable. Returns a hash table containing the column name and the maximum length.

.EXAMPLE
    PS .\Get-CSV-MaxLengths.ps1 -Path "..\..\MockData\MOCK_PEOPLE_DATA.csv"

    Name                           Value
    ----                           -----
    email                          37
    last_name                      22
    description                    550
    first_name                     14
    id                             4


.EXAMPLE
    PS> .\Get-CSV-MaxLengths.ps1 -Path "..\..\MockData\MOCK_PEOPLE_DATA.csv" | Export-Csv "C:\MOCK_PEOPLE_DATA_MaxColLengths.csv" -NoTypeInformation -Encoding UTF8 -Force

.EXAMPLE
    PS> .\Get-CSV-MaxLengths.ps1 -Path "..\..\MockData\MOCK_PEOPLE_DATA.csv" | Out-GridView
#>
[CmdletBinding()]
[OutputType([Hashtable])]
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

$content = Import-Csv -Path $Path -Delimiter $Delimiter

# create an empty hash for column lengths
$columnLengths = @{}

# Process each column by name
foreach ($columnName in $(($csv | Get-Member -MemberType NoteProperty).Name))
{
    $columnLengths[$columnName] = ($csv.$columnName  | Measure-Object -Maximum -Property Length).Maximum
}

# Output column lengths
Write-Output $columnLengths
