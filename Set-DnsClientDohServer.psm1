function Get-Adapter {
    param(
        [Parameter( Mandatory = $True )]
        [String[]]$InterfaceAlias
    )
    Process{

        $ValidInterfaces   = @()
        $InvalidInterfaces = @()

        foreach ( $Alias in $InterfaceAlias ) {
            try {

                $Param = @{
                    Name        = $Alias
                    ErrorAction = 'Stop'
                }
                $ValidInterfaces += Get-Netadapter @Param

            } catch {

                $InvalidInterfaces += $Alias

            } # End Try / Catch
        } # End ForEach

        if ( $InvalidInterfaces ) {

            Write-Error "$( $InvalidInterfaces -join ", " ) won't work. Not Valid interface(s)!" -ErrorAction Stop

        }

        $ValidInterfaces

    } # End Process
} # End Function

#REQUIRES -Version 5.1
#REQUIRES -Runasadministrator
Function Set-DnsClientDohServer {
<#
.SYNOPSIS
Sets the DNS and DoH servers for your computer.

.DESCRIPTION
A looping script to set your IPv4 AND IPv6 DNS over HTTPS servers to the desired interface. Then
set the right registry values to encrypt your traffic.

.EXAMPLE
Set-DnsClientDohServer -ServerAddress "1.1.1.1","1.0.0.1","2606:4700:4700::1111","2606:4700:4700::1001"
-DoHTemplate "https://cloudflare-dns.com/dns-query" -InterfaceAlias "Ethernet"

.EXAMPLE
$DNS = @{
    DoHTemplate       = "https://dns.google/dns-query"
    ServerAddress     = "8.8.8.8","8.8.4.4","2001:4860:4860::8844","2001:4860:4860::8888"
    InterfaceAlias    = "Ethernet","Wi-Fi"
    Fallback          = $false
    Verbose           = $true
    InformationAction = 'Continue'
    }
Set-DnsClientDohServer @DNS

.PARAMETER ServerAddresses
This is the IP addresses of your DoH DNS.

.PARAMETER DoHTemplate
The DoH Template URL of your DoH server in double quotations.

.PARAMETER InterfaceAlias
This is the Name of your Interface. Can include multiple names.
IE: "Ethernet","Wi-Fi"

.PARAMETER Fallback
Add the -Fallback parameter to fallback to plaintext.
#>

    [CmdletBinding(SupportsShouldProcess = $true,
                   ConfirmImpact         = "High")]

    Param(
        [Parameter(Mandatory   = $true,
                   HelpMessage = "Enter the IP addresses of your DoH server.")]
        [ValidateCount(1,4)]
        [string[]]$ServerAddresses,

        [Parameter(Mandatory   = $true,
                   HelpMessage = "Enter the right URL of your DoH server.")]
        [string]$DoHTemplate,

        [Parameter(Mandatory   = $true,
                   HelpMessage = "Enter the name of the interface name that you'd like to change.")]
        [String[]]$InterfaceAlias,

        [Parameter(HelpMessage = "Include fallback parameter to fallback to plaintext.")]
        [switch]$Fallback
    )
BEGIN{

        Write-Information @"
<------------------------ Computer Information ------------------------>
    Powershell Version = $( $PSVersionTable.PSVersion )
    Date               = $( Get-Date -Format "MM-dd-yyyy" )
    Operating System   = $( ( Get-CimInstance Win32_OperatingSystem ).Caption )
    Processor          = $env:PROCESSOR_ARCHITECTURE
    Uptime             = $( ( Get-Date ) - ( Get-CimInstance Win32_OperatingSystem ).LastBootUpTime )
    Execution Policy   = $( Get-ExecutionPolicy )
    Command Path       = $PSCommandPath
<------------------------ Computer Information ------------------------>
"@

}
PROCESS {

        # Separate IP's by version
        $IPv4 = ( [IPAddress[]]$ServerAddresses ).Where( { $_.AddressFamily -eq 'InterNetwork' } )
        $IPv6 = ( [IPAddress[]]$ServerAddresses ).Where( { $_.AddressFamily -eq 'InterNetworkV6' } )

        # Get Interface Information
        $Interface = Get-Adapter -InterfaceAlias $InterfaceAlias

        # Set DNS servers on selected interface(s).
        foreach ($int in $Interface) {
            if ($PSCmdlet.ShouldProcess($int.Name, "Set DNS server addresses $ServerAddresses")) {

                $DNS = @{
                    InterfaceAlias  = $int.Name
                    ServerAddresses = $ServerAddresses
                }
                Set-DnsClientServerAddress @DNS

            Write-Verbose "Set DNS servers on interface $($int.Name) to $ServerAddresses"
            } # End WhatIf

        # Set DoH registry keys on selected interface(s).
    $guid = $int.InterfaceGUID
    $baseKey = "HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\InterfaceSpecificParameters\$guid\DohInterfaceSettings"

        # Get the QWord value for Fallback to PlainText
    [int]$Number = switch ( $Fallback ){
        $True  { 21 } # Encryption Preferred
        $False { 2 }  # Encrypted
    }

    $map = @{
            ( Join-Path $baseKey 'Doh'  ) = $IPv4
            ( Join-Path $baseKey 'Doh6' ) = $IPv6
        }

        # Map IPv4 and IPv6 interfaces in registry.

        foreach ( $parentPath in $map.Keys ) {

            if ( $PSCmdlet.ShouldProcess($parentPath, "Recreate DoH registry path" ) ) {

                if ( Test-Path $parentPath ) {
                    Remove-Item -Path $parentPath -Recurse -Force
                    Write-Verbose "Removed $parentPath from registry."
                }

                [void]( New-Item -Path $parentPath -Force )
                    Write-Verbose "Made new entry in $parentPath."

            foreach ( $addr in $map[$parentPath] ) {

                $subKey = Join-Path $parentPath $addr

                [void]( New-Item -Path $subKey )

                $FlagItem = @{
                    Path         = $subKey
                    Name         = 'DohFlags'
                    PropertyType = 'Qword'
                    Value        = $Number
                    Force        = $true
                }
                [void]( New-ItemProperty @FlagItem )

                $TempItem = @{
                    Path         = $subKey
                    Name         = 'DohTemplate'
                    PropertyType = 'String'
                    Value        = $DoHTemplate
                    Force        = $true
                }
                [void]( New-ItemProperty @TempItem )

                    Write-Verbose "Configured DoH entry $addr under $subKey"

                    } # End Parentpath ForEach
                } # End WhatIf
            } # End Map ForEach
        } # End Interface ForEach
    } # End Process
} # End Function
