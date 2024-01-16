<#
.SYNOPSIS
    Downloads and install the latest PowerShell 7 win-x64 release from GitHub.

.DESCRIPTION
    Downloads the latest PowerShell 7 win-x64 release from GitHub
    into the user's Downloads directory and executes the installer.

.NOTES
    Author: Jonathan Panning <jpann [at] impostr-labs.com>
    Filename: Install-Latest-PowerShell7-Win64.ps1
    Created on: 01-16-2024
    Last updated: 01-16-2024

.PARAMETER DownloadOnly
    Boolean. Only download the installer.

.INPUTS
    None.

.OUTPUTS
    None. Install-Latest-PowerShell7-Win64.ps1 does not generate any output.

.EXAMPLE
	PS> .\Install-Latest-PowerShell7-Win64.ps1

.LINK
	https://github.com/jpann
#>


#requires -RunAsAdministrator
#requires -version 4
[CmdletBinding()]
Param(
    [Parameter(Mandatory=$false)]
    [switch]$DownloadOnly
)
BEGIN {
    function Get-Latest-Version {
        Param(
            [parameter(Mandatory=$true)]
            [ValidateNotNullOrEmpty()]
            $Url
        )

        Write-Verbose "URL: $Url"

        $tag = (Invoke-WebRequest -UseBasicParsing $Url| ConvertFrom-Json)[0].tag_name
        $tagUrl = (Invoke-WebRequest -UseBasicParsing $Url| ConvertFrom-Json)[0].html_url
        
        Write-Verbose "Tag URL: $tagUrl"

        $tag
    }

    function Get-Latest-Assets {
        Param(
            [parameter(Mandatory=$true)]
            [ValidateNotNullOrEmpty()]
            $Url
        )

        $assetsObject = (Invoke-WebRequest -UseBasicParsing $Url| ConvertFrom-Json)[0].assets

        $assets = @( )

        foreach ($asset in $assetsObject) {
            $assetName = $asset.name
            $assetUrl = $asset.browser_download_url

            $assets += @{ 
                Name = $assetName; 
                Url = $assetUrl 
            }
        }

        $assets
    }

    function Download {
        Param(
        [parameter(Mandatory=$true)]
            [ValidateNotNullOrEmpty()]
            $Url,
            
            [parameter(Mandatory=$true)]
            [ValidateNotNullOrEmpty()]
            $File
        )

        Write-Verbose "File: $File"
        Write-Verbose "URL: $Url"

        Invoke-WebRequest -Method Get -Uri:$Url -OutFile $File
    }

    $Script:REPO = "PowerShell/PowerShell"
    $Script:RELEASES = "https://api.github.com/repos/$Script:REPO/releases/latest"
}
PROCESS {
    Write-Host "Determining latest release ..."
    $tag = Get-Latest-Version -Url $Script:RELEASES
    Write-Host "Latest release is " -NoNewLine
    Write-Host "$tag" -ForegroundColor Green

    $assets = Get-Latest-Assets -Url $Script:RELEASES
    Write-Host "This release has " -NoNewLine
    Write-Host "$($assets.Count)" -ForegroundColor Green -NoNewLine 
    Write-Host " files"

    $fileName = "PowerShell-{0}-win-x64.msi" -f $tag.Replace("-Beta", "").Replace("p1", "").Replace("v", "")
    $filePath = Join-Path (Join-Path $HOME "Downloads") $fileName
    $url = "https://github.com/$($Script:REPO)/releases/download/$tag/$fileName"

    Write-Host ">> Downloading $fileName to $($filePath) ..."
    Download -File $filePath -Url $url

    if ($DownloadOnly) {
        # Launch installer
        if (Test-Path -Path "$filePath" -PathType Leaf) {
            Write-Host "Launching installer $filePath ..."

            # Install
            msiexec /i $filePath
        } else {
            Write-Error "Installer $filePath does not exist!"
        }
    }
}
