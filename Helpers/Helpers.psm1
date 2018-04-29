#
# Helpers.ps1
#

function ValidatePaths {
	param([string[]] $path)

	if(-not $path) {
		throw 'No task file specified' 
	}

	$path | % {
		if(-not (Test-Path($_))){
			throw "Task file $_ does not exist"
		}
	}
}

Export-ModuleMember -Function ValidatePaths