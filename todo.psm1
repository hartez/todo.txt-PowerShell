$classDefinitionPath = ($PSScriptRoot + '\todo.cs')
Add-Type -TypeDefinition (Get-Content $classDefinitionPath | Out-String) -Language "CSharpVersion3"

## Figure out licensing and copyright stuff (including manifest)

function LoadConfiguration() {
	param([string] $path)

	## Set up the defaults
	$script:TODOTXT_VERBOSE = $FALSE
	$script:TODOTXT_FORCE = $FALSE
	
	## Override the defaults with the configuration file
	if(Test-Path $path)
	{
		.$path			
	}
}

<# 
 .Synopsis
  TODO Update

 .Description
  TODO Update

 .Example
   # TODO Update
   todo 
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
	
	if(!$cmd -or $cmd -eq "list" -or $cmd -eq "ls")
    {
		$todoArgs = @{path=$todoLocation; search=$args[1..$args.Length]}
		
		(Get-ToDo @todoArgs).ToNumberedOutput();
    }
	elseif($cmd -eq "listall" -or $cmd -eq "lsa")
    {
		$todoArgs = @{path=$todoLocation; search=$args[1..$args.Length]; includeCompletedTasks=$TRUE}
		
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
		Write-Host ""
		Get-Project | % {Write-Host $_}
		Write-Host ""
	}
	elseif($cmd -eq "listcon" -or $cmd -eq "lsc" )
	{
		Write-Host ""
		Get-Context | % {Write-Host $_}
		Write-Host ""
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
}

function ParseToDoList {
param(
		[string] $path = $todoLocation,
		[boolean] $includeCompletedTasks = $FALSE
	)
	
	if($includeCompletedTasks -and $doneLocation -and (Test-Path $doneLocation))
	{
		$listLocations = @($path, $doneLocation)
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

function Get-ToDo {
param(
		[string[]] $search,
		[boolean] $includeCompletedTasks = $FALSE,
		[string] $path = $todoLocation
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
	
	## TODO - check configuration for whether to prepend the add date
	$now = (Get-Date -format "yyyy-MM-dd")	
	
	$item = [String]::Join(" ", $item) 
	
	Add-Content $todoLocation ($now + " " + $item)
	
	if($TODOTXT_VERBOSE)
	{
		$taskNum = (Get-Content $todoLocation | Measure-Object).Count
		Write-Host "$taskNum $item"
		Write-Host "$taskNum added."
	}
}

function Get-Context {
	$matches = (select-string $todoLocation -pattern '\s(@\w+)' -AllMatches) | % {$_.Matches}
	$matches | % {$_.Groups[1]} | Sort-Object | Get-Unique
}

function Get-Project {
	$matches = (select-string $todoLocation -pattern '\s(\+\w+)' -AllMatches) | % {$_.Matches}
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
			Set-Content $todoLocation $list.ToOutput()
		
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
			Set-Content $todoLocation $list.ToOutput()
			
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
			Set-Content $todoLocation $list.ToOutput()
			
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
			Set-Content $todoLocation $list.ToOutput()
			
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
				Set-Content $todoLocation $list.ToOutput()	
				
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
export-modulemember -function ToDo
export-modulemember -function ParseToDoList
