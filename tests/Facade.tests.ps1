. (Join-Path -Path ($MyInvocation.MyCommand.Path | Split-Path) -ChildPath "TestSetup.ps1")
EnsureTestEnvironment($MyInvocation.MyCommand.Path)



#function SetupTempList {
#	param([string] $path, [switch] $noTodoVariable)

#	if(-not $noTodoVariable){
#		Set-Variable -Name TODO_FILE -Value $path -Scope Global
#	}

#	$content = @"
#This is the first line
#This is the second line
#(D) This line has priority D
#This is the last line
#"@
#	Set-Content -Path $path -Value $content
#}

Mock LoadConfiguration { Write-Host "Mocked LoadConfiguration" } -ModuleName Facade
Mock Format-Priority { 
	param([object[]] $tasks)
	
	Write-Host "Mocked Format-Priority"

	$tasks | % { $_ } 

} -ModuleName Facade

Describe "Todo shell Facade" {

	Context "facade list" {
	
		BeforeEach {
			Set-Variable -Name TODO_FILE -Value ".\tests\data.txt" -Scope Global
		}
	
		AfterEach {
			Remove-Variable -Name TODO_FILE -Scope Global
		}

		It "should list tasks with the 'list' command aliases" -TestCases @( 
			@{ cmd = 'list' }
			@{ cmd = 'ls'; }
		) {
			param($cmd)
			((Todo $cmd) | Measure-Object).Count | Should Be 3 
			Assert-MockCalled -Scope It -ModuleName Facade -CommandName Format-Priority -Exactly 1
		}

	}
}