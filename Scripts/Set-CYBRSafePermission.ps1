Function Set-CYBRSafePermission {
	<#
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

#>
	[CmdLetBinding()]
	param(
		[parameter(
			Mandatory = $true,
			ValueFromPipeline = $false
		)]
		$SafePattern,
		[parameter(
			Mandatory = $true,
			ValueFromPipeline = $false
		)]
		$Region
	)

	Begin {

		#Example ACL Configurations/Roles.
		#These should be changed to match your organisational policy.
		#Permissions set to $true will be granted for members which match the role.
		#Permissions set to $false will be revoked for members which match the role.

		#Example User Role
		$UserPermisions = [PSCustomObject]@{
			UseAccounts                            = $true
			RetrieveAccounts                       = $false
			ListAccounts                           = $true
			AddAccounts                            = $false
			UpdateAccountContent                   = $false
			UpdateAccountProperties                = $false
			InitiateCPMAccountManagementOperations = $false
			SpecifyNextAccountContent              = $false
			RenameAccounts                         = $false
			DeleteAccounts                         = $false
			UnlockAccounts                         = $false
			ManageSafe                             = $false
			ManageSafeMembers                      = $false
			BackupSafe                             = $false
			ViewAuditLog                           = $true
			ViewSafeMembers                        = $true
			RequestsAuthorizationLevel             = 0
			AccessWithoutConfirmation              = $false
			CreateFolders                          = $false
			DeleteFolders                          = $false
			MoveAccountsAndFolders                 = $false
		}
		#Example Request Approver Role
		$ApproverPermisions = [PSCustomObject]@{
			UseAccounts                            = $false
			RetrieveAccounts                       = $false
			ListAccounts                           = $true
			AddAccounts                            = $false
			UpdateAccountContent                   = $false
			UpdateAccountProperties                = $false
			InitiateCPMAccountManagementOperations = $false
			SpecifyNextAccountContent              = $false
			RenameAccounts                         = $false
			DeleteAccounts                         = $false
			UnlockAccounts                         = $false
			ManageSafe                             = $false
			ManageSafeMembers                      = $false
			BackupSafe                             = $false
			ViewAuditLog                           = $true
			ViewSafeMembers                        = $true
			RequestsAuthorizationLevel             = 1
			AccessWithoutConfirmation              = $false
			CreateFolders                          = $false
			DeleteFolders                          = $false
			MoveAccountsAndFolders                 = $false
		}
		#Example Safe Support Role
		$SupportPermisions = [PSCustomObject]@{
			UseAccounts                            = $true
			RetrieveAccounts                       = $false
			ListAccounts                           = $true
			AddAccounts                            = $false
			UpdateAccountContent                   = $false
			UpdateAccountProperties                = $true
			InitiateCPMAccountManagementOperations = $true
			SpecifyNextAccountContent              = $false
			RenameAccounts                         = $false
			DeleteAccounts                         = $false
			UnlockAccounts                         = $true
			ManageSafe                             = $false
			ManageSafeMembers                      = $false
			BackupSafe                             = $false
			ViewAuditLog                           = $true
			ViewSafeMembers                        = $true
			RequestsAuthorizationLevel             = 0
			AccessWithoutConfirmation              = $true
			CreateFolders                          = $false
			DeleteFolders                          = $false
			MoveAccountsAndFolders                 = $false
		}
		#Example Full Rights Admin Role
		$FullPermisions = [PSCustomObject]@{
			UseAccounts                            = $true
			RetrieveAccounts                       = $true
			ListAccounts                           = $true
			AddAccounts                            = $true
			UpdateAccountContent                   = $true
			UpdateAccountProperties                = $true
			InitiateCPMAccountManagementOperations = $true
			SpecifyNextAccountContent              = $true
			RenameAccounts                         = $true
			DeleteAccounts                         = $true
			UnlockAccounts                         = $true
			ManageSafe                             = $true
			ManageSafeMembers                      = $true
			BackupSafe                             = $true
			ViewAuditLog                           = $true
			ViewSafeMembers                        = $true
			RequestsAuthorizationLevel             = 1
			AccessWithoutConfirmation              = $true
			CreateFolders                          = $true
			DeleteFolders                          = $true
			MoveAccountsAndFolders                 = $true
		}
		#No Permission Role
		$NoPermisions = [PSCustomObject]@{
			UseAccounts                            = $false
			RetrieveAccounts                       = $false
			ListAccounts                           = $false
			AddAccounts                            = $false
			UpdateAccountContent                   = $false
			UpdateAccountProperties                = $false
			InitiateCPMAccountManagementOperations = $false
			SpecifyNextAccountContent              = $false
			RenameAccounts                         = $false
			DeleteAccounts                         = $false
			UnlockAccounts                         = $false
			ManageSafe                             = $false
			ManageSafeMembers                      = $false
			BackupSafe                             = $false
			ViewAuditLog                           = $false
			ViewSafeMembers                        = $false
			RequestsAuthorizationLevel             = 0
			AccessWithoutConfirmation              = $false
			CreateFolders                          = $false
			DeleteFolders                          = $false
			MoveAccountsAndFolders                 = $false
		}

		#Object containing the ACL configurations
		$SafeRoles = [PSCustomObject]@{

			"User"     = $UserPermisions
			"Approver" = $ApproverPermisions
			"Support"  = $SupportPermisions
			"Full"     = $FullPermisions
			"None"     = $NoPermisions

		}


	}

	Process {

		#Search the vault for safes matching the safe pattern
		#Loop though all matching safes
		Find-PASSafe -search $SafePattern | ForEach-Object {

			$SafeName = $PSItem.SafeName

			#Expected members to be found configured on the safe
			#We expect region specific & "global" groups
			$ExpectedMembers = @(

				"$Region-CYBR-$SafeName-Usr",
				"$Region-CYBR-$SafeName-App",
				"GlobalSupport",
				"GlobalAdmin",
				"$Region`Support"

			)

			#Get UserNames of all existing safe members for the safe currently targeted
			$ExistingMembers = Get-PASSafeMember -SafeName $SafeName | Select-Object -ExpandProperty UserName

			#For each expected member UserName
			$ExpectedMembers | ForEach-Object {

				$UserName = $PSItem

				#Get the ACL Role for the Expected member
				#Determines which role to assign based on matching a naming pattern
				Switch ($UserName) {

					{ $PSItem -match "$SafeName-Usr$" } {

						$Permissions = $SafeRoles.User
						break

					}

					{ $PSItem -match "$SafeName-App$" } {

						$Permissions = $SafeRoles.Approver
						break

					}

					{ $PSItem -match "Support$" } {

						$Permissions = $SafeRoles.Support
						break

					}

					{ $PSItem -match "Admin$" } {

						$Permissions = $SafeRoles.Full
						break

					}

				}

				#If the expected member is not currently a safe member - add them
				If ($ExistingMembers -notcontains $Username) {

					Try {
						#Try to add the safe member
						#If you want the update to happen remove the `-WhatIf` switch parameter
						$null = $Permissions | Add-PASSafeMember -SafeName $SafeName -MemberName $UserName -Whatif
						Write-Verbose "Added Safe Member: $UserName" -Verbose
					}
					Catch {
						#Handle any errors adding the safe member here
						throw "Error Adding Safe Member $UserName"
					}
				}
				Else {
					#The expected member is already a safe member - update them

					Try {
						#Try to update the safe member
						#If you want the update to happen remove the `-WhatIf` switch parameter
						$null = $Permissions | Set-PASSafeMember -SafeName $SafeName -MemberName $UserName -Whatif
						Write-Verbose "Updated SafeMember: $UserName" -Verbose
					}
					Catch {
						#Handle any error updating the safe member here
						throw "Error Updating Safe Member $UserName"
					}

				}

			}

		}

	}

	End { }

}