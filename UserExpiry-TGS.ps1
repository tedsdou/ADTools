<#
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

Function AdsLargeIntegerToIn64($adsLargeInteger) {
       [Int32]$highPart = $adsLargeInteger.GetType().InvokeMember('HighPart', [System.Reflection.BindingFlags]::GetProperty, $null, $adsLargeInteger, $null)
       [Int32]$lowPart = $adsLargeInteger.GetType().InvokeMember('LowPart', [System.Reflection.BindingFlags]::GetProperty, $null, $adsLargeInteger, $null)
       return  [Int64]('0x{0:x8}{1:x8}' -f $highPart, $lowpart)
}


Function Get-UserExpiry {
       Param($accountName)
       #Create ADSI searcher
       $adsiSearcher = New-Object DirectoryServices.DirectorySearcher [ADSI]$null
       $adsiSearcher.filter = "(&(objectClass=user)(sAMAccountName=$accountName))"
       $adsiSearcherResult = $adsiSearcher.FindOne()
       If ($adsiSearcherResult) {
              $user = $adsiSearcherResult.GetDirectoryEntry()
              $PwdlastsetDate = [datetime]::fromfiletime($adsiSearcherResult.Properties.pwdlastset[0])
       
              #Check if user's password never expire
              If (($user.UserAccountControl[0] -band $ADS_UF_DONT_EXPIRE_PASSWD) -ne 0) {
                     $PwdExdate = 'Never'
              }
              Else {      
                     $PwdExdate = $PwdlastsetDate + $Days
                     $expDays = ($PwdExdate - (Get-Date).date).days
                     $dateinstring = ($PwdExdate).ToString()
                     $time1 = New-TimeSpan -End $PwdExdate
                     $daysleft = ($time1).Days
                     $hour = ($time1).Hours
                     $minute = ($time1).Minutes
       
              }
              $obj = New-Object PSobject  -Property @{'SamaccountName' = $accountname; 'LastPasswordsetdate' = $PwdlastsetDate; 'Passwordexpirationdate' = $PwdExdate; 'Days' = $expdays }
       }
       Else {
              $obj = New-Object PSobject  -Property @{'SamaccountName' = $accountname; 'LastPasswordsetdate' = 'Not found'; 'Passwordexpirationdate' = 'Not found' }
       }
       Write-Output $obj
}

$expdays = 35
$mandatory = $true
$accountName = [Environment]::UserName
#Check AD for Password Expiration date
#define a const variable
$ADS_UF_DONT_EXPIRE_PASSWD = 65536

#Create ADSI object 
$oDomain = New-Object System.DirectoryServices.DirectoryEntry

# Read maxPwdAge attribute and convert to Int64
$maxPwdAge = AdsLargeIntegerToIn64 $oDomain.maxPwdAge.Value
$maxPwdDays = [System.TimeSpan]::FromTicks([System.Math]::ABS($maxPwdAge)).Days
$Days = New-TimeSpan  -Days $maxPwdDays

Get-UserExpiry -accountName danpark 

