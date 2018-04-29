. (Join-Path -Path ($MyInvocation.MyCommand.Path | Split-Path) -ChildPath "TestSetup.ps1")
EnsureTestEnvironment($MyInvocation.MyCommand.Path)

function SetupTempList {
	param([string] $path, [switch] $noTodoVariable)

	if(-not $noTodoVariable){
		Set-Variable -Name TODO_FILE -Value $path -Scope Global
	}

	$content = @"
This is the first line
This is the second line
(D) This line has priority D
This is the last line
"@
	Set-Content -Path $path -Value $content
}

Describe "Add-Task" {

	Context "add tests" {
		
		Mock -ModuleName Add-Task Get-Date { return "1997-04-20" } -Verifiable -ParameterFilter {$format -match "yyyy-MM-dd"}

		Mock -ModuleName Add-Task Write-Verbose { $global:verboseOutput += $Message } 

		BeforeEach { SetupTempList -Path ".\tests\temp\addtests.txt" }

		AfterEach { 
			RemoveTempList 
			$global:verboseOutput = @()
		}
		
		It "should add a task to the list" {
			$body = "This is a new task"
			Add-Task $body
			Get-Task task | Should Be $body
		}

		It "should add a task with the date prefix" {
			$body = "This is a new task"
			Add-Task $body -PrefixDate
			Get-Task task | Should Be "1997-04-20 $body"
			Assert-VerifiableMocks 
		}

		It "should add a task and output verbose" {
			$body = "This is a new task"
			Add-Task $body -Verbose
			Get-Task task | Should Be $body

			Assert-VerboseOutput @("5 $body", "5 added.")
		}
	}
}