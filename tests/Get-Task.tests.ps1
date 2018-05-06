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

		BeforeEach { SetTODOVariables ".\tests\data.txt" }

		AfterEach { CleanTODOVariables }
		
		It "return all tasks in the file" {
			(Get-Task | Measure-Object).Count | Should Be 6 
		}

		# TODO Change -Search -> -Include

		It "return the second task (-search)" {
			Get-Task second | Should Be "This is the second line"
		}

		It "return the third task (-search array)" {
			Get-Task -search @("the", "last") | Should Be "This is the last line"
		}
		
		It "returns tasks filtered by Priority" {
			(Get-Task -Priority A | Measure-Object).Count | Should Be 1
			(Get-Task -Priority D | Measure-Object).Count | Should Be 2
		}	

		It "should return nothing because there is no match" {
			Get-Task nothing | Should Be $null
		}
	} 

	Context "including completed tasks" {

		BeforeEach { SetTODOVariables ".\tests\data.txt" ".\tests\done.txt" }

		AfterEach { CleanTODOVariables }

		It "return current and completed tasks from the done file" {
			(Get-Task -Path @($TODO_FILE, $DONE_FILE) | Measure-Object).Count | Should Be 7
		}
		
	}

	Context "no todo file" {
		
		CleanTODOVariables
		
		It "displays an error that there's no todo file specified" {
			{Get-Task} | Should Throw 'No task file specified'
		}
	}
}

Describe "Get-TaskList" {

	Context "specify path" {
	
		BeforeEach { CleanTODOVariables }

		It "gets a task list from the specified file" {
			(Get-TaskList -Path ".\tests\data.txt").Count | Should Be 6
		}
	}
}


