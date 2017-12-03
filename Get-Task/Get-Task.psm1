#
# Get-Task.ps1
#

Import-Module todotxtlib

function Get-Task {
[CmdletBinding(DefaultParameterSetName='Filter')]  
param(
		[Parameter(ParameterSetName='Filter', Position = 0)]
		[string[]] $search,
		[Parameter(ParameterSetName='ByIndex')]
		[ValidateRange(1, [int32]::MaxValue)]
		[int] $index,
		[Parameter(ParameterSetName='Filter')]
		[Parameter(ParameterSetName='ByIndex')]
		[string[]] $path = @($TODO_FILE)
	)

	ValidatePaths($path)
	
	$list = Get-TaskList $path
	
	if($index) {
		$result = ($list).GetTask($index)
		if($result) {
			return $result
		} else {
			throw "Invalid index"
		}
	}

	if(!$search) {
		$result = $list
	} else {
		$search = [String]::Join(" ", $search).Trim()
		## TODO - check for '-' at the beginning of the search term and handle notMatch
		$result = ($list.Search($search))
	}
	
	return $result
}

function Get-TaskList {
[CmdletBinding()]
param(
		[string[]] $path = @($TODO_FILE)
	)
	
	$listLocations = @()

	$path | % {
		if($_ -and (Test-Path $_)) {
			$listLocations += $_
		}
	}

	$todos = New-Object todotxtlib.net.TaskList

	$results = @(Get-Content $listLocations)
		
	for ($i=0; $i -lt $results.Length; $i++)
	{
		$todo = New-Object todotxtlib.net.Task($results[$i], ($i + 1))
		$todos.Add($todo)
	}
	
	return ,$todos
}

function ValidatePaths {
	param([string[]] $path)

	if(-not $path) {
		throw 'No task file specified' 
	}

	$path | % {
		if(-not (Test-Path($_))){
			throw "Task file $_ does not exist"
		}
	}
}

Export-ModuleMember -Function Get-Task
Export-ModuleMember -Function Get-TaskList