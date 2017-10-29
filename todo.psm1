#Requires -Modules Get-Todo

## Figure out licensing and copyright stuff (including manifest)

function LoadConfiguration() {
	param([string] $path)

	## Set up the defaults
	$script:TODOTXT_VERBOSE = $FALSE
	$script:TODOTXT_FORCE = $FALSE
	$script:TODOTXT_AUTO_ARCHIVE = $FALSE
	$script:TODOTXT_PRESERVE_LINE_NUMBERS = $FALSE
	$script:TODOTXT_DATE_ON_ADD = $TRUE
	
	$script:PRI_A = 'Yellow'
	$script:PRI_B = 'Green'
	$script:PRI_C = 'Cyan'
	$script:PRI_X = 'White'
	
	## Override the defaults with the configuration file
	if(Test-Path $path)
	{
		.$path			
	}
}

<# 
.Synopsis
	TODO.TXT Command Line Interface for PowerShell 3.0

.Description
	The Todo function is an entry point for running functions to manipulate a todo.txt file 
	using the same command syntax as todo.sh

.Example
	Todo list 
	
	List all of the todo items in your todo file. 

.Example
	Todo listall 
	
	List all of the items in the todo and done files.

.Example
	Todo add "THING I NEED TO DO +project @context"
	
	Adds "THING I NEED TO DO" to your todo.txt file on its own line, 
	assigning it to a project and context. 

.Example 
	Todo append 34 "TEXT TO APPEND"

	Adds "TEXT TO APPEND" to the end of the task on line 34.

.Example 
	Todo archive
	
	Moves all done tasks from todo.txt to done.txt.
	
.Example 

	Todo del 34 

	Deletes the task on line 34 in todo.txt.

.Example 

	Todo del 34 "foo"
	
	Deletes the text "foo" from line 34 in todo.txt
	
.Example 

	Todo move 34 .\otherfile.txt
	
	Moves item 34 to otherfile.txt
#>
function Todo {
param()
	
	if(!$configLocation)
	{
		$configLocation = ($PSScriptRoot + '\todo_cfg.ps1')
	}
	
	LoadConfiguration $configLocation
	
	## TODO process command line options for overrides
	
	$cmd = $args[0]
	
    $fore = $Host.UI.RawUI.ForegroundColor

	if(!$cmd -or $cmd -eq "list" -or $cmd -eq "ls")
    {
		$todoArgs = @{path=$TODO_FILE; search=$args[1..$args.Length]}
		
        Format-Priority((Get-ToDo @todoArgs))
    }
	elseif($cmd -eq "listall" -or $cmd -eq "lsa")
    {
		$todoArgs = @{path=$TODO_FILE; search=$args[1..$args.Length]; includeCompletedTasks=$TRUE}
		
		Format-Priority((Get-ToDo @todoArgs)) 
    }
	elseif($cmd -eq "listfile" -or $cmd -eq "lf")
    {
		$todoArgs = @{path=$args[1]; search=$args[2..$args.Length]}
	
		Format-Priority((Get-ToDo @todoArgs))
    }
	elseif($cmd -eq "add" -or $cmd -eq "a")
	{
		Add-Todo $args[1..$args.Length]
	}
	elseif($cmd -eq "addm")
	{
		$split = $args[$args.Length - 1].Split([environment]::newline, [StringSplitOptions]'RemoveEmptyEntries')

		($split) | % {
			Add-ToDo $_
		}
	}
	elseif($cmd -eq "rm" -or $cmd -eq "del")
	{
		Remove-ToDo $args[1] $args[2]
	}
	elseif($cmd -eq "listproj" -or $cmd -eq "lsprj" )
	{
		Get-Project
	}
	elseif($cmd -eq "listcon" -or $cmd -eq "lsc" )
	{
		Get-Context
	}
	elseif($cmd -eq "listpri" -or $cmd -eq "lsp")
	{
		Format-Priority((Get-Priority $args[1]))
	}	
	elseif($cmd -eq "replace")
	{
		Replace-Todo $args[1] ([String]::Join(" ", $args[2..$args.Length]))
	}
	elseif($cmd -eq "prepend" -or $cmd -eq "prep")
	{
		Prepend-Todo $args[1] ([String]::Join(" ", $args[2..$args.Length]))
	}
	elseif($cmd -eq "append" -or $cmd -eq "app")
	{
		Append-Todo $args[1] ([String]::Join(" ", $args[2..$args.Length]))
	}
	elseif($cmd -eq "do")
	{
		Set-TodoComplete $args[1..$args.Length]
	}
	elseif($cmd -eq "archive")
	{
		Archive-Todo
	}
	elseif($cmd -eq "pri" -or $cmd -eq "p")
	{
		Set-ToDoPriority $args[1] $args[2]
	}
	elseif($cmd -eq "depri" -or $cmd -eq "dp")
	{
		Deprioritize-ToDo $args[1..$args.Length]
	}
	elseif($cmd -eq "move" -or $cmd -eq "mv")
	{
		if($args[3])
		{
			Move-ToDo $args[1] $args[2] $args[3]
		}
		else
		{
			Move-ToDo $args[1] $args[2] 
		}
	}
	elseif($cmd -eq "help")
	{
		Get-Help Todo
	}
}

function Format-Priority {
param(
		[object[]] $tasks
	)
	
	$tasks | % {

        if($_.Raw -match "\(A\)")
		{
			    $Host.UI.RawUI.ForegroundColor = $PRI_A
		}
		elseif($_.Raw -match "\(B\)")
		{
			    $Host.UI.RawUI.ForegroundColor = $PRI_B
		}
		elseif($_.Raw -match "\(C\)")
		{
			    $Host.UI.RawUI.ForegroundColor = $PRI_C
		}
		elseif($_.Raw -match "\([D-Z]\)")
		{
			    $Host.UI.RawUI.ForegroundColor = $PRI_X
		}
		else
		{
			    $Host.UI.RawUI.ForegroundColor = $fore
		}

        $_
    }

    $Host.UI.RawUI.ForegroundColor = $fore
}

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

function Set-TodoPriority {
	param([int] $item,
		[string] $priority)

	if($priority -match "^[A-Z]{1}$")
	{
		$list = ParseTodoList
		
		if($item -le $list.Count)
		{
    		$list.SetItemPriority($item, $priority)
			$list.ToOutput() | Set-Content $TODO_FILE
			if($TODOTXT_VERBOSE)
			{
				Write-Host ("$item " + $list[$item - 1].Text)
				Write-Host "TODO: $item prioritized ($priority)."
			}
		}
		else
		{
			Write-Host "No task $item."
		}
	}
	
	## TODO show usage
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

function Prepend-Todo {
	param(
		[int] $item,
		[string] $term
		)

	$list = ParseTodoList
	
	if($term)
	{
		if($item -le $list.Count)
		{
			$list.PrependToTask($item, $term)
			$list.ToOutput() | Set-Content $TODO_FILE
		
			if($TODOTXT_VERBOSE)
			{
				Write-Host ("$item " + $list[$item-1].Body)
			}
		}
	}
}

function Replace-Todo {
	param(
		[int] $item,
		[string] $term
		)
		
	$list = ParseTodoList
	
	if($term)
	{
		if($item -le $list.Count)
		{
			$oldText = $list[$item-1].Body
			
			$list.ReplaceInTask($item, $term)
			$list.ToOutput() | Set-Content $TODO_FILE
			
			if($TODOTXT_VERBOSE)
			{
				Write-Host "$item $oldText"
				Write-Host "TODO: Replaced task with:"
				Write-Host "$item $term"
			}
		}
	}
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
