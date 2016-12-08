$VIServers = @('AM1-VCenter','AP1-VCenter','EM1-VCenter','EM1APVM006','AM1APVM006')
$VCenterCredential = Get-Credential
Connect-VIServer -Server $VIServers -Credential $VCenterCredential -ErrorAction Stop | Out-Null

$Datacenters = Get-Datacenter
$CDDrives = @()
[Array] $vmList = @( Get-VM -Location $Datacenters | Sort Name );

foreach ( $vmItem in $vmList )
{
    [Array] $vmCdDriveList = @( Get-CDDrive -VM $vmItem );

    foreach ( $vmCdDriveItem in $vmCdDriveList )
    {
        [String] $insertedElement = "";
        [String] $connectionType  = "";

        switch ( $vmCdDriveItem )
        {
            { $_.IsoPath      } { $insertedElement = $_.IsoPath;      $connectionType = "ISO";           break; }
            { $_.HostDevice   } { $insertedElement = $_.HostDevice;   $connectionType = "Host Device";   break; }
            { $_.RemoteDevice } { $insertedElement = $_.RemoteDevice; $connectionType = "Remote Device"; break; }
            default             { $insertedElement = "None";          $connectionType = "Client Device"; break; }
        }

        $output = New-Object -TypeName PSObject;

        $obj = New-Object -TypeName PSObject -Property @{
            VM                   = $vmItem
            'CD-Drive'           = $vmCdDriveItem.Name
            Connection           = $connectionType
            Inserted             = $insertedElement
            Connected            = $vmCdDriveItem.ConnectionState.Connected
            'Start Connected'    = $vmCdDriveItem.ConnectionState.StartConnected
            'Allow Guest Control'= $vmCdDriveItem.ConnectionState.AllowGuestControl
        }

        $CDDrives += $Obj
    }
}

$Obj | select -Property VM, `
                        'CD-Drive', `
                        Connection, `
                        Inserted, `
                        Connected, `
                        'Start Connected', `
                        'Allow Guest Control' | Out-gridview