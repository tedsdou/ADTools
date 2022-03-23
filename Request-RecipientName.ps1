function Request-RecipientName {
    <#
    .SYNOPSIS
        Checks for existence of RecipientName and increments until if finds an available option.
    .DESCRIPTION
        Checks for existence of RecipientName and increments until if finds an available option.
    .EXAMPLE
        PS C:\> Request-RecipientName -RecipientName 'DanPark@contoso.local', 'TedSdoukos@contoso.local'
        Gets available names in AD based off the names DanPark@contoso.local and TedSdoukos@contoso.local
    .NOTES
        Author: Ted Sdoukos
        Date Created: March 22, 2022
        Version: 1.0
 
        For assistance with Regular Expression:  Get-Help about_Regular_Expressions
        Regular Expression Cheat Sheet:
        \d              -> decimal digit
        .               -> any character
        +               -> one or more
        $Matches        -> anything that matched
        ()              -> group
        ?<GroupName>    -> group name
    #>
    [CmdletBinding()]
    param ([string[]]$EmailAddress)
    process {
        foreach ($Email in $EmailAddress) {
            $Matches = $null
            try {
                Write-Verbose -Message "Checking for RecipientName: $Email"
                $NotAvailable = Get-Recipient -Identity $Email -ResultSize Unlimited -ErrorAction stop
                Write-Verbose -Message "$Email is NOT available"
            }
            catch {
                Write-Verbose -Message "$Email is available"
                [PSCustomObject]@{'UserEmailAddress' = $Email }
                Continue
            }
            Write-Verbose -Message "NotAvailable: $NotAvailable"
            If ($Email -match '(?<Name>.+)(\d+)(?<Dom>@.+)') {
                $i = [int]$Matches[2]
            }
            else {
                $i = 0
                $null = $Email -match '(?<Name>.+)(?<Dom>@.+)'
            }
 
            while ($NotAvailable) {
                $NotAvailable = $null
                $i++
                try {
                    $NewEmail = "$($Matches.Name)$i$($Matches.Dom)"
                    Write-Verbose -Message "Checking for RecipientName: $NewEmail"
                    $NotAvailable = Get-Recipient -Identity $NewEmail -ResultSize Unlimited -ErrorAction stop
                }
                catch {
                    [PSCustomObject]@{'UserEmailAddress' = $NewEmail }
                }
            }
        }
    }
}