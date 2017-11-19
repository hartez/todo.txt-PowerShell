#
# Edit-Task.psm1
#

Import-Module Get-Task

#TODO Edit-Task should also support pipeline input of Tasks (instead of just taking an index)


function Edit-Task {
	[cmdletbinding()]
	param(
		[Parameter(ValueFromPipeline, Mandatory=$true,
			HelpMessage="Enter the number of the task to edit.",
			Position = 0)]
		[Parameter(ParameterSetName='ModifyBody')]
		[Parameter(ParameterSetName='SetPriority')]
		[Parameter(ParameterSetName='ClearPriority')]
		[int] $index,
		[Parameter(ParameterSetName='ModifyBody')]
		[string] $append,
		[Parameter(ParameterSetName='ModifyBody')]
		[string] $prepend,
		[Parameter(ParameterSetName='ModifyBody')]
		[string] $replace,
		[Parameter(Mandatory=$true, ParameterSetName='SetPriority')]
		[string] $priority,
		[Parameter(Mandatory=$true, ParameterSetName='ClearPriority')]
		[switch] $clearPriority
	)

	Begin {
		if($priority){
			if(-not ($priority -match "^[A-Z]{1}$")){
				throw "Invalid priority; priority must be a single letter from A-Z"
			}
		}
	}

	Process {
		# TODO error output for empty values

		if($replace) {
			ReplaceTask -Index $index -Value $replace
		}

		if($append) { 
			AppendToTask -Index $index -Append $append
		}

		if($prepend) { 
			PrependToTask -Index $index -Prepend $prepend
		}

		if($priority){
			SetPriority -Index $index -Priority $priority
		}

		if($clearPriority) {
			SetPriority -Index $index -Priority ""
		}
	}
}

function SetPriority {
	param(
		[int] $index,
		[string] $priority
	)
	
	$list = Get-TaskList
		
	$delegate = {
		param($list)
		$list.SetItemPriority($index, $priority)
		$list.ToOutput() | Set-Content $TODO_FILE
	}
	
	$output = {
		param($list)
		Write-Verbose ("$index " + $list[$index - 1].Text)
		Write-Verbose "TODO: $item prioritized ($priority)."
	}

	ModifyTask $index $delegate $output
		
	## TODO show usage (this comment got imported from todo.psm1, not sure what it meant)
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
	#else
	#{
		# Write Error goes here, maybe?
	#}
	
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