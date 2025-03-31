$DEFAULT_PREFIX = "UIUC-ENGR-"
$DEFAULT_SITE_CODE = "MP0"
$DEFAULT_PROVIDER = "sccmcas.ad.uillinois.edu"

Function Invoke-MECMAppInstall
{
    # Adapted from https://timmyit.com/2016/08/08/sccm-and-powershell-force-installuninstall-of-available-software-in-software-center-through-cimwmi-on-a-remote-client/
 
    Param
    (
        [Parameter(Mandatory=$True, Position=1, ValueFromPipeline=$True)] $Computer,
        [String][Parameter(Mandatory=$True, Position=2)] $AppName,
        [ValidateSet("Install","Uninstall")]
        [String][Parameter(Mandatory=$True, Position=3)] $Method,
        [string]$Prefix = $DEFAULT_PREFIX,
		[string]$SiteCode=$DEFAULT_SITE_CODE,
		[string]$Provider=$DEFAULT_PROVIDER,
        [string]$CMPSModulePath="$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1"
    )
 
    Begin {
        Write-Verbose "Not an array, running the function normally."
        $myPWD = $PWD.Path

        if($null -eq (Get-Module ConfigurationManager)){
            Connect-ToMECM -Prefix $Prefix -SiteCode $SiteCode -Provider $Provider -CMPSModulePath $CMPSModulePath
        }
        if($null -eq (Get-Module ActiveDirectory)){
            Import-Module ActiveDirectory
        }
    }
    
    Process
    
    {
        $Type = $Computer.GetType()
        Write-Verbose "The Type passed to Computer is $Type"

        if($Type -eq [Object[]] ){
            Write-Verbose "Array detected. Making recursive call."
            $Computer | ForEach-Object -Parallel {
                Write-Verbose "Recursive call on $_ with $($using:AppName) in order to $($using:Method)."
                Invoke-MECMAppInstall -Computer $_ -AppName $using:AppName -Method $using:Method
            }
        }else{
            # Ensure that a supported type was passed
            if ($Type -notin 
                [String],
                [Microsoft.ActiveDirectory.Management.ADComputer],
                [Microsoft.ConfigurationManagement.ManagementProvider.WqlQueryEngine.WqlResultObject]) {
                throw "Unsupported argument type passed to Computer parameter. The type passed was $Type. The parameter must be of type [String],[Microsoft.ActiveDirectory.Management.ADComputer], or [Microsoft.ConfigurationManagement.ManagementProvider.WqlQueryEngine.WqlResultObject]"
            }
            Write-Verbose "Computer is $Computer"
            Write-Verbose "Computer type is $Type"
            if ($Type -eq [String]) {
                $Name = $Computer
                Write-Verbose "Setting Name to $($Computer)"
            }elseif($Type -eq [Microsoft.ActiveDirectory.Management.ADComputer]) {
                $Name = $Computer | Select-Object -ExpandProperty Name
                Write-Verbose "Setting Name to $($Computer | Select-Object -ExpandProperty Name)"
            }
            elseif($Type -eq [Microsoft.ConfigurationManagement.ManagementProvider.WqlQueryEngine.WqlResultObject]) {
                $Name = $Computer | Select-Object -ExpandProperty Name
                Write-Verbose "Setting Name to $($Computer | Select-Object -ExpandProperty Name)"
            }
            
            Write-Verbose "Name is $Name"

            $Reachable = $false
            if(Test-Connection $Name -Count 1 -Quiet){
                $Reachable = $true
                $Application = (Get-CimInstance -ClassName CCM_Application -Namespace "root\ccm\clientSDK" -ComputerName $Name | Where-Object {$_.Name -like $AppName})
                Write-Verbose "Applications found: $($Application.Name)"
                Write-Verbose "Applications found: $($Application.Count)"

                if($Application.Id.Count -eq 0){
                    Write-Error "No applications were found matching $($AppName)." -ErrorAction Continue
                    $Reachable = $false
                }
                if($Application.Id.Count -ge 2){
                    Write-Error "More than 1 application was found matching $($AppName). This cmdlet is only designed for single applications." -ErrorAction Continue
                    $Reachable = $false
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
                $Reachable = $false
            }
            if($Reachable){
                Write-Verbose "Installing $Application on $Name using method $Method"
                Invoke-CimMethod -Namespace "root\ccm\clientSDK" -ClassName CCM_Application -ComputerName $Name -MethodName $Method -Arguments $Arguments
            }
        }
    }
    
    End {
        Set-Location $myPWD
    }
 
}