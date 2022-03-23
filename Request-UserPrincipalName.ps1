function Request-UserPrincipalName {
    <#
    .SYNOPSIS
        Checks for existence of UserPrincipalName and increments until if finds an available option.
    .DESCRIPTION
        Checks for existence of UserPrincipalName and increments until if finds an available option.
    .EXAMPLE
        PS C:\> Request-UserPrincipalName -UserPrincipalName 'DanPark@Contoso.local', 'TedSdoukos@Contoso.local'
        Gets available names in AD based off the names DanPark@Contoso.local and TedSdoukos@Contoso.local
    .NOTES
        Author: Ted Sdoukos
        Date Created: March 18, 2022
        Version: 1.0

        For assistance with Regular Expression:  Get-Help about_Regular_Expressions
        Regular Expression Cheat Sheet:
        \d       -> decimal digit
        .        -> any character
        ^        -> start of string
        $        -> end of string
        +        -> one or more
        $Matches -> anything that matched
    #>
    [CmdletBinding()]
    param (
        [ValidatePattern('^.+@.+$')]
        [string[]]$UserPrincipalName,
        $Domain = $env:USERDNSDOMAIN
    )
    process {
        foreach ($User in $UserPrincipalName) {
            $Matches = $null
            $null = $User -match '(.+)(@.+)'
            $UserNameTry = "$($Matches[1])$($Matches[2])"
            if (-not(Get-ADUser -Filter { UserPrincipalName -eq $UserNameTry } -Server $Domain)) {
                [PSCustomObject]@{
                    'UserPrincipalName' = $UserNameTry
                }
                Continue
            }
            else {
                If ($Matches[1] -match '\d+$') {
                    $i = [int]$Matches[0]
                }
                else {
                    $i = 0
                }
                do {
                    $i++
                    $UserNameTry = "$($Matches[1])$i$($Matches[2])"
                } until (-not(Get-ADUser -Filter { UserPrincipalName -eq $UserNameTry } -Server $Domain))
                [PSCustomObject]@{
                    'UserPrincipalName' = $UserNameTry
                }
            }   
        }
    }
}