Write-Host "Facade module"
Import-Module Add-Task
Import-Module Edit-Task
Import-Module Get-Context
Import-Module Get-Project

<# 
.Synopsis
	TODO.TXT Command Line Interface for PowerShell 5.0

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
		
        Format-Priority((Get-Task @todoArgs))
    }
	elseif($cmd -eq "listall" -or $cmd -eq "lsa")
    {
		Format-Priority(Get-Task -Path @($TODO_FILE, $DONE_FILE)) 
    }
	elseif($cmd -eq "listfile" -or $cmd -eq "lf")
    {
		$todoArgs = @{path=$args[1]; search=$args[2..$args.Length]}
	
		Format-Priority((Get-Task @todoArgs))
    }
	elseif($cmd -eq "add" -or $cmd -eq "a")
	{
		$todo = ([String]::Join(" ", $args[1..$args.Length])).Trim()

		Write-Host "date on add: $TODOTXT_DATE_ON_ADD"

		Add-Task $todo -Path $TODO_FILE -PrefixDate:$TODOTXT_DATE_ON_ADD -Verbose:$TODOTXT_VERBOSE
	}
	elseif($cmd -eq "addm")
	{
		$split = $args[$args.Length - 1].Split([environment]::newline, [StringSplitOptions]'RemoveEmptyEntries')

		($split) | % {
			Add-Task $_ -Path $TODO_FILE -PrefixDate:$TODOTXT_DATE_ON_ADD -Verbose:$TODOTXT_VERBOSE
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
		Format-Priority((Get-Task -Priority $args[1]))
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
		Edit-TaskList $args[1] -Append ([String]::Join(" ", $args[2..$args.Length]))
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

function LoadConfiguration() {
	param([string] $path)

	## Set up the defaults
	$script:TODOTXT_VERBOSE = $FALSE

	## TODO Make all the PowerShellish bits use Write-Verbose instead of write-host
	## then have this variable control whether Todo passes the -Verbose switch to those commands
	## Once we see what this looks like, we may have to modify/redirect the output from Todo (get rid of Verbose:)
	## prefixes

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

export-modulemember -function Todo