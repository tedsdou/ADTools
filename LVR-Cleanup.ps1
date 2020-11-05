<#
    .NOTES
    LVR Cleanup script
    https://blogs.technet.microsoft.com/heyscriptingguy/2014/04/22/remediate-active-directory-members-that-dont-support-lvr/

#>

#List all of the the legacy members and their associated group
$group = Get-ADGroup -Filter *  |
    Get-ADReplicationAttributeMetadata  -Properties Member -ShowAllLinkedValues |
    Where-Object {$_.Version -eq 0} | Select-Object @{n="LEGACY";e={$_.AttributeValue}},@{n="Group";e={$_.Object}}

Foreach($g in $group){
    #Check group for LEGACY members
    $DN = $g.Group
    $NonLVRMembers =  Get-ADReplicationAttributeMetadata -Object $DN -Properties Member -ShowAllLinkedValues | 
        Where-Object {$_.Version -eq 0}

    #Remove the LEGACY members from a particular group
    Remove-ADGroupMember -Identity $DN -Members ($NonLVRMembers).AttributeValue

    #Now, use Windows PowerShell to reinstate memberships:
    #Add the old LEGACY members back into a particular group
    Add-ADGroupMember -Identity $DN -Members ($NonLVRMembers).AttributeValue 

    #Here’s a command to look at all the Member values associated with the group:
    Get-ADReplicationAttributeMetadata -Object $DN  -Properties Member -ShowAllLinkedValues
}