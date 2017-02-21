
$DebugPreference="Continue"

. "$PSScriptRoot\Install-WebApp.ps1"
$projectRoot = (Get-Item $PSScriptRoot ).Parent.FullName
Install-WebApp -TargetServer AppSvr -PhysicalPath "c:\WebSites\Explore.Angular" -AppName ExploreAngular -ProjectRoot $projectRoot


