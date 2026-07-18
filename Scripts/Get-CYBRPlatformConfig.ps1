Function Get-CYBRPlatformConfig {
    <#
.SYNOPSIS
An example function using psPAS commands to Get Platform Configuration details.

.DESCRIPTION
This function shows
- Using `Get-PASPlatform` to return details of platforms
- Using `Get-PASPlatform` to return details of specific platforms
- Combining PowerShell objects to get data into a flat format for easy filtering & querying.
- Flattening array properties for CSV export compatibility.
- Expanding required/optional properties into boolean columns.

.PARAMETER PlatformID
Optional ID of a platform name to return configuration details of.

.PARAMETER ExpandProperties
Expand required and optional arrays into individual boolean columns
(e.g., required_property_Username, optional_property_LogonDomain).

.EXAMPLE
Get-CYBRPlatformConfig

Returns details of all active regular platforms

.EXAMPLE
Get-CYBRPlatformConfig | Export-Csv platforms.csv -NoTypeInformation

Exports platform configuration to CSV with arrays serialized as semicolon-delimited strings.

.EXAMPLE
Get-CYBRPlatformConfig -ExpandProperties | Export-Csv platforms.csv -NoTypeInformation

Exports with required/optional arrays expanded into boolean columns for easier filtering.

#>
    [CmdLetBinding()]
    param(
        [parameter(
            Mandatory = $false,
            ValueFromPipeline = $false
        )]
        [string]$PlatformID,

        [parameter(
            Mandatory = $false
        )]
        [switch]$ExpandProperties
    )

    Begin {
        $AllPlatforms = [System.Collections.Generic.List[PSObject]]::new()
    }

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
            $CurrentPlatformID = $ThisPlatform.general.id

            #create output object
            $PlatformSettings = [pscustomobject]@{
                "PlatformID" = $CurrentPlatformID
            }

            #get settings from each matching platform
            $PolicySettings = Get-PASPlatform -PlatformID $CurrentPlatformID -verbose:$false | Select-Object -ExpandProperty Details
            $ThisPlatform | Add-Member -MemberType NoteProperty -Name Classic -Value $PolicySettings -Force

            $ThisPlatform | Get-Member -type NoteProperty | ForEach-Object {

                $Node = $PSItem.Name

                $ThisPlatform.$Node | Get-Member -MemberType NoteProperty -ea SilentlyContinue | ForEach-Object {

                    #Add properties relating to platform configuration to output object.
                    $PlatformSettings | Add-Member -MemberType NoteProperty -Name $PSItem.Name -Value $ThisPlatform.$Node.$($PSItem.Name) -Force

                }

            }

            $AllPlatforms.Add($PlatformSettings)

        }

    }

    End {
        if (-not $ExpandProperties) {
            # Flatten arrays to semicolon-delimited strings for CSV compatibility
            foreach ($platform in $AllPlatforms) {
                foreach ($prop in $platform.PSObject.Properties) {
                    if ($prop.Value -is [System.Array]) {
                        $prop.Value = ($prop.Value | ForEach-Object {
                            if ($_ -is [PSCustomObject] -or $_ -is [hashtable]) {
                                $_ | ConvertTo-Json -Compress -Depth 10
                            } else {
                                $_
                            }
                        }) -join ";"
                    } elseif ($prop.Value -is [PSCustomObject]) {
                        $prop.Value = $prop.Value | ConvertTo-Json -Compress -Depth 10
                    }
                }
                $platform
            }
        } else {
            # Expand required/optional into boolean columns

            # First pass: discover all unique property names
            $allRequiredProps = [System.Collections.Generic.HashSet[string]]::new()
            $allOptionalProps = [System.Collections.Generic.HashSet[string]]::new()

            foreach ($platform in $AllPlatforms) {
                if ($platform.required -is [System.Array]) {
                    foreach ($prop in $platform.required) {
                        if ($prop.name) { [void]$allRequiredProps.Add($prop.name) }
                    }
                }
                if ($platform.optional -is [System.Array]) {
                    foreach ($prop in $platform.optional) {
                        if ($prop.name) { [void]$allOptionalProps.Add($prop.name) }
                    }
                }
            }

            $requiredPropsSorted = $allRequiredProps | Sort-Object
            $optionalPropsSorted = $allOptionalProps | Sort-Object

            # Second pass: create flattened objects with expanded columns
            foreach ($platform in $AllPlatforms) {
                $props = [ordered]@{}

                # Add all original properties except required/optional arrays
                foreach ($p in $platform.PSObject.Properties) {
                    if ($p.Name -in @("required", "optional")) { continue }

                    $value = $p.Value
                    if ($value -is [System.Array]) {
                        $props[$p.Name] = ($value | ForEach-Object {
                            if ($_ -is [PSCustomObject] -or $_ -is [hashtable]) {
                                $_ | ConvertTo-Json -Compress -Depth 10
                            } else {
                                $_
                            }
                        }) -join ";"
                    } elseif ($value -is [PSCustomObject]) {
                        $props[$p.Name] = $value | ConvertTo-Json -Compress -Depth 10
                    } else {
                        $props[$p.Name] = $value
                    }
                }

                # Build sets of required/optional property names for this platform
                $thisRequired = [System.Collections.Generic.HashSet[string]]::new()
                $thisOptional = [System.Collections.Generic.HashSet[string]]::new()

                if ($platform.required -is [System.Array]) {
                    foreach ($prop in $platform.required) {
                        if ($prop.name) { [void]$thisRequired.Add($prop.name) }
                    }
                }
                if ($platform.optional -is [System.Array]) {
                    foreach ($prop in $platform.optional) {
                        if ($prop.name) { [void]$thisOptional.Add($prop.name) }
                    }
                }

                # Add boolean columns for each required property
                foreach ($propName in $requiredPropsSorted) {
                    $props["required_property_$propName"] = $thisRequired.Contains($propName)
                }

                # Add boolean columns for each optional property
                foreach ($propName in $optionalPropsSorted) {
                    $props["optional_property_$propName"] = $thisOptional.Contains($propName)
                }

                [PSCustomObject]$props
            }
        }
    }

}