Function Unlock-CYBRUser {
    <#
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

#>
    [CmdLetBinding()]
    param($username)

    Begin { }

    Process {

        $User = Get-PASUser -Search $username

        If ($User.ID) {
            $User | Unblock-PASUser -Whatif
        }

    }

    End { }

}