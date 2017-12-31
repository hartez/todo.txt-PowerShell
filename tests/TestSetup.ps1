#
# TestSetup.ps1
#

function EnsureTestEnvironment {
	param(
		[string] $path
	)

	$projectPath = $path | Split-Path | Split-Path

	pushd($projectPath)

	if(-not ($env:PSModulePath -like "*$projectPath*")){
		$env:PSModulePath = $env:PSModulePath + ";$projectPath" + '\'
	}

	$ThisModule = $path -replace '\.tests\.ps1$'
	$ThisModuleName = $ThisModule | Split-Path -Leaf

	Get-Module -Name $ThisModuleName -All | Remove-Module -Force -ErrorAction Ignore
	Import-Module -Name "$ThisModuleName" -Force -ErrorAction Stop
}

