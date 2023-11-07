Function Connect-ToMECM {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string]$Prefix,
		[string]$SiteCode,
		[string]$Provider,
        [string]$CMPSModulePath
    )

    Write-Verbose "Preparing connection to MECM..."
    $initParams = @{}
    if($null -eq (Get-Module ConfigurationManager)) {
        # The ConfigurationManager Powershell module switched filepaths at some point around CB 18##
        # So you may need to modify this to match your local environment
        Import-Module $CMPSModulePath @initParams -Scope Global
    }
    if(($null -eq (Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue))) {
        New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $Provider @initParams
    }
    Set-Location "$($SiteCode):\" @initParams
    Write-Verbose "Done prepping connection to MECM."
}

Function Invoke-MECMAppInstall
{
    # Adapted from https://timmyit.com/2016/08/08/sccm-and-powershell-force-installuninstall-of-available-software-in-software-center-through-cimwmi-on-a-remote-client/
 
    Param
    (
         [Parameter(Mandatory=$True, Position=1)] $Computer,
         [String][Parameter(Mandatory=$True, Position=2)] $AppName,
         [ValidateSet("Install","Uninstall")]
         [String][Parameter(Mandatory=$True, Position=3)] $Method
    )
 
Begin {

        $myPWD = $PWD.Path

    $Reachable = 0
    if(Test-Connection $Name -Count 1 -Quiet){
        $Reachable = 1
        $Application = (Get-CimInstance -ClassName CCM_Application -Namespace "root\ccm\clientSDK" -ComputerName $Name | Where-Object {$_.Name -like $AppName})

        if($Application.Count -ne 1){
            throw "Either 0 or more than 1 application was found matching $($AppName). This cmdlet is only designed for single applications."
        }
 
        $Arguments = @{
        EnforcePreference = [UINT32] 0
        Id = "$($Application.id)"
        IsMachineTarget = $Application.IsMachineTarget
        IsRebootIfNeeded = $False
        Priority = 'High'
        Revision = "$($Application.Revision)"
        }
    } else {
        Write-Error "Could not ping $Name" -ErrorAction Continue
    }
}
 
Process
 
{
    if($Reachable){
    Invoke-CimMethod -Namespace "root\ccm\clientSDK" -ClassName CCM_Application -ComputerName $Name -MethodName $Method -Arguments $Arguments
    }
}
 
End {}
 
}