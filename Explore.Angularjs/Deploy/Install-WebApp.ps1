<#
Installs app on target server.
Assumptions: Target server has IIS installed on it.  This must be run as Admin to work.
#>

$ErrorActionPreference="Stop"

Import-Module -Name D:\dev\git\PSLib\Craftsmaneer-Main.psm1 -Force -Scope Local

function Install-WebApp
{
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true)]$TargetServer,
		[Parameter(Mandatory=$true)]$PhysicalPath,
		[Parameter(Mandatory=$true)]$AppName,
		[Parameter(Mandatory=$true)]$ProjectRoot,
		$WebSite = "Default Web Site",
		[switch]$Overwrite,
		$ProjectBin="$ProjectRoot\bin",
		$ContentRoot=$ProjectRoot,
		[string[]]$IncludeDirs = @("app","Content","fonts","Scripts","Views"),
		[string[]]$includeFiles = @("web.config", "global.asax", "favicon.ico", "Project_Readme.html")

	)
	Write-Host "Starting Install of $AppName to $TargetServer..."
	
		Write-Debug "`$TargetServer=$TargetServer"
		Write-Debug "`$PhysicalPath=$PhysicalPath"
		Write-Debug "`$AppName=$AppName"
		Write-Debug "`$ProjectRoot=$ProjectRoot"
		Write-Debug "`$WebSite=$WebSite"
		Write-Debug "`$Overwrite=$Overwrite"
		Write-Debug "`$ProjectBin=$ProjectBin"
		Write-Debug "`$ContentRoot=$ContentRoot"
		Write-Debug "`$IncludeDirs=$IncludeDirs"
		Write-Debug "`$includeFiles=$includeFiles"

	$virtualPath = "$appName"
	$remotePath = "\\{0}\{1}" -f $targetServer, ($physicalPath -replace ":", "$")

	$cred = Get-MyCredential -ComputerName $targetServer -ErrorAction Stop
	$session = New-PSSession -ComputerName $targetServer -Credential $cred


	if (!(Test-Path $remotePath) -or $Overwrite)
	{
		Write-Host "Perforing intial web app configuration..."
		New-Item $remotePath -ItemType Directory -Force | Out-Null

		$cmd = {
			Import-Module WebAdministration
			$appPoolIISPath = "IIS:\AppPools\$using:appName"
			if (Test-Path $appPoolIISPath)
			{
				Remove-Item $appPoolIISPath -Recurse
			}
			New-Item $appPoolIISPath
			Set-ItemProperty -Path $appPoolIISPath -Name managedRuntimeVersion -Value 'v4.0'
		
			$webAppIISPath = "IIS:\Sites\$using:WebSite\$using:AppName"
			if (Test-Path $webAppIISPath)
			{
				Write-Host "$webAppIISPath exists, removing it..."
				Remove-Item $webAppIISPath -Recurse
			}
			New-WebApplication -Site $using:webSite -Name $using:virtualPath -PhysicalPath $using:physicalPath -ApplicationPool $using:appName  -Force
		}
		Invoke-Command -Session $session -ScriptBlock $cmd
	}
	
	Invoke-Command -Session $session -ScriptBlock {Import-Module WebAdministration; Stop-WebAppPool -Name $using:AppName }
	

	Write-Host "Updating files..."
	gci $remotePath | Remove-Item -Recurse -Force;   
	$IncludeDirs | %{ Copy-Item "$ContentRoot\$_"  "$remotePath\$_" -Recurse -Force }
	$includeFiles | %{ Copy-Item "$ContentRoot\$_"  "$remotePath\$_" -Force }
	Copy-Item $ProjectBin (Join-Path $remotePath bin) -Recurse -Force
	

	#restart
	Invoke-Command -Session $session -ScriptBlock {Import-Module WebAdministration; Start-WebAppPool -Name $using:AppName }

	# clean up	
	Remove-PSSession -Session $session
	Write-Host "Install Complete."

}