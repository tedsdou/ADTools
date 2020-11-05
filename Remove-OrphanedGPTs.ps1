#requires -Version 3
$gpos = Get-GPO  -All
$guids = $gpos | ForEach-Object -Process {
  "{$($_.Id.Guid)}" 
}
$files = Get-ChildItem -Path \\$env:USERDNSDOMAIN\SYSVOL\$env:USERDNSDOMAIN\Policies |
Where-Object -Property Name -NotIn -Value $guids |
Where-Object -Property Name -NE -Value 'PolicyDefinitions'
$files | ForEach-Object -Process {
  Write-Host -Object "Deleting orphaned GPO, $($_.Name)..."
  $_ | Remove-Item -Recurse -Confirm:$false
} 
