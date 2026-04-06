# TODO Take these out when you're done debugging

$TODO_FILE = "C:\Users\hartez\Dropbox\testtodo\todo.txt"
Update-FormatData -AppendPath .\todo.ps1xml

$assemblyPath = ($PSScriptRoot + '\staging\todotxtlib.net.dll')
$assemblyLoadPath = ($PSScriptRoot + '\lib')

if (!(Test-Path $assemblyLoadPath)) {
	New-Item $assemblyLoadPath -ItemType directory
}

Try {
	# Let's see if the library is already available 
	New-Object -TypeName todotxtlib.net.TaskList 
}
Catch {
	$assemblyLoadPath = $assemblyLoadPath + '\todotxtlib.net.dll'

	Try {
		Copy-Item -Path $assemblyPath -Destination $assemblyLoadPath	
	}
	Catch {
		[system.exception]
	}

	Add-Type -Path $assemblyLoadPath
}

## Figure out licensing and copyright stuff (including manifest)

function LoadConfiguration() {
	param([string] $path)

	## Set up the defaults
	$script:TODOTXT_VERBOSE = $TRUE
	$script:TODOTXT_FORCE = $FALSE
	$script:TODOTXT_AUTO_ARCHIVE = $FALSE
	$script:TODOTXT_PRESERVE_LINE_NUMBERS = $FALSE
	$script:TODOTXT_DATE_ON_ADD = $TRUE
	
	$script:PRI_A = 'Yellow'
	$script:PRI_B = 'Green'
	$script:PRI_C = 'Cyan'
	$script:PRI_X = 'White'
	
	## Override the defaults with the configuration file
	if (Test-Path $path) {
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
	
	if (!$configLocation) {
		$configLocation = ($PSScriptRoot + '\todo_cfg.ps1')
	}
	
	LoadConfiguration $configLocation
	
	## TODO process command line options for overrides

	## TODO Add a command to mark pending
	
	$cmd = $args[0]
	
	# TODO Is there a better way to set a global variable? Or do we just collect it a the beginning of format priority?
	$fore = $Host.UI.RawUI.ForegroundColor

	if (!$cmd -or $cmd -eq "list" -or $cmd -eq "ls") {
		$todoArgs = @{path = $TODO_FILE; search = $args[1..$args.Length] }
		
		Format-Priority((Get-ToDo @todoArgs))
	}
	elseif ($cmd -eq "listall" -or $cmd -eq "lsa") {
		$todoArgs = @{path = $TODO_FILE; search = $args[1..$args.Length]; includeCompletedTasks = $TRUE }
		
		Format-Priority((Get-ToDo @todoArgs)) 
	}
	elseif ($cmd -eq "listfile" -or $cmd -eq "lf") {
		$todoArgs = @{path = $args[1]; search = $args[2..$args.Length] }
	
		Format-Priority((Get-ToDo @todoArgs))
	}
	elseif ($cmd -eq "add" -or $cmd -eq "a") {
		Add-Todo $args[1..$args.Length]
	}
	elseif ($cmd -eq "addm") {
		$split = $args[$args.Length - 1].Split([environment]::newline, [StringSplitOptions]'RemoveEmptyEntries')

		($split) | % {
			Add-ToDo $_
		}
	}
	elseif ($cmd -eq "rm" -or $cmd -eq "del") {
		Remove-ToDo $args[1] $args[2]
	}
	elseif ($cmd -eq "listproj" -or $cmd -eq "lsprj" ) {
		Get-Project
	}
	elseif ($cmd -eq "listcon" -or $cmd -eq "lsc" ) {
		Get-Contexts
	}
	elseif ($cmd -eq "listpri" -or $cmd -eq "lsp") {
		Format-Priority((Get-Priority $args[1]))
	}	
	elseif ($cmd -eq "replace") {
		Replace-ToDo $args[1] ([String]::Join(" ", $args[2..$args.Length]))
	}
	elseif ($cmd -eq "prepend" -or $cmd -eq "prep") {
		Prepend-ToDo $args[1] ([String]::Join(" ", $args[2..$args.Length]))
	}
	elseif ($cmd -eq "append" -or $cmd -eq "app") {
		Append-ToDo $args[1] ([String]::Join(" ", $args[2..$args.Length]))
	}
	elseif ($cmd -eq "do") {
		Set-ToDoComplete $args[1..$args.Length]
	}
	elseif ($cmd -eq "archive") {
		Archive-ToDo
	}
	elseif ($cmd -eq "pri" -or $cmd -eq "p") {
		Set-ToDoPriority $args[1] $args[2]
	}
	elseif ($cmd -eq "depri" -or $cmd -eq "dp") {
		Deprioritize-ToDo $args[1..$args.Length]
	}
	elseif ($cmd -eq "move" -or $cmd -eq "mv") {
		if ($args[3]) {
			Move-ToDo $args[1] $args[2] $args[3]
		}
		else {
			Move-ToDo $args[1] $args[2] 
		}
	}
	elseif ($cmd -eq "help") {
		Get-Help Todo
	}
}

function Format-Priority {
	param(
		[object[]] $numberedTasks
	)

	$numberedTasks | ForEach-Object {

		$pri = $_.Priority

		if ($pri -eq "A") {
			$Host.UI.RawUI.ForegroundColor = $PRI_A
		}
		elseif ($pri -eq "B") {
			$Host.UI.RawUI.ForegroundColor = $PRI_B
		}
		elseif ($pri -eq "C") {
			$Host.UI.RawUI.ForegroundColor = $PRI_C
		}
		elseif ($pri -match "[D-Z]") {
			$Host.UI.RawUI.ForegroundColor = $PRI_X
		}
		else {
			$Host.UI.RawUI.ForegroundColor = $fore
		}

		$_
	}

	$Host.UI.RawUI.ForegroundColor = $fore
}

function ParseToDoList {
	param(
		[string] $path = $TODO_FILE,
		[boolean] $includeCompletedTasks = $FALSE
	)
	
	if ($includeCompletedTasks -and $DONE_FILE -and (Test-Path $DONE_FILE)) {
		$listLocations = @($path, $DONE_FILE)
	}
	else {
		$listLocations = @($path)
	}
	
	$list = New-Object todotxtlib.net.TaskList

	## TODO doing this right now to support listall and multiple sources; could
	## just as easily support that directly in the library with params paths[]
	$results = @(Get-Content $listLocations)
		
	$results | ForEach-Object {
		$list.Add($_)
	}
		
	, $list
}

function Get-ToDo {
	param(
		[string[]] $search,
		[boolean] $includeCompletedTasks = $FALSE,
		[string] $path = $TODO_FILE
	)
	
	## TODO Error/warning message for no todo location set

	$list = ParseToDoList $path $includeCompletedTasks
	
	if ($search) {
		$search = [String]::Join(" ", $search).Trim() 
	}
	
	if (!$search) {
		return $list
	}
	
	## TODO - check for '-' at the beginning of the search term and handle notMatch
	($list.Search($search))
}

function Add-ToDo {
	param(
		[string[]] $item
	)
	
	$item = ([String]::Join(" ", $item)).Trim()

	$list = ParseToDoList

	$newTask = $list.Create($item, $TODOTXT_DATE_ON_ADD)
	
	$list.SaveTasks($TODO_FILE)

	if ($TODOTXT_VERBOSE) {
		Write-Host $newTask
		Write-Host "$($newTask.Number) added."
	}
}


function Set-ToDoComplete {
	param([int[]] $items)
	
	if (-not $items) {
		return
	}

	$list = ParseToDoList		

	$items | ForEach-Object { 

		if (-not $list.ItemExists($_)) {
			Write-Host "No task $_."
		}
		else {

			$task = $list.GetTask($_)

			if ($task.Completed) {
				Write-Host "$_ is already marked done."
			}
			else {
				$list.MarkCompleted($_)
					
				if ($TODOTXT_VERBOSE) {
					Write-Host ($task)
					Write-Host "TODO: $_ marked as done."
				}
			}

		}
	}
		
	$list.SaveTasks($TODO_FILE)
		
	if ($TODOTXT_AUTO_ARCHIVE) {
		Archive-ToDo
	}
}

function Get-Priority {
	param(
		[Nullable[char]] $priority 
	)

	$list = ParseToDoList
	$list.GetPriority($priority) 
}

# For Get-Context and Get-Project, we don't need to worry about item numbers. So even though we _could_ parse the whole list
# into a TaskList and retrieve all the tags from it, it's just as easy to do it in PowerShell-ish way and avoid the overhead

function Get-Context {
	Select-String $TODO_FILE -Pattern '\s(@\w+)' -AllMatches 
		| Select-Object -Property @{N = 'Context'; E = {$_.Matches.Groups[1].ToString()}} 
		|  Sort-Object -Property Context -Unique
}

function Get-Project {
	Select-String $TODO_FILE -Pattern '\s(\+\w+)' -AllMatches 
		| Select-Object -Property @{N = 'Project'; E = {$_.Matches.Groups[1].ToString()}} 
		|  Sort-Object -Property Project -Unique
}

function Set-ToDoPriority {
	param([int] $item,
		[string] $priority)

	if ($priority -match "^[A-Z]{1}$") {
		$list = ParseToDoList
		
		if (-not $list.ItemExists($_)) {
			Write-Host "No task $item."
		} 
		else {
			$list.SetItemPriority($item, $priority)
			$list.SaveTasks($TODO_FILE)

			## TODO This one never had an if(verbose) - should it?
		}
	} else{
		Write-Host "Priority must be A-Z"
	}
	
	## TODO show usage
}

function Deprioritize-ToDo {
	param([int[]] $items)
	
	if($items.Length -eq 0){
		return
	}

	$list = ParseToDoList
	
	$items | ForEach-Object {
		
		if (-not $list.ItemExists($_)) {
			Write-Host "No task $_."
		}
		else {
			$task = $list.GetTask($_)
			$list.ClearItemPriority($_)
			if ($TODOTXT_VERBOSE) {
				Write-Host ($task)
				Write-Host "TODO: $_ deprioritized."
			}
		}
	}
	
	$list.SaveTasks($TODO_FILE)
}

function Prepend-ToDo {
	param(
		[int] $item,
		[string] $term
	)

	if (-not $term) {
		Write-Host "Please specify the text"
		return
	}

	$list = ParseToDoList

	if (-not $list.ItemExists($_)) {
		Write-Host "No task $_."
		return
	}
	
	$list.PrependToTask($item, $term)
	$list.SaveTasks($TODO_FILE)
	
	if ($TODOTXT_VERBOSE) {
		$task = $list.GetTask($item)
		Write-Host $task
	}
}

function Append-ToDo {
	param(
		[int] $item,
		[string] $term
	)

	if (-not $term) {
		Write-Host "Please specify the text"
		return
	}

	$list = ParseToDoList

	if (-not $list.ItemExists($_)) {
		Write-Host "No task $_."
		return
	}
			
	$list.AppendToTask($item, $term)
	$list.SaveTasks($TODO_FILE)
	
	if ($TODOTXT_VERBOSE) {
		$task = $list.GetTask($item)
		Write-Host $task
	}
}

function Replace-ToDo {
	param(
		[int] $item,
		[string] $task
	)
		
	if (-not $task) {
		Write-Host "Please specify the replacement task"
		return
	}

	$list = ParseToDoList

	if (-not $list.ItemExists($_)) {
		Write-Host "No task $_."
		return
	}

	if ($TODOTXT_VERBOSE) {
		$oldTask = $list.GetTask($item)
		Write-Host $oldTask
	}
	
	$list.ReplaceTask($item, $task, $TODOTXT_DATE_ON_ADD)
	$list.SaveTasks($TODO_FILE)
	
	if ($TODOTXT_VERBOSE) {
		$newTask = $list.GetTask($item)
		Write-Host "TODO: Replaced task with:"
		Write-Host $newTask
	}
}

function Archive-ToDo {

	if(-not $DONE_FILE){
		Write-Error "'`$DONE_FILE' not specified; cannot archive"
		return
	}

	## Todo show an error if $DONE_FILE isn't specified
	if ($DONE_FILE) {
		$list = ParseToDoList
		$completed = $list.RemoveCompletedTasks($TODOTXT_PRESERVE_LINE_NUMBERS)
		
		# TODO SaveTasks could probably be an extension method that works for any 
		# IEnumerable<NumberedTask>, so saving would work for any of the "views"
		$completed.ToOutput() | Add-Content $DONE_FILE 
		$list.SaveTasks($TODO_FILE)
		
		if ($TODOTXT_VERBOSE) {
			$completed | ForEach-Object { Write-Host $_ }
			Write-Host "TODO: $TODO_FILE archived."
		}
	}
}

function Move-ToDo {
	param (
		[int] $item,
		[string] $dest,
		[string] $src = $TODO_FILE
	)
	
	if (-not $dest) {
		## TODO can we achieve the same thing by making the params required? can we get nice error messages?
		return;
	}

	if (!(Test-Path $dest)) {
		Set-Content $dest ''
	}
	
	$srcList = ParseToDoList $src

	if (-not $srcList.ItemExists($item)) {
		Write-Host "No task $item."
		return
	}
	
	$destList = ParseToDoList $dest

	$oldTask = $srcList.GetTask($item)

	$confirmed = $TRUE
	
	if (!$TODOTXT_FORCE) {
		$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", "Moves the task."
		$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", "Does nothing."

		$options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)

		$result = $host.ui.PromptForChoice("Move Item", "Move '$oldTask'?", $options, 1) 
			
		if ($result -eq 1) {
			$confirmed = $FALSE
		}
	}

	if (-not $confirmed) {
		if ($TODOTXT_VERBOSE) {
			## We need a WriteIfVerbose function
			Write-Host "TODO: No tasks moved."
		}

		return
	}
		
	## add it to the destination file
	$destList.Create($oldTask.ToString(), $TODOTXT_DATE_ON_ADD) | Out-Null
	$destList.SaveTasks($dest)
			
	## remove it from the original
	$srcList.RemoveTask($item, $TODOTXT_PRESERVE_LINE_NUMBERS)
	$srcList.SaveTasks($src) 
			
	if ($TODOTXT_VERBOSE) {
		Write-Host $oldTask
		Write-Host "TODO: $item moved from '$src' to '$dest'."
	}
}

function Remove-ToDo {
	param(
		[int] $item,
		[string] $term
	)
	
	$list = ParseToDoList
	
	if (-not $list.ItemExists($item)) {
		Write-Host "No task $item."
		return
	}

	$oldItem = $list.GetTask($item)
	
	if ($term) {
		$success = $list.RemoveFromTask($item, $term)
		$list.SaveTasks($TODO_FILE)
		
		if ($success) {
			$newItem = $list.GetTask($item)
			Write-Host "$item $oldItem"
			Write-Host "TODO: Removed '$term' from task."
			Write-Host "$item $newItem"
		}
		else {
			Write-Host "$item $oldItem"
			Write-Host "TODO: '$term' not found; no removal done."
		}
	}
	else {
		$confirmed = $TRUE
	
		if (!$TODOTXT_FORCE) {
			$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", "Deletes the task."
			$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", "Retains the task."

			$options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)

			$result = $host.ui.PromptForChoice("Delete Item", "Delete '$oldItem'?", $options, 1) 
			
			if ($result -eq 1) {
				$confirmed = $FALSE
			}
		}

		if ($confirmed) {
			$list.RemoveTask($item, $TODOTXT_PRESERVE_LINE_NUMBERS)
			$list.SaveTasks($TODO_FILE)
			
			if ($TODOTXT_VERBOSE) {
				Write-Host ("$item $oldItem") 
				Write-Host ("TODO: $item deleted")
			}
		}
		else {
			Write-Host "TODO: No tasks were deleted"
		}
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
