#
# Get-Task.ps1
#

Import-Module todotxtlib

function Get-Task {
[CmdletBinding()]  
param(
		[string[]] $search,
		[string[]] $path = @($TODO_FILE)
	)
	
	if(-not $path) {
		throw 'No task file specified' 
	}
	
	$list = Get-TaskList $path
		
	if($search)
	{
		$search = [String]::Join(" ", $search).Trim() 
	}
	
	if(!$search)
	{
		$result = $list
	}
	else
	{
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

Export-ModuleMember -Function Get-Task
Export-ModuleMember -Function Get-TaskList