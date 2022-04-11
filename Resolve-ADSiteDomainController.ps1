function Resolve-ADSiteDomainController {
    <#
    .SYNOPSIS
        Gets DC in site that communicates over specified port.
    .DESCRIPTION
        Returns first domain controller in specified site that successfully communicates over specified port.
    .EXAMPLE
        PS C:\> Resolve-ADSiteDomainController -SiteName 'Cloud' -Port 9389
        Parses domain controllers in the 'Cloud' AD site and searches for one that communicates over port 9389.
    .NOTES
        Author:  Ted Sdoukos (Ted.Sdoukos@Microsoft.com)
        Date:    11APR2022
        Version: 1.0
       
        DISCLAIMER:
        ===========
        This Sample Code is provided for the purpose of illustration only and is 
        not intended to be used in a production environment.  
        THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT
        WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT 
        LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS
        FOR A PARTICULAR PURPOSE.  

        We grant You a nonexclusive, royalty-free
        right to use and modify the Sample Code and to reproduce and distribute
        the object code form of the Sample Code, provided that You agree:
        (i) to not use Our name, logo, or trademarks to market Your software
        product in which the Sample Code is embedded; (ii) to include a valid
        copyright notice on Your software product in which the Sample Code is
        embedded; and (iii) to indemnify, hold harmless, and defend Us and
        Our suppliers from and against any claims or lawsuits, including
        attorneys' fees, that arise or result from the use or distribution
        of the Sample Code.
    #>
    [CmdletBinding()]
    param (
        $SiteName = 'Default-First-Site-Name',
        $Port = 9389
    )
    $ProgressPreference = $WarningPreference = 'SilentlyContinue'
    $DCs = (Get-ADDomainController -Filter {Site -eq $SiteName}).HostName
    if (-not($DCs)) {
        Throw "Unable to parse DCs in $SiteName"
    }
    switch ($DCs) {
        {(Test-NetConnection -ComputerName $_ -Port $Port).TcpTestSucceeded -eq 'True'} {
            $DC = $_
            [PSCustomObject]@{
                'DomainController' = $DC
                'TCPPort' = $Port
            }  
            Break
        }
        Default {Throw "Unable to communicate with any DC over port: $Port in AD Site: $SiteName"}
    }
}