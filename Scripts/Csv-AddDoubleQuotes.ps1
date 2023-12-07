<#
    .SYNOPSIS
        This script will import a CSV file and convert it to using qouted fields.

    .DESCRIPTION
        This script will import a CSV file and convert it to using qouted fields.
        You must update the columns specified in the script manually.

    .NOTES
        Author:         Jonathan Panning <jpann [at] impostr-labs.com>
        Filename:     	Csv-AddDoubleQuotes.ps1
        Created on:   	12-06-2023
        Version:        1.0
        Last updated:   12-06-2023

    .PARAMETER Path
        Specifies the input file.

    .PARAMETER Output
        Specifies the output file.

    .PARAMETER Delimiter
        Specifies the CSV column delimter. Default: ,

    .EXAMPLE
    PS> Import-Module .\Csv-AddDoubleQuotes.ps1 -Force
    PS> Add-CsvDoubleQuotes -Path .\MyCSV.csv -Output .\Updated.csv

    .EXAMPLE
    PS> Import-Module .\Csv-AddDoubleQuotes.ps1 -Force
    PS> Add-CsvDoubleQuotes -Path ..\..\MockData\MOCK_COLORS.csv -Output $HOME\MOCK_COLORS_Quoted.csv
#>


#Requires -Version 7.0
function Add-CsvDoubleQuotes {
<#
    .SYNOPSIS
        This script will import a CSV file and convert it to using qouted fields.

    .DESCRIPTION
        This script will import a CSV file and convert it to using qouted fields.
        You must update the columns specified in the script manually.

    .NOTES
        Author:         Jonathan Panning <jpann [at] impostr-labs.com>
        Filename:     	Csv-AddDoubleQuotes.ps1
        Created on:   	12-06-2023
        Version:        1.0
        Last updated:   12-06-2023

    .PARAMETER Path
        Specifies the input file.

    .PARAMETER Output
        Specifies the output file.

    .PARAMETER Delimiter
        Specifies the CSV column delimter. Default: ,

    .EXAMPLE
    PS> Import-Module .\Csv-AddDoubleQuotes.ps1 -Force
    PS> Add-CsvDoubleQuotes -Path .\MyCSV.csv -Output .\Updated.csv

    .EXAMPLE
    PS> Import-Module .\Csv-AddDoubleQuotes.ps1 -Force
    PS> Add-CsvDoubleQuotes -Path ..\MockData\MOCK_COLORS.csv -Output $HOME\MOCK_COLORS_Quoted.csv
#>

    [CmdletBinding()]
    Param(
        # Specifies the input file.
        [parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [alias("s")]
        [Alias('FullName')]
        [string]
        $Path,

        # Specifies the output file.
        [parameter(Mandatory=$true)]
        [alias("o")]
        [string]
        $Output,

        [parameter(Mandatory=$false)]
        [string]
        $Delimiter = ","
    )

    BEGIN {

    }
    PROCESS {
        $content = Import-Csv -Path $Path -Delimiter $Delimiter
        $columns = ($content[0].PSObject.Properties).Name

        [String[]]$columnsList = @()
        $columns | Foreach { $columnsList += $_}

        # Could also do it using -UseQuotes Always, which will quote everything...
        #$content | Export-Csv -Path $Output -NoTypeInformation -UseQuotes Always
        $content | Export-Csv -QuoteFields $columnsList -Path $Output -NoTypeInformation
    }
}
