# TODO Take all this boilerplate and make it reusable

$projectPath = $MyInvocation.MyCommand.Path | Split-Path | Split-Path

if(-not ($env:PSModulePath -like "*$projectPath*")){
	$env:PSModulePath = $env:PSModulePath + ";$projectPath" + '\'
}

$ThisModule = $MyInvocation.MyCommand.Path -replace '\.tests\.ps1$'
$ThisModuleName = $ThisModule | Split-Path -Leaf
Get-Module -Name $ThisModuleName -All | Remove-Module -Force -ErrorAction Ignore
Import-Module -Name "$ThisModuleName" -Force -ErrorAction Stop


Describe "Append-Todo" {
	
	Context "append tests" {
		
		BeforeEach {
			# Set up a throwaway txt data file
			Set-Variable -Name TODO_FILE -Value ".\tests\temp\appendtests.txt" -Scope Global

			$content = @"
This is the first line
This is the second line
This is the last line
"@
			Set-Content -Path $TODO_FILE -Value $content
		}

		AfterEach {
			Remove-Item $TODO_FILE
			Remove-Variable -Name TODO_FILE -Scope Global
		}
		
		It "should append content to the second item" {
			Append-Todo 2 "; this is appended"
			Get-Todo second | Should Be "This is the second line; this is appended"
		}
	}

}