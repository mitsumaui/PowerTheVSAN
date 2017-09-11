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
    )
  
    Begin {
      $vchs = Get-VsanView -Id "VsanVcClusterHealthSystem-vsan-cluster-health-system"
      $VsanVersion = (Get-VsanView -Id "VsanVcClusterHealthSystem-vsan-cluster-health-system").VsanVcClusterQueryVerifyHealthSystemVersions((Get-Cluster).Id) | select VcVersion
    }
  
    Process {
      if($VsanCluster.VsanEnabled -and $VsanVersion.VcVersion -lt '6.6') {
        $result = $vchs.VsanQueryVcClusterHealthSummary($VsanCluster.id, $null, $null, $ShowObjectUUIDs, $null, $UseCachedInfo)
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
      elseif ($VsanCluster.VsanEnabled -and $VsanVersion.VcVersion -lt '6.6') {
          Write-Warning -Message 'vSAN cluster is currently at a version newer than this call allows. Please open an issue: https://github.com/mitsumaui/PowerTheVSAN/issues'
      }
    }
  }
