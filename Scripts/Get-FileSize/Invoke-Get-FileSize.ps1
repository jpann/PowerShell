<#
    .SYNOPSIS
    Basic example of invoking Get-FileSize.ps1

    .DESCRIPTION
    Basic example of invoking Get-FileSize.ps1

    .NOTES
    Author:         Jonathan Panning <jpann [at] impostr-labs.com>
    Filename:     	Invoke-Get-FileSize.ps1
#>
clear
cd $PSScriptRoot

# Get the size of each .csv file in the MockData directory
# and display it in different formats.
Get-ChildItem -File -Path ..\..\MockData\*.csv | ./Get-FileSize.ps1 `
    | Select FullName, Size, `
    @{Name="SizeGB";Expression={ (($_.Size / 1GB).ToString("F") + 'GB') }}, `
    @{Name="SizeMB";Expression={ (($_.Size / 1MB).ToString("F") + 'MB') }}, `
    @{Name="SizeKB";Expression={ (($_.Size / 1KB).ToString("F") + 'KB') }} `
    | Format-Table

# FullName                                                          Size SizeGB SizeMB SizeKB
# --------                                                          ---- ------ ------ ------
# C:\Users\MyUser\PowerShell\Scripts\MockData\MOCK_COLORS.csv       21625 0.00GB 0.02MB 21.12KB
# C:\Users\MyUser\PowerShell\Scripts\MockData\MOCK_PEOPLE_DATA.csv  207766 0.00GB 0.20MB 202.90KB



