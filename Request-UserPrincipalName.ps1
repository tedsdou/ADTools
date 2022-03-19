function Request-UserPrincipalName {
    <#
    .SYNOPSIS
        Checks for existence of UserPrincipalName and increments until if finds an available option.
    .DESCRIPTION
        Checks for existence of UserPrincipalName and increments until if finds an available option.
    .EXAMPLE
        PS C:\> Request-UserPrincipalName -UserPrincipalName 'DanPark', 'TedSdoukos'
        Gets available names in AD based off the names DanPark and TedSdoukos
    .NOTES
        Author: Ted Sdoukos
        Date Created: March 18, 2022
        Version: 1.0

        For assistance with Regular Expression:  Get-Help about_Regular_Expressions
        Regular Expression Cheat Sheet:
        \d       -> decimal digit
        $        -> end of string
        $Matches -> anything that matched
    #>
    [CmdletBinding()]
    param (
        [string[]]$UserPrincipalName
    )
    process {
        foreach ($User in $UserPrincipalName) {
            try {
                $NotAvailable = Get-ADUser -Filter {UserPrincipalName -eq $UserPrincipalName}
            }
            catch {
                [PSCustomObject]@{
                    'UserPrincipalName' = $User
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
                    $NotAvailable = Get-ADUser - -Filter {UserPrincipalName -eq $User$i} 
                }
                catch {
                    [PSCustomObject]@{
                        'UserPrincipalName' = "$User$i"
                    }
                }
            }
        }
    }
}

Request-UserPrincipalName -UserPrincipalName 'DanPark', 'TedSdoukos','DanPark1','Ted'