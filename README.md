# Invoke-MECMAppInstall

# Description
A function that can remotely invoke the installation or uninstallation of a deployed MECM application. Relies on WMI calls, so requires admin on the target computer(s). Supports wildcards in the `AppName` parameter.

If multiple applications are returned by a wildcard search, this command will fail.

# Syntax
```powershell
Invoke-MECMAppInstall
    [-Computer]
    [-AppName]
    [-Method]
```

# Examples
This command remotely installs the application named "Fusion 360 - Latest" on target computer "RemoteComputer"
```powershell
Invoke-MECMAppInstall -Computer RemoteComputer -AppName "Fusion 360 - Latest" -Method Install
```

This command remotely installs any application matching "*Fusion\*"
```powershell
Invoke-MECMAppInstall -Computer RemoteComputer -AppName "*Fusion*" -Method Install
```

This command remotely uninstalls any application matching "*Fusion\*"
```powershell
Invoke-MECMAppInstall -Computer RemoteComputer -AppName "*Fusion*" -Method Uninstall
```

This set of commands remotely installs any application matching "*Fusion\*" on computers matching `meb-0023b-*`
```powershell
$comps = Get-ADComputer -Filter { Name -like "meb-0023b-*" }

foreach($comp in $comps){Invoke-MECMAppInstall -Computer $comp.Name -AppName "*Fusion*" -Method Install }
```

# Parameters
### -Computer
The target remote computer. Can be passed as any of the following three types:
[String]
[Microsoft.ConfigurationManagement.ManagementProvider.WqlQueryEngine.WqlResultObject] (e.g. the result from `Get-CMCollectionMember`)
[Microsoft.ActiveDirectory.Management.ADComputer] (e.g. the result from `Get-ADComputer`)

### AppName
The name of the application to be invoked. Supports wildcards.

Note: This function is only designed to handle one application at a time. If multiple applications are returned by a wildcard query, the command will fail. 

### Method
Options: Install, Uninstall

Used to declare whether to install or uninstall the given application.