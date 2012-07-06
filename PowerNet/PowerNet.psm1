# Network Utilities PowerShell Module
# http://powershell.codeplex.com

Function Send-TCPMessage
{
	param ( [ValidateNotNullOrEmpty()]
	[string] $EndPoint,
	[int] $Port,
	[string] $Message )
	
	$IP = [System.Net.Dns]::GetHostAddresses($EndPoint)
	$Address = [System.Net.IPAddress]::Parse($IP)
	$Socket = New-Object System.Net.Sockets.TCPClient($Address,$Port)
	$Stream = $Socket.GetStream()
	$Writer = New-Object System.IO.StreamWriter($Stream)
	$Writer.AutoFlush = $true
	$Writer.NewLine = $true
	$Writer.Write($Message)
	$Socket.Close()
}
Function Receive-TCPMessage
{
	param ( [ValidateNotNullOrEmpty()]
	[int] $Port )

	try
	{
		$EndPoint = New-Object System.Net.IPEndPoint([System.Net.IPAddress]::Loopback,$Port)
		$Socket = New-Object System.Net.Sockets.TCPListener($EndPoint)
		$Socket.Start()
		$Socket = $Socket.AcceptTCPClient()
		$EncodedText = New-Object System.Text.ASCIIEncoding
		$Stream = $Socket.GetStream()
		$Buffer = New-Object System.Byte[] $Socket.ReceiveBufferSize		
		while( $Bytes = $Stream.Read($Buffer,0,$Buffer.Length) )
		{
		    $Stream.Write($Buffer,0,$Bytes)
		    Write-Output $EncodedText.GetString($Buffer,0,$Bytes)
		}
		$Socket.Close()
		$Socket.Stop()
	}
	catch{}
}
Function Send-UDPMessage
{
	param ( [ValidateNotNullOrEmpty()]
	[string] $EndPoint,
	[int] $Port,
	[string] $Message )
	
	$IP = [System.Net.Dns]::GetHostAddresses($EndPoint)
	$Address = [System.Net.IPAddress]::Parse($IP)
	$EndPoint = New-Object System.Net.IPEndPoint($Address,$Port)
	$Socket = New-Object System.Net.Sockets.UDPClient
	$EncodedText = [Text.Encoding]::ASCII.GetBytes($Message)
	$SendMessage = $Socket.Send($EncodedText,$EncodedText.Length,$EndPoint)
	$Socket.Close()
}
Function Receive-UDPMessage
{
	param ( [ValidateNotNullOrEmpty()]
	[int] $Port )
	
	try
	{
		$EndPoint = New-Object System.Net.IPEndPoint([System.Net.IPAddress]::Loopback,$Port)
		$UDPClient = New-Object System.Net.Sockets.UDPClient($Port)
		$ReceiveMessage = $UDPClient.Receive([System.Management.Automation.PSReference]$EndPoint)
		[System.Text.Encoding]::ASCII.GetString($ReceiveMessage)
	}
	catch{}
}
Function Test-TCPPort
{
	param ( [ValidateNotNullOrEmpty()]
	[string] $EndPoint = $(throw "Please specify an EndPoint (Host or IP Address)"),
	[string] $Port = $(throw "Please specify a Port") )
	
	try
	{
		$TimeOut = 1000
		if ( $IP = [System.Net.Dns]::GetHostAddresses($EndPoint) )
		{
			$Address = [System.Net.IPAddress]::Parse($IP)
			$Socket = New-Object System.Net.Sockets.TCPClient
			$Connect = $Socket.BeginConnect($Address,$Port,$null,$null)
			if ( $Connect.IsCompleted )
			{
				$Wait = $Connect.AsyncWaitHandle.WaitOne($TimeOut,$false)			
				if(!$Wait) 
				{
					$Socket.Close() 
					return $false 
				} 
				else
				{
					$Socket.EndConnect($Connect)
					$Socket.Close()
					return $true
				}
			}
			else
			{
				return $false
			}
		}
		else
		{
			return $false
		}
	}
	catch{}
}
Function Enable-Monitoring
{
	Param 
	( 
		[ValidateNotNullOrEmpty()]
		[Parameter(Mandatory = $true)] [string] $Url,
		[Parameter(Mandatory = $true)] [Int64] $Port,
		[Parameter(Mandatory = $true)] [string] $Client,
		[Parameter(Mandatory = $true)] [string] $Column
	)
	
	try
	{
		$Socket = New-Object System.Net.Sockets.TCPClient($Url,$Port)
		$Stream = $Socket.GetStream()
		$Writer = New-Object System.IO.StreamWriter($Stream)
		$Writer.AutoFlush = $true
		$Writer.NewLine = $true
		$Writer.Write("enable $Client.$Column")
		$Socket.Close()
	}
	catch
	{
		Write-Host "ERROR :`r`n$_"
	}
}
Function Disable-Monitoring
{
	Param 
	( 
		[ValidateNotNullOrEmpty()]
		[Parameter(Mandatory = $true)] [string] $Url,
		[Parameter(Mandatory = $true)] [Int64] $Port,
		[Parameter(Mandatory = $true)] [string] $Client,
		[Parameter(Mandatory = $true)] [string] $Column,
		[string] $Message,
		[string] $Duration
	)
	
	try
	{
		if ($Duration)
		{
			$Message = "disable $Client.$Column $Duration $Message"
		}
		else
		{
			$Message = "disable $Client.$Column"
		}
		$Socket = New-Object System.Net.Sockets.TCPClient($Url,$Port)
		$Stream = $Socket.GetStream()
		$Writer = New-Object System.IO.StreamWriter($Stream)
		$Writer.AutoFlush = $true
		$Writer.NewLine = $true
		$Writer.Write($Message)
		$Socket.Close()
	}
	catch
	{
		Write-Host "ERROR :`r`n$_"
	}
}
Function Write-Monitoring
{
	Param 
	( 
		[ValidateNotNullOrEmpty()]
		[Parameter(Mandatory = $true)] [string] $Url,
		[Parameter(Mandatory = $true)] [Int64] $Port,
		[Parameter(Mandatory = $true)] [string] $Client,
		[Parameter(Mandatory = $true)] [string] $Column,
		[Parameter(Mandatory = $true)] [string] $Message,
		[ValidateSet('red','yellow','green')] [string] $Color = "green"
	)
	
	try
	{
		$Socket = New-Object System.Net.Sockets.TCPClient($Url,$Port)
		$Stream = $Socket.GetStream()
		$Writer = New-Object System.IO.StreamWriter($Stream)
		$Writer.AutoFlush = $true
		$Writer.NewLine = $true
		$Writer.Write("status $Client.$Column $Color $Message")
		$Socket.Close()
	}
	catch
	{
		Write-Host "ERROR :`r`n$_"
	}
}

Export-ModuleMember -Function *