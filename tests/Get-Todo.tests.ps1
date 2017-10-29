$projectPath = $MyInvocation.MyCommand.Path | Split-Path | Split-Path

if(-not ($env:PSModulePath -like "*$projectPath*")){
	$env:PSModulePath = $env:PSModulePath + ";$projectPath" + '\'
}

$env:PSModulePath -split ";"

$ThisModule = $MyInvocation.MyCommand.Path -replace '\.tests\.ps1$'
$ThisModuleName = $ThisModule | Split-Path -Leaf
Get-Module -Name $ThisModuleName -All | Remove-Module -Force -ErrorAction Ignore
Import-Module -Name "$ThisModuleName" -Force -ErrorAction Stop

Describe "Get-Todo" {

	Context "using data.txt" {

		BeforeEach {
			Set-Variable -Name TODO_FILE -Value ".\tests\data.txt" -Scope Global
		}

		AfterEach {
			Remove-Variable -Name TODO_FILE -Scope Global
		}
		
		It "should list three tasks" {
			(Get-Todo | Measure-Object).Count | Should Be 3 -Verbose
		}

		It "should find the second task (-search)" {
			Get-Todo second | Should Be "This is the second line"
		}

		It "should find the third task (-search array)" {
			Get-Todo -search @("the", "last") | Should Be "This is the last line"
		}
			
	}

	Context "using data.txt and done.txt" {

		BeforeEach {
			Set-Variable -Name TODO_FILE -Value ".\tests\data.txt" -Scope Global
			Set-Variable -Name DONE_FILE -Value ".\tests\done.txt" -Scope Global
		}

		AfterEach {
			Remove-Variable -Name TODO_FILE -Scope Global
			Remove-Variable -Name DONE_FILE -Scope Global
		}

		It "should include completed tasks" {
			(Get-Todo -includeCompleted | Measure-Object).Count | Should Be 4
		}
		
	}

	Context "no todo file" {
		
		if( (Get-Variable -Name TODO_FILE -Scope Global).Value ){
			Remove-Variable -Name TODO_FILE -Scope Global
		}
		
		It "displays an error that there's no todo file specified" {
			{Get-Todo} | Should Throw '$TODO_FILE not set'
		}
	}
} 


