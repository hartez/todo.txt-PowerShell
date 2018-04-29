. (Join-Path -Path ($MyInvocation.MyCommand.Path | Split-Path) -ChildPath "TestSetup.ps1")
EnsureTestEnvironment($MyInvocation.MyCommand.Path)

function SetupTempList {
	param([string] $path, [switch] $noTodoVariable)

	if(-not $noTodoVariable){
		Set-Variable -Name TODO_FILE -Value $path -Scope Global
	}

	$content = @"
This is the first line +project0 @context3
(A) This is the second line +project1 @context1
(D) This line has priority D @context2 @context4 +project0
(A) This is the last line
"@
	Set-Content -Path $path -Value $content
}

Mock LoadConfiguration { Write-Host "Mocked LoadConfiguration" } -ModuleName Facade
Mock Format-Priority { 
	param([object[]] $tasks)
	
	Write-Host "Mocked Format-Priority"

	$tasks | % { $_ } 

} -ModuleName Facade

Describe "Todo shell Facade" {

	Context "facade list" {
	
		BeforeEach { SetTODOVariables ".\tests\data.txt" }
	
		AfterEach { CleanTODOVariables }

		It "should list tasks with the 'list' command aliases" -TestCases @( 
			@{ cmd = 'list' }
			@{ cmd = 'ls'; }
		) {
			param($cmd)
			((Todo $cmd) | Measure-Object).Count | Should Be 6 
			Assert-MockCalled -Scope It -ModuleName Facade -CommandName Format-Priority -Exactly 1
		}

	}

	Context "facade listall" {

		BeforeEach { SetTODOVariables ".\tests\data.txt" ".\tests\done.txt" }

		AfterEach { CleanTODOVariables }

		It "should list tasks with the 'list' command aliases" -TestCases @( 
			@{ cmd = 'listall' }
			@{ cmd = 'lsa'; }
		) {
			param($cmd)
			((Todo $cmd) | Measure-Object).Count | Should Be 7 
			Assert-MockCalled -Scope It -ModuleName Facade -CommandName Format-Priority -Exactly 1
		}
	}

	Context "facade listfile" {

		It "should list tasks with the 'list' command aliases" -TestCases @( 
			@{ cmd = 'listfile' }
			@{ cmd = 'lf'; }
		) {
			param($cmd)
			((Todo $cmd ".\tests\data.txt") | Measure-Object).Count | Should Be 6 
			Assert-MockCalled -Scope It -ModuleName Facade -CommandName Format-Priority -Exactly 1
		}
	}

	Context "facade add" {

		BeforeEach { SetupTempList -Path ".\tests\temp\facade_add_tests.txt" }

		AfterEach { RemoveTempList }

		It "should add a task with the 'add' command aliases" -TestCases @( 
			@{ cmd = 'add' }
			@{ cmd = 'a'; }
		) {
			param($cmd)

			$content = "A new task"

			Todo $cmd $content
			((Todo list) | Measure-Object).Count | Should Be 5 
			Get-Task $content | Should Be $content
		}

		# TODO Add some tests to set up Verbose for this to make sure the messages are showing up
		# TODO Add some tests which set $TODOTXT_DATE_ON_ADD
	}

	Context "facade addm" {

		BeforeEach { SetupTempList -Path ".\tests\temp\facade_add_tests.txt" }

		AfterEach { RemoveTempList }

		It "should add multiple tasks with the 'addm' command alias" -TestCases @( 
			@{ cmd = 'addm' }
		) {
			param($cmd)

			$content = @"
task 1
task 2
task 3
"@

			Todo $cmd $content
			((Todo list) | Measure-Object).Count | Should Be 7 
			Get-Task "task 1" | Should Be "task 1"
			Get-Task "task 2" | Should Be "task 2"
			Get-Task "task 3" | Should Be "task 3"
		}

	}

	Context "facade rm" {

		BeforeEach { SetupTempList -Path ".\tests\temp\facade_rm_tests.txt" }

		AfterEach { RemoveTempList }

		It "should remove a task with the 'rm' command aliases" -TestCases @( 
			@{ cmd = 'rm' }
			@{ cmd = 'del'; }
		) {
			param($cmd)

			Todo $cmd 4
			((Todo list) | Measure-Object).Count | Should Be 3 
		}
	}

	Context "facade list projects" {

		BeforeEach { SetupTempList -Path ".\tests\temp\facade_listproj_tests.txt" }

		AfterEach { RemoveTempList }

		It "should list projects with the 'listproj' command aliases" -TestCases @( 
			@{ cmd = 'listproj' }
			@{ cmd = 'lsprj'; }
		) {
			param($cmd)

			((Todo $cmd) | Measure-Object).Count | Should Be 2 
		}
	}

	Context "facade list contexts" {

		BeforeEach { SetupTempList -Path ".\tests\temp\facade_listcon_tests.txt" }

		AfterEach { RemoveTempList }

		It "should list contexts with the 'listcon' command aliases" -TestCases @( 
			@{ cmd = 'listcon' }
			@{ cmd = 'lsc'; }
		) {
			param($cmd)

			((Todo $cmd) | Measure-Object).Count | Should Be 4 
		}
	}

	Context "facade list priority tasks" {

		BeforeEach { SetupTempList -Path ".\tests\temp\facade_listpri_tests.txt" }

		AfterEach { RemoveTempList }

		It "should list tasks with priorities 'listpri' command aliases" -TestCases @( 
			@{ cmd = 'listpri' }
			@{ cmd = 'lsp'; }
		) {
			param($cmd)

			((Todo $cmd A) | Measure-Object).Count | Should Be 2 
			((Todo $cmd D) | Measure-Object).Count | Should Be 1 
			Assert-MockCalled -Scope It -ModuleName Facade -CommandName Format-Priority -Exactly 2
		}
	}
	
	Context "facade append to task" {

		BeforeEach { SetupTempList -Path ".\tests\temp\facade_append_tests.txt" }

		AfterEach { RemoveTempList }

		It "should append to task with 'append' command aliases" -TestCases @( 
			@{ cmd = 'append' }
			@{ cmd = 'app'; }
		) {
			param($cmd)
			
			Todo $cmd 2 " some text" 
			Todo list "the second line" | Should Be "(A) This is the second line +project1 @context1 some text"
		}
	}

	
	# replace
	# prepend
	
	# do
	# archive
	# pri
	# move
	# help
}