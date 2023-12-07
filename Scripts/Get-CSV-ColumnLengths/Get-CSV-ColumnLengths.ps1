<#
.SYNOPSIS
    Gets the min and max lengths of each column in the specified CSV file.

.DESCRIPTION
    This gets the minimum and maximum column lengths with value of each column in the specified CSV file.

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

.EXAMPLE
    PS> .\Get-CSV-ColumnLengths.ps1 -Path "..\..\MockData\MOCK_PEOPLE_DATA.csv" | Format-Table

    Column      MinLength MaxLength MinValue             MaxValue
    ------      --------- --------- --------             --------
    email              20        23 hfahey1@marriott.com nstopher0@discovery.com
    last_name           5         7 Fahey                Stopher
    description         0       348                      Nullam porttitor lacus at turpis. Donec posuere metus vitae ipsum. Aliquam non mauris....
    first_name          5         8 Hanni                Nathalie
    id                  1         1 1                    1

.EXAMPLE
    PS> .\Get-CSV-ColumnLengths.ps1 -Path "..\..\MockData\MOCK_PEOPLE_DATA.csv"

.EXAMPLE
    PS> .\Get-CSV-ColumnLengths.ps1 -Path "..\..\MockData\MOCK_PEOPLE_DATA.csv" | Export-Csv "C:\MOCK_PEOPLE_DATA_MaxColLengths.csv" -NoTypeInformation -Encoding UTF8 -Force

.EXAMPLE
    PS> .\Get-CSV-ColumnLengths.ps1 -Path "..\..\MockData\MOCK_PEOPLE_DATA.csv" | Out-GridView
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

$content = Import-Csv -Path $Path -Delimiter $Delimiter

$columns = ($content[0].PSObject.Properties).Name

# Create hashtable that will contain the column data
$columnData = @{}

foreach ($col in $columns) {
    $value = @{
        Column = $col
        MinLength = 0
        MaxLength = 0
        MinValue = ""
        MaxValue = ""
    }

    $columnData.Add($col, $value)
}

$rowIndex = 1
# Loop through each row in the file
foreach ($row in $content | Select -First 2) {
    # Loop through the columns in this row
    foreach ($column in $row.PSObject.Properties) {
        $colName = $column.Name
        $colData = $row.$($column.Name)
        $colLength = $colData.Length

        # Set MinLength
        if (($colLength -lt $columnData[$colName].MinLength -or $columnData[$colName].MinLength -eq 0) -or $rowIndex -eq 1) {
            $columnData[$colName].MinLength = $colLength
            $columnData[$colName].MinValue = $colData
        }

        # Set MaxLength
        if ($colLength -gt $columnData[$colName].MaxLength) {
            $columnData[$colName].MaxLength = $colLength
            $columnData[$colName].MaxValue = $colData
        }

        Write-Verbose "`t Column: $colName"
        Write-Verbose "`t Column Data: $colData"
        Write-Verbose "`t Column Length: $colLength"
        Write-Verbose "`t------"
    }

    $rowIndex++

    Write-Verbose "======"
}

$columns = $columnData.GetEnumerator() | Select @{Name="Column";Expression={ $_.Value['Column'] }} `
    , @{Name="MinLength";Expression={ $_.Value['MinLength'] }} `
    , @{Name="MaxLength";Expression={ $_.Value['MaxLength'] }} `
    , @{Name="MinValue";Expression={ $_.Value['MinValue'] }} `
    , @{Name="MaxValue";Expression={ $_.Value['MaxValue'] }}

Write-Output $columns
