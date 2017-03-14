function Set-WinRmSettings
{
	[CmdletBinding(DefaultParameterSetName = "Host")]

	param
	(
		[Parameter(ParameterSetName = "Host", Position=0)]
		[String] $ComputerName = $env:ComputerName,

		[Parameter(ParameterSetName = "Cluster")]
		[String] $ClusterName,

		[Parameter(ParameterSetName = "Host")]
		[Parameter(ParameterSetName = "Cluster")]
		[String] $MaxTimeoutMS = "1800000",

		[Parameter(ParameterSetName = "Host")]
		[Parameter(ParameterSetName = "Cluster")]
		[String] $MaxConcurrentUserOps = "1500",

        [Parameter(ParameterSetName = "Host")]
        [Parameter(ParameterSetName = "Cluster")]
        [String] $MaxConcurrentUsers = "100",

        [Parameter(ParameterSetName = "Host")]
        [Parameter(ParameterSetName = "Cluster")]
        [String] $MaxProcessesPerShell = "100",

        [Parameter(ParameterSetName = "Host")]
        [Parameter(ParameterSetName = "Cluster")]
        [String] $MaxShellsPerUser = "100",

        [Parameter(ParameterSetName = "host")]
        [Parameter(ParameterSetName = "Cluster")]
        [Int] $MaxConcurrentUserOperationsPlugin = 400
	)

	$computers = @()
	if ($pscmdlet.ParameterSetName -eq "Cluster")
	{
		$computers = (Get-ClusterNode -Cluster $ClusterName).Name
	}
	else
	{
		$computers = $computerName
	}

	foreach ($c in $computers)
	{
		Invoke-Command -ComputerName $c -ArgumentList $MaxTimeoutMS, $MaxConcurrentUserOps, $MaxConcurrentUsers, $MaxProcessesPerShell, $MaxShellsPerUser, $MaxConcurrentUserOperationsPlugin -ScriptBlock {
			param ($MaxTimeoutMS, $MaxConcurrentUserOps, $MaxConcurrentUsers, $MaxProcessesPerShell, $MaxShellsPerUser, $MaxConcurrentUserOperationsPlugin)
			$changes = 0
			Write-Host "Executing on $($env:ComputerName)" -ForegroundColor Magenta

			function Get-WinRmTimeoutMS {
				((Invoke-Expression "winrm get winrm/config" | Select-String 'MaxTimeoutms')).Line.Split("=")[1].Trim()
			}

			function Get-WinRmMaxConcurrentOps {
				((Invoke-Expression 'winrm get winrm/config/Service' | Select-String 'MaxConcurrentOperationsPerUser')).Line.Split("=")[1].Trim()
			}
            function Get-MaxConUsers {
                ((Invoke-Expression 'winrm get winrm/config/winrs' | Select-String 'MaxConcurrentUsers')).Line.Split("=")[1].Trim()
            }
            function Get-MaxProcPerShell {
                ((Invoke-Expression 'winrm get winrm/config/winrs' | Select-String 'MaxProcessesPerShell')).Line.Split("=")[1].Trim()
            }
            function Get-MaxShellsPerUser {
                ((Invoke-Expression 'winrm get winrm/config/winrs' | Select-String 'MaxShellsPerUser')).Line.Split("=")[1].Trim()
            }
            function Get-MaxConOpsUserPS {
                (get-item "WsMan:\localhost\plugin\WMI Provider\Quotas\MaxConcurrentOperationsPerUser").Value
            }
            function Get-SCWinRmOwnsProcess {
                (sc.exe query winrm | select-string 'type').line -match "Own_Process"
            }
            function Get-SCWinMgmtOwnsProcess {
                (sc.exe query winmgmt | select-string 'type').line -match "Own_Process"
            }

			try
			{
				$timeout = Get-WinRmTimeoutMS
				if ($timeout -eq $MaxTimeoutMS)
				{
					Write-host "  The timeout winrm setting is already set to $MaxTimeoutMS" -ForegroundColor Green
				}
				else
				{
					$timeoutCmd = "winrm set winrm/config '@{MaxTimeoutms=`"$MaxTimeoutMS`"}'"
					Write-Host "  Setting the max timeout for winrm..." -NoNewline
					Invoke-Expression $timeoutCmd -ErrorAction Stop | out-null
					
					if ($timeout -ne (Get-WinRmTimeoutMS)) 
					{
						Write-host "OK" -ForegroundColor Green 
						$changes++ 
					}
					else
					{
						write-host "Error" -ForegroundColor Red 
					}
				}

				$max = Get-WinrmMaxConcurrentOps
				if ($max -eq $MaxConcurrentUserOps)
				{
					Write-host "  The max ops per user is already set to $MaxConcurrentUserOps" -ForegroundColor Green
				}
				else
				{
					Write-Host "  Setting the max operations per user..." -NoNewline
					$maxCmd = "winrm set winrm/config/Service '@{MaxConcurrentOperationsPerUser=`"$MaxConcurrentUserOps`"}'"
					Invoke-Expression $maxCmd -ErrorAction Stop | out-null				
					if ($maxCmd -ne (Get-WinRmMaxConcurrentOps)) 
					{
						Write-host "OK" -ForeGroundColor Green 
						$changes++
					}
					Else
					{
						Write-Host "Error" -foregroundcolor Red 
					}
				}

                $certCmd = "winrm set winrm/config/service '@{CertificateThumbprint=`"`"}'"

                $maxConUsers = Get-MaxConUsers
                
                if ($maxConUsers -eq $MaxConcurrentUsers)
                {
                    Write-Host "  The max concurrent users is already set to $MaxConcurrentUsers" -ForegroundColor Green
                }
                else
                {
                    Write-Host "  Setting the max concurrent users..." -NoNewline
                    $MaxConcurrentUsersCmd = "winrm set winrm/config/winrs '@{MaxConcurrentUsers=`"$MaxConcurrentUsers`"}'"
                    Invoke-Expression $MaxConcurrentUsersCmd -ErrorAction Stop | out-null
                    if ($maxConUsers -ne (Get-MaxConUsers))
                    {
                        Write-Host "OK" -ForegroundColor Green
                        $changes++
                    }
                    else
                    {
                        Write-HOst "Error" -ForegroundColor Red
                    }
                }

                $maxProcs = Get-MaxProcPerShell
                if ($maxProcs -eq $MaxProcessesPerShell)
                {
                    Write-Host "  The max processes per shell is already set to $MaxProcessesPerShell" -ForegroundColor Green
                }
                else
                {
                    Write-Host "  Setting the max processes per shell..." -NoNewline
                    $MaxProcessesPerShellCmd = "winrm set winrm/config/winrs '@{MaxProcessesPerShell=`"$MaxProcessesPerShell`"}'"
                    Invoke-Expression $MaxProcessesPerShellCmd -ErrorAction Stop | Out-Null
                    if ($maxProcs -ne (Get-MaxProcPerShell))
                    {
                        Write-host "OK" -ForegroundColor Green
                        $changes++
                    }
                    else
                    {
                        Write-Host "Error" -ForegroundColor Red
                    }
                }

                $maxShells = Get-MaxShellsPerUser
                if ($maxShells -eq $MaxShellsPerUser)
                {
                    write-host "  The max shells per user is already set to $MaxShellsPerUser" -ForegroundColor Green   
                }
                else
                {
                    Write-host "  Setting the max shells per user..." -NoNewline
                    $maxShellsPerUserCmd = "winrm set winrm/config/winrs '@{MaxShellsPerUser=`"$MaxShellsPerUser`"}'"
                    Invoke-expression $maxShellsPerUserCmd -ErrorAction Stop | Out-Null
                    if ($maxShells -ne (Get-MaxShellsPerUser))
                    {
                        Write-Host "OK" -ForegroundColor Green
                        $changes++
                    }
                    else
                    {
                        Write-Host "Error" -ForegroundColor Red
                    }

                }

                $maxConOpsUserPS = Get-MaxConOpsUserPS
                if ($MaxConcurrentUserOperationsPlugin -eq $maxConOpsUserPS)
                {
                    Write-Host "  The max concurrent ops per user plug in is already set to $MaxConcurrentUserOperationsPlugin" -ForegroundColor Green
                }
                else
                {
                    Write-Host "  Setting the max concurrent ops per user plug-in..." -NoNewline
                    try {
                        $out = Set-Item -Path "WSMan:\localhost\Plugin\WMI Provider\Quotas\MaxConcurrentOperationsPerUser" $MaxConcurrentUserOperationsPlugin -ErrorAction Stop | Out-Null
                        Write-Host "OK" -ForegroundColor Green
                        $changes++
                    }
                    catch {
                        Write-Host 'Error' -ForegroundColor Red                        
                    }
                }

                $winrmSC = Get-SCWinRmOwnsProcess
                if ($winrmSC -eq $true)
                {
                    Write-Host "  WinRm is already set to own the process" -ForegroundColor Green
                }
                else
                {
                    Write-HOst "  Setting WinRm to own the process..." -NoNewline
                    $out = & sc.exe config winrm type=own
                    if ($out -match "Success")
                    {
                        Write-Host "OK" -ForegroundColor Green
                        $changes++
                    }
                    else
                    {
                        Write-Host "Error" -ForegroundColor Red
                    }
                }

                $winMgmtSC = Get-SCWinMgmtOwnsProcess
                if ($winMgmtSC -eq $true)
                {
                    Write-Host "  WinMgmt is already set to own process" -ForegroundColor Green
                }
                else
                {
                    Write-Host "  Setting WinMgmt to own the process..." -NoNewline
                    $out = & sc.exe config winmgmt type=own
                    if ($out -match "Success")
                    {
                        Write-host "OK" -ForegroundColor Green
                        $changes++
                    }
                    else
                    {
                        Write-Host "Error" -ForegroundColor Red
                    }
                }
                
                


                Write-Host "  Running winrm quickconfig"
                $winRmQuickConfigCmd = "winrm quickconfig"
                Invoke-Expression $winRmQuickConfigCmd

				if ($changes -gt 0) { Write-host "  $($env:ComputerName): $changes changes were made.  A reboot is needed for changes to take effect."}
			}
			catch
			{
				Write-Error $error[0].Exception.ToString()
			}
		}

	}
}

function Get-WinRmSettings
{
	[CmdletBinding(DefaultParameterSetName = "Host")]

	param
	(
		[Parameter(ParameterSetName = "Host", Position=0)]
		[String] $ComputerName = $env:ComputerName,

		[Parameter(ParameterSetName = "Cluster")]
		[String] $ClusterName
	)

	$computers = @()
	if ($pscmdlet.ParameterSetName -eq "Cluster")
	{
		$computers = (Get-ClusterNode -Cluster $ClusterName).Name
	}
	else
	{
		$computers = $computerName
	}

	$retObjs = @()
	foreach ($c in $computers) 
	{
		$retObjs += Invoke-Command -ComputerName $c -ScriptBlock {

			function Get-WinRmTimeoutMS {
				((Invoke-Expression "winrm get winrm/config" | Select-String 'MaxTimeoutms')).Line.Split("=")[1].Trim()
			}

			function Get-WinRmMaxConcurrentOps {
				((Invoke-Expression 'winrm get winrm/config/Service' | Select-String 'MaxConcurrentOperationsPerUser')).Line.Split("=")[1].Trim()
			}
            function Get-MaxConUsers {
                ((Invoke-Expression 'winrm get winrm/config/winrs' | Select-String 'MaxConcurrentUsers')).Line.Split("=")[1].Trim()
            }
            function Get-MaxProcPerShell {
                ((Invoke-Expression 'winrm get winrm/config/winrs' | Select-String 'MaxProcessesPerShell')).Line.Split("=")[1].Trim()
            }
            function Get-MaxShellsPerUser {
                ((Invoke-Expression 'winrm get winrm/config/winrs' | Select-String 'MaxShellsPerUser')).Line.Split("=")[1].Trim()
            }
            function Get-MaxConOpsUserPS {
                (get-item "WsMan:\localhost\plugin\WMI Provider\Quotas\MaxConcurrentOperationsPerUser").Value
            }
            function Get-SCWinRmOwnsProcess {
                (sc.exe query winrm | select-string 'type').line -match "Own_Process"
            }
            function Get-SCWinMgmtOwnsProcess {
                (sc.exe query winmgmt | select-string 'type').line -match "Own_Process"
            }

			$retObj = New-Object -TypeName psobject 
			Add-Member -InputObject $retObj -MemberType NoteProperty -Name "Computer" -Value $env:ComputerName | Out-null
			Add-Member -InputObject $retObj -MemberType NoteProperty -Name 'MaxTimeoutMS' -Value $(Get-WinRmTimeoutMS) | out-null
			Add-Member -InputObject $retObj -MemberType NoteProperty -Name 'MaxConcurrentOpsPerUser' -Value $(Get-WinRmMaxConcurrentOps) | out-null
			Add-Member -InputObject $retObj -MemberType NoteProperty -Name 'MaxConcurrentUsers' -Value $(Get-MaxConUsers) | Out-Null
			Add-Member -InputObject $retObj -MemberType NoteProperty -Name 'MaxProcessesPerShell' -Value $(Get-MaxProcPerShell) | Out-Null
			Add-Member -InputObject $retObj -MemberType NoteProperty -Name 'MaxShellsPerUser' -Value $(Get-MaxShellsPerUser) | Out-Null
			Add-Member -InputObject $retObj -MemberType NoteProperty -Name 'MaxConcurrentOpsQuota' -Value $(Get-MaxConOpsUserPS) | Out-Null
			Add-Member -InputObject $retObj -MemberType NoteProperty -Name 'SCWinRmOwnsProcess' -Value $(Get-SCWinRmOwnsProcess) | Out-Null
			Add-Member -InputObject $retObj -MemberType NoteProperty -Name 'SCWinRmMgmtOwnsProcess' -Value $(Get-SCWinMgmtOwnsProcess) | Out-Null
			return $retObj
		}
	}

	return $retObjs
}