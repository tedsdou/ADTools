#requires -Version 3 -Modules ActiveDirectory
Try
{
    $domains = (Get-ADForest).Domains
}
Catch
{
    Throw "Unable to query domains!! Exception: $($_.Exception.Message)"
}

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
    $DCs = (Get-ADDomainController -DomainName $d -Discover).HostName
    Foreach($DC in $DCs)
    {
        Try
        {
            # Find missing AD subnets
            $content = (Get-Content -Path "\\$DC\c$\Windows\debug\netlogon.log" -ErrorAction Stop |
                Select-String ".+NO_CLIENT_SITE.+\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}" -AllMatches).Matches.Value
                
        }
        Catch
        {
            Write-Warning -Message "ERROR contacting $DC. MESSAGE: $($_.Exception.Message)"
        }
        If($content)
        {
            $appended = foreach($c in $content){$c.split()[-1]}
            $list = $appended | Select-Object -Unique
            Foreach($l in $list)
            {
                [PSCustomObject]@{
                        'DomainName' = $d
                        'DomainController' = $DC
                        'IP' = $l
                        }
            }
        }
    }
}
