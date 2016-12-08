Function Get-GuestOSFromVMWare{
    Param
    (
        $VM
    )

    Try{
        $GuestOS = $VM | Get-View -ErrorAction Stop
        $GuestOS = $GuestOS.config.guestfullname
    }
    Catch [System.Exception]{
        Add-content -Path "c:\temp\errors\$($VM.name).txt" -Value $($_.Exception.Message)
        $GuestOS = Get-GuestOSFromAD -VM $VM
    }
    Finally
    {
        If($GuestOS -eq '' -or $GuestOS -eq $Null){
            $GuestOS = ''
            Write-Output $GuestOS
        }
        Else{
            Write-Output $GuestOS
        }
    }
    
}

Import-Module VMware.VimAutomation.Core 
$VIServers = @('AM1-VCenter','AP1-VCenter','EM1-VCenter','EM1APVM006','AM1APVM006')
$VCenterCredential = Get-Credential
Connect-VIServer -Server $VIServers -Credential $VCenterCredential -ErrorAction Stop | Out-Null

[Array]$Results = @()
[Array]$VMList = Get-VM | sort-object -Property Name

Foreach($VM in $VMList){

    If($VM.ExtensionData.Guest.ToolsStatus -ne "toolsOk"){
        $obj = New-Object -TypeName PSObject -Property @{
            VM               = $VM.name
            OS               = Get-GuestOSFromVMWare -VM $VM
            "Tools Version"  = $VM.ExtensionData.Guest.Toolsversion
        }
        Write-Output "$($VM.name) Checked"
        $Results += $Obj
    }
}

$Results | select -property VM, OS, "Tools Version" | Out-GridView