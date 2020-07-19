Function Get-CYBRSafeMember {
    <#
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

#>
    [CmdLetBinding()]
    param(
        [parameter(
            Mandatory = $true,
            ValueFromPipeline = $false
        )]
        [string]$SafePattern
    )

    Begin {

        #build lists of usernames:
        #BuiltIn Admin Accounts
        $admins = Get-PASUser -UserType Built-InAdmins | Select-Object -ExpandProperty UserName
        #Vault Groups
        $vaultgroups = Get-PASGroup -filter 'groupType eq Vault' | Select-Object -ExpandProperty groupname
        #Component Users
        $components = Get-PASUser -ComponentUser $true | Select-Object -ExpandProperty UserName
        #Combine lists into `$IgnoreMembers`
        $IgnoreMembers = @("Master", "Batch") + $admins + $components + $vaultgroups

    }

    Process {

        #Find all safes matching pattern
        Find-PASSafe -search $SafePattern | ForEach-Object {

            #For every matching safe
            #Get the members of the safe where `$IgnoreMembers` does not contain the username of the member
            #This should mean only directory users & groups.
            $SafeName = $PSItem.SafeName
            $Members = Get-PASSafeMember -SafeName $SafeName |

            Where-Object {

                ($IgnoreMembers -notcontains $_.Username)

            }

            #for each member
            $Members | ForEach-Object {

                $UserName = $PSItem.UserName

                #If the member is a directory group
                if ($Group = Get-PASGroup -filter 'groupType eq Directory' -search $UserName) {

                    #Get the membership of the group from AD
                    $ADMembers = Get-ADGroupMember $($Group.groupName)

                    If ($ADMembers.count -eq 0) {

                        #Report on groups with no members
                        [array]$ADMembers = ("<No Members>")

                    }

                    #Output the configured permissions for each group member or group
                    foreach ($GroupMember in $ADMembers) {

                        [pscustomobject]@{
                            "Safe"                    = $SafeName
                            "Member"                  = $($Group.groupName)
                            "Source"                  = "LDAP"
                            "GroupMember"             = $GroupMember
                            "RetrieveAccounts"        = $PSItem.Permissions.Retrieve
                            "UseAccounts"             = $PSItem.Permissions.RestrictedRetrieve
                            "ListAccounts"            = $PSItem.Permissions.ListContent
                            "AddAccounts"             = $PSItem.Permissions.Add
                            "UpdateAccountContent"    = $PSItem.Permissions.Update
                            "UpdateAccountProperties" = $PSItem.Permissions.UpdateMetadata
                            "RenameAccounts"          = $PSItem.Permissions.Rename
                            "DeleteAccounts"          = $PSItem.Permissions.Delete
                            "UnlockAccounts"          = $PSItem.Permissions.Unlock
                            "ManageSafe"              = $PSItem.Permissions.ManageSafe
                            "ManageSafeMembers"       = $PSItem.Permissions.ManageSafeMembers
                            "BackupSafe"              = $PSItem.Permissions.BackupSafe
                            "ViewAuditLog"            = $PSItem.Permissions.ViewAudit
                            "ViewSafeMembers"         = $PSItem.Permissions.ViewMembers
                            "CreateFolders"           = $PSItem.Permissions.AddRenameFolder
                            "DeleteFolders"           = $PSItem.Permissions.DeleteFolder
                            "MoveAccountsAndFolders"  = $PSItem.Permissions.MoveFilesAndFolders

                        }

                    }

                }

            }

        }

    }

    End { }

}