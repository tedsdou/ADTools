<#
.NOTES
Microsoft PowerShell Source File -- Created with Windows PowerShell ISE

FILENAME: 6-findLowMembershipCount.ps1
VERSION:  .09
AUTHOR: Ted Sdoukos - Ted.Sdoukos@microsoft.com
DATE:   Wednesday, October 19, 2016

WORKSHOP:  Windows PowerShell v4.0 for the IT Professional, Part 2
MODULE: Module 6 - Error Handling

Please provide credit to original author when used :-)


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

#requires -Version 3 -Modules ActiveDirectory
Try {
    $domains = (Get-ADForest).Domains
}
Catch {
    Throw "Unable to query domains!! Exception: $($_.Exception.Message)"
}
$report = $null
Foreach ($domain in $domains) {
    $dNames = @()
    $dNames += $domain
    If ((Get-ADDomain -Identity $domain).ChildDomains) {
        [array]$cDomain = (Get-ADDomain -Identity $domain).ChildDomains
        foreach ($c in $cDomain) { $dNames += $c }
    }
}
Foreach ($d in $dNames) {
    Try {
        $groups = Get-ADGroup -Server (Get-ADDomain -Identity $d).PDCEmulator -Filter *
    }
    Catch {
    }
    foreach ($group in $groups) {
        Try {
            $grpCount = (Get-ADGroupMember -Identity $group).Count
        }
        Catch {
        }
        If ($grpCount -le 1) {
            $props = @{
                'DomainName' = $d
                'GroupName'  = $group.Name
                'GroupCount' = $grpCount
            }
            $report += @(New-Object -TypeName PSCustomObject -Property $props)
        }
    }

}
$report | Format-Table -Property 'DomainName', 'GroupName', 'GroupCount' -AutoSize
