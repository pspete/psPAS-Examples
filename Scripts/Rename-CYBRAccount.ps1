Function Rename-CYBRAccount {
    <#
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

#>
    [CmdletBinding()]
    param(
        [parameter(
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [object[]]$Account
    )

    Begin { }

    Process {

        #Get Properties from input object
        $AccountID = $PSItem.id
        $userName = $PSItem.userName
        $platformId = $PSItem.platformId
        $address = $PSItem.address

        #Define New Account Name value from PlatformID, Address & Username Properties of input object
        $NewName = "$platformId-$address-$userName"

        #Replace name of account with new name.
        Set-PASAccount -AccountID $AccountID -op replace -path /name -value $NewName -WhatIf

    }

    End { }

}