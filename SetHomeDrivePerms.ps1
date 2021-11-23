foreach ($d in $domains) {
    get-adcomputer -filter { Name -like $name } -server "$d" -properties * -Credential $cred |
    Select-Object CN, `
    @{Name = 'Domain_name'; Expression = { ($_.CanonicalName.Split('/'))[0] } }, Enabled, DistinguishedName `
    | Out-GridView -PassThru  
} 


Get-ADForest

Import-Module 'ActiveDirectory'
$exportFile = 'c:\temp\userHomeDriveReport.csv'
Import-Csv E:\usersname.csv | ForEach-Object {
    $user = $_.name
    $homeDrive = (Get-ADUser -Identity $user -Properties homedirectory).homedirectory  #Query AD for the HomeDrive attribute
    try {    
        $ACL = Get-Acl $homeDrive -ErrorAction Stop
        $ACL.setAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule($_.name, 'Read', 'ContainerInherit,ObjectInherit', 'none', 'allow')))
        Set-Acl -Path $homeDrive -AclObject $ACL -ErrorAction Stop
        $result = 'SUCCESS'
    }
    catch {
        $result = "FAIL: $($_.Exception.Message)"
    }
    finally {
        (Get-Acl -Path $homeDrive).Access | Where-Object { $_.identityreference -eq $user } | 
        Add-Member -MemberType NoteProperty -Name 'Result' -Value $result -PassThru |
        Add-Member -MemberType NoteProperty -Name 'HomeDrive' -Value $homeDrive -PassThru |
        Export-Csv -NoTypeInformation -Path -Append $exportFile
    }
}
