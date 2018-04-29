#
# Edit-Task.psm1
#

Import-Module Get-Task

function Edit-Task {
	[cmdletbinding()]
	param(
		[Parameter(ValueFromPipeline, Mandatory=$true, Position = 0)]
		[todotxtlib.net.Task] $task,
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

	Begin{}

	Process {
		if($replace) {
			$task.Replace($replace)
		}

		if($append) { 
			$task.Append($append)
		}

		if($prepend) { 
			$task.Prepend($prepend)
		}

		if($priority){
			$task.Priority = $priority
		}

		if($clearPriority) {
			$task.Priority = ""
		}

		$task
	}
}

function Edit-TaskList {
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
		[switch] $clearPriority,
		[string] $path = $TODO_FILE
	)

	Begin {

		ValidatePaths($path)

		if($priority){
			if(-not ($priority -match "^[A-Z]{1}$")){
				throw "Invalid priority; priority must be a single letter from A-Z"
			}
		}
	}

	Process {
		# TODO error output for empty values

		if($replace) {
			ReplaceTaskInList -Index $index -Value $replace -path $path
		}

		if($append) { 
			AppendToTaskInList -Index $index -Append $append -path $path
		}

		if($prepend) { 
			PrependToTaskInList -Index $index -Prepend $prepend -path $path
		}

		if($priority){
			SetPriorityInList -Index $index -Priority $priority -path $path
		}

		if($clearPriority) {
			SetPriorityInList -Index $index -Priority "" -path $path
		}
	}
}

function SetPriorityInList {
	param(
		[string] $path,
		[int] $index,
		[string] $priority
	)
	
	$list = Get-TaskList -path $path
	$list.SetItemPriority($index, $priority)
	$list.ToOutput() | Set-Content $TODO_FILE
	Write-Verbose ("$index " + $list[$index - 1].Text)
	Write-Verbose "TODO: $item prioritized ($priority)."
		
	## TODO show usage (this comment got imported from todo.psm1, not sure what it meant)
}


function AppendToTaskInList {
	param(
		[string] $path,
		[int] $index,
		[string] $append
	)

	if(-not $append) { return }

	$list = Get-TaskList -path $path
	$list.AppendToTask($index, $append)
	$list.ToOutput() | Set-Content $path 
	Write-Verbose ("$index " + $list[$index-1].Body)
}

function PrependToTaskInList {
	param(
		[string] $path,
		[int] $index,
		[string] $prepend
	)

	if(-not $prepend) { return }

	$list = Get-TaskList -path $path
	$list.PrependToTask($index, $prepend)
	$list.ToOutput() | Set-Content $path 
	Write-Verbose ("$index " + $list[$index-1].Body)
}

function ReplaceTaskInList {
	param(
		[string] $path,
		[int] $item,
		[string] $value
	)

	if(-not $value) { return }

	$list = Get-TaskList -path $path
	$list.ReplaceInTask($index, $value)
	$list.ToOutput() | Set-Content $path 
	Write-Verbose "TODO: Replaced task with:"
	Write-Verbose ("$index " + $list[$index-1].Body)
}

#function ValidatePaths {
#	param([string[]] $path)

#	if(-not $path) {
#		throw 'No task file specified' 
#	}

#	$path | % {
#		if(-not (Test-Path($_))){
#			throw "Task file $_ does not exist"
#		}
#	}
#}

Export-ModuleMember -Function Edit-TaskList
Export-ModuleMember -Function Edit-Task