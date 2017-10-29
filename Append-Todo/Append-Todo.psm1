#
# Append_Todo.psm1
#

Import-Module Get-Todo

function Append-Todo {
	param(
		[int] $item,
		[string] $term
	)

	$list = Get-TodoList
	
	if($term)
	{
		if($item -le $list.Count)
		{
			$list.AppendToTask($item, $term)
			$list.ToOutput() | Set-Content $TODO_FILE
			
			if($TODOTXT_VERBOSE)
			{
				Write-Host ("$item " + $list[$item-1].Body)
			}
		}
	}
}

Export-ModuleMember -Function Append-Todo