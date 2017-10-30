#
# Edit-Task.psm1
#

Import-Module Get-Task

function Edit-Task {
	param(
		[Parameter(Mandatory=$true)]
		[int] $index,
		[string] $append,
		[string] $prepend,
		[string] $replace
	)

	if($replace) {
		ReplaceTask -Index $index -Value $replace
	}

	if($append) { 
		AppendToTask -Index $index -Append $append
	}

	if($prepend) { 
		PrependToTask -Index $index -Prepend $prepend
	}
}

function ModifyTask {
	param(
		[int] $index,
		[scriptblock] $modify,
		[scriptblock] $output
	)

	$list = Get-TaskList
		
	if($index -le $list.Count)
	{
		& $modify $list
		$list.ToOutput() | Set-Content $TODO_FILE
		& $output $list		
	}
	
}

function AppendToTask {
	param(
		[int] $index,
		[string] $append
	)

	if(-not $append) { return }

	$delegate = {
		param($list)
		$list.AppendToTask($index, $append)
	}

	$output = {
		param($list)
		Write-Verbose ("$index " + $list[$index-1].Body)
	}

	ModifyTask $index $delegate $output
}

function PrependToTask {
	param(
		[int] $index,
		[string] $prepend
	)

	if(-not $prepend) { return }

	$delegate = {
		param($list)
		$list.PrependToTask($index, $prepend)
	}

	$output = {
		param($list)
		Write-Verbose ("$index " + $list[$index-1].Body)
	}

	ModifyTask $index $delegate $output
}

function ReplaceTask {
	param(
		[int] $item,
		[string] $value
	)

	if(-not $value) { return }

	$delegate = {
		param($list)
		$list.ReplaceInTask($index, $value)
	}

	$output = {
		param($list)
		Write-Verbose "TODO: Replaced task with:"
		Write-Verbose ("$index " + $list[$index-1].Body)
	}

	ModifyTask $index $delegate $output
}

Export-ModuleMember -Function Edit-Task