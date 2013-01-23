$assemblyPath = ($PSScriptRoot + '\staging\todotxtlib.net.dll')
$assemblyLoadPath = ($PSScriptRoot + '\lib')

if(!(Test-Path $assemblyLoadPath))
{
	New-Item $assemblyLoadPath -ItemType directory
}

$assemblyLoadPath = $assemblyLoadPath + '\todotxtlib.net.dll'

# Before we try to load up the newest version of the DLL, we need to see if it's already loaded
# so we'll try to New-Object a task list; if it fails, we'll know it's safe to copy the dll

Try
{
	Copy-Item -Path $assemblyPath -Destination $assemblyLoadPath	
}
Catch
{
	[system.exception]
}

Add-Type -Path $assemblyLoadPath

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
	TODO.TXT Command Line Interface for PowerShell 2.0

.Description
	The ToDo function is an entry point for running functions to manipulate a todo.txt file 
	using the same command syntax as todo.sh

.Example
	ToDo list 
	
	List all of the todo items in your todo file. 

.Example
	ToDo listall 
	
	List all of the items in the todo and done files.

.Example
	ToDo add "THING I NEED TO DO +project @context"
	
	Adds "THING I NEED TO DO" to your todo.txt file on its own line, 
	assigning it to a project and context. 

.Example 
	ToDo append 34 "TEXT TO APPEND"

	Adds "TEXT TO APPEND" to the end of the task on line 34.

.Example 
	ToDo archive
	
	Moves all done tasks from todo.txt to done.txt.
	
.Example 

	ToDo del 34 

	Deletes the task on line 34 in todo.txt.

.Example 

	ToDo del 34 "foo"
	
	Deletes the text "foo" from line 34 in todo.txt
	
.Example 

	ToDo move 34 .\otherfile.txt
	
	Moves item 34 to otherfile.txt
#>
function ToDo {
param()
	
	if(!$configLocation)
	{
		$configLocation = ($PSScriptRoot + '\todo_cfg.ps1')
	}
	
	LoadConfiguration $configLocation
	
	## TODO process command line options for overrides
	
	##TODO handle no arguments
	
	$cmd = $args[0]
	
	Write-Host ""
	
	if(!$cmd -or $cmd -eq "list" -or $cmd -eq "ls")
    {
		$todoArgs = @{path=$TODO_FILE; search=$args[1..$args.Length]}
		
		Format-Priority((Get-ToDo @todoArgs).ToNumberedOutput())
    }
	elseif($cmd -eq "listall" -or $cmd -eq "lsa")
    {
		$todoArgs = @{path=$TODO_FILE; search=$args[1..$args.Length]; includeCompletedTasks=$TRUE}
		
		Format-Priority((Get-ToDo @todoArgs).ToNumberedOutput())
    }
	elseif($cmd -eq "listfile" -or $cmd -eq "lf")
    {
		$todoArgs = @{path=$args[1]; search=$args[2..$args.Length]}
	
		Format-Priority((Get-ToDo @todoArgs).ToNumberedOutput())
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
		Get-Project | % {Write-Host $_}
	}
	elseif($cmd -eq "listcon" -or $cmd -eq "lsc" )
	{
		Get-Context | % {Write-Host $_}
	}
	elseif($cmd -eq "listpri" -or $cmd -eq "lsp")
	{
		Format-Priority((Get-Priority $args[1]).ToNumberedOutput())
	}	
	elseif($cmd -eq "replace")
	{
		Replace-ToDo $args[1] ([String]::Join(" ", $args[2..$args.Length]))
	}
	elseif($cmd -eq "prepend" -or $cmd -eq "prep")
	{
		Prepend-ToDo $args[1] ([String]::Join(" ", $args[2..$args.Length]))
	}
	elseif($cmd -eq "append" -or $cmd -eq "app")
	{
		Append-ToDo $args[1] ([String]::Join(" ", $args[2..$args.Length]))
	}
	elseif($cmd -eq "do")
	{
		Set-ToDoComplete $args[1..$args.Length]
	}
	elseif($cmd -eq "archive")
	{
		Archive-ToDo
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
	
	Write-Host ""
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
	
		$srcList = ParseToDoList $src
		$destList = ParseToDoList $dest
		
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
				$task = New-Object todotxtlib.net.Task(($srcList[$item - 1].Raw), ($destList.Count + 1))
			
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

function Set-ToDoComplete {
	param([int[]] $items)
	
	if($items)
	{
		$list = ParseToDoList
		
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
			Archive-ToDo
		}
	}
}

function Archive-ToDo {

	## Todo figure out what to do if $DONE_FILE isn't specified
	if($DONE_FILE)
	{
		$list = ParseToDoList
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
	
	$list = ParseToDoList
	
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

function Set-ToDoPriority {
	param([int] $item,
		[string] $priority)

	if($priority -match "^[A-Z]{1}$")
	{
		$list = ParseToDoList
		
		if($item -le $list.Count)
		{
			$currentPriority = $list.GetPriority($priority)
			
			if($currentPriority.Count -gt 0)
			{
				Write-Host "There is already an item with this priority"
			}
			else
			{
				$list.SetItemPriority($item, $priority)
				$list.ToOutput() | Set-Content $TODO_FILE
				if($TODOTXT_VERBOSE)
				{
					Write-Host ("$item " + $list[$item - 1].Text)
					Write-Host "TODO: $item prioritized ($priority)."
				}
			}
		}
		else
		{
			Write-Host "No task $item."
		}
	}
	
	## TODO show usage
}

function Get-ToDo {
param(
		[string[]] $search,
		[boolean] $includeCompletedTasks = $FALSE,
		[string] $path = $TODO_FILE
	)
	
	## TODO Error/warning message for no todo location set
	
	$list = ParseToDoList $path $includeCompletedTasks
	
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
	
	return ,$result
}

function Format-Priority {
param(
		[string[]] $tasks
	)
	
	$tasks | % {
		
		if($_ -match "\(A\)")
		{
			Write-Host $_ -foregroundcolor $PRI_A
		}
		elseif($_ -match "\(B\)")
		{
			Write-Host $_ -foregroundcolor $PRI_B
		}
		elseif($_ -match "\(C\)")
		{
			Write-Host $_ -foregroundcolor $PRI_C
		}
		elseif($_ -match "\([D-Z]\)")
		{
			Write-Host $_ -foregroundcolor $PRI_X
		}
		else
		{
			Write-Host $_
		}
	}
}

function Add-ToDo {
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
	$matches | % {$_.Groups[1]} | Sort-Object | Get-Unique
}

function Get-Project {
	$matches = (select-string $TODO_FILE -pattern '\s(\+\w+)' -AllMatches) | % {$_.Matches}
	$matches | % {$_.Groups[1]} | Sort-Object | Get-Unique 
}

function Get-Priority {
param(
	[string] $priority
	)

	$list = ParseToDoList
	,$list.GetPriority($priority) 
}

function Prepend-ToDo {
	param(
		[int] $item,
		[string] $term
		)

	$list = ParseToDoList
	
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

function Append-ToDo {
	param(
		[int] $item,
		[string] $term
		)

	$list = ParseToDoList
	
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

function Replace-ToDo {
	param(
		[int] $item,
		[string] $term
		)
		
	$list = ParseToDoList
	
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

function Remove-ToDo {
param(
	[int] $item,
	[string] $term
	)
	
	$list = ParseToDoList
	
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

export-modulemember -function Get-ToDo
export-modulemember -function Add-ToDo
export-modulemember -function Remove-ToDo
export-modulemember -function Get-Context
export-modulemember -function Get-Project
export-modulemember -function Get-Priority
export-modulemember -function Append-ToDo
export-modulemember -function Prepend-ToDo
export-modulemember -function Replace-ToDo
export-modulemember -function Set-ToDoDone
export-modulemember -function Set-ToDoPriority
export-modulemember -function Archive-ToDo
export-modulemember -function Set-ToDoComplete
export-modulemember -function Deprioritize-ToDo
export-modulemember -function Move-ToDo
export-modulemember -function ToDo
export-modulemember -function ParseToDoList
