<#
.SYNOPSIS
    Gets the connected client list from the specified Asus router.

.DESCRIPTION
    Gets the connected client list from the specified Asus router
    by requesting an authentication token and querying the router's 
    appGet.cgi interface.
    
.NOTES
    Author:         Jonathan Panning <jpann [at] impostr-labs.com>
    Created on:   	01-18-2024
    Last updated:   01-18-2024

.PARAMETER Address
    System.String. Specifies the IP address or host name of the router.

.PARAMETER User
    System.String. Specifies rhe router's login username.

.PARAMETER Password
    System.Security.SecureString. Secure string containing the router's password.

.INPUTS
    Does not accept any inputs.

.OUTPUTS
    PSObject[]. Returns an object array containing each client's information.

.EXAMPLE
    PS> .\Get-Asus-Router-ClientList.ps1 -Address 192.168.1.1 -User admin | Format-Table
    Enter Password> *****

    type defaultType name                        nickName                 ip            mac               from        macRepeat isGateway isWebServer
    ---- ----------- ----                        --------                 --            ---               ----        --------- --------- -----------
    72   10                                      Computer                 192.168.1.13  A4:A0:21:F6:FF:F8 networkmapd 0         0         0
    2    2           camera                   	 Camera                   192.168.1.43  E9:FD:D3:2A:30:4B networkmapd 0         0         0
    4    0           Electronics Inc             Device                   192.168.1.18  C5:AD:B0:A6:DD:40 networkmapd 0         0         0

.EXAMPLE
    PS> $Password = Read-Host -AsSecureString
    PS> .\Get-Asus-Router-ClientList.ps1 -Address 192.168.1.1 -User admin -Password $Password 
        | Select name, nickname, ip, mac 
        | Export-Csv -Path C:\temp\clients.csv -NoTypeInformation
#>

[CmdletBinding()]
[OutputType([System.Management.Automation.PSCustomObject[]])]
Param(
    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [String]
    $Address,

    [parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
    [string]$User,

    [parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
    [SecureString]$Password
)
BEGIN {
    function Get-Login-Token {
        [OutputType('System.String')]
        Param(
            [parameter(Mandatory=$true)]
            [ValidateNotNullOrEmpty()]
            [string]$Address,

            [parameter(Mandatory=$true)]
            [ValidateNotNullOrEmpty()]
            [string]$User,

            [parameter(Mandatory=$true)]
            [ValidateNotNullOrEmpty()]
            [SecureString]$Password
        )

        $account = "$($User):$([System.Net.NetworkCredential]::new("""", $Password).Password)"
        $string_bytes = $([System.Text.Encoding]::ASCII.GetBytes($account))
        $login = [Convert]::ToBase64String($string_bytes)

        $postParams = @{
            'login_authorization' = $login;
        }

        # Using this specific User-Agent is required
        $headers = @{
            'User-Agent' = 'asusrouter-Android-DUTUtil-1.0.0.245';
            'Content-Type' = 'application/json';
         }

        $loginUrl = "http://$($Address)/login.cgi"

        $response = Invoke-WebRequest -Uri $loginUrl -Method POST -Body $postParams -Headers $headers
        $token = ($response | ConvertFrom-Json).asus_token

        Write-Output $token
    }

    function Get-Client-List {
        [OutputType('System.String')]
        Param(
            [parameter(Mandatory=$true)]
            [ValidateNotNullOrEmpty()]
            [string]$Address,

            [parameter(Mandatory=$true)]
            [ValidateNotNullOrEmpty()]
            [string]$Token
        )

        $clientListUrl = "http://$($Address)/appGet.cgi"

        $postParams = @{
            'hook' = "get_clientlist();";
        }

        # Using this specific User-Agent is required
        $headers = @{
            'User-Agent' = 'asusrouter-Android-DUTUtil-1.0.0.245';
            'Content-Type' = 'application/x-www-form-urlencoded';
            'Accept' = "*/*"
        }

        # Add token cookie
        $session = [Microsoft.PowerShell.Commands.WebRequestSession]::new()
        $tokenCookie = [System.Net.Cookie]::new('asus_token', $Token)
        $session.Cookies.Add($clientListUrl, $tokenCookie)
        $clickedItemCookie = [System.Net.Cookie]::new('clickedItem_tab', '0')
        $session.Cookies.Add($clientListUrl, $clickedItemCookie)

        $response = Invoke-WebRequest -Uri $clientListUrl -Method POST -Body $postParams -Headers $headers -WebSession $session
        $clientList = ($response | ConvertFrom-Json).get_clientlist  | Select-Object -Property * -ExcludeProperty maclist,ClientAPILevel  

        $clientList.PSObject.Properties.Value | Write-Output
    }

}
PROCESS {
    $token = Get-Login-Token -Address $Address -User $User -Password $Password
    Write-Verbose "asus_token: $token"

    # Get client list
    $clientList = Get-Client-List -Address $Address -Token $token

    Write-Output $clientList
}
