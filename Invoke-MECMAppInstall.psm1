# Adapted from https://timmyit.com/2016/08/08/sccm-and-powershell-force-installuninstall-of-available-software-in-software-center-through-cimwmi-on-a-remote-client/

Function Invoke-MECMAppInstall
{
 
    Param
    (
         [String][Parameter(Mandatory=$True, Position=1)] $Computername,
         [String][Parameter(Mandatory=$True, Position=2)] $AppName,
         [ValidateSet("Install","Uninstall")]
         [String][Parameter(Mandatory=$True, Position=3)] $Method
    )
 
Begin {

    $Reachable = 0
    if(Test-Connection $Computername -Count 1 -Quiet){
        $Reachable = 1
        $Application = (Get-CimInstance -ClassName CCM_Application -Namespace "root\ccm\clientSDK" -ComputerName $Computername | Where-Object {$_.Name -like $AppName})
 
        $Arguments = @{
        EnforcePreference = [UINT32] 0
        Id = "$($Application.id)"
        IsMachineTarget = $Application.IsMachineTarget
        IsRebootIfNeeded = $False
        Priority = 'High'
        Revision = "$($Application.Revision)"
        }
    } else {
        Write-Host "Could not ping $Computername"
    }
}
 
Process
 
{
    if($Reachable){
    Invoke-CimMethod -Namespace "root\ccm\clientSDK" -ClassName CCM_Application -ComputerName $Computername -MethodName $Method -Arguments $Arguments
    }
}
 
End {}
 
}