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
    if (!(Test-Path -Path $conflictAndDeletedPath)) {
      $conflictAndDeletedPath = 'C:\Windows\SYSVOL_DFSR\Domain\DfsrPrivate\ConflictAndDeleted' 
    }
    if (Test-Path -Path $conflictAndDeletedPath) {
      $fileCount = (Get-ChildItem -Path $conflictAndDeletedPath -Recurse -Force).Count
      if ($fileCount -gt 0) {
        Stop-Service -Name DFSR
        Get-ChildItem -Path $conflictAndDeletedPath -Force | Remove-Item -Recurse -Force -Confirm:$false
        Remove-Item -Path $conflictAndDeletedPath\..\ConflictAndDeletedManifest.xml -Force -Confirm:$false
        Start-Service -Name DFSR
        Write-Host -Object "$fileCount ConflictAndDeleted items removed from $env:ComputerName."
      }
      else {
        Write-Host -Object "No ConflictAndDeleted items found on $env:ComputerName." 
      }
    }
    else {
      Write-Error -Message 'This computer is not a Domain Controller, or you do not have sufficient permissions.' 
    }
  }
}
 
$jobs = Get-Job
do {
  $completed = Get-Job | Where-Object -Property State -In -Value 'Completed', 'Failed'
  $completed |
  Where-Object -Property HasMoreData -EQ -Value $true |
  Receive-Job
}
until($jobs.Count -eq $completed.Count)
$jobs | Remove-Job 