#
# Get_Todo.ps1
#

Import-Module todotxtlib

function Get-Todo {
[CmdletBinding()]
param(
		[string[]] $search,
		[switch] $includeCompleted,
		[string] $path = $TODO_FILE
	)
	
	if(-not $path) {
		throw '$TODO_FILE not set' 
	}
	
	$list = ParseTodoList $path $includeCompleted
	
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

function ParseToDoList {
param(
		[string] $path = $TODO_FILE,
		[boolean] $includeCompletedTasks = $FALSE
	)
	
	if($includeCompletedTasks -and $DONE_FILE -and (Test-Path $DONE_FILE))
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

Export-ModuleMember -Function Get-Todo