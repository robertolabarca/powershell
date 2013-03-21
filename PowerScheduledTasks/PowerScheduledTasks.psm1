# Windows Scheduled Tasks Management PowerShell Module
# http://powershell.codeplex.com
Import-LocalizedData -BindingVariable LengTable

function Get-ScheduledTaskFilterby{
    [CmdletBinding()]
    param(
        [string] 
        [ValidateSet("Running", "Not Running", "Disabled", "Listo", "Deshabilitado")] 
        $TaskStatus=$LengTable.statusnotrun
    )
    $resu= Get-ScheduledTask | where {$_.TaskStatus -eq $TaskStatus}
    return $resu
}

Function Get-winver{
    $vtemp=[Environment]::OSVersion.Version.ToString()
    if ($vtemp -match "6.2.9200"){
        "8"
    }
    else{
        "2003"
    }

 }

Function Get-ScheduledTask
{
	[CmdletBinding()]
	param (
		[ValidateNotNullOrEmpty()]
        [Parameter(ValueFromPipelineByPropertyName=$true,ValueFromPipeline=$true)]
		[string] $TaskName,
		[string] $HostName )
	
	process
	{
		if ( $HostName ) { $HostName = "/S $HostName" }
		$ScheduledTasks = SCHTASKS.EXE /QUERY /FO CSV /NH $HostName
		foreach ( $Item in $ScheduledTasks )
		{
			if ( $Item -ne "" )
			{
				$Item = $Item -replace("""|\s","")
				$SplitItem = $Item -split(",")
				$ScheduledTaskName = $SplitItem[0]
                Write-Host $ScheduledTaskName
                $ScheduledTaskStatus = if ("", $null -contains $SplitItem[3]) {$LengTable.statusnotrun} else {$lengTable.statusrun}
                $vtem=Get-winver
                  if ("2008","7","8" -match $vtem){
                    $ScheduledTaskStatus = if (($LengTable.statusnotrun -eq $ScheduledTaskStatus) -and ($SplitItem[2] -eq $LengTable.statusdisa)) {$LengTable.statusdisa} else {$LengTable.statusnotrun}    
                   }
                else{
                    $ScheduledTaskStatus = if (($LengTable.statusnotrun -eq $ScheduledTaskStatus) -and ($SplitItem[1] -eq $LengTable.statusdisa)) {$LengTable.statusdisa} else {$LengTable.statusnotrun}        
                }
				
				if ( $ScheduledTaskName -ne "" )
				{
					$objScheduledTaskName = New-Object System.Object
	    			$objScheduledTaskName | Add-Member -MemberType NoteProperty -Name TaskName -Value $ScheduledTaskName
					$objScheduledTaskName | Add-Member -MemberType NoteProperty -Name TaskStatus -Value $ScheduledTaskStatus
					$objScheduledTaskName | Where-Object { $_.TaskName -match $TaskName }
				}
			}
		}
	}
}


Function Start-ScheduledTask
{
	[CmdletBinding()]
	param (
		[ValidateNotNullOrEmpty()]
		[Parameter(ValueFromPipelineByPropertyName=$true,Mandatory=$true)]
		[string] $TaskName,
		[string] $HostName )

	process
	{
		if ( $HostName ) { $HostName = "/S $HostName" }
		SCHTASKS.EXE /RUN /TN $TaskName $HostName
	}
}
Function Stop-ScheduledTask
{
	[CmdletBinding()]
	param (
		[ValidateNotNullOrEmpty()]
		[Parameter(ValueFromPipelineByPropertyName=$true,Mandatory=$true)]
		[string] $TaskName,
		[string] $HostName )

	process
	{
		if ( $HostName ) { $HostName = "/S $HostName" }
		SCHTASKS.EXE /END /TN $TaskName $HostName
	}
}

Export-ModuleMember -Function *

