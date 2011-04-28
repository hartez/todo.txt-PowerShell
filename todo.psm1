$classDefinitionPath = ($PSScriptRoot + '\todo.cs')
Add-Type -TypeDefinition (Get-Content $classDefinitionPath | Out-String) -Language "CSharpVersion3"

## Figure out licensing and copyright stuff (including manifest)

function LoadConfiguration() {
	param([string] $path)

	## Set up the defaults
	$script:TODOTXT_VERBOSE = $FALSE
	$script:TODOTXT_FORCE = $FALSE
	$script:TODOTXT_AUTO_ARCHIVE = $FALSE
	$script:TODOTXT_PRESERVE_LINE_NUMBERS = $FALSE
	$script:TODOTXT_DATE_ON_ADD = $TRUE
	
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
		
		(Get-ToDo @todoArgs).ToNumberedOutput();
    }
	elseif($cmd -eq "listall" -or $cmd -eq "lsa")
    {
		$todoArgs = @{path=$TODO_FILE; search=$args[1..$args.Length]; includeCompletedTasks=$TRUE}
		
		(Get-ToDo @todoArgs).ToNumberedOutput();
    }
	elseif($cmd -eq "listfile" -or $cmd -eq "lf")
    {
		$todoArgs = @{path=$args[1]; search=$args[2..$args.Length]}
	
		(Get-ToDo @todoArgs).ToNumberedOutput();
    }
	elseif($cmd -eq "add" -or $cmd -eq "a")
	{
		Add-Todo $args[1..$args.Length]
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
		(Get-Priority $args[1]).ToNumberedOutput()
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
	
	$todos = New-Object ToDoList

	$results = @(Get-Content $listLocations)
		
	for ($i=0; $i -lt $results.Length; $i++)
	{
		$todo = New-Object ToDo($results[$i], ($i + 1))
		$todos.Add($todo)
	}
	
	return ,$todos
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
					$list[$_ - 1].MarkCompleted()
					
					if($TODOTXT_VERBOSE)
					{
						Write-Host ("$_ " + $list[$_ - 1].Text)
						Write-Host "TODO: $_ marked as done."
					}
				}
			}
			else
			{
				Write-Host "No task $_."
			}
		}
		
		Set-Content $TODO_FILE $list.ToOutput()
		
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
		$completed = $list.RemoveCompletedItems($TODOTXT_PRESERVE_LINE_NUMBERS)
		
		Add-Content $DONE_FILE $completed.ToOutput()
		Set-Content $TODO_FILE $list.ToOutput();
		
		if($TODOTXT_VERBOSE)
		{
			$completed.ToNumberedOutput() | % {Write-Host $_}
			Write-Host "TODO: $TODO_FILE archived."
		}
	}
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
				Set-Content $TODO_FILE $list.ToOutput()
				if($TODOTXT_VERBOSE)
				{
					  Write-Host ("$item " + $list[$item - 1].Text)
						Write-Host "TODO: $item prioritized ($priority)."
				}
			}
		}
		else
		{
			Write-Host "No task $_."
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
		return ,$list
	}
	else
	{
		## TODO - check for '-' at the beginning of the search term and handle notMatch
		return ,($list.Search($search))
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
			$list.PrependToDo($item, $term)
			Set-Content $TODO_FILE $list.ToOutput()
		
			if($TODOTXT_VERBOSE)
			{
				Write-Host ("$item " + $list[$item-1].Text)
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
			$list.AppendToDo($item, $term)
			Set-Content $TODO_FILE $list.ToOutput()
			
			if($TODOTXT_VERBOSE)
			{
				Write-Host ("$item " + $list[$item-1].Text)
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
			$oldText = $list[$item-1].Text
			
			$list.ReplaceToDo($item, $term)
			Set-Content $TODO_FILE $list.ToOutput()
			
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
		$oldItem = ($list[$item - 1]).Text
	
		if($term)
		{
			$success =  $list.RemoveFromItem($item, $term)
			Set-Content $TODO_FILE $list.ToOutput()
			
			if($success)
			{
				$newItem = ($list[$item - 1]).Text
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
			## TODO - Check configuration for 'preserve line numbers'
			$preserveLineNumbers = $FALSE
			
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
				$list.RemoveItem($item, $preserveLineNumbers)
				Set-Content $TODO_FILE $list.ToOutput()	
				
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

## TODO Create a table view for TODOS http://msdn.microsoft.com/en-us/library/dd901841%28v=vs.85%29.aspx

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
export-modulemember -function ToDo
export-modulemember -function ParseToDoList
