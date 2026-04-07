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
	TODO.TXT Command Line Interface for PowerShell 3.0

.Description
	The Invoke-TaskCommand function is an entry point for running functions to manipulate a todo.txt file 
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
function Invoke-TaskCommand {
	param()
	
	if (!$configLocation) {
		$configLocation = ($PSScriptRoot + '\todo_cfg.ps1')
	}
	
	LoadConfiguration $configLocation
	
	if($TODOTXT_VERBOSE){
		$VerbosePreference = 'Continue'
	}

	## TODO process command line options for overrides

	## TODO Add a command to mark pending
	
	$cmd = $args[0]
	
	# TODO Is there a better way to set a global variable? Or do we just collect it a the beginning of format priority?
	$fore = $Host.UI.RawUI.ForegroundColor

	if (!$cmd -or $cmd -eq "list" -or $cmd -eq "ls") {
		$todoArgs = @{path = $TODO_FILE; search = $args[1..$args.Length] }
		
		Format-Priority((Get-Task @todoArgs))
	}
	elseif ($cmd -eq "listall" -or $cmd -eq "lsa") {
		$todoArgs = @{path = $TODO_FILE; search = $args[1..$args.Length]; includeCompletedTasks = $TRUE }
		
		Format-Priority((Get-Task @todoArgs)) 
	}
	elseif ($cmd -eq "listfile" -or $cmd -eq "lf") {
		$todoArgs = @{path = $args[1]; search = $args[2..$args.Length] }
	
		Format-Priority((Get-Task @todoArgs))
	}
	elseif ($cmd -eq "add" -or $cmd -eq "a") {
		Add-Task $args[1..$args.Length]
	}
	elseif ($cmd -eq "addm") {
		$split = $args[$args.Length - 1].Split([environment]::newline, [StringSplitOptions]'RemoveEmptyEntries')

		($split) | % {
			Add-Task $_
		}
	}
	elseif ($cmd -eq "rm" -or $cmd -eq "del") {
		Remove-Task $args[1] $args[2]
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
		Set-Task $args[1] ([String]::Join(" ", $args[2..$args.Length]))
	}
	elseif ($cmd -eq "prepend" -or $cmd -eq "prep") {
		Edit-Task $args[1] $false ([String]::Join(" ", $args[2..$args.Length]))
	}
	elseif ($cmd -eq "append" -or $cmd -eq "app") {
		Edit-Task $args[1] $true ([String]::Join(" ", $args[2..$args.Length]))
	}
	elseif ($cmd -eq "do") {
		Set-TaskComplete $args[1..$args.Length]
	}
	elseif ($cmd -eq "archive") {
		Sync-TaskArchive
	}
	elseif ($cmd -eq "pri" -or $cmd -eq "p") {
		Set-TaskPriority $args[1] $args[2]
	}
	elseif ($cmd -eq "depri" -or $cmd -eq "dp") {
		Remove-TaskPriority $args[1..$args.Length]
	}
	elseif ($cmd -eq "move" -or $cmd -eq "mv") {
		if ($args[3]) {
			Move-Task $args[1] $args[2] $args[3]
		}
		else {
			Move-Task $args[1] $args[2] 
		}
	}
	elseif ($cmd -eq "help") {
		Get-Help Todo
	}
}

Set-Alias -Name todo -Value Invoke-TaskCommand

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

function Read-TaskList {
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

function Get-Task {
	param(
		[string[]] $search,
		[boolean] $includeCompletedTasks = $FALSE,
		[string] $path = $TODO_FILE
	)
	
	if(-not $path){
		Write-Error "Source path must be specified (have you set `$TODO_FILE?)"
		return
	}

	$list = Read-TaskList $path $includeCompletedTasks
	
	if ($search) {
		$search = [String]::Join(" ", $search).Trim() 
	}
	
	if (!$search) {
		return $list
	}
		
	$list.Search($search)
}

function Add-Task {
	param(
		[string[]] $item
	)
	
	$item = ([String]::Join(" ", $item)).Trim()

	$list = Read-TaskList

	$newTask = $list.Create($item, $TODOTXT_DATE_ON_ADD)
	
	$list.SaveTasks($TODO_FILE)

	Write-Verbose $newTask
	Write-Verbose "$($newTask.Number) added."
}

function Set-TaskComplete {
	param([int[]] $items)
	
	if (-not $items) {
		return
	}

	$list = Read-TaskList		

	$items | ForEach-Object { 

		if (-not $list.ItemExists($_)) {
			Write-Error "No task $_."
		}
		else {

			$task = $list.GetTask($_)

			if ($task.Completed) {
				Write-Verbose "$_ is already marked done."
			}
			else {
				$list.MarkCompleted($_)
				
				Write-Verbose ($task)
				Write-Verbose "TODO: $_ marked as done."
			}

		}
	}
		
	$list.SaveTasks($TODO_FILE)
		
	if ($TODOTXT_AUTO_ARCHIVE) {
		Sync-TaskArchive
	}
}

function Get-Priority {
	param(
		[Nullable[char]] $priority 
	)

	$list = Read-TaskList
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

function Set-TaskPriority {
	param([int] $item,
		[string] $priority)

	if ($priority -match "^[A-Z]{1}$") {
		$list = Read-TaskList
		
		if (-not $list.ItemExists($_)) {
			Write-Host "No task $item."
		} 
		else {
			$list.SetItemPriority($item, $priority)
			$list.SaveTasks($TODO_FILE)

			Write-Verbose "TODO: $item set to priority ($priority)"
		}
	} else{
		Write-Error "Priority must be A-Z"
	}
}

function Remove-TaskPriority {
	param([int[]] $items)
	
	if($items.Length -eq 0){
		return
	}

	$list = Read-TaskList
	
	$items | ForEach-Object {
		
		if (-not $list.ItemExists($_)) {
			Write-Error "No task $_."
		}
		else {
			$task = $list.GetTask($_)
			$list.ClearItemPriority($_)

			Write-Verbose ($task)
			Write-Verbose "TODO: $_ deprioritized."
		}
	}
	
	$list.SaveTasks($TODO_FILE)
}

function Edit-Task {
	param(
		[int] $item,   
		[bool] $append,
		[string] $term
	)

	if (-not $term) {
		Write-Error "Please specify the text"
		return
	}

	$list = Read-TaskList

	if (-not $list.ItemExists($_)) {
		Write-Error "No task $_."
		return
	}
	
	if ($append) {
		$list.AppendToTask($item, $term)
	}
	else {
		$list.PrependToTask($item, $term)
	}
	
	$list.SaveTasks($TODO_FILE)
	
	$task = $list.GetTask($item)
	Write-Verbose $task
}

function Set-Task {
	param(
		[int] $item,
		[string] $task
	)
		
	if (-not $task) {
		Write-Error "Please specify the replacement task"
		return
	}

	$list = Read-TaskList

	if (-not $list.ItemExists($_)) {
		Write-Error "No task $_."
		return
	}
	
	$oldTask = $list.GetTask($item)
		
	$list.ReplaceTask($item, $task, $TODOTXT_DATE_ON_ADD)
	$list.SaveTasks($TODO_FILE)
		
	$newTask = $list.GetTask($item)
	Write-Verbose $oldTask
	Write-Verbose "TODO: Replaced task with:"
	Write-Verbose $newTask
}

function Sync-TaskArchive {

	if(-not $DONE_FILE){
		Write-Error "'`$DONE_FILE' not specified; cannot archive"
		return
	}

	$list = Read-TaskList
	$completed = $list.RemoveCompletedTasks($TODOTXT_PRESERVE_LINE_NUMBERS)
	
	# TODO SaveTasks could probably be an extension method that works for any 
	# IEnumerable<NumberedTask>, so saving would work for any of the "views"
	$completed.ToOutput() | Add-Content $DONE_FILE 
	$list.SaveTasks($TODO_FILE)
	
	$completed | ForEach-Object { Write-Host $_ }
	Write-Verbose "TODO: $TODO_FILE archived."
}

function Move-Task {
	param (
		[int] $item,
		[string] $dest,
		[string] $src = $TODO_FILE
	)
	
	if (-not $dest) {
		## TODO can we achieve the same thing by making the params required? can we get nice error messages?
		Write-Error "Please specify a destination file"
		return;
	}

	if (!(Test-Path $dest)) {
		Set-Content $dest ''
	}
	
	$srcList = Read-TaskList $src

	if (-not $srcList.ItemExists($item)) {
		Write-Error "No task $item."
		return
	}
	
	$destList = Read-TaskList $dest

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
		Write-Verbose "TODO: No tasks moved."
		return
	}
		
	## add it to the destination file
	$destList.Create($oldTask.ToString(), $TODOTXT_DATE_ON_ADD) | Out-Null
	$destList.SaveTasks($dest)
			
	## remove it from the original
	$srcList.RemoveTask($item, $TODOTXT_PRESERVE_LINE_NUMBERS)
	$srcList.SaveTasks($src) 

	Write-Verbose $oldTask
	Write-Verbose "TODO: $item moved from '$src' to '$dest'."
}

function Remove-Task {
	param(
		[int] $item,
		[string] $term
	)
	
	$list = Read-TaskList
	
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

			Write-Verbose ("$item $oldItem") 
			Write-Verbose ("TODO: $item deleted")
		}
		else {
			Write-Host "TODO: No tasks were deleted"
		}
	}
}

export-modulemember -function Invoke-TaskCommand
