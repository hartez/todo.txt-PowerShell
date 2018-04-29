#
# todotxtlib.psm1
#
$assemblyPath = ($PSScriptRoot + '\staging\todotxtlib.net.dll')
$assemblyLoadPath = ($PSScriptRoot + '\lib')

if(!(Test-Path $assemblyLoadPath))
{
	New-Item $assemblyLoadPath -ItemType directory
}

$assemblyLoadPath = $assemblyLoadPath + '\todotxtlib.net.dll'

# Before we try to load up the newest version of the DLL, we need to see if it's already loaded
# so we'll try to New-Object a task list; if it fails, we'll know it's safe to copy the dll

Try
{
	Copy-Item -Path $assemblyPath -Destination $assemblyLoadPath	
}
Catch
{
	[system.exception]
}

Add-Type -Path $assemblyLoadPath

