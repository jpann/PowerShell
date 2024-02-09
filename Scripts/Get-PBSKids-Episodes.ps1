<#
.SYNOPSIS
    Downloads episodes of the specified PBS Kids program.

.DESCRIPTION
    Downloads episodes of the specified PBS Kids program.

.NOTES
    Author:         Jonathan Panning <jpann [at] impostr-labs.com>
    Filename:     	Get-PBSKids-Episodes.ps1
    Created on:   	02-08-2024
    Last updated:   02-09-2024

.PARAMETER OutPath
    String. The path to download episodes to.

.PARAMETER Slug
    System.String. The  slug of the show.

.PARAMETER Slugs
    System.Boolean. Lists each show and their slug.

.PARAMETER Minimum
    System.Boolean. Include the minimum amount of metadata in the episodes file.
    The minimum metadata is: id, title, description, air_date, duration, video_uri, title_clean,
    program, program_slug, proc_date.

.PARAMETER After
    System.DateTime. Only get episodes with an air date before the specified date.

.PARAMETER Before
    System.DateTime. Only get episodes with an air date after the specified date.

.PARAMETER Collection
    System.String[]. Specifies the program collection to query. Default: Tier1, Tier2, Tier3

.INPUTS
    None.

.OUTPUTS
    PSObject[]. Get-PBSKids-Episodes.ps1 generates output when using the -Slugs parameter.

.EXAMPLE
	PS> .\Get-PBSKids-Episodes.ps1 -Slugs

    title                               slug                             websiteUrl                           ages
    -----                               ----                             ----------                           ----
    Alma's Way                          almas-way                        https://pbskids.org/almasway         4-6
    Arthur                              arthur                           https://pbskids.org/arthur           4-8
    City Island                         city-island                                                           4-8
    Curious George                      curious-george                   https://pbskids.org/curiousgeorge/   3-5
    Daniel Tiger's Neighborhood         daniel-tigers-neighborhood       https://pbskids.org/daniel/          2-4
    Dinosaur Train                      dinosaur-train                   https://pbskids.org/dinosaurtrain/   3-6
    Donkey Hodie                        donkey-hodie                     https://pbskids.org/donkeyhodie      2-4
    Elinor Wonders Why                  elinor-wonders-why               https://pbskids.org/elinor           3-5

.EXAMPLE
	PS> .\Get-PBSKids-Episodes.ps1 -Slug lyla-loop -OutPath $HOME\Downloads

.EXAMPLE
	PS> .\Get-PBSKids-Episodes.ps1 -Slug nature-cat -OutPath $HOME\Downloads -After '01/01/2024'

.EXAMPLE
	PS> .\Get-PBSKids-Episodes.ps1 -Slug nature-cat -OutPath $HOME\Downloads -Before '01/01/2024'

.LINK
	https://github.com/jpann/PowerShell
#>


#requires -version 4
[CmdletBinding(DefaultParameterSetName = 'GetShows',
    SupportsShouldProcess=$true)]
Param(
    [Parameter(Mandatory=$false,
        ParameterSetName = 'GetEpisodes')]
    [alias("o")]
    [string] 
    $OutPath,

    [Parameter(Mandatory=$false,
        ParameterSetName = 'GetEpisodes')]
    [alias("ef")]
    [string] 
    $EpisodesFile,

    [Parameter(Mandatory=$false,
        ParameterSetName = 'GetShows')]
    [alias("min")]
    [switch]
    $Minimum,

    [Parameter(Mandatory=$true,
        ParameterSetName = 'GetEpisodes')]
    [alias("e")]
    [string] 
    $Slug,

    [Parameter(Mandatory=$false,
        ParameterSetName = 'GetEpisodes')]
    [Parameter(Mandatory=$false,
        ParameterSetName = 'CutOffAfter')]
    [alias("a")]
    [datetime] 
    $After,

    [Parameter(Mandatory=$false,
        ParameterSetName = 'GetEpisodes')]
    [Parameter(Mandatory=$false,
        ParameterSetName = 'CutOffBefore')]
    [alias("b")]
    [datetime] 
    $Before,

    [Parameter(Mandatory=$false,
        ParameterSetName = 'GetShows')]
    [alias("s")]
    [switch]
    $Slugs,

    [Parameter(Mandatory = $false,
        ParameterSetName = 'GetShows')]
    [ValidateSet(
        'Spotlight',
        'Promo',
        'Tier1',
        'Tier2',
        'Tier3'
    )]
    [string[]]
    $Collection = ('Tier1','Tier2', 'Tier3')
)
BEGIN {
    $Script:CollectionMapTable = @{ 
        Spotlight = 'kids-show-spotlight'; 
        Promo = 'kids-promo';
        Tier1 = 'kids-programs-tier-1'; 
        Tier2 = 'kids-programs-tier-2';
        Tier3 = 'kids-programs-tier-3'
    }

    $Script:DEFAULT_OUTPUT = "$HOME\Downloads"
    $Script:DEFAULT_EPISODES_FILENAME = "Episodes.json"
    $Script:ShowsUri = "https://content.services.pbskids.org/v2/kidspbsorg/home"
    $Script:ShowUri = "https://content.services.pbskids.org/v2/kidspbsorg/programs/{0}"

    if (-not($OutPath)) {
        $OutPath = $Script:DEFAULT_OUTPUT
    }

    if (-not($EpisodesFile)) {
        $EpisodesFile = $Script:DEFAULT_EPISODES_FILENAME
    }

    $EpisodesFile = Join-Path -Path $OutPath -ChildPath $EpisodesFile

    function Backup-File {
        [CmdletBinding(SupportsShouldProcess=$true)]
        [OutputType([System.String])]
        Param(
            [Parameter(Mandatory=$true)]
            [ValidateNotNullOrEmpty()]
            [string]
            $File,

            [Parameter(Mandatory=$false)]
            [string]
            $Suffix = "_BACKUP",

            [Parameter(Mandatory=$false)]
            [string]
            $DateTimeFormat = "yyyy-MM-dd_hh.mmtt"
        )
        process {
            Write-Verbose "Backup-File  - File: $File"

            $filePath = Split-Path -Parent $File
            $fileName = Split-Path -Path $File -Leaf
            $fileNameNoExt = [System.IO.Path]::GetFileNameWithoutExtension($fileName)
            $fileExt = ((Split-Path $File -Leaf).Split('.'))[1]
    
            # Use default file extension if there is not one
            if (-not($fileExt)) {
                $fileExt = "bak"
            }
    
            if (Test-Path -Path $EpisodesFile -PathType Leaf) {
                if (-not(Test-Path -Path $filePath -PathType Container)) {
                    New-Item -Path $filePath -ItemType Directory -Force | Out-Null
                }
    
                $backupFileName = "$($fileNameNoExt)_$((Get-Date).ToString($DateTimeFormat))$($Suffix).$($fileExt)"
                $backupFilePath = Join-Path -Path $filePath -ChildPath $backupFileName
    
                if ($PSCmdlet.ShouldProcess($backupFilePath, "Backup File")) {
                    Copy-Item -Path $File -Destination $backupFilePath -Force
                }
    
                $backupFilePath | Write-Output
            }
        }
    }

    function Download {
        [CmdletBinding(SupportsShouldProcess=$true)]
        Param(
        [Parameter(Mandatory=$true)]
            [ValidateNotNullOrEmpty()]
            [string]
            $Url,
            
            [parameter(Mandatory=$true)]
            [ValidateNotNullOrEmpty()]
            [string]
            $File
        )
        process {
            Write-Verbose "File: $File"
            Write-Verbose "URL: $Url"
    
            $filePath = Split-Path -Parent $File
    
            if (-not(Test-Path -Path $filePath -PathType Container)) {
                New-Item -Path $filePath -ItemType Directory -Force | Out-Null
            }
    
            if ($PSCmdlet.ShouldProcess($File,"Download File")) {
                Invoke-WebRequest -Method Get -Uri:$Url -OutFile $File
            }
        }
    }

    function Get-Slugs {
        [CmdletBinding()]
        [OutputType([PSObject[]])]
        Param(
            [Parameter(Mandatory = $false)]
            [ValidateSet(
                'Spotlight',
                'Promo',
                'Tier1',
                'Tier2',
                'Tier3'
            )]
            [string[]]
            $Collection = ('Tier1','Tier2', 'Tier3')
        )

        $response = try { 
            Invoke-WebRequest -UseBasicParsing $Script:ShowsUri -ErrorAction Stop
        } catch [System.Net.WebException] { 
            Write-Verbose "An exception was caught: $($_.Exception.Message)"
            $_.Exception.Response 
        } 

        $programs = @()

        if ($response.StatusCode -eq '200') {
            $jsonObj = ConvertFrom-Json $([String]::new($response.Content))

            foreach ($collectionKey in $Collection) {
                if (-not $Script:CollectionMapTable.ContainsKey($collectionKey)) { 
                    Throw "Invalid -Collection argument: $collectionKey"
                }

                $collectionName =  $Script:CollectionMapTable[$collectionKey]
                $propertyNames = $jsonObj.collections.psobject.Properties.Name

                if ($propertyNames -contains $collectionName) {
                    $programData = $jsonObj.collections.$collectionName

                    $programsData = $programData.Content | Where-Object { $_.content_type -eq 'program' -and $null -ne $_.ages } | 
                        Select-Object -Property title, slug, websiteUrl, ages | Sort-Object -Property slug

                    $programs += $programsData
                }
            }
        }

        $programs | Write-Output
    }

    function Get-Program {
        [CmdletBinding()]
        [OutputType([PSObject[]])]
        Param(
            [Parameter(Mandatory = $true)]
            [ValidateNotNullOrEmpty()]
            [string]
            $ProgramSlug,

            [Parameter(Mandatory = $false)]
            [string]
            $TitleSeparator = " -- ",
            
            [Parameter(Mandatory=$false,
                ParameterSetName = 'CutOffAfter')]
            [alias("a")]
            [datetime] 
            $After,

            [Parameter(Mandatory=$false,
                ParameterSetName = 'CutOffBefore')]
            [alias("b")]
            [datetime] 
            $Before
        )

        $uri = $Script:ShowUri -f $ProgramSlug

        $response = try { 
            Invoke-WebRequest -UseBasicParsing $uri -ErrorAction Stop
        } catch [System.Net.WebException] { 
            Write-Verbose "An exception was caught: $($_.Exception.Message)"
            $_.Exception.Response 
        } 

        $episodes = @()

        if ($response.StatusCode -eq '200') {
            $jsonObj = ConvertFrom-Json $([String]::new($response.Content))

            # TODO: Split episode title by / and store resulting array
            # into episodes property.

            if ($Before) {
                $filterScript = { ($_.video_type -eq "Episode" -and $_.content_type -eq "video") `
                    -and ($_.air_date -lt $Before)
                }
            }

            if ($After) {
                $filterScript = { ($_.video_type -eq "Episode" -and $_.content_type -eq "video") `
                    -and ($_.air_date -gt $After)
                }
            }

            $episodeData = $jsonObj.collections.episodes.content |
                Where-Object -FilterScript $filterScript |
                Select-Object -Property  id, title, description, short_description `
                    , air_date, is_new, is_special, is_movie, video_type, duration `
                    , @{Name="video_uri";Expression={$_.mp4}} `
                    , @{Name="title_clean";Expression={[string]($_.title.Replace(" / ", $TitleSeparator).Replace("/", $TitleSeparator)).ToString()}} `
                    , @{Name="program_title";Expression={[string]$_.program.title}} `
                    , @{Name="program_slug";Expression={[string]$_.program.slug}} `
                    , @{Name="proc_date";Expression={([datetime](Get-Date))}}
                    #, @{Name="episodes";Expression={($_.title.Split("/"))}}
                
            $episodes += $episodeData
        }

        $episodes | Write-Output
    }

    function Get-Episode-FileName {
        [CmdletBinding()]
        [OutputType([System.String])]
        Param(
            [Parameter(Mandatory = $true,
                ValueFromPipeline = $true,
                ValueFromPipelineByPropertyName = $true)]
            [ValidateNotNullOrEmpty()]
            [psobject]
            $Episode,

            [Parameter(Mandatory = $false)]
            [string]
            $Template = "{{ProgramTitle}} - {{EpisodeTitle}} [{{AirDate}}]",

            [Parameter(Mandatory = $false)]
            [string]
            $AirDateFormat = "yyyy-MM-dd"
        )

        $fileName = $Template
        $episode_airDate = ([DateTime]::Parse($Episode.air_date)).ToString($AirDateFormat)

        $program_title = $Episode.program_title
        $episode_title = $Episode.title_clean

        # Remove invalid characters from program title
        $program_title = Remove-InvalidFileNameChars -Name $program_title

        # Remove invalid characters from episode title
        $episode_title = Remove-InvalidFileNameChars -Name $episode_title
        
        $fileName = $fileName -replace "{{ProgramTitle}}", $program_title
        $fileName = $fileName -replace "{{EpisodeTitle}}", $episode_title
        $fileName = $fileName -replace "{{AirDate}}", $episode_airDate

        $fileName | Write-Output
    }

    function Test-ValidFileName {
        [CmdletBinding()]
        [OutputType([System.Boolean])]
        Param(
            [Parameter(Mandatory = $true)]
            [string]
            $Value
        )

        $IndexOfInvalidChar = $Value.IndexOfAny([System.IO.Path]::GetInvalidFileNameChars())

        return $IndexOfInvalidChar -eq -1
    }

    function Test-ValidPath {
        [CmdletBinding()]
        [OutputType([System.Boolean])]
        Param(
            [Parameter(Mandatory = $true)]
            [string]
            $Value
        )

        $IndexOfInvalidChar = $Value.IndexOfAny([System.IO.Path]::GetInvalidPathChars())

        return $IndexOfInvalidChar -eq -1
    }

    function Remove-InvalidFileNameChars {
        [CmdletBinding()]
        [OutputType([System.String])]
        Param(
            [Parameter(Mandatory=$true,
                Position=0,
                ValueFromPipeline=$true,
                ValueFromPipelineByPropertyName=$true)]
            [string]
            $Name,

            [Parameter(Mandatory=$false)]
            [switch]
            $ReplaceCommandSymbols
        )

        $invalidChars = [IO.Path]::GetInvalidFileNameChars() -join ''
        $re = "[{0}]" -f [RegEx]::Escape($invalidChars)
        
        $Name = ($Name -replace $re)

        # Replace spaces with _
        #$Name = $Name.Replace(" ", "_")

        # Replace command symbols
        if ($ReplaceCommandSymbols) {
            $Name = $Name.Replace("&", "and")
            $Name = $Name.Replace("\", "")
            $Name = $Name.Replace("<", "")
            $Name = $Name.Replace(">", "")
            $Name = $Name.Replace("^", "")
            $Name = $Name.Replace("|", "")
        }

        $Name | Write-Output
    }

    function Remove-InvalidPathChars {
        [CmdletBinding()]
        [OutputType([System.String])]
        Param(
            [Parameter(Mandatory=$true,
                Position=0,
                ValueFromPipeline=$true,
                ValueFromPipelineByPropertyName=$true)]
            [string]
            $Name,

            [Parameter(Mandatory=$false)]
            [switch]
            $ReplaceCommandSymbols
        )

        $invalidChars = [IO.Path]::GetInvalidPathChars() -join ''
        $re = "[{0}]" -f [RegEx]::Escape($invalidChars)
        
        $Name = ($Name -replace $re)

        # Replace command symbols
        if ($ReplaceCommandSymbols) {
            $Name = $Name.Replace("&", "and")
            $Name = $Name.Replace("\", "")
            $Name = $Name.Replace("<", "")
            $Name = $Name.Replace(">", "")
            $Name = $Name.Replace("^", "")
            $Name = $Name.Replace("|", "")
        }

        $Name | Write-Output
    }
}
PROCESS {
    if ($Slugs) {
        Get-Slugs -Collection:$Collection | Write-Output
    } else {
        # Load  episodes file that contains a list of previously downloaded episodes
        $episodes_previous = @()

        if (Test-Path -Path $EpisodesFile -PathType Leaf) {
            $episodes_previous = Get-Content -Raw $EpisodesFile  | ConvertFrom-Json
        }

        # If existing episodes file exists, rename it to back it up.
        Backup-File -File $EpisodesFile

        if ($Before) {
            $episodes = Get-Program -ProgramSlug $Slug -Before:$Before
        } 

        if ($After) {
            $episodes = Get-Program -ProgramSlug $Slug -After:$After
        }

        foreach ($episode in $episodes) {
            # Check of previously processed episodes list contains 
            # this episode
            $episodeExists = $episodes_previous | Where-Object { $_.id -eq $episode.id }

            if ($episodeExists) {
                Write-Host "Episode '$($episode.title)' with ID $($episode.id) in program '$($programTitle)' exists in metadata file. Skipping ..."

                continue
            }

            $fileNameNoExt = Get-Episode-FileName -Episode $episode
            $fileName = "$fileNameNoExt.mp4"

            # Append program title to OutPath
            $programTitle = $episode.program_title

            if ($programTitle) {
                $programTitle = Remove-InvalidPathChars -Name $programTitle
                $filePath = (Join-Path -Path $OutPath -ChildPath $programTitle)
            }
            
            $filePath = (Join-Path -Path $filePath -ChildPath $fileName)
            
            Write-Host "Downloading '$($episode.title)' in program '$($programTitle)' ..."

            Download -Url $episode.video_uri -File $filePath
        }

        # Append new episodes to previous episodes
        $episodes_previous += $episodes

        # Export downloaded to json
        if ($Minimum) {
            $MinimumProperties = @(
                'id',
                'title',
                'description',
                'air_date',
                'duration',
                'video_uri',
                'title_clean',
                'program',
                'program_slug',
                'proc_date'
            )

            $episodes_previous | Select-Object -Property -$MinimumProperties | ConvertTo-Json -Depth 100 | Out-File $EpisodesFile -Force
        } else {
            $episodes_previous | ConvertTo-Json -Depth 100 | Out-File $EpisodesFile -Force
        } 
    }
}