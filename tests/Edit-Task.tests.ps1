. (Join-Path -Path ($MyInvocation.MyCommand.Path | Split-Path) -ChildPath "TestSetup.ps1")
EnsureTestEnvironment($MyInvocation.MyCommand.Path)

Describe "Edit-Task" {
	
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
		
		It "should append content to the second task (index implied)" {
			Edit-Task 2 -Append "; this is appended"
			Get-Task second | Should Be "This is the second line; this is appended"
		}

		It "should append content to the second task using the Index parameter " {
			Edit-Task -Index 2 -Append "; this is appended"
			Get-Task second | Should Be "This is the second line; this is appended"
		}
	}

}