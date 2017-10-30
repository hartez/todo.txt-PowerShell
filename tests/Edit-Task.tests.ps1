. (Join-Path -Path ($MyInvocation.MyCommand.Path | Split-Path) -ChildPath "TestSetup.ps1")
EnsureTestEnvironment($MyInvocation.MyCommand.Path)

function SetupTempList {
	param([string] $path)

	Set-Variable -Name TODO_FILE -Value $path -Scope Global

	$content = @"
This is the first line
This is the second line
This is the last line
"@
	Set-Content -Path $TODO_FILE -Value $content
}

Describe "Edit-Task" {
	
	Context "append tests" {
		
		BeforeEach {
			# Set up a throwaway txt data file
			SetupTempList -Path ".\tests\temp\appendtests.txt"
		}

		AfterEach {
			Remove-Item $TODO_FILE
			Remove-Variable -Name TODO_FILE -Scope Global
		}
		
		It "should append content to the second task (index implied)" {
			Edit-Task 2 -Append "; this is appended"
			Get-Task second | Should Be "This is the second line; this is appended"
		}

		It "should append content to the second task using the Index parameter" {
			Edit-Task -Index 2 -Append "; this is appended"
			Get-Task second | Should Be "This is the second line; this is appended"
		}
	}

	Context "prepend tests" {
		
		BeforeEach {
			# Set up a throwaway txt data file
			SetupTempList -Path ".\tests\temp\prependtests.txt"
		}

		AfterEach {
			Remove-Item $TODO_FILE
			Remove-Variable -Name TODO_FILE -Scope Global
		}
		
		It "should prepend content to the second task (index implied)" {
			Edit-Task 2 -Prepend "this is in front;"
			Get-Task second | Should Be "this is in front;This is the second line"
		}

		It "should prepend content to the second task using the Index parameter" {
			Edit-Task -Index 2 -Prepend "this is in front;"
			Get-Task second | Should Be "this is in front;This is the second line"
		}
	}

	Context "replace tests" {
		
		BeforeEach {
			# Set up a throwaway txt data file
			SetupTempList -Path ".\tests\temp\replacetests.txt"
		}

		AfterEach {
			Remove-Item $TODO_FILE
			Remove-Variable -Name TODO_FILE -Scope Global
		}
		
		It "should replace content of the second task (index implied)" {
			Edit-Task 2 -Replace "this is what should be on the second line now"
			Get-Task second | Should Be "this is what should be on the second line now"
		}

		It "should prepend content to the second task using the Index parameter" {
			Edit-Task -Index 2 -Replace "this is what should be on the second line now"
			Get-Task second | Should Be "this is what should be on the second line now"
		}
	} 

	## TODO Add tests where Edit-Task takes a path to each context. (They'll fail, right now it assumes $TODO_FILE)
}

