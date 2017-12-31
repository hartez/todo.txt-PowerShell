. (Join-Path -Path ($MyInvocation.MyCommand.Path | Split-Path) -ChildPath "TestSetup.ps1")
EnsureTestEnvironment($MyInvocation.MyCommand.Path)

Describe "Get-Task" {  

	Context "invalid path" {
		It "throw because the path does not exist" {
			{Get-Task -Path "fail.txt"} | Should Throw "Task file fail.txt does not exist"
		}

		It "throw because one of the paths does not exist" {
			{Get-Task -Path @(".\tests\data.txt", "fail.txt")} | Should Throw "Task file fail.txt does not exist"
		}

		It "throw because no path was specified" {
			{Get-Task} | Should Throw "No task file specified"
		}
	}

	Context "using data.txt" {

		BeforeEach {
			Set-Variable -Name TODO_FILE -Value ".\tests\data.txt" -Scope Global
		}

		AfterEach {
			Remove-Variable -Name TODO_FILE -Scope Global
		}
		
		It "return three tasks" {
			(Get-Task | Measure-Object).Count | Should Be 3 
		}

		# TODO Change -Search -> -Include

		It "return the second task (-search)" {
			Get-Task second | Should Be "This is the second line"
		}

		It "return the third task (-search array)" {
			Get-Task -search @("the", "last") | Should Be "This is the last line"
		}
			
	} 

	Context "including completed tasks" {

		BeforeEach {
			Set-Variable -Name TODO_FILE -Value ".\tests\data.txt" -Scope Global
			Set-Variable -Name DONE_FILE -Value ".\tests\done.txt" -Scope Global
		}

		AfterEach {
			Remove-Variable -Name TODO_FILE -Scope Global
			Remove-Variable -Name DONE_FILE -Scope Global
		}

		It "return current and completed tasks from the done file" {
			(Get-Task -Path @($TODO_FILE, $DONE_FILE) | Measure-Object).Count | Should Be 4
		}
		
	}

	Context "no todo file" {
		
		if(Test-Path variable:global:TODO_FILE) {
			Remove-Variable -Name TODO_FILE -Scope Global
		}
		
		It "displays an error that there's no todo file specified" {
			{Get-Task} | Should Throw 'No task file specified'
		}
	}
}

Describe "Get-TaskList" {

	Context "specify path" {
	
		BeforeEach {
			if(Test-Path variable:global:TODO_FILE) {
				Remove-Variable -Name TODO_FILE -Scope Global
			}
		}

		It "gets a task list from the specified file" {
			(Get-TaskList -Path ".\tests\data.txt").Count | Should Be 3
		}
	}
}


