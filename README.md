<h1 style="text-align: center;">Set-DnsClientDohServer</h1>

<p align: "center">
This function sets your DNS servers then edits the registry to use the right URL to encrypt your traffic for DNS over HTTPS.

The following registry tree is deleted then repopulated with the right DNS server and URL to properly encrypt your traffic.

`HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\InterfaceSpecificParameters\<YOUR_INTERFACES_GUID>\DohInterfaceSettings`

I added a `-Verbose` parameter to get a print out of what's happening. There's also a General `-WhatIf` function. 

If you want to have your DoH traffic to fallback to plaintext then include the `-Fallback` Parameter. Not adding it will default to encrypted with no fallback.

There's an information stream to help diagnose any issues that may arise. You'll just have to include the parameter `-InformationAction 'Continue'`
</p>

---

Here's an example of the function splatted and its output:

```
PS C:\Windows\system32> $DNS = @{
>>         DoHTemplate       = "https://dns.google/dns-query"
>>         ServerAddress     = "8.8.8.8","8.8.4.4","2001:4860:4860::8844","2001:4860:4860::8888"
>>         InterfaceAlias    = "Ethernet"
>>         Fallback          = $false
>>         Verbose           = $true
>>         InformationAction = 'Continue'
>>         }
PS C:\Windows\system32> Set-DnsClientDohServer @DNS
VERBOSE: Perform operation 'Enumerate CimInstances' with following parameters, ''namespaceName' = root\cimv2,'className' = Win32_OperatingSystem'.
VERBOSE: Operation 'Enumerate CimInstances' complete.
VERBOSE: Perform operation 'Enumerate CimInstances' with following parameters, ''namespaceName' = root\cimv2,'className' = Win32_OperatingSystem'.
VERBOSE: Operation 'Enumerate CimInstances' complete.
<------------------------ Computer Information ------------------------>
    Powershell Version = 5.1.26100.7920
    Date               = 03-20-2026
    Operating System   = Microsoft Windows 11 Enterprise
    Processor          = AMD64
    Uptime             = 05:10:20.0039521
    Execution Policy   = Restricted
    Command Path       =
<------------------------ Computer Information ------------------------>

Confirm
Are you sure you want to perform this action?
Performing the operation "Set DNS server addresses 8.8.8.8 8.8.4.4 2001:4860:4860::8844 2001:4860:4860::8888" on target "Ethernet".
[Y] Yes  [A] Yes to All  [N] No  [L] No to All  [S] Suspend  [?] Help (default is "Y"): a
VERBOSE: Set DNS servers on interface Ethernet to 8.8.8.8 8.8.4.4 2001:4860:4860::8844 2001:4860:4860::8888
VERBOSE: Removed HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\InterfaceSpecificParameters\{5036853E-EB9B-4537-9FD4-D0DFACEBB42C}\DohInterfaceSettings\Doh from
registry.
VERBOSE: Made new entry in
HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\InterfaceSpecificParameters\{5036853E-EB9B-4537-9FD4-D0DFACEBB42C}\DohInterfaceSettings\Doh.
VERBOSE: Configured DoH entry 8.8.8.8 under
HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\InterfaceSpecificParameters\{5036853E-EB9B-4537-9FD4-D0DFACEBB42C}\DohInterfaceSettings\Doh\8.8.8.8
VERBOSE: Configured DoH entry 8.8.4.4 under
HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\InterfaceSpecificParameters\{5036853E-EB9B-4537-9FD4-D0DFACEBB42C}\DohInterfaceSettings\Doh\8.8.4.4
VERBOSE: Removed HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\InterfaceSpecificParameters\{5036853E-EB9B-4537-9FD4-D0DFACEBB42C}\DohInterfaceSettings\Doh6 from
registry.
VERBOSE: Made new entry in
HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\InterfaceSpecificParameters\{5036853E-EB9B-4537-9FD4-D0DFACEBB42C}\DohInterfaceSettings\Doh6.
VERBOSE: Configured DoH entry 2001:4860:4860::8844 under
HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\InterfaceSpecificParameters\{5036853E-EB9B-4537-9FD4-D0DFACEBB42C}\DohInterfaceSettings\Doh6\2001:4860:4860::8844
VERBOSE: Configured DoH entry 2001:4860:4860::8888 under
HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\InterfaceSpecificParameters\{5036853E-EB9B-4537-9FD4-D0DFACEBB42C}\DohInterfaceSettings\Doh6\2001:4860:4860::8888
```

---
