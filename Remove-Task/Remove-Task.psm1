#
# Remove_Task.psm1
#

## TODO Add and test with Force (have the facade pass in TODOTXT_FORCE
## TODO Can we test confirmation with Pester? Probably have to mock PromptForChoice
## TODO What does $TODOTXT_PRESERVE_LINE_NUMBERS do? Do we support that?
## TODO Test verbose ouput for term removal (found and not found)
## TODO Test verbose output for item removal (found and not)

Import-Module todotxtlib
Import-Module Helpers

function Remove-Task {
	[cmdletbinding()]
	param(
		[Parameter(ValueFromPipeline, Mandatory=$true, Position = 0)]
		[int] $index,
		[string] $term,
		[string] $path = $TODO_FILE
	)

	Begin {
		ValidatePaths($Path) 
	}

	Process {
		$list = Get-TaskList -path $path
		#$task = $list[$index - 1]
		$list.RemoveTask($index, $false)
		$list.ToOutput() | Set-Content $path 
	}
}