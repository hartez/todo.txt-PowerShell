$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

Describe "Get-HelloWorld" {
    It "does nothing because there's no input file" {
        Get-HelloWorld | Should BeNullOrEmpty
    }

    It "outputs the last line of the input file" {
        Get-HelloWorld data.txt | Should Be 'This is the last line'
    }
}


