#
# Get-Task.ps1
#

Import-Module todotxtlib

function Get-Task {
[CmdletBinding()]  
param(
		[string[]] $search,
		[switch] $includeCompleted,
		[string] $path = $TODO_FILE
	)
	
	if(-not $path) {
		throw '$TODO_FILE not set' 
	}
	
	if($includeCompleted){
		$list = Get-TaskList $path -includeCompleted
	} else {
		$list = Get-TaskList $path
	}
	
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
		[string] $path = $TODO_FILE,
		[switch] $includeCompleted
	)
	
	## TODO includeCompleted is sort of awkward; it might make more sense to take an array of paths
	## in both of these functions and let the top-level Todo handle specifying DONE_FILE

	if($includeCompleted -and $DONE_FILE -and (Test-Path $DONE_FILE))
	{
		$listLocations = @($path, $DONE_FILE)
	}
	else
	{
		$listLocations = @($path)
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