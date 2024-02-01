<#
.SYNOPSIS
    Performs a 'git pull' in the specified directory.

.DESCRIPTION
    Performs a 'git pull' in the specified directory.

    This is used by OpenWithPlusPlus and the 'Git Pull' context menu.

.NOTES
    File:           OpenWithPlusPlus-Git-Pull.ps1
    Author:         Jonathan Panning <jpann [at] impostr-labs.com>
    Created on:   	03/09/2023
    Version:        2.0
    Last updated:   02/01/2024

    OpenWithPlusPlus settings:
    Name: Git Pull
    Path: C:\Program Files\PowerShell\7\pwsh.exe
    Arguments: -ExecutionPolicy RemoteSigned -File "%USERPROFILE%\PowerShell\Scripts\OpenWithPlusPlus\OpenWithPlusPlus-Git-Pull.ps1" -Path %paths%
    Show for directories: checked
    Run hidden: Unchecked

.PARAMETER Path
    The path to the git repository.

.PARAMETER Pause
    Pause and wait for input before exiting.

.PARAMETER Sleep
    System.Double. Specifies the number of seconds to sleep before existing. Default value: 0.5

.INPUTS
    System.String. Accepts paths to git repositories as the parameter Path or FullName.

.OUTPUTS
    None. Returns no output.

.EXAMPLE
    PS> .\OpenWithPlusPlus-Git-Pull.ps1 -Path %HOME%\RepositoryHere

.EXAMPLE
    PS> Get-ChildItem -Path $HOME\Src -Directory | .\OpenWithPlusPlus-Git-Pull.ps1
#>

#[CmdletBinding()]
[CmdletBinding(DefaultParameterSetName = 'None')]
Param(
    [Parameter(Mandatory=$true,
        ValueFromPipeline = $true,
        ValueFromPipelineByPropertyName = $true)]
    [ValidateNotNullOrEmpty()]
    [Alias('FullName')]
    [string]
    $Path,

    [Parameter(ParameterSetName = 'Pause', Mandatory = $false)]
    [alias("p")]
    [switch]
    $Pause,

    [Parameter(ParameterSetName = 'Sleep', Mandatory = $false)]
    [alias("s")]
    [ValidateRange(0, [double]::MaxValue)]
    [double]
    $Sleep = 2.5
)
PROCESS {
    if (Test-Path $Path -PathType Container) {
        try {
            if (Test-Path -Path (Join-Path -Path $Path -ChildPath ".git") -PathType Container) {
                Write-Debug -Message "env:GIT_SSH_COMMAND: $($env:GIT_SSH_COMMAND)"

                if (-not($env:GIT_SSH_COMMAND)) {
                    if (Get-Command -Name ssh -ErrorAction Ignore) {
                        $sshPath = (Get-Command -Name ssh).Source
                        Write-Verbose -Message "env:GIT_SSH_COMMAND is empty, setting to '$sshPath'"

                        $env:GIT_SSH_COMMAND = '"' + $sshPath + '"';
                    } else {
                        Write-Warning -Message "env:GIT_SSH_COMMAND is empty and 'ssh' command was not found."

                    }
                }

                 if (!(Get-Command -Name git -ErrorAction Ignore)) {
                    Write-Error -Message 'Unable to locate git executable.'
                    return
                }

                Write-Debug -Message "git Path: $((Get-Command -Name git).Source))"
                Write-Verbose -Message "Executing a git pull for '$Path'"

                git -C $Path pull 

                if ($Pause) {
                    Write-Host
                    Read-Host -Prompt "Press any key to continue"
                } else {
                    Write-Verbose -Message "Sleeping for $Sleep seconds ..."

                    Start-Sleep -Seconds $Sleep
                }
            } else {
                Write-Verbose -Message "Path '$Path' is not a git repository!"
            }            
        }
        catch {
            Write-Error -Message "An error occurred:" $_ -Exception $_
        }
    }
}
