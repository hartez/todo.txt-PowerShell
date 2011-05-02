$path = $env:homedrive + "\" + $env:homepath + "\Documents\WindowsPowerShell\Modules\todo"

if($args[0])
{
	$path = $args[0]
}

if(!(Test-Path $path))
{
	mkdir $path
}

$files = @("license.txt", "readme.markdown", `
 "todo.ps1xml", "todo.psd1", `
 "todo.psm1", "todo_cfg.ps1")

Copy-Item -path $files -destination $path

$path = $path + "\staging"

if(!(Test-Path $path))
{
	mkdir $path
}

Add-Type -AssemblyName "Microsoft.Build.Utilities.v3.5"
$msbuild = [Microsoft.Build.Utilities.ToolLocationHelper]::GetPathToDotNetFrameworkFile("msbuild.exe", "VersionLatest")

Write-Host $msbuild

& $msbuild /p:Configuration=Release /p:TargetVersion=v3.5 /fileLogger ".\todotxtlib.net\todotxtlib.net.csproj" 

Copy-Item -path .\todotxtlib.net\bin\Release\* -destination $path -force

Remove-Item "msbuild.log"

Write-Host ""
Write-Host ""
Write-Host "Todo.txt deployed - you'll need to restart PowerShell"
Write-Host "and call 'Import-Module todo' to load it"