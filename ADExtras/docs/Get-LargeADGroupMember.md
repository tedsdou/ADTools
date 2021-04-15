---
external help file: ADExtras-help.xml
Module Name: ADExtras
online version:
schema: 2.0.0
---

# Get-LargeADGroupMember

## SYNOPSIS
Get AD group members when membership is larger than 5,000 members

## SYNTAX

```
Get-LargeADGroupMember [-Name] <String[]> [-Recurse] [<CommonParameters>]
```

## DESCRIPTION
The default action of Get-ADGroupMember is to only retrieve the first 5,000 members.
 
This is due to ADWS restrictions - https://technet.microsoft.com/en-us/library/dd391908(WS.10).aspx
This function will retrieve all group members regardless of membership size.
NOTE: Larger groups will take some time to process.
NOTE: Function *requires* ActiveDirectory Module

## EXAMPLES

### EXAMPLE 1
```
Get-LargeADGroupMember -name 'Domain Admins'
```

This command gets all membership information for the group 'Domain Admins'

### EXAMPLE 2
```
'Domain Admins', 'HelpDesk' | Get-LargeADGroupMember
```

This command is sending the groups 'Domain Admins' and 'HelpDesk' as the value to search.

### EXAMPLE 3
```
Get-LargeADGroupMember -Name 'Domain Admins', 'TestGroup' -Recurse
```

This command is searching groups 'Domain Admins' and 'TestGroup' recursively.

## PARAMETERS

### -Name
{{ Fill Name Description }}

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Recurse
{{ Fill Recurse Description }}

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES
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

## RELATED LINKS
