function Request-UserName {
    <#
    .SYNOPSIS
        Checks for existence of Username and increments until if finds an available option.
    .DESCRIPTION
        Checks for existence of Username and increments until if finds an available option.
    .EXAMPLE
        PS C:\> Request-UserName -UserName 'DanPark', 'TedSdoukos'
        Gets available names in AD based off the names DanPark and TedSdoukos
    .NOTES
        Author: Ted Sdoukos
        Date Created: March 18, 2022
        Version: 1.0

        For assistance with Regular Expression:  Get-Help about_Regular_Expressions
        Regular Expression Cheat Sheet:
        \d -> decimal digit
        $Matches -> anything that matched
    #>
    [CmdletBinding()]
    param (
        [string[]]$UserName,
        $Domain = $env:USERDNSDOMAIN
    )
    process {
        foreach ($User in $UserName) {
            try {
                $NotAvailable = Get-ADUser -Identity $User -Server $Domain
            }
            catch {
                [PSCustomObject]@{
                    'UserName' = $User
                }
                Continue
            }
            If($User -match '\d+$')
            {
                $i = [int]$Matches[0]
                $Matches = $null
            }
            else {
                $i = 0
            }
            while ($NotAvailable) {
                $NotAvailable = $null
                $i++
                try {
                    $NotAvailable = Get-ADUser -Identity $User$i -Server $Domain
                }
                catch {
                    [PSCustomObject]@{
                        'UserName' = "$User$i"
                    }
                }
            }
        }
    }
}

Request-UserName -UserName 'DanPark', 'TedSdoukos','DanPark1','Ted'