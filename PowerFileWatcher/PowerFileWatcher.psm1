# File Watcher PowerShell Module
# http://powershell.codeplex.com

Function Start-FileWatcher
{
	param ( [string] $FileName = $(throw "Please specify a File Name"),
	[int] $TimeOut = $(throw "Please specify a TimeOut in Seconds"),
	[string] $ChangeType = $(throw "Please specify a Change Type [ Created | Deleted | Changed | Renamed ]"),
	[switch] $IncludeSubDirectories )
	
	$Loop = $true
	$TimeOut = $TimeOut * 1000	
	$ChangeTypes = @( "Created", "Deleted", "Changed", "Renamed" )
	
	if ( $ChangeTypes -notcontains $ChangeType )
	{
		throw "Please specify a Change Type [ Created | Deleted | Changed | Renamed ]"
	}
	
	while ( $Loop -eq $true )
	{
		$FileWatcher = New-Object System.IO.FileSystemWatcher
		$FileWatcher.Path = Split-Path $FileName
		$FileWatcher.Filter = Split-Path -Leaf $FileName
		$FileWatcher.EnableRaisingEvents = $true
		if ( $IncludeSubDirectories )
		{
			$FileWatcher.IncludeSubdirectories = $true
		}
		$FileWatcherResult = New-Object System.IO.WaitForChangedResult
		$FileWatcherResult = $FileWatcher.WaitForChanged($ChangeType,$TimeOut)
		if ( $FileWatcherResult.ChangeType -eq $ChangeType )
		{
			$RootName = $FileWatcher.Path
			$TreeName = $FileWatcherResult.Name
			$FullFileName = "$RootName\$TreeName"
			if ( $RootName -match "\\$" )
			{
				$FullFileName = "$RootName$TreeName"
			}
			return $FullFileName
			$Loop = $false
		}
		if ( $FileWatcherResult.TimedOut -eq $true )
		{
			return $false
			$Loop = $false
		}
	}
}

Export-ModuleMember -Function Start-FileWatcher