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

function Add-Task {
	[cmdletbinding()]
	param(
		[Parameter(ValueFromPipeline, Mandatory=$true, Position = 0)]
		[string] $Task,
		[string] $Path = $TODO_FILE,
		[switch] $PrefixDate
	)

	Begin {
		ValidatePaths($path) 
	}

	Process {
		
		if($PrefixDate) 
		{
			$Task = ((Get-Date -format "yyyy-MM-dd") + " " + $Task)
		}

		Add-Content $Path $Task

		$taskNum = (Get-Content $Path | Measure-Object).Count
		Write-Verbose "$taskNum $Task"
		Write-Verbose "$taskNum added."
	}
}