#
# Edit-Task.psm1
#

Import-Module Get-Task

function Edit-Task {
	param(
		[Parameter(Mandatory=$true)]
		[int] $index,
		[string] $append,
		[string] $prepend
	)

	if($append) { 
		AppendToTask -Index $index -Append $append
	}

	if($prepend) { 
		PrependToTask -Index $index -Prepend $prepend
	}
}

## TODO Refactor these, everything is pretty much the same except which method on TaskList is called

function AppendToTask {
	param(
		[int] $index,
		[string] $append
	)

	$list = Get-TaskList
	
	if($append)
	{
		if($index -le $list.Count)
		{
			$list.AppendToTask($index, $append)
			$list.ToOutput() | Set-Content $TODO_FILE
			
			if($TODOTXT_VERBOSE)
			{
				Write-Host ("$index " + $list[$index-1].Body)
			}
		}
	}
}

function PrependToTask {
	param(
		[int] $index,
		[string] $prepend
	)

	$list = Get-TaskList
	
	if($prepend)
	{
		if($index -le $list.Count)
		{
			$list.PrependToTask($index, $prepend)
			$list.ToOutput() | Set-Content $TODO_FILE
		
			if($TODOTXT_VERBOSE)
			{
				Write-Host ("$index " + $list[$index-1].Body)
			}
		}
	}
}

Export-ModuleMember -Function Edit-Task