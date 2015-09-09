param (
    [CmdletBinding()]

    [parameter(Mandatory = $false, ValueFromPipeline = $false, Position = 0, HelpMessage = 'Should the user profile be modified to automatically load ToDo Module?')]
    [switch] $ModifyProfile,

    [parameter(Mandatory = $false, ValueFromPipeline = $true, Position = 1, HelpMessage = 'Path to install PowerShell Module to')]
    [string] $InstallPath = $env:homedrive + "\" + $env:homepath + "\Documents\WindowsPowerShell\Modules\todo",

    [parameter(Mandatory = $false, ValueFromPipeline = $false, Position = 2, HelpMessage = 'Path to todo.txt')]
    [ValidateScript({Test-Path $_})]
    [string] $TODO_FILE,

    [parameter(Mandatory = $false, ValueFromPipeline = $false, Position = 3, HelpMessage = 'Path to done.txt')]
    [ValidateScript({Test-Path $_})]
    [string] $DONE_FILE,

    [parameter(Mandatory = $false, ValueFromPipeline = $false, Position = 4, HelpMessage = 'Path to nuget.exe (if not already in your path)')]
    [string] $nugetExePath
)

function Get-DropboxFolder {
    $appDataFolder = [Environment]::GetFolderPath('ApplicationData')
    [string[]] $dbPath = Get-Content $appDataFolder\Dropbox\host.db
    [byte[]] $base64text = [System.Convert]::FromBase64String($dbPath[1])
    return [System.Text.Encoding]::ASCII.GetString($base64text)
}

function Get-ScriptDirectory
{
  $Invocation = (Get-Variable MyInvocation -Scope 1).Value
  Split-Path $Invocation.MyCommand.Path
}

$files = @("license.txt", "readme.markdown", "todo.ps1xml", "todo.psd1", "todo.psm1", "todo_cfg.ps1")


$ttlSearchPath = Join-Path `
		-Path (Get-ScriptDirectory) `
		-ChildPath packages\todotxtlib.net.*\lib\net35\todotxtlib.net.dll
		
$ttlPath = Get-ChildItem -Path $ttlSearchPath -ErrorAction SilentlyContinue |
	Select-Object -First 1 -ExpandProperty FullName 

if ($ttlpath -eq $null)
{
    # todotxtlib.net assembly not found - we will need nuget

    if(!$nugetExePath)
    {
        Write-Host "nuget.exe path not on command line. Using nuget.exe in current path"
    	$nugetExePath = 'nuget'
    }

    if (!(Test-Path -Path $nugetExePath -PathType Leaf))
    {
        Write-Host "nuget.exe not found at $nugetExePath. -nugetExePath must be full path name of nuget.exe. Exiting."
        exit
    }
}

if (!(Test-Path $InstallPath))
{
    Write-Debug "Install Path $InstallPath"
    mkdir $InstallPath | out-null
}

try {
    Write-Verbose "Copying files from current directory to $InstallPath"
    Copy-Item -path $files -destination $InstallPath -Force
}
catch {
    throw "Problem copying files to {0}" -f $InstallPath
    break;
}

$StagingPath = $InstallPath + "\staging"

if(!(Test-Path $StagingPath))
{
    Write-Verbose "Creating $StagingPath"
    mkdir $StagingPath | out-null
}

	
If ($ttlPath -eq $null) {
		
	Write-Host "todotxtlib.net assembly not found; retrieving it from NuGet"
		
	# Attempt to get the Razor libraries from nuget
	$packageDestination = ([string](Get-ScriptDirectory) + "\packages")
	if(!(Test-Path $packageDestination))
	{
		mkdir $packageDestination
	}
		
	$nugetCmd = '$nugetExePath install todotxtlib.net /OutputDirectory $packageDestination'
	iex "& $nugetCmd"
		
	# Now that it's installed, get the razor path again
	$ttlPath = Get-ChildItem -Path $ttlSearchPath |
		Select-Object -First 1 -ExpandProperty FullName
}

Write-Verbose "Copy the todotxtlib.net dll to our staging directory."
Copy-Item -path $ttlPath -destination $StagingPath -force

if ($ModifyProfile)
{
    $options = @()
    $options += new-Object System.Management.Automation.Host.ChoiceDescription ("&Yes","Continue")
    $options += new-Object System.Management.Automation.Host.ChoiceDescription ("&No","Exit")
    $choices = [System.Management.Automation.Host.ChoiceDescription[]]($Options)

    # if we weren't given the files.
    if (!$TODO_FILE)
    {
        Write-Verbose "Finding Dropbox Folder"
        $DropboxFolder = Get-DropboxFolder
        Write-Debug "$DropboxFolder"

        $todofile = Test-Path $DropboxFolder\todo\todo.txt
        
        if ($todofile)
        {
            Write-Host "Todo File Located!" -foregroundcolor:Green
            Write-Host "Do you wish to set your todo.txt path to $DropboxFolder\todo\todo.txt?"
            $Selection = $host.ui.PromptForChoice($caption,$message,$Choices,0)
            switch ($Selection)
            {
                0 {[string] $TODO_FILE = "$DropboxFolder\todo\todo.txt"}
                1 { $TODO_FILE = Read-Host "Please indicate the location of the todo.txt you wish to use" }
            }
        }
        else {
            $TODO_FILE = Read-Host "Please indicate the location of the todo.txt you wish to use"
        }
    }

    if ($TODO_FILE -and !$DONE_FILE)
    {
        Write-Verbose "Finding DropboxFolder"
        $DropboxFolder = Get-DropboxFolder
        Write-Debug "$DropboxFolder"
                
        $donefile = Test-Path $DropboxFolder\todo\done.txt

        if ($donefile)
        {
            Write-Host "Done File Located!" -foregroundcolor:Green
            Write-Host "Do you wish to set your done.txt path to $DropboxFolder\todo\done.txt?"
            $Selection = $host.ui.PromptForChoice($caption,$message,$Choices,0)
            switch ($Selection)
            {
                0 {[string] $DONE_FILE = "$DropboxFolder\todo\done.txt"}
                1 { $DONE_FILE = Read-Host "Please indicate the location of the done.txt you wish to use" }
            }
        }
        else {
            $DONE_FILE = Read-Host "Please indicate the location of the done.txt you wish to use"
        }
    }

    if ($TODO_FILE -and $DONE_FILE)
    {
        # Build our string builder. Super efficiency! A++
        Write-Verbose "Saving the PowerShell Profile"
        $stringBuilder = New-Object System.Text.StringBuilder

        # Check that the profile exists.
        if (!(Test-Path $profile))
        {
            # No File. Need to create one. Borrowed straight from the example of new-item. http://technet.microsoft.com/library/hh849795.aspx
            new-item -path $profile -itemtype file -force
        }
     
        [void] $stringBuilder.append([Environment]::NewLine)
        [void] $stringBuilder.append([Environment]::NewLine)
        [void] $stringBuilder.append("# Added by todo.txt PowerShell module")
        [void] $stringBuilder.append([Environment]::NewLine)
        [void] $stringBuilder.append("Import-Module -DisableNameChecking todo")
        [void] $stringBuilder.append([Environment]::NewLine)
        [void] $stringBuilder.append("Set-Variable -Name TODO_FILE -Value '{0}'" -f $TODO_FILE )
        [void] $stringBuilder.append([Environment]::NewLine)
        [void] $stringBuilder.append("Set-Variable -Name DONE_FILE -Value '{0}'" -f $DONE_FILE )
        [void] $stringBuilder.append([Environment]::NewLine)
        $newprofile = $stringBuilder.toString();

        Write-Verbose "Updating the profile."
        Add-Content $profile $newprofile
    } else { 
        Write-Host "Unable to update profile. You may have to run the deployment script again, or update your profile manually." 
    }
}

Write-Host ""
Write-Host "Todo.txt deployed - you'll need to restart PowerShell" -NoNewLine
if (!$ModifyProfile) {Write-Host " and call 'Import-Module todo' to load it"}
Write-Host ""