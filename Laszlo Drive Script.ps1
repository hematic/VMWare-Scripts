#requires -Version 3
Function Get-DiskData {

    Param
    (
        [String]$VMName,
        $Creds
    )

    $ResultsArray = @()
    $DiskDrives = Get-WMIObject -Class Win32_DiskDrive -ComputerName $vmname -Credential $Creds
    
    Foreach($Drive in $DiskDrives){
        Write-Verbose "Drive Info :"
        Write-verbose $($Drive | Out-String)
        [Int]$SCSIPort = [Int]$Drive.scsiport
        [Int]$SCSIPort = [Int]$SCSIPort - 2
        $PartitionQuery = "ASSOCIATORS OF {Win32_DiskDrive.DeviceID='$($Drive.DeviceID)'} WHERE ResultClass=Win32_DiskPartition"
        $Diskpartitions = Get-WMIObject -Query $PartitionQuery -ComputerName $vmname -Credential $Creds
        Foreach($Partition in $Diskpartitions){
            Write-Verbose "Partition Info :"
            Write-verbose $($Partition | Out-String)
            $LogicalDiskQuery = "ASSOCIATORS OF {Win32_DiskPartition.DeviceID='$($Partition.DeviceID)'} WHERE ResultClass=Win32_LogicalDisk"
            $tempObj = Get-WMIObject -Query $LogicalDiskQuery -ComputerName $vmname -Credential $Creds | Select DeviceID,VolumeName
            Write-Verbose "Logical Disks :"
            Write-verbose $($TempOBJ | Out-String)
            If($tempObj.DeviceID -ne '' -and $tempObj.deviceid -ne $Null){
                $Result = [PSCustomobject]@{
                    DeviceID = $tempObj.deviceid
                    VolumeName = $tempObj.volumename
                    SCSIBus = $SCSIPort
                    SCSITarget = $Drive.SCSITargetId
                    Serial = $Drive.SerialNumber
                }
                $ResultsArray += $Result
                Write-verbose $($Result | out-string)
                Remove-Variable Result
            }
        }
    }
    Write-Output $ResultsArray
}

Import-Module -Name VMware.VimAutomation.Core

###################
#Connect-ToVCenter#
###################

Write-Host "Enter vCenter name: " -nonewline -foregroundcolor "DarkGreen"
$VCenter = Read-Host
Write-Host "Please Enter your VCenter Credentials: " -nonewline -foregroundcolor "DarkGreen"
$Creds = Get-Credential
Write-Host "Connecting to the vCenter $VCenter" -foregroundcolor "DarkGreen"
Connect-VIServer -Server $VCenter -Credential $Creds | Out-Null

#######################
#Prompt for Parameters#
#######################
Write-Host "Enter VM name to get the disk mappings: " -nonewline -foregroundcolor "DarkGreen"
$VMname = Read-Host
Write-Host "Gathering Data...Please be patient."
Try{
    $VMView = Get-VM -Name $VMname -ErrorAction Stop | Get-View
}
Catch [System.Exception]{
    Write-Host "Error Getting VM : $($_.Exception.Message)"
}

#Thanks go to Richard Siddaway for the basic queries to tie diskdrive>partition>logicaldisk.
#http://itknowledgeexchange.techtarget.com/powershell/mapping-physical-drives-to-logical-drives-part-3/
#Laszlo Krencz added: changed $dks.SCSIBus to $dks.SCSIport which is the real SCSI bus number in Windows despite the name :)

#########
#Do Work#
#########
$DiskData = Get-DiskData -VMName $VMname -Creds $Creds

$ViewHostWithStorage = Get-View -Id $VMView.Runtime.Host -Property Config.StorageDevice.ScsiLun
$VirtualSCSIController = $VMView.Config.Hardware.Device | Where {$_.DeviceInfo.Label -match "SCSI Controller"}
$VMDisks = @()
Foreach($Controller in $VirtualSCSIController){

    $VirtualDiskDevices = $VMView.Config.Hardware.Device | Where {$_.ControllerKey -eq $Controller.Key}
    Write-verbose $($Controller.key)
    Foreach($VirtualDiskDevice in $VirtualDiskDevices){
        $oScsiLun = $viewHostWithStorage.Config.StorageDevice.ScsiLun | ? {$_.UUID -eq $VirtualDiskDevice.Backing.LunUuid}
        $MatchingDisk = $DiskData | Where-Object {$_.SCSITarget -eq $VirtualDiskDevice.UnitNumber -and $_.SCSIBus -eq $Controller.BusNumber}
        
        $VMDisk = [pscustomobject]@{
            VM = $VMView.Name
            DiskFilePath = $VirtualDiskDevice.Backing.FileName
            VMDiskName = $VirtualDiskDevice.DeviceInfo.Label
            ScsiCanonicalName = $oScsiLun.CanonicalName
            VMDiskSizeinGB =  "{0:N0}" -f $($VirtualDiskDevice.CapacityinKB/1MB)
            SCSIController = $Controller.BusNumber
            SCSITarget = $VirtualDiskDevice.UnitNumber
            DriveLetter = $MatchingDisk.DeviceID
        }
        $VMDIsks += $VMDisk
    }
}

$DiskData | Sort-Object -Property Serial,SCSITarget | out-gridview

$VMDisks | Sort-object -Property Scsicontroller,scsitarget | out-gridview