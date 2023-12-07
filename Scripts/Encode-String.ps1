<#
    .SYNOPSIS
    Functions for URL encoding and decoding strings .

    .DESCRIPTION
    Functions for URL encoding and decoding strings .

    .NOTES
    Author:         Jonathan Panning <jpann [at] impostr-labs.com>
    Filename:     	Encode-String.ps1
    Created on:   	12-06-2023
    Version:        1.0
    Last updated:   12-06-2023

    .EXAMPLE
    PS> Import-Module .\Encode-String.ps1
    PS> Encode-String -String "this is a test"
    this+is+a+test

    PS> Import-Module .\Encode-String.ps1
    PS> Decode-String -String "this+is+a+test"
    this is a test
#>


function Encode-String
{
<#
    .SYNOPSIS
    URL encodes a string.

    .DESCRIPTION
    URL encodes a string.

    .NOTES
    Author:         Jonathan Panning <jpann [at] impostr-labs.com>
    Filename:     	Encode-String.ps1
    Created on:   	12-06-2023
    Version:        1.0
    Last updated:   12-06-2023

    .PARAMETER String
    String to encode

    .INPUTS
    System.String. String to encode.

    .OUTPUTS
    System.String. The URL encoded string.

    .EXAMPLE
    PS> Encode-String -String "this is a test"
    this+is+a+test

    .EXAMPLE
    PS> "this is a test" | Encode-String
    this+is+a+test
#>
    [CmdletBinding()]
    [OutputType('System.String')]
    Param(
        [parameter(Mandatory=$true,Position=0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$String
    )

    Add-Type -AssemblyName System.Web

    $EncodedString = [System.Web.HttpUtility]::UrlEncode($String)

    Write-Output $EncodedString
}

function Decode-String
{
<#
    .SYNOPSIS
    URL decodes a string.

    .DESCRIPTION
    URL decodes a string.

    .NOTES
    Author:         Jonathan Panning <jpann [at] impostr-labs.com>
    Created on:   	12-06-2023
    Version:        1.0
    Last updated:   12-06-2023

    .PARAMETER String
    String to encode

    .INPUTS
    System.String. The URL encoded string.

    .OUTPUTS
    System.String. The decoded string.

    .EXAMPLE
    PS> Decode-String -String "this+is+a+test"
    this is a test

    .EXAMPLE
    PS> "this+is+a+test" | Decode-String
    this is a test
#>
    [CmdletBinding()]
    [OutputType('System.String')]
    Param(
        [parameter(Mandatory=$true,Position=0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$String
    )

    Add-Type -AssemblyName System.Web

    $DecodedString = [System.Web.HttpUtility]::UrlDecode($String)

    Write-Output $DecodedString
}
