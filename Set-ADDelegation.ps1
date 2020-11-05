<#
.SYNOPSIS
 Name: Set-ADDelegation.ps1
 The purpose of this script is to provide delegated access to administrator
 in Active Directory.

.DESCRIPTION
 The script will provide the predefined permissions to IT administrators by
 modifying the ACLs of Organizational Units so they will be able to perform
 their jobs with the least possible permissions.

.RELATED LINKS
 Home

.NOTES
 Version: 1.1

 Update: 12-04-2018 - Code Optimization

 Release Date: 16-03-2018

 Author: Stephanos Constantinou

.EXAMPLE
 Set-ADDelegation.ps1
#>

Import-module ActiveDirectory

cd ad:

$rootdse = Get-ADRootDSE
$domain = Get-ADDomain
$guidmap = @{}

$GuidMapParams = @{
SearchBase = ($rootdse.SchemaNamingContext)
LDAPFilter = "(schemaidguid=*)"
Properties = ("lDAPDisplayName","schemaIDGUID")}

Get-ADObject @GuidMapParams |
foreach {$guidmap[$_.lDAPDisplayName]=[System.GUID]$_.schemaIDGUID}

$ExtendedMapParams = @{
SearchBase = ($rootdse.ConfigurationNamingContext)
LDAPFilter = "(&(objectclass=controlAccessRight)(rightsguid=*))"
Properties = ("displayName","rightsGuid")}

$extendedrightsmap = @{}

Get-ADObject @ExtendedMapParams |
foreach {$extendedrightsmap[$_.displayName]=[System.GUID]$_.rightsGuid}

$objectinfo = @"

List of the objects that you can delegate control:

1. User
2. Computer
3. Group
4. Service Accounts
5. Servers

"@

$countryinfo = @"

List of the countries that you want to apply the delegation for:

1. Cyprus
2. Greece
3. Germany
4. India

"@

$AllOUsParams = @{
Properties = "DistinguishedName"
SearchBase = ("OU=Offices,"+$domain.DistinguishedName)
Filter = "*"}

$AllOUs = Get-ADOrganizationalUnit @AllOUsParams

$ServersOUsParams = @{
Properties = "DistinguishedName"
SearchBase = ("OU=Servers,"+$domain.DistinguishedName)
Filter = "*"}
$ServersOUs = Get-ADOrganizationalUnit @ServersOUsParams

$OtherOUsParams = @{
Properties = "DistinguishedName"
SearchBase = ("OU=Other,"+$domain.DistinguishedName)
Filter = "*"}

$OtherOUs = Get-ADOrganizationalUnit @OtherOUsParams
$again = "y"
$userinput = "wrong"

while ($again -eq "y"){
do{Write-Host $objectinfo
$objectoption = Read-Host -Prompt 'Please select the number of the object'}
until (($objectoption -eq "1") -or ($objectoption -eq "2") -or
($objectoption -eq "3") -or ($objectoption -eq "4") -or
($objectoption -eq "5"))

do{Write-Host $countryinfo
$countryoption = Read-Host -Prompt 'Please select the number of the country'}
until (($countryoption -eq "1") -or ($countryoption -eq "2") -or
($countryoption -eq "3") -or ($countryoption -eq "4") -or
($countryoption -eq "5") -or ($countryoption -eq "6") -or
($countryoption -eq "7") -or ($countryoption -eq "8") -or
($countryoption -eq "9") -or ($countryoption -eq "10") -or
($countryoption -eq "11") -or ($countryoption -eq "12") -or
($countryoption -eq "13"))

switch ($countryoption){
1{$CyprusEmployeesOUs = ($AllOUs |
where {(($_.DistinguishedName -like "*Employees*") -or
($_.DistinguishedName -like "*NormalMailbox*") -or
($_.DistinguishedName -like "*SharedMailbox*") -or
($_.DistinguishedName -like "*RoomMailbox*") -or
($_.DistinguishedName -like "*WithoutMailbox*") -or
($_.DistinguishedName -like "*ApplicationAccounts*") -or
($_.DistinguishedName -like "*LyncOnly*")) -and
($_.DistinguishedName -like "*Cyprus*")}).DistinguishedName

$CyprusComputersOUs = ($AllOUs |
where {($_.DistinguishedName -like "*Computers*") -and
($_.DistinguishedName -like "*Cyprus*")}).DistinguishedName

$CyprusGroupsOUs = ($AllOUs |
where {(($_.DistinguishedName -like "*DistributionGroups*") -or
($_.DistinguishedName -like "*SecurityGroups*")) -and
($_.DistinguishedName -like "*Cyprus*")}).DistinguishedName

$CyprusServiceOUs = ($AllOUs |
where {($_.DistinguishedName -like "*ServiceAccounts*") -and
($_.DistinguishedName -like "*Cyprus*")}).DistinguishedName

$CyprusServersOUs = ($ServersOUs |
where {(($_.DistinguishedName -like "*2008*") -or
($_.DistinguishedName -like "*2012*") -or
($_.DistinguishedName -like "*2016*") -or
($_.DistinguishedName -like "*2003*") -or
($_.DistinguishedName -like "*Linux*") -or
($_.DistinguishedName -like "*WinXP*") -or
($_.DistinguishedName -like "*Win7*")) -and
($_.DistinguishedName -like "*Cyprus*")}).DistinguishedName

$CyprusOtherOUs = ($OtherOUs |
where {(($_.DistinguishedName -like "*Clusters*") -or
($_.DistinguishedName -like "*Storages*")) -and
($_.DistinguishedName -like "*Cyprus*")}).DistinguishedName

$CyprusServersOUs += $CyprusOtherOUs

$servicedesk = "cy-ServiceDesk"
$computeradmin = "cy-DesktopAdmin"
$useradmin = "cy-UserAdmin"
$adadmin = "cy-ADAdmin"
$activeuserou = $CyprusEmployeesOUs
$activedesktopou = $CyprusComputersOUs
$activegroupou = $CyprusGroupsOUs
$activeserviceou = $CyprusServiceOUs
$activeserverou = $CyprusServersOUs
$country = "Cyprus"}
2{$GreeceEmployeesOUs = ($AllOUs |
where {(($_.DistinguishedName -like "*Employees*") -or
($_.DistinguishedName -like "*NormalMailbox*") -or
($_.DistinguishedName -like "*SharedMailbox*") -or
($_.DistinguishedName -like "*RoomMailbox*") -or
($_.DistinguishedName -like "*WithoutMailbox*") -or
($_.DistinguishedName -like "*ApplicationAccounts*") -or
($_.DistinguishedName -like "*LyncOnly*")) -and
($_.DistinguishedName -like "*Greece*")}).DistinguishedName

$GreeceComputersOUs = ($AllOUs |
where {($_.DistinguishedName -like "*Computers*") -and
($_.DistinguishedName -like "*Greece*")}).DistinguishedName

$GreeceGroupsOUs = ($AllOUs |
where {(($_.DistinguishedName -like "*DistributionGroups*") -or
($_.DistinguishedName -like "*SecurityGroups*")) -and
($_.DistinguishedName -like "*Greece*")}).DistinguishedName

$GreeceServiceOUs = ($AllOUs |
where {($_.DistinguishedName -like "*ServiceAccounts*") -and
($_.DistinguishedName -like "*Greece*")}).DistinguishedName

$GreeceServersOUs = ($ServersOUs |
where {(($_.DistinguishedName -like "*2008*") -or
($_.DistinguishedName -like "*2012*") -or
($_.DistinguishedName -like "*2016*") -or
($_.DistinguishedName -like "*2003*") -or
($_.DistinguishedName -like "*Linux*") -or
($_.DistinguishedName -like "*WinXP*") -or
($_.DistinguishedName -like "*Win7*")) -and
($_.DistinguishedName -like "*Greece*")}).DistinguishedName

$GreeceOtherOUs = ($OtherOUs |
where {(($_.DistinguishedName -like "*Clusters*") -or
($_.DistinguishedName -like "*Storages*")) -and
($_.DistinguishedName -like "*Greece*")}).DistinguishedName

$GreeceServersOUs += $GreeceOtherOUs

$servicedesk = "gr-ServiceDesk"
$computeradmin = "gr-DesktopAdmin"
$useradmin = "gr-UserAdmin"
$adadmin = "gr-ADAdmin"
$activeuserou = $GreeceEmployeesOUs
$activedesktopou = $GreeceComputersOUs
$activegroupou = $GreeceGroupsOUs
$activeserviceou = $GreeceServiceOUs
$activeserverou = $GreeceServersOUs
$country = "Greece"}
3{$GermanyEmployeesOUs = ($AllOUs |
where {(($_.DistinguishedName -like "*Employees*") -or
($_.DistinguishedName -like "*NormalMailbox*") -or
($_.DistinguishedName -like "*SharedMailbox*") -or
($_.DistinguishedName -like "*RoomMailbox*") -or
($_.DistinguishedName -like "*WithoutMailbox*") -or
($_.DistinguishedName -like "*ApplicationAccounts*") -or
($_.DistinguishedName -like "*LyncOnly*")) -and
($_.DistinguishedName -like "*Germany*")}).DistinguishedName

$GermanyComputersOUs = ($AllOUs |
where {($_.DistinguishedName -like "*Computers*") -and
($_.DistinguishedName -like "*Germany*")}).DistinguishedName

$GermanyGroupsOUs = ($AllOUs |
where {(($_.DistinguishedName -like "*DistributionGroups*") -or
($_.DistinguishedName -like "*SecurityGroups*")) -and
($_.DistinguishedName -like "*Germany*")}).DistinguishedName

$GermanyServiceOUs = ($AllOUs |
where {($_.DistinguishedName -like "*ServiceAccounts*") -and
($_.DistinguishedName -like "*Germany*")}).DistinguishedName

$GermanyServersOUs = ($ServersOUs |
where {(($_.DistinguishedName -like "*2008*") -or
($_.DistinguishedName -like "*2012*") -or
($_.DistinguishedName -like "*2016*") -or
($_.DistinguishedName -like "*2003*") -or
($_.DistinguishedName -like "*Linux*") -or
($_.DistinguishedName -like "*WinXP*") -or
($_.DistinguishedName -like "*Win7*")) -and
($_.DistinguishedName -like "*Germany*")}).DistinguishedName

$GermanyOtherOUs = ($OtherOUs |
where {(($_.DistinguishedName -like "*Clusters*") -or
($_.DistinguishedName -like "*Storages*")) -and
($_.DistinguishedName -like "*Germany*")}).DistinguishedName

$GermanyServersOUs += $GermanyOtherOUs

$servicedesk = "de-ServiceDesk"
$computeradmin = "de-DesktopAdmin"
$useradmin = "de-UserAdmin"
$adadmin = "de-ADAdmin"
$activeuserou = $GermanyEmployeesOUs
$activedesktopou = $GermanyComputersOUs
$activegroupou = $GermanyGroupsOUs
$activeserviceou = $GermanyServiceOUs
$activeserverou = $GermanyServersOUs
$country = "Germany"}
4{$IndiaEmployeesOUs = ($AllOUs |
where {(($_.DistinguishedName -like "*Employees*") -or
($_.DistinguishedName -like "*NormalMailbox*") -or
($_.DistinguishedName -like "*SharedMailbox*") -or
($_.DistinguishedName -like "*RoomMailbox*") -or
($_.DistinguishedName -like "*WithoutMailbox*") -or
($_.DistinguishedName -like "*ApplicationAccounts*") -or
($_.DistinguishedName -like "*LyncOnly*")) -and
($_.DistinguishedName -like "*India*")}).DistinguishedName

$IndiaComputersOUs = ($AllOUs |
where {($_.DistinguishedName -like "*Computers*") -and
($_.DistinguishedName -like "*India*")}).DistinguishedName

$IndiaGroupsOUs = ($AllOUs |
where {(($_.DistinguishedName -like "*DistributionGroups*") -or
($_.DistinguishedName -like "*SecurityGroups*")) -and
($_.DistinguishedName -like "*India*")}).DistinguishedName

$IndiaServiceOUs = ($AllOUs |
where {($_.DistinguishedName -like "*ServiceAccounts*") -and
($_.DistinguishedName -like "*India*")}).DistinguishedName

$IndiaServersOUs = ($ServersOUs |
where {(($_.DistinguishedName -like "*2008*") -or
($_.DistinguishedName -like "*2012*") -or
($_.DistinguishedName -like "*2016*") -or
($_.DistinguishedName -like "*2003*") -or
($_.DistinguishedName -like "*Linux*") -or
($_.DistinguishedName -like "*WinXP*") -or
($_.DistinguishedName -like "*Win7*")) -and
($_.DistinguishedName -like "*India*")}).DistinguishedName

$IndiaOtherOUs = ($OtherOUs |
where {(($_.DistinguishedName -like "*Clusters*") -or
($_.DistinguishedName -like "*Storages*")) -and
($_.DistinguishedName -like "*India*")}).DistinguishedName

$IndiaServersOUs += $IndiaOtherOUs

$servicedesk = "in-ServiceDesk"
$computeradmin = "in-DesktopAdmin"
$useradmin = "in-UserAdmin"
$adadmin = "in-ADAdmin"
$activeuserou = $IndiaEmployeesOUs
$activedesktopou = $IndiaComputersOUs
$activegroupou = $IndiaGroupsOUs
$activeserviceou = $IndiaServiceOUs
$activeserverou = $IndiaServersOUs
$country = "India"}
default {"You have entered a wrong number. Run the script again"; Exit}}

$servicegroup = New-Object System.Security.Principal.SecurityIdentifier (Get-ADGroup "$servicedesk").SID
$computergroup = New-Object System.Security.Principal.SecurityIdentifier (Get-ADGroup "$computeradmin").SID
$usergroup = New-Object System.Security.Principal.SecurityIdentifier (Get-ADGroup "$useradmin").SID
$adgroup = New-Object System.Security.Principal.SecurityIdentifier (Get-ADGroup "$adadmin").SID
$engineergroup = New-Object System.Security.Principal.SecurityIdentifier (Get-ADGroup "group-ADEngineer").SID
$ownerrights = New-Object System.Security.Principal.SecurityIdentifier 'S-1-3-4'

$AllAces = New-Object System.Collections.Generic.List[System.Object]

switch ($objectoption){
1{foreach ($currentuserou in $activeuserou){
$acl = get-acl $currentuserou

$Ace = New-Object System.DirectoryServices.ActiveDirectoryAccessRule $servicegroup,
"ReadProperty",
"Allow",
"Descendents",
$guidmap["user"]
$AllAces.Add($Ace)

$Ace = New-Object System.DirectoryServices.ActiveDirectoryAccessRule $servicegroup,
"WriteProperty",
"Allow",
$guidmap["lockoutTime"],
"Descendents",
$guidmap["user"]
$AllAces.Add($Ace)

$Ace = New-Object System.DirectoryServices.ActiveDirectoryAccessRule $servicegroup,
"ExtendedRight",
"Allow",
$extendedrightsmap["Reset Password"],
"Descendents",
$guidmap["user"]
$AllAces.Add($Ace)

$UserCreatePermission = "$usergroup",
"CreateChild",
"Allow",
$guidmap["user"]

$Ace = New-Object System.DirectoryServices.ActiveDirectoryAccessRule $usergroup,
"CreateChild",
"Allow",
$guidmap["user"]
$AllAces.Add($Ace)

$UserWriteProperties = @("company","department","description",
"displayName","facsimileTelephoneNumber",
"otherFacsimileTelephoneNumber","givenName",
"homeDrive","homeDirectory","homePhone",
"otherHomePhone","initials","title",
"userPrincipalName","sAMAccountName","manager",
"mobile","otherMobile","cn","name","info",
"otherTelephone","postOfficeBox","pwdLastSet",
"streetAddress","telephoneNumber","thumbnailPhoto",
"wWWHomePage","postalCode","sn","st","c","l",
"physicalDeliveryOfficeName","userAccountControl",
"extensionAttribute2","userWorkstations","logonHours")

foreach ($UserWriteProperty in $UserWriteProperties){
$Ace = New-Object System.DirectoryServices.ActiveDirectoryAccessRule $usergroup,
"WriteProperty",
"Allow",
$guidmap["$UserWriteProperty"],
"Descendents",
$guidmap["user"]
$AllAces.Add($Ace)}

$EngineerMainProperties = @("CreateChild","DeleteChild")

foreach ($EngineerMainProperty in $EngineerMainProperties){
$Ace = New-Object System.DirectoryServices.ActiveDirectoryAccessRule $engineergroup,
$EngineerMainProperty,
"Allow",
$guidmap["user"]
$AllAces.Add($Ace)}

$Ace = New-Object System.DirectoryServices.ActiveDirectoryAccessRule $engineergroup,
"ReadProperty",
"Allow",
"Descendents",
$guidmap["user"]
$AllAces.Add($Ace)

$EngineerWriteProperties = @("lockoutTime","company","department","description",
"displayName","facsimileTelephoneNumber",
"otherFacsimileTelephoneNumber","givenName",
"homeDrive","homeDirectory","homePhone",
"otherHomePhone","initials","title",
"userPrincipalName","sAMAccountName","manager",
"mobile","otherMobile","cn","name","info",
"otherTelephone","postOfficeBox","pwdLastSet",
"streetAddress","telephoneNumber","thumbnailPhoto",
"wWWHomePage","postalCode","sn","st","c","l",
"physicalDeliveryOfficeName","userAccountControl",
"extensionAttribute2","userWorkstations","logonHours")

foreach ($EngineerWriteProperty in $EngineerWriteProperties){
$Ace = New-Object System.DirectoryServices.ActiveDirectoryAccessRule $engineergroup,
"WriteProperty",
"Allow",
$guidmap["$EngineerWriteProperty"],
"Descendents",
$guidmap["user"]
$AllAces.Add($Ace)}

$Ace = New-Object System.DirectoryServices.ActiveDirectoryAccessRule $engineergroup,
"ExtendedRight",
"Allow",
$extendedrightsmap["Reset Password"],
"Descendents",
$guidmap["user"]
$AllAces.Add($Ace)

$Ace = New-Object System.DirectoryServices.ActiveDirectoryAccessRule $ownerrights,
"ReadProperty",
"Allow",
"Descendents",
$guidmap["user"]
$AllAces.Add($Ace)

ForEach ($Ace in $AllAces){
$acl.AddAccessRule($Ace)}

set-acl -aclobject $acl -Path $currentuserou

$Confirmation = "User objects delegation on $currentuserou for $country was successful."

Write-Host $Confirmation -ForegroundColor Green}}
2{foreach ($currentdesktopou in $activedesktopou){
$acl = get-acl $currentdesktopou
$AdminGroups = @("$computergroup","$engineergroup")

foreach ($AdminGroup in $AdminGroups){
$DesktopMainProperties = @("CreateChild","DeleteChild")

foreach ($DesktopMainProperty in $DesktopMainProperties){
$Ace = New-Object System.DirectoryServices.ActiveDirectoryAccessRule $AdminGroup,
$DesktopMainProperty,
"Allow",
$guidmap["computer"]
$AllAces.Add($Ace)}

$Ace = New-Object System.DirectoryServices.ActiveDirectoryAccessRule $AdminGroup,
"ReadProperty",
"Allow",
"Descendents",
$guidmap["computer"]
$AllAces.Add($Ace)

$Ace = New-Object System.DirectoryServices.ActiveDirectoryAccessRule $AdminGroup,
"WriteProperty",
"Allow",
"Descendents",
$guidmap["computer"]
$AllAces.Add($Ace)

$DesktopExtendedProperties = @("Reset Password","Account Restrictions",
"Validated write to DNS host name",
"Validated write to service principal name")

foreach ($DesktopExtendedProperty in $DesktopExtendedProperties){
$Ace = New-Object System.DirectoryServices.ActiveDirectoryAccessRule $AdminGroup,
"ExtendedRight",
"Allow",
$extendedrightsmap["$DesktopExtendedProperty"],
"Descendents",
$guidmap["computer"]
$AllAces.Add($Ace)}}

ForEach ($Ace in $AcesArray){
$acl.AddAccessRule($Ace)}

set-acl -aclobject $acl -Path $currentdesktopou

$Confirmation = "Computer objects delegation on $currentdesktopou for $country was successful."

Write-Host $Confirmation -ForegroundColor Green}}
3{foreach ($currentgroupou in $activegroupou){
$acl = get-acl $currentgroupou

$AdminGroups = @("$adgroup","$engineergroup")

foreach ($AdminGroup in $AdminGroups){
$GroupMainProperties = @("CreateChild","DeleteChild")

foreach ($GroupMainProperty in $GroupMainProperties){
$Ace = New-Object System.DirectoryServices.ActiveDirectoryAccessRule $AdminGroup,
$GroupMainProperty,
"Allow",
$guidmap["group"]
$AllAces.Add($Ace)}

$Ace = New-Object System.DirectoryServices.ActiveDirectoryAccessRule $AdminGroup,
"ReadProperty",
"Allow",
"Descendents",
$guidmap["group"]
$AllAces.Add($Ace)

$GroupWriteProperties = @("description","sAMAccountName","groupType",
"member","cn","name","info")

foreach ($GroupWriteProperty in $GroupWriteProperties){
$Ace = New-Object System.DirectoryServices.ActiveDirectoryAccessRule $AdminGroup,
"WriteProperty",
"Allow",
$guidmap["$GroupWriteProperty"],
"Descendents",
$guidmap["group"]
$AllAces.Add($Ace)}}

ForEach ($Ace in $AcesArray){
$acl.AddAccessRule($Ace)}

set-acl -aclobject $acl -Path $currentgroupou

$Confirmation = "Group objects delegation on $currentgroupou for $country was successful."

Write-Host $Confirmation -ForegroundColor Green}}
4{foreach ($currentserviceou in $activeserviceou){
$acl = get-acl $currentserviceou

$AdminGroups = @("$adgroup","$engineergroup")

foreach ($AdminGroup in $AdminGroups){
$Ace = New-Object System.DirectoryServices.ActiveDirectoryAccessRule $AdminGroup,
"ReadProperty",
"Allow",
"Descendents",
$guidmap["user"]
$AllAces.Add($Ace)

$Ace = New-Object System.DirectoryServices.ActiveDirectoryAccessRule $AdminGroup,
"ExtendedRight",
"Allow",
$extendedrightsmap["Reset Password"],
"Descendents",
$guidmap["user"]
$AllAces.Add($Ace)

$Ace = New-Object System.DirectoryServices.ActiveDirectoryAccessRule $AdminGroup,
"CreateChild",
"Allow",
$guidmap["user"]
$AllAces.Add($Ace)

$ServicesWriteProperties = @("lockoutTime","company","department","description",
"displayName","facsimileTelephoneNumber",
"otherFacsimileTelephoneNumber","givenName",
"homeDrive","homeDirectory","homePhone",
"otherHomePhone","initials","title",
"userPrincipalName","sAMAccountName","manager",
"mobile","otherMobile","cn","name","info",
"otherTelephone","postOfficeBox","pwdLastSet",
"streetAddress","telephoneNumber","thumbnailPhoto",
"wWWHomePage","postalCode","sn","st","c","l",
"physicalDeliveryOfficeName","userAccountControl",
"extensionAttribute2","userWorkstations","logonHours")

foreach ($ServicesWriteProperty in $ServicesWriteProperties){
$Ace = New-Object System.DirectoryServices.ActiveDirectoryAccessRule $AdminGroup,
"WriteProperty",
"Allow",
$guidmap["$ServicesWriteProperty"],
"Descendents",
$guidmap["user"]
$AllAces.Add($Ace)}}

$Ace = New-Object System.DirectoryServices.ActiveDirectoryAccessRule $engineergroup,
"DeleteChild",
"Allow",
$guidmap["user"]
$AllAces.Add($Ace)

ForEach ($Ace in $AcesArray){
$acl.AddAccessRule($Ace)}

set-acl -aclobject $acl -Path $currentuserou

$Confirmation = "User objects delegation on $currentuserou for $country was successful."

Write-Host $Confirmation -ForegroundColor Green}}
5{foreach ($currentserverou in $activeserverou){
$acl = get-acl $currentserverou

$AdminGroups = @("$adgroup","$engineergroup")

foreach ($AdminGroup in $AdminGroups){
$ServerMainProperties = @("CreateChild","DeleteChild")

foreach ($ServerMainProperty in $ServerMainProperties){
$Ace = New-Object System.DirectoryServices.ActiveDirectoryAccessRule $AdminGroup,
$ServerMainProperty,
"Allow",
$guidmap["computer"]
$AllAces.Add($Ace)}

$Ace = New-Object System.DirectoryServices.ActiveDirectoryAccessRule $AdminGroup,
"ReadProperty",
"Allow",
"Descendents",
$guidmap["computer"]
$AllAces.Add($Ace)

$Ace = New-Object System.DirectoryServices.ActiveDirectoryAccessRule $AdminGroup,
"WriteProperty",
"Allow",
"Descendents",
$guidmap["computer"]
$AllAces.Add($Ace)

$ServerExtendedProperties = @("Reset Password","Account Restrictions",
"Validated write to DNS host name",
"Validated write to service principal name")

foreach ($ServerExtendedProperty in $ServerExtendedProperties){
$Ace = New-Object System.DirectoryServices.ActiveDirectoryAccessRule $AdminGroup,
"ExtendedRight",
"Allow",
$extendedrightsmap["$ServerExtendedProperty"],
"Descendents",
$guidmap["computer"]
$AllAces.Add($Ace)}}

ForEach ($Ace in $AcesArray){
$acl.AddAccessRule($Ace)}

set-acl -aclobject $acl -Path $currentserverou

$Confirmation = "Computer objects delegation on $currentserverou for $country was successful."

Write-Host $Confirmation -ForegroundColor Green}}
default {"You have entered a wrong number. Run the script again"; Exit}}

do{$answer = Read-Host -Prompt 'Do you want to run delegation script again for another object or country? (y or n)'
If (($answer -eq "n") -or ($answer -eq "y")){
$userinput = "correct"}
else{
$userinput = "wrong"

$WrongAnswer = @"

You have entered a wrong answer.

Please enter y [YES] or n [NO]

"@

Write-Host $WrongAnswer -ForegroundColor Red}}
while ($userinput -eq "wrong")

$again = $answer}