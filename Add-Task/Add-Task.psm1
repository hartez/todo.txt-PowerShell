#
# Add_Task.psm1
#

Import-Module todotxtlib
Import-Module Helpers

## TODO Add pipeline tests 
## TODO Test with and without prefixdate
## TODO Test missing paths
## TODO Test bad paths
## TODO Test verbose

## TODO Determine once and for all what your parameter casing is going to be and make it consistent

function Add-Task {
	[cmdletbinding()]
	param(
		[Parameter(ValueFromPipeline, Mandatory=$true, Position = 0)]
		[string] $task,
		[string] $path = $TODO_FILE,
		[switch] $prefixDate
	)

	Begin {
		ValidatePaths($Path) 
	}

	Process {
		
		if($prefixDate) 
		{
			$task = ((Get-Date -format "yyyy-MM-dd") + " " + $task)
		}

		Add-Content $path $task

		$taskNum = (Get-Content $path | Measure-Object).Count
		Write-Verbose "$taskNum $task"
		Write-Verbose "$taskNum added."
	}
}