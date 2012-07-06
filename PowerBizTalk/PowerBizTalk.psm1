# BizTalk Administration PowerShell Module
# http://powershell.codeplex.com

# BizTalk Generic WMI Call
Function Invoke-BizTalkGenericWmiCall
{
	param ( [string] $Artifact,
	[string] $ArtifactChild,
	[string] $Action )

	if ( $Artifact -eq "HostInstance" )
	{
		$WMIQuery = Get-WmiObject -Class "MSBTS_$Artifact" -Namespace "root\MicrosoftBizTalkServer" -Filter "HostName='$ArtifactChild'"
	}
	else
	{
		$WMIQuery = Get-WmiObject -Class "MSBTS_$Artifact" -Namespace "root\MicrosoftBizTalkServer" -Filter "Name='$ArtifactChild'"
	}

	if ( $WMIQuery -eq $null )
	{
		Write-Output "ERROR : Unknown $Artifact [ $ArtifactChild ] !"
	}
	else
	{
		[string] $ObjectState = $WMIQuery.State

		switch ( $Artifact )
		{
			'Orchestration' { $StopState = "Stopped|Bound" ; $StartState = "Started" ; }
			'SendPortGroup' { $StopState = "Stopped|Bound" ; $StartState = "Started" ; }
			'SendPort' { $StopState = "Stopped|Bound" ; $StartState = "Started" ; }
			'ReceiveLocation' { $StopState = "Disabled" ; $StartState = "Enabled" ; }
			'HostInstance' { $StopState = "Stopped" ; $StartState = "Running" ; }
		}

		switch ( $Action )
		{
			'Start' { $ExpectedState = $StopState ; $WMICommand = '$WMIQuery.Start()' ; }
			'Stop' { $ExpectedState = $StartState ; $WMICommand = '$WMIQuery.Stop()' ; }
			'Enable' { $ExpectedState = $StopState ; $WMICommand = '$WMIQuery.Enable()' ; }
			'Disable' { $ExpectedState = $StartState ; $WMICommand = '$WMIQuery.Disable()' ; }
			'Enlist' { $ExpectedState = "Bound" ; $WMICommand = '$WMIQuery.Enlist()' ; }
			'Unenlist' { $ExpectedState = "$StopState|$StartState" ; $WMICommand = '$WMIQuery.Unenlist()' ; }
		}

		if ( $ObjectState -match $ExpectedState )
		{
			$WMICommit = Invoke-Expression -Command $WMICommand

			if ( ( $WMICommit ) -and ( $? -eq $true ) )
			{
				Write-Output "SUCCESS : $Action of $Artifact [ $ArtifactChild ]"
			}
			else
			{
				Write-Output "ERROR : Unable to $Action $Artifact [ $ArtifactChild ] !"
			}
		}
		else
		{
			Write-Output "$Artifact [ $ArtifactChild ] is already $WMIQueryState"
		}
	}
}

# BizTalk Catalog Explorer Assembly
Function Invoke-BizTalkEOM
{
	$BizTalkConnectionString = "SERVER=.;DATABASE=BizTalkMgmtDb;Integrated Security=SSPI"
	if ( ( Test-Path "HKLM:SOFTWARE\Microsoft\Biztalk Server\3.0\Administration" ) -eq $true )
	{
		$BizTalkMgmtDBServer = ( Get-ItemProperty "HKLM:SOFTWARE\Microsoft\Biztalk Server\3.0\Administration" ).MgmtDBServer
		$BizTalkMgmtDBName = ( Get-ItemProperty "HKLM:SOFTWARE\Microsoft\Biztalk Server\3.0\Administration" ).MgmtDBName
		$BizTalkConnectionString = "SERVER=$BizTalkMgmtDBServer;DATABASE=$BizTalkMgmtDBName;Integrated Security=SSPI"
	}
	$BizTalkCatalogExplorer = New-Object Microsoft.BizTalk.ExplorerOM.BtsCatalogExplorer
	$BizTalkCatalogExplorer.ConnectionString = $BizTalkConnectionString
	return $BizTalkCatalogExplorer
}

# Applications
Function Get-Application
{
	[CmdletBinding()]
	param (
		[ValidateNotNullOrEmpty()]
		[string] $Name )

	process
	{
		$BizTalkCatalogExplorer = Invoke-BizTalkEOM
		$Application = $BizTalkCatalogExplorer.Applications  | Where-Object { $_.Item -match "$Name" }
		$Application
	}
}
Function Start-Application
{
	[CmdletBinding()]
	param (
		[ValidateNotNullOrEmpty()]
		[Parameter(ValueFromPipelineByPropertyName=$true,Mandatory=$true)]
		[string] $Name )

	process
	{
		$BizTalkCatalogExplorer = Invoke-BizTalkEOM
		$BizTalkApplication = $BizTalkCatalogExplorer.Applications[$Name]
		if ( $BizTalkApplication.State -ne "Started" )
		{
			$BizTalkApplication.Start([Microsoft.BizTalk.ExplorerOM.ApplicationStartOption] "StartAll")
			$BizTalkCatalogExplorer.SaveChanges()
			if ( ( $BizTalkApplication ) -and ( $? -eq $true ) )
			{
				Write-Output "SUCCESS : Start of Application [ $Name ]"
			}
			else
			{
				Write-Output "ERROR : Unable to Start Application [ $Name ] !"
			}
		}
		else
		{
			Write-Output "Application [ $Name ] is already Started"
		}
	}
}
Function Stop-Application
{
	[CmdletBinding()]
	param (
		[ValidateNotNullOrEmpty()]
		[Parameter(ValueFromPipelineByPropertyName=$true,Mandatory=$true)]
		[string] $Name )

	process
	{
		$BizTalkCatalogExplorer = Invoke-BizTalkEOM
		$BizTalkApplication = $BizTalkCatalogExplorer.Applications[$Name]
		if ( $BizTalkApplication.State -ne "Stopped" )
		{
			$BizTalkApplication.Stop([Microsoft.BizTalk.ExplorerOM.ApplicationStopOption] ("DisableAllReceiveLocations","UnenlistAllOrchestrations","UnenlistAllSendPortGroups","UnenlistAllSendPorts","UndeployAllPolicies"))
			$BizTalkCatalogExplorer.SaveChanges()
			if ( ( $BizTalkApplication ) -and ( $? -eq $true ) )
			{
				Write-Output "SUCCESS : Stop of Application [ $Name ]"
			}
			else
			{
				Write-Output "ERROR : Unable to Stop Application [ $Name ] !"
			}
		}
		else
		{
			Write-Output "Application [ $Name ] is already Stopped"
		}
	}
}
#

# Orchestrations
Function Get-Orchestration
{
	[CmdletBinding()]
	param (
		[ValidateNotNullOrEmpty()]
		[string] $Name )

	process
	{
		Get-WmiObject -Class "MSBTS_Orchestration" -Namespace 'root\MicrosoftBizTalkServer' | Where-Object { $_.Item -match "$Name" }
	}
}
Function Start-Orchestration
{
	[CmdletBinding()]
	param (
		[ValidateNotNullOrEmpty()]
		[Parameter(ValueFromPipelineByPropertyName=$true,Mandatory=$true)]
		[string] $Name )

	process
	{
		Invoke-BizTalkGenericWmiCall -Action 'Start' -Artifact 'Orchestration' -ArtifactChild $Name
	}
}
Function Stop-Orchestration
{
	[CmdletBinding()]
	param (
		[ValidateNotNullOrEmpty()]
		[Parameter(ValueFromPipelineByPropertyName=$true,Mandatory=$true)]
		[string] $Name )

	process
	{
		Invoke-BizTalkGenericWmiCall -Action 'Stop' -Artifact 'Orchestration' -ArtifactChild $Name
	}
}
Function Register-Orchestration
{
	[CmdletBinding()]
	param (
		[ValidateNotNullOrEmpty()]
		[Parameter(ValueFromPipelineByPropertyName=$true,Mandatory=$true)]
		[string] $Name )

	process
	{
		Invoke-BizTalkGenericWmiCall -Action 'Enlist' -Artifact 'Orchestration' -ArtifactChild $Name
	}
}
Function Unregister-Orchestration
{
	[CmdletBinding()]
	param (
		[ValidateNotNullOrEmpty()]
		[Parameter(ValueFromPipelineByPropertyName=$true,Mandatory=$true)]
		[string] $Name )

	process
	{
		Invoke-BizTalkGenericWmiCall -Action 'Unenlist' -Artifact 'Orchestration' -ArtifactChild $Name
	}
}
#

# Send Port Groups
Function Get-SendPortGroup
{
	[CmdletBinding()]
	param (
		[ValidateNotNullOrEmpty()]
		[string] $Name )

	process
	{
		Get-WmiObject -Class "MSBTS_SendPortGroup" -Namespace 'root\MicrosoftBizTalkServer' | Where-Object { $_.Item -match "$Name" }
	}
}
Function Start-SendPortGroup
{
	[CmdletBinding()]
	param (
		[ValidateNotNullOrEmpty()]
		[Parameter(ValueFromPipelineByPropertyName=$true,Mandatory=$true)]
		[string] $Name )

	process
	{
		Invoke-BizTalkGenericWmiCall -Action 'Start' -Artifact 'SendPortGroup' -ArtifactChild $Name
	}
}
Function Stop-SendPortGroup
{
	[CmdletBinding()]
	param (
		[ValidateNotNullOrEmpty()]
		[Parameter(ValueFromPipelineByPropertyName=$true,Mandatory=$true)]
		[string] $Name )

	process
	{
		Invoke-BizTalkGenericWmiCall -Action 'Stop' -Artifact 'SendPortGroup' -ArtifactChild $Name
	}
}
Function Register-SendPortGroup
{
	[CmdletBinding()]
	param (
		[ValidateNotNullOrEmpty()]
		[Parameter(ValueFromPipelineByPropertyName=$true,Mandatory=$true)]
		[string] $Name )

	process
	{
		Invoke-BizTalkGenericWmiCall -Action 'Enlist' -Artifact 'SendPortGroup' -ArtifactChild $Name
	}
}
Function Unregister-SendPortGroup
{
	[CmdletBinding()]
	param (
		[ValidateNotNullOrEmpty()]
		[Parameter(ValueFromPipelineByPropertyName=$true,Mandatory=$true)]
		[string] $Name )

	process
	{
		Invoke-BizTalkGenericWmiCall -Action 'Unenlist' -Artifact 'SendPortGroup' -ArtifactChild $Name
	}
}
#

# Send Ports
Function Get-SendPort
{
	[CmdletBinding()]
	param (
		[ValidateNotNullOrEmpty()]
		[string] $Name )

	process
	{
		Get-WmiObject -Class "MSBTS_SendPort" -Namespace 'root\MicrosoftBizTalkServer' | Where-Object { $_.Item -match "$Name" }
	}
}
Function Start-SendPort
{
	[CmdletBinding()]
	param (
		[ValidateNotNullOrEmpty()]
		[Parameter(ValueFromPipelineByPropertyName=$true,Mandatory=$true)]
		[string] $Name )

	process
	{
		Invoke-BizTalkGenericWmiCall -Action 'Start' -Artifact 'SendPort' -ArtifactChild $Name
	}
}
Function Stop-SendPort
{
	[CmdletBinding()]
	param (
		[ValidateNotNullOrEmpty()]
		[Parameter(ValueFromPipelineByPropertyName=$true,Mandatory=$true)]
		[string] $Name )

	process
	{
		Invoke-BizTalkGenericWmiCall -Action 'Stop' -Artifact 'SendPort' -ArtifactChild $Name
	}
}
Function Register-SendPort
{
	[CmdletBinding()]
	param (
		[ValidateNotNullOrEmpty()]
		[Parameter(ValueFromPipelineByPropertyName=$true,Mandatory=$true)]
		[string] $Name )

	process
	{
		Invoke-BizTalkGenericWmiCall -Action 'Enlist' -Artifact 'SendPort' -ArtifactChild $Name
	}
}
Function Unregister-SendPort
{
	[CmdletBinding()]
	param (
		[ValidateNotNullOrEmpty()]
		[Parameter(ValueFromPipelineByPropertyName=$true,Mandatory=$true)]
		[string] $Name )

	process
	{
		Invoke-BizTalkGenericWmiCall -Action 'Unenlist' -Artifact 'SendPort' -ArtifactChild $Name
	}
}
#

# Receive Locations
Function Get-ReceiveLocation
{
	[CmdletBinding()]
	param (
		[ValidateNotNullOrEmpty()]
		[string] $Name )

	process
	{
		Get-WmiObject -Class "MSBTS_ReceiveLocation" -Namespace 'root\MicrosoftBizTalkServer' | Where-Object { $_.Item -match "$Name" }
	}
}
Function Enable-ReceiveLocation
{
	[CmdletBinding()]
	param (
		[ValidateNotNullOrEmpty()]
		[Parameter(ValueFromPipelineByPropertyName=$true,Mandatory=$true)]
		[string] $Name )

	process
	{
		Invoke-BizTalkGenericWmiCall -Action 'Enable' -Artifact 'ReceiveLocation' -ArtifactChild $Name
	}
}
Function Disable-ReceiveLocation
{
	[CmdletBinding()]
	param (
		[ValidateNotNullOrEmpty()]
		[Parameter(ValueFromPipelineByPropertyName=$true,Mandatory=$true)]
		[string] $Name )

	process
	{
		Invoke-BizTalkGenericWmiCall -Action 'Disable' -Artifact 'ReceiveLocation' -ArtifactChild $Name
	}
}
#

# Host Instances
Function Get-HostInstance
{
	[CmdletBinding()]
	param (
		[ValidateNotNullOrEmpty()]
		[string] $Name )

	process
	{
		Get-WmiObject -Class "MSBTS_HostInstance" -Namespace 'root\MicrosoftBizTalkServer' -Filter "HostType='1'" | Where-Object { $_.Item -match "$Name" }
	}
}
Function Start-HostInstance
{
	[CmdletBinding()]
	param (
		[ValidateNotNullOrEmpty()]
		[Parameter(ValueFromPipelineByPropertyName=$true,Mandatory=$true)]
		[string] $Name )

	process
	{
		Invoke-BizTalkGenericWmiCall -Action 'Start' -Artifact 'HostInstance' -ArtifactChild $Name
	}
}
Function Stop-HostInstance
{
	[CmdletBinding()]
	param (
		[ValidateNotNullOrEmpty()]
		[Parameter(ValueFromPipelineByPropertyName=$true,Mandatory=$true)]
		[string] $Name )

	process
	{
		Invoke-BizTalkGenericWmiCall -Action 'Stop' -Artifact 'HostInstance' -ArtifactChild $Name
	}
}
#

# Service Instances
Function Get-ServiceInstance
{
	[CmdletBinding()]
	param (
		[ValidateNotNullOrEmpty()]
		[string] $Name )

	process
	{
		Get-WmiObject -Class "MSBTS_ServiceInstance" -Namespace 'root\MicrosoftBizTalkServer' | Where-Object { $_.Item -match "$Name" -and $_.Item -ne "" }
	}
}
Function Remove-ServiceInstance
{
	[CmdletBinding()]
	param (
		[ValidateNotNullOrEmpty()]
		[Parameter(ValueFromPipelineByPropertyName=$true,Mandatory=$true)]
		$InstanceID )

	process
	{
		$WMIQuery = Get-WmiObject -Class "MSBTS_ServiceInstance" -Namespace 'root\MicrosoftBizTalkServer' -Filter "InstanceID='$InstanceID'"
		$WMICommit = $WMIQuery.Terminate()
		if ( ( $WMICommit ) -and ( $? -eq $true ) )
		{
			Write-Output "SUCCESS : Remove of ServiceInstance [ $InstanceID ]"
		}
		else
		{
			Write-Output "ERROR : Unable to Remove ServiceInstance [ $InstanceID ] !"
		}
	}
}
#

Export-ModuleMember -Function Get-*, Start-*, Stop-*, Enable-*, Disable-*, Register-*, Unregister-*, Remove-*