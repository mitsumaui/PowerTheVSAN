Function Get-VSANObjectHealth {
  <#
      .SYNOPSIS
      Obtain object health for vSAN Cluster
      .DESCRIPTION
      This function performs an object health report for a vSAN Cluster
      .PARAMETER VsanCluster
      Specifies a vSAN Cluster object, returned by Get-Cluster cmdlet.
      .EXAMPLE
      PS C:\> Get-Cluster | Get-VSANObjectHealth
  #>
  
  [CmdletBinding()]
  Param (
    [Parameter(Mandatory, ValueFromPipeline)]
    [Alias("Cluster")]
    [VMware.VimAutomation.ViCore.Types.V1.Inventory.Cluster]$VsanCluster
    ,
    [Parameter(Mandatory = $false)]
    [switch]$ShowObjectUUIDs
    ,
    [Parameter(Mandatory = $false)]
    [switch]$UseCachedInfo
    ,
    [Parameter(Mandatory = $false)]
    [switch]$HealthyOnly
    ,
    [Parameter(Mandatory = $false)]
    [ValidateSet("defaultView", "deployAssist")]
    [string]$VsanHealthPerspective = "defaultView"
  )
  
  Begin {

  }
  
  Process {
    $vcName = $vsancluster.Uid.Split("@")[1].Split(":")[0]
    $vchs = Get-VsanView -Id "VsanVcClusterHealthSystem-vsan-cluster-health-system" -Server $vcName
    $VsanVersion = (Get-VsanView -Id "VsanVcClusterHealthSystem-vsan-cluster-health-system" -Server $vcName).VsanVcClusterQueryVerifyHealthSystemVersions(($VsanCluster).Id) | select VcVersion

    if($VsanCluster.VsanEnabled -and $VsanVersion.VcVersion -lt '6.6') {
      $result = $vchs.VsanQueryVcClusterHealthSummary($VsanCluster.id, $null, $null, $ShowObjectUUIDs, $null, $UseCachedInfo)
    }
    elseif ($VsanCluster.VsanEnabled -and $VsanVersion.VcVersion -gt '6.6') {
      $result = $vchs.VsanQueryVcClusterHealthSummary($VsanCluster.id, $null, $null, $ShowObjectUUIDs, $null, $UseCachedInfo, $VsanHealthPerspective)
    }

    if($result) {
      if($HealthyOnly) {
        $Health = $result.ObjectHealth.ObjectHealthDetail | Where-Object {$_.Health -notlike 'healthy' -and $_.NumObjects -gt 0}
        if($Health) {
          return $false
        } else {
          return $true
        }
      } else {
        return $result.ObjectHealth.ObjectHealthDetail
      }
    }
  }
}
