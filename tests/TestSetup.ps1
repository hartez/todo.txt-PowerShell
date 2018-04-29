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

function SetTODOVariables {
	param(
		[Parameter(Position = 0)]
		[string] $todo, 
		[Parameter(Position = 1)]
		[string] $done
	)

	if($todo) { 
		Set-Variable -Name TODO_FILE -Value $todo -Scope Global
	}

	if($done) { 
		Set-Variable -Name DONE_FILE -Value $done -Scope Global
	}
}

function CleanTODOVariables {
	if(Test-Path variable:global:TODO_FILE) {
		Remove-Variable -Name TODO_FILE -Scope Global
	}

	if(Test-Path variable:global:DONE_FILE) {
		Remove-Variable -Name DONE_FILE -Scope Global
	}
}

function RemoveTempList {
	if(Test-Path variable:global:TODO_FILE) {
		Remove-Item $TODO_FILE 
	}

	if(Test-Path variable:global:DONE_FILE) {
		Remove-Item $DONE_FILE 
	}

	CleanTODOVariables
}