Function Get-TempPassword{
[CmdletBinding()]
#Taken from http://blogs.technet.com/b/heyscriptingguy/archive/2013/06/03/generating-a-new-password-with-windows-powershell.aspx
Param([int]$Length=10)

$ascii=$NULL;For ($a=33;$a -le 126;$a++) {$ascii+=,[char][byte]$a }

For ($loop=1; $loop -le $length; $loop++) {
            $TempPassword+=($ascii | Get-Random)
            }

    $TempPassword
}

Function Find-ConflictObject
{
[CmdletBinding()]
Param()
    Get-ADObject -LDAPFilter "(|(cn=*\0ACNF:*)(ou=*CNF:*))"
}

Function Remove-ConflictObject
{
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
Param()

$conflicts = Get-ADObject -LDAPFilter "(|(cn=*\0ACNF:*)(ou=*CNF:*))"
    If($PSCmdlet.ShouldProcess($conflicts.name,'Removing Conflict Objects'))
    {
         $conflicts | Remove-ADObject -Confirm:$false
    }

}

Function Remove-OrphanedGPT
{
[CmdletBinding(SupportsShouldProcess=$true,ConfirmImpact='High')]
 Param()   
    $gpos = Get-GPO  -All
    $guids = $gpos | ForEach-Object { "{$($_.Id.Guid)}" }
    $files = Get-ChildItem -Path "\\$env:USERDNSDOMAIN\SYSVOL\$env:USERDNSDOMAIN\Policies" | 
        Where-Object {($_.Name -notin $guids) -and ($_.Name -ne 'PolicyDefinitions')}
    $files | ForEach-Object {
      if ($pscmdlet.ShouldProcess("$env:USERDOMAIN", "Removing orphaned GPT: $_"))
            {
                Write-Output "Deleting orphaned GPO, $($_.Name)"
                $_ | Remove-Item -Recurse -Confirm:$false
            }
      } 
}

Function Find-LowGroupMembership
{
[CmdletBinding()]
Param()
    Try
    {
        $domains = (Get-ADForest).Domains
    }
    Catch
    {
        Throw "Unable to query domains!! Exception: $($_.Exception.Message)"
    }
    $report = $null
    Foreach($domain in $domains){
        $dNames = @()
        $dNames += $domain
        If((Get-ADDomain -Identity $domain).ChildDomains)
        {
            [array]$cDomain = (Get-ADDomain -Identity $domain).ChildDomains
            foreach($c in $cDomain){ $dNames += $c }
        }
    }
    Foreach($d in $dNames)
    {
        Try
        {
            $groups = Get-ADGroup -Server (Get-ADDomain -Identity $d).PDCEmulator -Filter *
        }
        Catch
        {
        }
        foreach ($group in $groups)
        {
            Try
            {
                $grpCount = (Get-ADGroupMember -Identity $group).Count
            }
            Catch
            {
            }
            If(($grpCount -le 1) -and ($group.name -notin  (Get-ADObject -SearchBase "CN=Builtin,DC=$env:USERDOMAIN,DC=com" -Filter *).name) )
            {
                $props = @{
                            'DomainName' = $d
                            'GroupName' = $group.Name
                            'GroupCount' = $grpCount
                        }
                $report += @(New-Object -TypeName PSCustomObject -Property $props)
            }
        }

    }
    $report | Select-Object -Property 'DomainName','GroupName','GroupCount' 
}

Function Remove-ConflictFile
{
[CmdletBinding()]
Param()
    #requires -Version 3
    $dcs = ([System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()).DomainControllers |
    ForEach-Object -Process {
      $_.Name 
    } |
    Sort-Object
 
    $dcs | ForEach-Object -Process {
      Write-Host -Object "Cleaning $_ of ConflictAndDeleted items..." -ForegroundColor Cyan
      $null = Invoke-Command -ComputerName $_ -AsJob -ScriptBlock {
        $conflictAndDeletedPath = 'C:\Windows\SYSVOL\Domain\DfsrPrivate\ConflictAndDeleted'
        if(!(Test-Path -Path $conflictAndDeletedPath)) 
        {
          $conflictAndDeletedPath = 'C:\Windows\SYSVOL_DFSR\Domain\DfsrPrivate\ConflictAndDeleted' 
        }
        if(Test-Path -Path $conflictAndDeletedPath) 
        {
          $fileCount = (Get-ChildItem -Path $conflictAndDeletedPath -Recurse -Force).Count
          if($fileCount -gt 0) 
          {
            Stop-Service -Name DFSR
            Get-ChildItem -Path $conflictAndDeletedPath -Force | Remove-Item -Recurse -Force -Confirm:$false
            Remove-Item -Path $conflictAndDeletedPath\..\ConflictAndDeletedManifest.xml -Force -Confirm:$false
            Start-Service -Name DFSR
            Write-Host -Object "$fileCount ConflictAndDeleted items removed from $env:ComputerName."
          }
          else 
          {
            Write-Host -Object "No ConflictAndDeleted items found on $env:ComputerName." 
          }
        }
        else 
        {
          Write-Error -Message 'This computer is not a Domain Controller, or you do not have sufficient permissions.' 
        }
      }
    }
 
    $jobs = Get-Job
    do 
    {
      $completed = Get-Job | Where-Object -Property State -In -Value 'Completed', 'Failed'
      $completed |
      Where-Object -Property HasMoreData -EQ -Value $true |
      Receive-Job
    }
    until($jobs.Count -eq $completed.Count)
    $jobs | Remove-Job 
}

function Get-RemainingRID
{
[CmdletBinding()]
param ($domainDN = (Get-ADDomain).distinguishedName)
    $property = Get-ADObject "cn=rid manager$,cn=system,$domainDN" `
        -Property rIDAvailablePool -server ((Get-ADDomain $domaindn).RidMaster)
    $rid = $property.rIDAvailablePool   
    [int32]$totalSIDS = $($rid) / ([math]::Pow(2,32))
    [int64]$temp64val = $totalSIDS * ([math]::Pow(2,32))
    [int32]$currentRIDPoolCount = $($rid) - $temp64val
    $ridsremaining = $totalSIDS - $currentRIDPoolCount
    Write-Host "SIDs issued: $("{0:N0}" -f $currentRIDPoolCount)"
    Write-Host "SIDs remaining: $("{0:N0}" -f $ridsremaining)"
}

Function Get-LargeADGroupMember
{
<#
.Synopsis
   Get AD group members when membership is larger than 5,000 members
.DESCRIPTION
   The default action of Get-ADGroupMember is to only retrieve the first 5,000 members.  
   This is due to ADWS restrictions - https://technet.microsoft.com/en-us/library/dd391908(WS.10).aspx
   This function will retrieve all group members regardless of membership size.
   NOTE: Larger groups will take some time to process.
   NOTE: Function *requires* ActiveDirectory Module
.EXAMPLE
   Get-LargeADGroupMember -name 'Domain Admins'

   This command gets all membership information for the group 'Domain Admins'
.EXAMPLE
    'Domain Admins', 'HelpDesk' | Get-LargeADGroupMember

    This command is sending the groups 'Domain Admins' and 'HelpDesk' as the value to search.
.EXAMPLE
    Get-LargeADGroupMember -Name 'Domain Admins', 'TestGroup' -Recurse

    This command is searching groups 'Domain Admins' and 'TestGroup' recursively.
.NOTES
Microsoft PowerShell Source File -- Created with Windows PowerShell ISE

FILENAME: 3-getLargeADGroupMember.ps1
VERSION:  .09
AUTHOR: Ted Sdoukos - Ted.Sdoukos@microsoft.com
DATE:   Wednesday, October 19, 2014


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

Param( [Parameter(Mandatory=$true,
        ValueFromPipeline=$true)]
        [ValidateScript({Get-ADGroup -Identity $_})]
        [string[]]$Name,
        [switch]$Recurse
        )
    Process{
        foreach($n in $Name){
            $obj = $null
            $grpName = (Get-ADGroup -Identity $n).DistinguishedName
            $group =[adsi]"LDAP://$($(Get-ADGroup -Identity $n).DistinguishedName)"
            # Retrieve all group members
            $members = $group.psbase.invoke("Members") | 
                ForEach-Object {$_.GetType().InvokeMember("Name",'GetProperty',$null,$_,$null)} 
            # Bind to group members
            $groups = @()
            if(-not($members)){ 
                $props = @{
                            'GroupName' = (($grpName -split ',')[0]).Replace('CN=','')
                            'Name'      = '**EmptyGroup**'
                            'Type'      = '**EmptyGroup**'
                        }
                $obj += @(New-Object -TypeName PSCustomObject -Property $props)
                }
                foreach($m in $members) { 
                $mn = $m -replace 'CN='                
                    $props = @{
                        'GroupName' = (($grpName -split ',')[0]).Replace('CN=','')
                        'Name'      = (Get-ADObject -Filter {Name -eq $mn}).Name
                        'Type'      = (Get-ADObject -Filter {Name -eq $mn}).ObjectClass
                    }
                $obj += @(New-Object -TypeName PSCustomObject -Property $props)
                If((Get-ADObject -Filter {Name -eq $mn}).ObjectClass -eq 'group'){$groups += $mn}
                }     
             $obj
        }
        If ($Recurse -and $groups -and $members -gt 0)
        {
           Get-LargeADGroupMember -Name $groups -Recurse
        }
    }
}
Function Add-TestADUsers{
[CmdletBinding()]
Param()
1..1000 | ForEach-Object{
    $Surname = ("Smith","Neo","Trinity","Morpheus","Cipher","Tank","Dozer","Switch","Mouse") | Get-Random
    [pscustomobject]@{
        SamAccountName = "test$_"
        Name = "test$_ $Surname"
        Surname = $Surname
        DisplayName = "$Surname, Test$_"
        Enabled = "TRUE"
        Office = ("Chicago","Athens","New York","San Diego","Miami","Boston","Philadelphia") | Get-Random
       }
    } | Export-Csv -Path C:\Temp\testAccounts.csv
    Write-Warning "Test users have been built.  CSV is at c:\temp\testAccounts.csv"
}

Function Find-MissingADSubnets
{
[CmdletBinding()]
Param()
    Try
    {
        $domains = (Get-ADForest).Domains
    }
    Catch
    {
        Throw "Unable to query domains!! Exception: $($_.Exception.Message)"
    }
    $report = $null
    Foreach($domain in $domains)
    {
        $dNames = @()
        $dNames += $domain
        If((Get-ADDomain -Identity $domain).ChildDomains)
        {
            [array]$cDomain = (Get-ADDomain -Identity $domain).ChildDomains
            foreach($c in $cDomain)
            {
                $dNames += $c 
            }
        }
    }
    Foreach($d in $dNames)
    {
        $DCs = (Get-ADDomainController -DomainName $d -Discover).HostName
        Foreach($DC in $DCs)
        {
            Try
            {
                # Find missing AD subnets
                $content = (Get-Content -Path "\\$DC\c$\Windows\debug\netlogon.log" -ErrorAction Stop |
                Select-String -Pattern '.+NO_CLIENT_SITE.+\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}' -AllMatches).Matches.Value
            }
            Catch
            {
                Write-Warning -Message "ERROR contacting $DC. MESSAGE: $($_.Exception.Message)"
            }
            If($content)
            {
                $appended = foreach($c in $content)
                {
                    $c.split()[-1]
                }
                $list = $appended | Select-Object -Unique
                Foreach($l in $list)
                {
                    $props = @{
                        'DomainName'     = $d
                        'DomainController' = $DC
                        'IP'             = $l
                    }
                    $report += @(New-Object -TypeName PSCustomObject -Property $props)
                }
            }
        }
    }
    $report | Select-Object -Property 'DomainName', 'DomainController', 'IP' 
}

Function Measure-ADConvergence
{
[CmdletBinding()]
Param([int]$timeout = 90)
    Try{ $null = Get-ADForest } Catch {Throw 'Unable to query forest'}
Write-Output -InputObject '***Forest Information***'
Get-ADForest | Select-Object -Property `
    @{Name = 'Forest Name' ; Expression = {$_.Name}},
    @{Name = 'Functional Level' ; Expression = {$_.ForestMode}} | Format-Table -AutoSize
Write-Output -InputObject '***Domain Information***'
(Get-ADForest).Domains | Select-Object -Property `
    @{Name = 'Domain Name'; Expression = {$_}}, 
    @{Name = 'Functional Level'; Expression = {(Get-ADDomain -Identity $_).DomainMode}} | Format-Table -AutoSize

$sb = (Get-ADRootDSE).configurationNamingContext
$pdc = (Get-ADRootDSE).dnsHostName
$DCs= (Get-ADForest).Domains | ForEach-Object { Get-ADDomainController -Filter * -Server $_ } |
    Select-Object -ExpandProperty HostName

$ausers = Get-ADObject -Filter {Name -eq 'Authenticated Users'} -SearchBase $sb | 
    Select-Object -ExpandProperty DistinguishedName

# Grab original description for 'Authenticated Users' group
$oldDesc = (Get-ADObject -Identity $ausers -Properties Description -Server $pdc).Description
Set-ADObject -Identity $ausers -Description "$oldDesc-TestConverge-$(Get-Date -Format ddMMMyy)" -Server $pdc

# Grab change time from source
$oriChg = Get-ADObject -Identity $ausers -Properties whenChanged | Select-Object -ExpandProperty whenChanged

foreach($DC in $DCs){
Write-Verbose -Message "Working on $DC"  
    # Loop until change time on dc is higher than originating change
    $startTime = Get-Date
    Do{
        #Write-Warning -Message "Waiting on replication for $DC" 
        $lstChange = Get-ADObject -Identity $ausers -Properties whenChanged -Server $DC | Select-Object -ExpandProperty whenChanged 
        Write-Verbose "Original: $oriChg Updated: $lstChange"
        Write-Verbose "`$startTime - $startTime `$timeout - $timeout"
        If( (Get-Date) -ge ($startTime).AddMinutes($timeout) ){ 
            Write-Warning "Timeout threshold of $timeout minutes has been reached for $DC...skipping"
            $lstChange = $oriChg 
            $timeout = $true
            }
    }
    Until($lstChange -ge $oriChg)
    If($timeout){$lstChange = 'Timeout exceeded'}
    [PSCustomObject] @{
        'Domain Controller' = $DC
        'Original Change' = $oriChg
        'Last Change' = $lstChange
        'Convergence Time'  = $lstChange - $oriChg
    }
    $timeout = $false
}

# After test is complete, set description back to what it was
Set-ADObject -Identity $ausers -Description $oldDesc -Server $pdc
}

Function Get-FSMOHolder
{
[CmdletBinding()]
Param() 
    [PSCustomObject]@{
        'ForestFunctionality'  = [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest().ForestMode
        'DomainFunctionality'  = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain().DomainMode
        'DomainNamingMaster'   = [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest().NamingRoleOwner
        'SchemaMaster'         = [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest().SchemaRoleOwner
        'PdcEmulator'          = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain().PdcRoleOwner
        'RidMaster'            = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain().RidRoleOwner
        'InfrastructureMaster' = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain().InfrastructureRoleOwner
    }
}

Function Find-ADGroup
{
[CmdletBinding()]
Param($groupName = 'HelpDesk')
    $domain = [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest().Domains.Name
    Foreach($d in $domain){
        Try{
            $exist = [adsi]::Exists("WinNT://$d/$groupName") 
            If($exist){Write-Output $exist ; break}           
            }
        Catch{}
    }
    If(!($exist)){$exist = $false ; Write-Output $exist}
}

Function Find-ParentOU
{
    [CmdletBinding()]
    Param([Parameter(Mandatory)]$Name)
    (Get-ADObject -Filter {Name -eq $Name}).DistinguishedName -replace '^CN=\w+,'
}

Function Get-ADGroupMemberList
{
    [CmdletBinding()]
    param ($GroupName)
    try {
        (Get-ADGroup -Identity $GroupName -Properties Members).Members
    }
    catch {
        "ERROR: $($_.Exception.Message)"
    }
}

function Get-ADComputerSite {
    [CmdletBinding()]
    Param()
    [System.DirectoryServices.ActiveDirectory.ActiveDirectorySite]::GetComputerSite()
}