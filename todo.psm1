#Requires -Modules Get-Todo

## Figure out licensing and copyright stuff (including manifest)


function Move-ToDo {
	param (
		[int] $item,
		[string] $dest,
		[string] $src = $TODO_FILE
	)
	
	if($dest)
	{
		if(!(Test-Path $dest))
		{
			Set-Content $dest ''
		}
	
		$srcList = ParseTodoList $src
		$destList = ParseTodoList $dest
		
		if($item -le $srcList.Count)
		{
			$oldItem = ($srcList[$item - 1]).Body
			$confirmed = $TRUE
		
			if(!$TODOTXT_FORCE)
			{
				$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", "Moves the task."
				$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", "Does nothing."
	
				$options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)

				$result = $host.ui.PromptForChoice("Move Item", "Move '$oldItem'?", $options, 1) 
				
				if($result -eq 1)
				{
					$confirmed = $FALSE
				}
			}

			if($confirmed)
			{
				$task = New-Object todotxtlib.net.Task(($srcList[$item - 1].Raw), ($destList.Count + 1))instag
			
				## add it to the destination file
				$destList.Add($task)
				$destList.ToOutput() | Set-Content $dest 
				
				## remove it from the original
				$srcList.RemoveTask($item, $TODOTXT_PRESERVE_LINE_NUMBERS)
				$srcList.ToOutput() | Set-Content $src 
				
				if($TODOTXT_VERBOSE)
				{
					Write-Host "$item $oldItem"
					Write-Host "TODO: $item moved from '$src' to '$dest'."
				}
			}
			else
			{
				if($TODOTXT_VERBOSE)
				{
					Write-Host "TODO: No tasks moved."
				}
			}
		}
		else
		{
			Write-Host "No task $item."
		}
	}
}

function Set-TodoComplete {
	param([int[]] $items)
	
	if($items)
	{
		$list = ParseTodoList
		
		$items | % {
			if($_ -le $list.Count)
			{
				if($list[$_ - 1].Done)
				{
					Write-Host "$_ is already marked done."
				}
				else
				{
					$list[$_ - 1].ToggleCompleted()
					
					if($TODOTXT_VERBOSE)
					{
						Write-Host ("$_ " + $list[$_ - 1].Body)
						Write-Host "TODO: $_ marked as done."
					}
				}
			}
			else
			{
				Write-Host "No task $_."
			}
		}
		
		$list.ToOutput() | Set-Content $TODO_FILE
		
		if($TODOTXT_AUTO_ARCHIVE)
		{
			Archive-Todo
		}
	}
}

function Archive-Todo {

	## Todo figure out what to do if $DONE_FILE isn't specified
	if($DONE_FILE)
	{
		$list = ParseTodoList
		$completed = $list.RemoveCompletedTasks($TODOTXT_PRESERVE_LINE_NUMBERS)
		
		$completed.ToOutput() | Add-Content $DONE_FILE 
		$list.ToOutput() | Set-Content $TODO_FILE 
		
		if($TODOTXT_VERBOSE)
		{
			$completed.ToNumberedOutput() | % {Write-Host $_}
			Write-Host "TODO: $TODO_FILE archived."
		}
	}
}

function Deprioritize-ToDo {
	param([int[]] $items)
	
	$list = ParseTodoList
	
	$items | % {
		if($_ -le $list.Count)
		{
			$list.SetItemPriority($_, '')
			if($TODOTXT_VERBOSE)
			{
				Write-Host ("$_ " + $list[$_ - 1].Text)
				Write-Host "TODO: $_ deprioritized."
			}
		}
		else
		{
			Write-Host "No task $_."
		}
	}
	
	$list.ToOutput() | Set-Content $TODO_FILE
}


function Add-Todo {
param(
	[string[]] $item
	)
	
	$item = ([String]::Join(" ", $item)).Trim()

	if($TODOTXT_DATE_ON_ADD)
	{
		$item = ((Get-Date -format "yyyy-MM-dd") + " " + $item)
	}
	
	Add-Content $TODO_FILE ($item)
	
	if($TODOTXT_VERBOSE)
	{
		$taskNum = (Get-Content $TODO_FILE | Measure-Object).Count
		Write-Host "$taskNum $item"
		Write-Host "$taskNum added."
	}
}

function Get-Context {
	$matches = (select-string $TODO_FILE -pattern '\s(@\w+)' -AllMatches) | % {$_.Matches}
	$matches | % {$_.Groups[1]} | Sort-Object | Get-Unique | Select -property @{N='Context';E={$_.Value}}
}

function Get-Project {
	$matches = (select-string $TODO_FILE -pattern '\s(\+\w+)' -AllMatches) | % {$_.Matches}
	$matches | % {$_.Groups[1]} | Sort-Object | Get-Unique | Select -property @{N='Project';E={$_.Value}}
}

function Get-Priority {
param(
	[string] $priority
	)

	$list = ParseTodoList
	,$list.GetPriority($priority) 
}

function Remove-Todo {
param(
	[int] $item,
	[string] $term
	)
	
	$list = ParseTodoList
	
	if($item -le $list.Count)
	{
		$oldItem = ($list[$item - 1]).Body
	
		if($term)
		{
			$success =  $list.RemoveFromTask($item, $term)
			$list.ToOutput() | Set-Content $TODO_FILE
			
			if($success)
			{
				$newItem = ($list[$item - 1]).Body
				Write-Host "$item $oldItem"
				Write-Host "TODO: Removed '$term' from task."
				Write-Host "$item $newItem"
			}
			else
			{
				Write-Host "$item $oldItem"
				Write-Host "TODO: '$term' not found; no removal done."
			}
		}
		else
		{
			$confirmed = $TRUE
		
			if(!$TODOTXT_FORCE)
			{
				$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", "Deletes the task."
				$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", "Retains the task."
	
				$options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)

				$result = $host.ui.PromptForChoice("Delete Item", "Delete '$oldItem'?", $options, 1) 
				
				if($result -eq 1)
				{
					$confirmed = $FALSE
				}
			}

			if($confirmed)
			{
				$list.RemoveTask($item, $TODOTXT_PRESERVE_LINE_NUMBERS)
				$list.ToOutput() | Set-Content $TODO_FILE	
				
				if($TODOTXT_VERBOSE)
				{
					Write-Host ("$item $oldItem") 
					Write-Host ("TODO: $item deleted")
				}
			}
			else
			{
				Write-Host "TODO: No tasks were deleted"
			}
		}
	}
	else
	{
		Write-Host "TODO: No task $item"
	}
}

export-modulemember -function Add-Todo
export-modulemember -function Remove-Todo
export-modulemember -function Get-Context
export-modulemember -function Get-Project
export-modulemember -function Get-Priority
#export-modulemember -function Append-Todo
export-modulemember -function Prepend-Todo
export-modulemember -function Replace-Todo
export-modulemember -function Set-TodoDone
export-modulemember -function Set-TodoPriority
export-modulemember -function Archive-Todo
export-modulemember -function Set-TodoComplete
export-modulemember -function Deprioritize-Todo
export-modulemember -function Move-Todo
export-modulemember -function Todo
