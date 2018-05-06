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


Describe "Remove-Task" {

	Context "remove tests" {
		
		Mock -ModuleName Add-Task Write-Verbose { $global:verboseOutput += $Message } 

		BeforeEach { SetupTempList -Path ".\tests\temp\addtests.txt" }

		AfterEach { 
			RemoveTempList 
			$global:verboseOutput = @()
		}
		
		It "should remove a task from the list" {
			Remove-Task 1
			(Get-Task | Measure-Object).Count | Should Be 3
			Get-Task first | Should Be $null
		}

		It "should throw because the index is out of range" {
			{Remove-Task 85} | Should Throw 'Task index 85 is out of range (list only has 4 tasks)'
		}

		#It "should add a task with the date prefix" {
		#	$body = "This is a new task"
		#	Add-Task $body -PrefixDate
		#	Get-Task task | Should Be "1997-04-20 $body"
		#	Assert-VerifiableMocks 
		#}

		#It "should add a task and output verbose" {
		#	$body = "This is a new task"
		#	Add-Task $body -Verbose
		#	Get-Task task | Should Be $body

		#	Assert-VerboseOutput @("5 $body", "5 added.")
		#}
	}
}