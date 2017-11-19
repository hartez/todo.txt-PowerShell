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
		[switch] $clearPriority,
		[string[]] $path = @($TODO_FILE)
	)

	Begin {

		$path | % {Write-Verbose $_}
		

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
			ReplaceTask -Index $index -Value $replace -path $path
		}

		if($append) { 
			AppendToTask -Index $index -Append $append -path $path
		}

		if($prepend) { 
			PrependToTask -Index $index -Prepend $prepend -path $path
		}

		if($priority){
			SetPriority -Index $index -Priority $priority -path $path
		}

		if($clearPriority) {
			SetPriority -Index $index -Priority "" -path $path
		}
	}
}

function SetPriority {
	param(
		[string[]] $path,
		[int] $index,
		[string] $priority
	)
	
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

	ModifyTask $path $index $delegate $output
		
	## TODO show usage (this comment got imported from todo.psm1, not sure what it meant)
}

function ModifyTask {
	param(
		[string[]] $path,
		[int] $index,
		[scriptblock] $modify,
		[scriptblock] $output
	)

	$list = Get-TaskList -path $path
		
	if($index -le $list.Count)
	{
		& $modify $list

		# TODO Okay, all the edit-task methods should use one of two methods to specify a task
		# 1 index/path - single path, n indexes; edits done this way modify the file at path
		# 2 Task - n tasks; edits done this way return the edited tasks (task for one, list for multiple) as objects; no changes on disk

		# This way we can do stuff like 
		# (Get-Task "derp" | Edit-Task -Prepend "herp").ToOutput() | Set-Content -Path "new.txt" 
		# Or stuff like
		# (Get-Task "derp" | select ItemNumber) | Edit-Task -Prepend "herp" 
		# this last version will actually change TODO_FILE 

		# so we need to make all the paths in this file single (instead of arrays)
		# and rename these methods with 'List' suffix

		# then add new versions which operate on a single Task

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
		[string[]] $path,
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

	ModifyTask $path $index $delegate $output
}

function PrependToTask {
	param(
		[string[]] $path,
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

	ModifyTask $path $index $delegate $output
}

function ReplaceTask {
	param(
		[string[]] $path,
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

	ModifyTask $path $index $delegate $output
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

Export-ModuleMember -Function Edit-Task