#
# Get_Project.psm1
#

function Get-Project {
	$matches = (select-string $TODO_FILE -pattern '\s(\+\w+)' -AllMatches) | % {$_.Matches}
	$matches | % {$_.Groups[1]} | Sort-Object | Get-Unique | Select -property @{N='Project';E={$_.Value}}
}