#
# Get_Context.psm1
#

function Get-Context {
	$matches = (select-string $TODO_FILE -pattern '\s(@\w+)' -AllMatches) | % {$_.Matches}
	$matches | % {$_.Groups[1]} | Sort-Object | Get-Unique | Select -property @{N='Context';E={$_.Value}}
}