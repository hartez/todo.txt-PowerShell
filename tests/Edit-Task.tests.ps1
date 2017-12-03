#. (Join-Path -Path ($MyInvocation.MyCommand.Path | Split-Path) -ChildPath "TestSetup.ps1")
#EnsureTestEnvironment($MyInvocation.MyCommand.Path)

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

#Describe "Edit-Task" {
	
#	Context "append tests" {
		
#		BeforeEach {
#			# Set up a throwaway txt data file
#			SetupTempList -Path ".\tests\temp\appendtests.txt"
#		}

#		AfterEach {
#			Remove-Item $TODO_FILE
#			Remove-Variable -Name TODO_FILE -Scope Global
#		}
		
#		It "should append content to the second task (-index implied)" {
#			Edit-Task 2 -Append "; this is appended"
#			Get-Task second | Should Be "This is the second line; this is appended"
#		}

#		It "should append content to the second task using the Index parameter" {
#			Edit-Task -Index 2 -Append "; this is appended"
#			Get-Task second | Should Be "This is the second line; this is appended"
#		}
#	}

#	Context "explicit paths tests" {
#		BeforeEach {
#			# Set up a throwaway txt data file
#			SetupTempList -Path ".\tests\temp\explicit.txt" -noTodoVariable
#		}

#		AfterEach {
#			Remove-Item -Path ".\tests\temp\explicit.txt"
#		}

#		It "should append content to the second task" {

#			$x = ".\tests\temp\explicit.txt"

#			Write-Host $x

#			Edit-Task 2 -Append "; this is appended" -Path $x -Verbose
#			Get-Task second -Path $x | Should Be "This is the second line; this is appended"
#		}
#	}

#	Context "prepend tests" {
		
#		BeforeEach {
#			# Set up a throwaway txt data file
#			SetupTempList -Path ".\tests\temp\prependtests.txt"
#		}

#		AfterEach {
#			Remove-Item $TODO_FILE
#			Remove-Variable -Name TODO_FILE -Scope Global
#		}
		
#		It "should prepend content to the second task (index implied)" {
#			Edit-Task 2 -Prepend "this is in front;"
#			Get-Task second | Should Be "this is in front;This is the second line"
#		}

#		It "should prepend content to the second task using the Index parameter" {
#			Edit-Task -Index 2 -Prepend "this is in front;"
#			Get-Task second | Should Be "this is in front;This is the second line"
#		}
#	}

#	Context "replace tests" {
		
#		BeforeEach {
#			# Set up a throwaway txt data file
#			SetupTempList -Path ".\tests\temp\replacetests.txt"
#		}

#		AfterEach {
#			Remove-Item $TODO_FILE
#			Remove-Variable -Name TODO_FILE -Scope Global
#		}
		
#		It "should replace content of the second task (index implied)" {
#			Edit-Task 2 -Replace "this is what should be on the second line now"
#			Get-Task second | Should Be "this is what should be on the second line now"
#		}

#		It "should prepend content to the second task using the Index parameter" {
#			Edit-Task -Index 2 -Replace "this is what should be on the second line now"
#			Get-Task second | Should Be "this is what should be on the second line now"
#		}
#	} 

#	Context "mixed append/prepend/replace tests" {
#		BeforeEach {
#			# Set up a throwaway txt data file
#			SetupTempList -Path ".\tests\temp\mixedtests.txt"
#		}

#		AfterEach {
#			Remove-Item $TODO_FILE
#			Remove-Variable -Name TODO_FILE -Scope Global
#		}

#		It "should append and prepend content to the second task using the Index parameter" {
#			Edit-Task -Index 2 -Append "end" -Prepend "begin"
#			Get-Task second | Should Be "beginThis is the second lineend"
#		}

#		It "should replace then prepend/append content in the second task" {
#			Edit-Task -Index 2 -Replace "second task" -Append " end" -Prepend "begin "
#			Get-Task second | Should Be "begin second task end"
#		}
#	}

#	## TODO Add tests where Edit-Task takes a path to each pester Context. (They'll fail, right now it assumes $TODO_FILE) (path should be optional parameter with index) 
#	# This might make the parameter sets ugly; maybe this is what dynamic parameter sets are for?

	

#	Context "invalid item numbers" {

#		## TODO Test that passing in an invalid item number writes to verbose output but doesn't fail (eventually we'll want to think about that)
#		# So we need to hook into Write-Verbose here

#		BeforeEach {
#			# Set up a throwaway txt data file
#			SetupTempList -Path ".\tests\temp\invaliditemnumbers.txt"
#		}

#		AfterEach {
#			Remove-Item $TODO_FILE
#			Remove-Variable -Name TODO_FILE -Scope Global
#		}

#		It "should do nothing because this is an invalid item number" {
#			Edit-Task 10 -Priority "A"
#		}
#	}

#	Context "set priority" {

#		BeforeEach {
#			# Set up a throwaway txt data file
#			SetupTempList -Path ".\tests\temp\priorities.txt"
#		}

#		AfterEach {
#			Remove-Item $TODO_FILE
#			Remove-Variable -Name TODO_FILE -Scope Global
#		}

#		It "should set the first task's priority to A" {
#			Edit-Task 1 -Priority "A"
#			Get-Task first | Should Be "(A) This is the first line"
#		}

#		It "should throw an exception because the priority is invalid (two letters)" {
#			{Edit-Task 1 -Priority "AA"} | Should Throw "invalid"
#		}

#		It "should throw an exception because the priority is invalid (number)" {
#			{Edit-Task 1 -Priority "1"} | Should Throw "invalid"
#		}

#		It "should throw an exception because the priority is invalid (a space)" {
#			{Edit-Task 1 -Priority " "} | Should Throw "invalid"
#		}

#		It "should throw an exception because the priority is invalid (empty string)" {
#			{Edit-Task 1 -Priority ""} | Should Throw "cannot bind"
#		}

#		It "should throw because it's mixing parameter sets (append and set priority)" {
#			{Edit-Task 1 -Append "derp" -Priority "A"} | Should Throw "parameter set"
#		}

#		It "should throw because it's mixing parameter sets (set priority and clear priority)" {
#			{Edit-Task 1 -ClearPriority -Priority "A"} | Should Throw "parameter set"
#		}

#		It "should throw because it's mixing parameter sets (append and clear priority)" {
#			{Edit-Task 1 -ClearPriority -Append "this will fail"} | Should Throw "parameter set"
#		}

#	}

#	Context "clear priorities" {
#		BeforeEach {
#			# Set up a throwaway txt data file
#			SetupTempList -Path ".\tests\temp\priorities.txt"
#		}

#		It "should clear the priority from the third task" {
#			Get-Task "priority D" | Should Be "(D) This line has priority D"
#			Edit-Task 3 -ClearPriority
#			Get-Task "priority D" | Should Be "This line has priority D"
#		}

#		It "should clear the priorities from each task passed in" {
			
#			Edit-Task 1 -Priority "A"
			
#			# Tasks 1 and 3 are priority tasks
#			Get-Task "first" | Select-Object -ExpandProperty Priority | Should Be "A"
#			Get-Task "line has" | Select-Object -ExpandProperty Priority | Should Be "D"

#			1,3 | Edit-Task -ClearPriority -Verbose

#			Get-Task "first" | Select-Object -ExpandProperty Priority | Should Be ""
#			Get-Task "line has" | Select-Object -ExpandProperty Priority | Should Be ""
#		}
#	}
#}

