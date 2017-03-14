# WinRm Settings for SCVMM Environment

## Running the script
### dot source
To run the script in an interactive PowerShell session, you must dot source the script.  This is simply loading the script into your session.  You do this by placing a single '.' (no quotes) in front of the path to the .ps1 file.

For example, if the WinRmSettings.ps1 file is located on the Adminstrators desktop I would load the file like this with dot sourcing:
```
PS> . c:\users\Administrator\Desktop\WinRmSettings.ps1
```
Notice that there is a space between the '.' and the path to the file.

### Description
There are two functions packaged in the script that can be used to view and configure WinRm settings within your SCVMM/Hyper-V Environment: Get-WinRmSettings and Set-WinRmSettings.

Each of these cmdlets takes an argument of a computer name (set to the local computer name by default) or a cluster name.  If a cluster name is used then the cmdlet will run the cmdlet on all nodes of the specified cluster.

#### Get-WinRmSettings
This command will retrieve a list of important WinRm Settings and return them as an object.

```
PS> Get-WinRmSettings
```
This command will retrieve the WinRm Settings on a specific Hyper-V Host (or any Windows Server)
```
PS> Get-WinRmSettings -ComputerName 'HYPERVHOST01'
```
This command will retrieve the WinRm Settings on all nodes of a cluster named 'cluster01'
```
PS> Get-WinRmSettings -ClusterName 'cluster01'
```

#### Set-WinRmSettings
This command will set the WinRm Settings to the recommended values.  These values can be overridden by providing parameter values to the settings listed below with the exception of configuring the WinRm process to be a stand alone process.  The SC configurations are currently baked into the cmdlet.

* MaxTimeoutMS = 1800000
* MaxConcurrentUserOps = 1500
* MaxConcurrentUsers = 100
* MaxProcessesPerShell = 100
* MaxShellsPerUser = 100
* MaxConcurrentUserOperationsPlugin = 400
* WinRm will also be configured to run as a stand alone process not attached to svchost


The Set-WinRmSettings cmdlet is ran the same way as the above examples.
```
PS> Set-WinRmSettings
PS> Set-WinRmSettings -ComputerName 'HYPERVHOST01'
PS> Set-WinRmSettings -ClusterName 'cluster01'
```
Additionally, if desired, settings can be overridden with parameter values.
```
PS> Set-WinRmSettings -ComputerName 'hypervhost02' -MaxTimeoutMS 185000 -MaxConcurrentUserOps 1000 -MaxConcurrentUsers 500
-MaxShellsPerUser 200 -MaxProcessesPerShell 200 -MaxConcurrentUserOperationsPlugin 500
```

