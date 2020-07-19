Function New-CYBRSafe {
    <#
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

#>
    [cmdletbinding()]
    Param(
        [parameter(
            Mandatory = $true,
            ValueFromPipeline = $false
        )]
        [string]$SafeName

    )

    Begin { }

    Process {

        #determine safe configuration based on safe name pattern
        #The variables set here are used for the new safe command
        switch -Wildcard ($SafeName) {

            "EU_*" {
                #safename begins with "EU_"
                $Region = "EU"
                $SafeParams = @{
                    "ManagingCPM"               = "PasswordManager"
                    "NumberOfVersionsRetention" = 10
                }

                break

            }

            "APAC_*" {
                #safename begins with "APAC_"
                $Region = "APAC"
                $SafeParams = @{
                    "ManagingCPM"           = "PasswordManager1"
                    "NumberOfDaysRetention" = 30
                }

                break
            }

            default {
                #safename begins with anything except "EU_" or "APAC_"
                $Region = "Default"
                $SafeParams = @{
                    "ManagingCPM"               = "PasswordManager"
                    "NumberOfVersionsRetention" = 10
                }
                break
            }
        }

        #Add the safename to the parameters to be sent with the new safe request
        $SafeParams.Add("SafeName", $SafeName)

        try {

            #Try and create the new safe -
            $null = Add-PASSafe @SafeParams -WhatIf
            Write-Verbose "Safe Created: $SafeName" -Verbose
        }
        catch {
            #Handle any errors relating to the creation of the safe here
            throw "Error Creating Safe: $SafeName"
        }

        #another function adds the safe members to the safe: Set-CYBRSafePermission
        Set-CYBRSafePermission -SafePattern $SafeName -Region $Region

    }

    End { }

}