$VIServers = @('AM1-VCenter','AP1-VCenter','EM1-VCenter','EM1APVM006','AM1APVM006')
$VCenterCredential = Get-Credential
Connect-VIServer -Server $VIServers -Credential $VCenterCredential -ErrorAction Stop | Out-Null

$Datacenters = Get-Datacenter
[Array]$Snapshots = @()
[Array] $vmList = @( Get-VM -Location $Datacenters | Sort Name );

ForEach ( $vmItem in $vmList )
{
    [Array] $vmSnapshotList = @( Get-Snapshot -VM $vmItem );

    foreach ( $snapshotItem in $vmSnapshotList )
    {
        $vmProvisionedSpaceGB = [Math]::Round( $vmItem.ProvisionedSpaceGB, 2 );
        $vmUsedSpaceGB        = [Math]::Round( $vmItem.UsedSpaceGB,        2 );
        $snapshotSizeGB       = [Math]::Round( $snapshotItem.SizeGB,       2 );
        $snapshotAgeDays      = ((Get-Date) - $snapshotItem.Created).Days;

        $obj = New-Object -TypeName PSObject -Property @{
            VM                       = $vmItem
            Name                     = $snapshotItem.Name
            Description              = $snapshotItem.Description
            Created                  = $snapshotItem.Created
            'Age in Days'            = $snapshotAgeDays
            'Parent Snapshot'        = $snapshotItem.ParentSnapshot.Name
            'Is Current Snapshot'    = $snapshotItem.IsCurrent
            'Snapshot Size (GB)'     = $vmProvisionedSpaceGB
            'Provisioned Space (GB)' = $vmProvisionedSpaceGB
            'Used Space (GB)'        = $vmUsedSpaceGB
            'Power State'            = $snapshotItem.PowerState
        }

        $Snapshots += $obj
    }
}

$Snapshots | select -Property VM, `
                             Name, `
                             Description, `
                             Created, `
                             'Age in Days', `
                             'Parent Snapshot', `
                             'Is Current Snapshot', `
                             'Snapshot Size (GB)', `
                             'Provisioned Space (GB)', `
                             'Used Space (GB)', `
                             'Power State' ` | Out-Gridview