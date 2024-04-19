$DEFAULT_PREFIX = "UIUC-ENGR-"
$DEFAULT_SITE_CODE = "MP0"
$DEFAULT_PROVIDER = "sccmcas.ad.uillinois.edu"

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