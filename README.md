# psPAS Example Scripts

psPAS Example scripts from my session at Impact Live 2020.

These examples show how different psPAS commands can be incorporated into custom scripts and tools to support any logic driven processes.

Review the code and commands in each example to see how Automation with psPAS can be used to support your CyberArk operational tasks & processes.

![psPAS](https://github.com/pspete/psPAS/blob/master/docs/assets/images/shop_banner_symbol.png?raw=true)

- [psPAS](https://github.com/pspete/psPAS) is required by each example
  - [Install Instructions](https://pspas.pspete.dev/docs/install/)
- It is assumed an authenticated session with the API from psPAS is available in the current PowerShell session.
  - [Authentication Documentation](https://pspas.pspete.dev/docs/authentication/)
- The `-WhatIf` switch has been added to any command which makes a change.
  - This will show what the code would do, without actually doing it.
  - If the `-WhatIf` switch is removed from the command, the change will happen.

![psPAS](https://github.com/pspete/psPAS/blob/master/docs/assets/images/shop_banner_symbol.png?raw=true)

## `Unlock-CYBRUser`

```powershell
.SYNOPSIS
An example function using psPAS commands to activate a suspended CyberArk Vault User.

.DESCRIPTION
This function shows:
Searches for vault user by name using `Get-PASUser`
Unlock/Activate vault user using `Unblock-PASUser`.

A simple example to search for & unlock a vault user.

.PARAMETER username
The username of the vault user to unlock.

.EXAMPLE
Unlock-CYBRUser -username SomeUserName
```

![psPAS](https://github.com/pspete/psPAS/blob/master/docs/assets/images/shop_banner_symbol.png?raw=true)

## `Get-CYBRSafeMember`

```powershell
.SYNOPSIS
An example function using psPAS commands to Get Safe Members

.DESCRIPTION
This function shows how an example safe access attestation process can be supported:
- Using `Get-PASUser` to find Built-In & Component users.
- Using `Get-PASGroup` to find Vault Groups
- Using `Find-PASSafe` to a list of safe names matching a naming pattern.
- Using `Get-PASSafeMember` to get a list of safe members
- Filtering a list of safe members to remove entries relating to Built-In & Component users as well as vault groups.
- Using `Get-PASGroup` to determine if a safe member is a directory group
- Using `Get-ADGroupMember` to report on users who are group members from AD.

.PARAMETER SafePattern
A pattern to used to find safes to check members of.

.EXAMPLE
Get-CYBRSafeMember -SafePattern Region1_TeamA_

Will report on all AD groups which are members of safes matching name pattern "Region1_TeamA_"
```

![psPAS](https://github.com/pspete/psPAS/blob/master/docs/assets/images/shop_banner_symbol.png?raw=true)

## `New-CYBRSafe`

```powershell
.SYNOPSIS
An example function using psPAS commands to Create a New Safe

.DESCRIPTION
This function shows how a naming convention can be used to dictate logic.
Based on the proposed name, we can assume requisite configurations.
- psPAS function `Add-PASSafe` is used to create the safe.
- Example function `Set-CYBRSafePermission` is used to add the safe members.

A safename starting with the characters "EU_" will be configured to use CPM "PasswordManager",
and will be set to retain the last 10 password versions.

A safename starting with the characters "APAC_" will be configured to use CPM "PasswordManager1",
and will be set to retain the last 30 days of password versions.

Permissions for the new safe will be set via the rules and roles configured in the `Set-CYBRSafePermission` function.

.PARAMETER SafeName
The name of the safe to create.

.EXAMPLE
New-CYBRSafe -SafeName "EU_NewSafeExample"

Creates the EU_NewSafeExample safe and sets permissions via `Set-CYBRSafePermission`
```

![psPAS](https://github.com/pspete/psPAS/blob/master/docs/assets/images/shop_banner_symbol.png?raw=true)

## `Set-CYBRSafePermission`

```powershell
.SYNOPSIS
An example function using psPAS commands to add & update default safe members

.DESCRIPTION
This function shows:
- PowerShell Objects being used to define to safe member ACLs.
- Finding target safes using `Find-PASSafe`
- Geting existing safe members using `Get-PASSafeMember`
- Determining expected members based on a naming convention
  - Adding new members to the target safe
  - Updating existing members on the target safe
- Catching errors when adding/updating safe members

This example expects each safe to have 5 specific members
- "GlobalSupport",
- "GlobalAdmin",
- "<Region>-CYBR-<SafeName>-Usr",
- "<Region>-CYBR-<SafeName>-App",
- "<Region>Support"
If any of the above list are not currently a safe member, they are added.
If any of the above is a current member of the target safe, their safe permissions are updated.

The permissions applied are defined in the script, and assigned based on the naming convention of the member.

.PARAMETER SafePattern
Safename or safename pattern to set member permissons on.

.PARAMETER Region
A business region (like "EU" or "APAC")

.EXAMPLE
Set-CYBRSafePermission -SafePattern TargetSafeName -Region APAC

On safe TargetSafeName, adds or updates members
"GlobalSupport",
"GlobalAdmin",
"APAC-CYBR-TargetSafeName-Usr",
"APAC-CYBR-TargetSafeName-App",
"APACSupport"
```

![psPAS](https://github.com/pspete/psPAS/blob/master/docs/assets/images/shop_banner_symbol.png?raw=true)

## `Get-CYBRPlatformConfig`

```powershell
.SYNOPSIS
An example function using psPAS commands to Get Platform Configuration details.

.DESCRIPTION
This function shows
- Using `Get-PASPlatform` to return details of platforms
- Using `Get-PASPlatform` to return details of specific platforms
- Combining PowerShell objects to get data into a flat format for easy filtering & querying.

.PARAMETER PlatformID
Optional ID of a platform name to return configuration details of.

.EXAMPLE
Get-CYBRPlatformConfig

Returns details of all active regular platforms
```

![psPAS](https://github.com/pspete/psPAS/blob/master/docs/assets/images/shop_banner_symbol.png?raw=true)

## `Rename-CYBRAccount`

```powershell
.SYNOPSIS
An example function using psPAS commands to Rename CyberArk Accounts

.DESCRIPTION
This function shows:
- Using  an account object as input
  - psPAS function `Set-PASAccount` is used to replace the existing name value of an account.
  - The new name will be "$platformId-$address-$userName" based on the property values of the input object

.PARAMETER Account
An object describing the current properties of an account.
Can be an account object output from `Get-PASAccount`, or a custom object.

.EXAMPLE
$Account = [pscustomobject]@{

    "id" = 123_456
    "userName" = SomeUser
    "platformId" = SomePlatform
    "address" = Some.Address

}

Rename-CYBRAccount -Account $Account


Renames account with id 123_456 to "SomePlatform-Some.Address-SomeUser"

.EXAMPLE
Get-PASAccount -id 123_456 | Rename-CYBRAccount

Renames account with id 123_456 to "<platformId>-<address>-<userName>"
```
![psPAS](https://github.com/pspete/psPAS/blob/master/docs/assets/images/shop_banner_symbol.png?raw=true)