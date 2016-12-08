Function sConvert-Size {
    param (
	# Disk or Volume Space
	[Parameter(Mandatory = $true)]
	$DiskVolumeSpace,
	# Disk or Volume Space Input Unit
	[Parameter(Mandatory = $true)]
	[string]$DiskVolumeSpaceUnit
    )
    if ($DiskVolumeSpaceUnit -eq "byte") # byte input
    {
        if (($DiskVolumeSpace -ge "1024") -and ($DiskVolumeSpace -lt "1048576"))
        {
            $DiskVolumeSpace =  [math]::round(($DiskVolumeSpace/1024))
            $DiskVolumeSpaceUnit = "KB"
            return $DiskVolumeSpace, $DiskVolumeSpaceUnit
        }
        elseif (($DiskVolumeSpace -ge "1048576") -and ($DiskVolumeSpace -lt "1073741824"))
        {
            $DiskVolumeSpace =  [math]::round(($DiskVolumeSpace/1024/1024))
            $DiskVolumeSpaceUnit = "MB"
            return $DiskVolumeSpace, $DiskVolumeSpaceUnit
        }
        elseif (($DiskVolumeSpace -ge "1073741824") -and ($DiskVolumeSpace -lt "1099511627776"))
        {
            $DiskVolumeSpace =  "{0:N1}" -f ($DiskVolumeSpace/1024/1024/1024)
            $DiskVolumeSpaceUnit = "GB"
            return $DiskVolumeSpace, $DiskVolumeSpaceUnit
        }
        elseif (($DiskVolumeSpace -ge "1099511627776") -and ($DiskVolumeSpace -lt "1125899906842624"))
        {
            $DiskVolumeSpace =  "{0:N2}" -f ($DiskVolumeSpace/1024/1024/1024/1024)
            $DiskVolumeSpaceUnit = "TB"
            return $DiskVolumeSpace, $DiskVolumeSpaceUnit
        }
        Else
        {
            $DiskVolumeSpace =  $DiskVolumeSpace
            $DiskVolumeSpaceUnit = "Byte"
            return $DiskVolumeSpace, $DiskVolumeSpaceUnit
        }    
    }
    elseif ($DiskVolumeSpaceUnit -eq "kb") # kb input
    {
        if (($DiskVolumeSpace -ge "1") -and ($DiskVolumeSpace -lt "1024"))
        {
            $DiskVolumeSpace =  $DiskVolumeSpace
            $DiskVolumeSpaceUnit = "KB"
            return $DiskVolumeSpace, $DiskVolumeSpaceUnit
        }
        elseif (($DiskVolumeSpace -ge "1024") -and ($DiskVolumeSpace -lt "1048576"))
        {
            $DiskVolumeSpace =  ($DiskVolumeSpace/1024)
            $DiskVolumeSpaceUnit = "MB"
            return $DiskVolumeSpace, $DiskVolumeSpaceUnit
        }
        elseif (($DiskVolumeSpace -ge "1048576") -and ($DiskVolumeSpace -lt "1073741824"))
        {
            $DiskVolumeSpace =  "{0:N1}" -f ($DiskVolumeSpace/1024/1024)
            $DiskVolumeSpaceUnit = "GB"
            return $DiskVolumeSpace, $DiskVolumeSpaceUnit
        }
        elseif (($DiskVolumeSpace -ge "1073741824") -and ($DiskVolumeSpace -lt "1099511627776"))
        {
            $DiskVolumeSpace =  "{0:N2}" -f ($DiskVolumeSpace/1024/1024/1024)
            $DiskVolumeSpaceUnit = "TB"
            return $DiskVolumeSpace, $DiskVolumeSpaceUnit
        }
        Else
        {
            $DiskVolumeSpace =  $DiskVolumeSpace
            $DiskVolumeSpaceUnit = "KB"
            return $DiskVolumeSpace, $DiskVolumeSpaceUnit
        }    
    }
    elseif ($DiskVolumeSpaceUnit -eq "mb") # mb input
    {
        if (($DiskVolumeSpace -ge "1") -and ($DiskVolumeSpace -lt "1024"))
        {
            $DiskVolumeSpace =  $DiskVolumeSpace
            $DiskVolumeSpaceUnit = "MB"
            return $DiskVolumeSpace, $DiskVolumeSpaceUnit
        }
        elseif (($DiskVolumeSpace -ge "1024") -and ($DiskVolumeSpace -lt "1048576"))
        {
            $DiskVolumeSpace =  "{0:N1}" -f ($DiskVolumeSpace/1024)
            $DiskVolumeSpaceUnit = "GB"
            return $DiskVolumeSpace, $DiskVolumeSpaceUnit
        }
        elseif (($DiskVolumeSpace -ge "1048576") -and ($DiskVolumeSpace -lt "1073741824"))
        {
            $DiskVolumeSpace =  "{0:N2}" -f ($DiskVolumeSpace/1024/1024)
            $DiskVolumeSpaceUnit = "TB"
            return $DiskVolumeSpace, $DiskVolumeSpaceUnit
        }
        Else
        {
            $DiskVolumeSpace =  $DiskVolumeSpace
            $DiskVolumeSpaceUnit = "MB"
            return $DiskVolumeSpace, $DiskVolumeSpaceUnit
        }    
    }
    else
    {
        return "Unknown Parameter"
    }
}

Import-Module DataONTAP -ErrorAction SilentlyContinue
$ControllerCredential = get-credential
Connect-NcController am1stdk050 -credential $ControllerCredential
$HighUsageVols = Get-NcVol

$TotalSnaps = @()
Foreach($vol in $HighUsageVols){

    $Snapshots = Get-NCSnapshot $Vol.name
    $objSnapshots = @()
    Foreach($Snapshot in $Snapshots)
    {
        $object = [pscustomobject]@{
            VolumnName = $Vol.name
            SnapshotName = $Snapshot.name
            Created = $SnapShot.Created
            Total = sConvert-Size -DiskVolumeSpace $Snapshot.Total -DiskVolumeSpaceUnit "byte"
        }
        $objSnapshots += $object
	}
 
    $TotalSnaps += $Objsnapshots
}

$TotalSnaps | Where-Object {$_.created -lt (get-date).AddDays(-20)} | sort-object -Property created | FT
