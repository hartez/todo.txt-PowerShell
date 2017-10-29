#
# Edit-Task.psm1
#

Import-Module Get-Task

function Edit-Task {
	param(
		[Parameter(Mandatory=$true)]
		[int] $index,
		[string] $append
	)

	if($append) { 
		AppendToTask -Index $index -Append $append
	}
}

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

Export-ModuleMember -Function Edit-Task