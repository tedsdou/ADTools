#requires -version 5
$userName = "$env:USERNAME"
$grpName = 'Domain'
$lGrpName = 'Administrators'
$searcher = [adsisearcher]"(samaccountname=$userName)"
$regKey = 'HKLM:\SOFTWARE\Microsoft\PowerShell' #Just an example
$regKeyVal = 'DisablePromptToUpdateHelp' #Example key value
$logFile = "$env:TEMP\addAdmin.log"
Add-Content -Path $logFile -Value "`n`r`n`rRunTime Start: $(Get-Date)`n`r"
Try {
    $KeyExists = Get-ItemPropertyValue -Path $regKey -Name $regKeyVal
    If ($KeyExists -eq 1) {
        Exit #Exit out if regKey exists and is set to 1
    }
    Else {
        Throw 'Key exists but is not set to 1'
    }
}
Catch { Add-Content -Path $logFile -Value "$($_.Exception.Message)`n`r" }
 
If ($searcher.FindOne()) {
    $doesExist = $true
    Add-Content -Path $logFile -Value "$userName exists in Active Directory`n`r"
    If ($searcher.FindOne().Properties.memberof | Where-Object -FilterScript { $_ -match "CN=$grpName.+" }) {
        $isMember = $true
        Add-Content -Path $logFile -Value "$userName is in $grpName`n`r"
    }
    Else {
        $isMember = $false
        Add-Content -Path $logFile -Value "$userName is NOT in $grpName`n`r"
    }
}
Else {
    $doesExist = $false
    Add-Content -Path $logFile -Value "$userName does not exist in Active Directory`n`r"
}
 
If ($doesExist -and $isMember) {
    Try {
        Add-LocalGroupMember -Group $lGrpName -Member "$env:USERDOMAIN\$userName"
        Add-Content -Path $logFile -Value "SUCCESS:  $userName has been added to $lGrpName on $env:COMPUTERNAME`n`r"
    }
    Catch {
        Add-Content -Path $logFile -Value  "Unable to add $userName to $lGrpName`n`rERROR: $($_.Exception.Message)`n`r"
    }
}
#check if user is part of the group 
#create/update your regkey
#see this blog: https://devblogs.microsoft.com/scripting/update-or-add-registry-key-value-with-powershell/ 
