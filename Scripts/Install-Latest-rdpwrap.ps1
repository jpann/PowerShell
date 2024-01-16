<#
.SYNOPSIS
    Downloads the latest sebaxakerhtc/rdpwrap installers from GitHub.

.DESCRIPTION
    Downloads the latest sebaxakerhtc/rdpwrap installers from GitHub 
    and copies them into the "C:\Program Files\RDP Wrapper" folder
    and executes the installer.

    If Windows Defender is enabled, "C:\Program Files\RDP Wrapper"
    will be added to the exclusions list.

.NOTES
    Author: Jonathan Panning <jpann [at] impostr-labs.com>
    Filename: Get-Latest-rdpwrap.ps1
    Created on: 11-21-2023
    Last updated: 01-04-2024

.PARAMETER OutPath
    String. The path to download to.

.INPUTS
    None.

.OUTPUTS
    None. Get-Latest-rdpwrap.ps1 does not generate any output.

.EXAMPLE
	PS> .\Get-Latest-rdpwrap.ps1

.LINK
	https://github.com/jpann
#>


#requires -RunAsAdministrator
#requires -version 4
[CmdletBinding()]
Param()
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

    $Script:REPO = "sebaxakerhtc/rdpwrap"
    $Script:RELEASES = "https://api.github.com/repos/$Script:REPO/releases/latest"
    $Script:RDPWrapperPath = "C:\Program Files\RDP Wrapper"

    # Create RDP Wrapper path early so we can add it to the Windows Security Exclusions
    if (-not(Test-Path -Path $Script:RDPWrapperPath  -PathType Container)) {
        Write-Host "Creating $($Script:RDPWrapperPath) ..."
        New-Item $Script:RDPWrapperPath -Type Directory -Force | Out-Null
    }
}
PROCESS {
    $winSecurityEnabled = (Get-MpComputerStatus).AntivirusEnabled

    if ($winSecurityEnabled) {
        Write-Host "Adding $($Script:RDPWrapperPath) to Windows Security Exclusions ..."
        Add-MpPreference -ExclusionPath $Script:RDPWrapperPath
    }

    Write-Host "Determining latest release ..."
    $tag = Get-Latest-Version -Url $Script:RELEASES
    Write-Host "Latest release is " -NoNewLine
    Write-Host "$tag" -ForegroundColor Green

    $assets = Get-Latest-Assets -Url $Script:RELEASES
    Write-Host "This release has " -NoNewLine
    Write-Host "$($assets.Count)" -ForegroundColor Green -NoNewLine 
    Write-Host " files"

    foreach($asset in $assets) {
        $fileName = $asset.Name
        $url = $asset.Url
        $filePath = Join-Path $Script:RDPWrapperPath $fileName

        Write-Host ">> Downloading $fileName to $($Script:RDPWrapperPath) ..."
        Download -File $filePath -Url $url
    }

    # Launch installer
    $installerPath = Join-Path $Script:RDPWrapperPath "RDPW_Installer.exe"
    if (Test-Path -Path "$installerPath" -PathType Leaf) {
        Write-Host "Launching installer $installerPath ..."

        Start-Process $installerPath
    } else {
        Write-Error "Installer $installerPath does not exist!"
    }
}

