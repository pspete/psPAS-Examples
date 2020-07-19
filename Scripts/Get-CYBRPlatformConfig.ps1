Function Get-CYBRPlatformConfig {
    <#
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

#>
    [CmdLetBinding()]
    param(
        [parameter(
            Mandatory = $false,
            ValueFromPipeline = $false
        )]
        [string]$PlatformID
    )

    Begin { }

    Process {

        #Return details of regular platforms which are active
        $PlatformParams = @{

            "Active"       = $true
            "PlatformType" = "Regular"

        }

        If ($PlatformID) {

            #if a platformID value has been given, return details of search for platformID value.
            $PlatformParams.Add("search", $PlatformID)

        }

        #Get details of all matching platforms
        Get-PASPlatform @PlatformParams | Select-Object -ExpandProperty Details | ForEach-Object {

            #current platform details
            $ThisPlatform = $PSItem
            #current platform name
            $PlatformID = $ThisPlatform.general.id

            #create output object
            $PlatformSettings = [pscustomobject]@{
                "PlatformID" = $PlatformID
            }

            #get settings from each matching platform
            $PolicySettings = Get-PASPlatform -PlatformID $PlatformID -verbose:$false | Select-Object -ExpandProperty Details
            $ThisPlatform | Add-Member -MemberType NoteProperty -Name Classic -Value $PolicySettings -Force

            $ThisPlatform | Get-Member -type NoteProperty | ForEach-Object {

                $Node = $PSItem.Name

                $ThisPlatform.$Node | Get-Member -MemberType NoteProperty -ea SilentlyContinue | ForEach-Object {

                    #Add properties relating to platform configuration to output object.
                    $PlatformSettings | Add-Member -MemberType NoteProperty -Name $PSItem.Name -Value $ThisPlatform.$Node.$($PSItem.Name) -Force

                }

            }

            #output matching platform details
            $PlatformSettings

        }

    }

    End { }

}