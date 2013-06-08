param (
    [CmdletBinding()]

    [parameter(Mandatory = $false, ValueFromPipeline = $false, Position = 0, HelpMessage = 'Should the user profile be modified to automatically load ToDo Module?')]
    [switch] $ModifyProfile,

    [parameter(Mandatory = $false, ValueFromPipeline = $true, Position = 1, HelpMessage = 'Path to install PowerShell Module too')]
    [string] $InstallPath = $env:homedrive + "\" + $env:homepath + "\Documents\WindowsPowerShell\Modules\todo",

    [parameter(Mandatory = $false, ValueFromPipeline = $false, Position = 2, HelpMessage = 'Path to todo.txt')]
    [ValidateScript({Test-Path $_})]
    [string] $TODO_FILE,

    [parameter(Mandatory = $false, ValueFromPipeline = $false, Position = 3, HelpMessage = 'Path to done.txt')]
    [ValidateScript({Test-Path $_})]
    [string] $DONE_FILE
    )

function Get-DropboxFolder {
    $appDataFolder = [Environment]::GetFolderPath('ApplicationData')
    [string[]] $dbPath = Get-Content $appDataFolder\Dropbox\host.db
    [byte[]] $base64text = [System.Convert]::FromBase64String($dbPath[1])
    return [System.Text.Encoding]::ASCII.GetString($base64text)
    }

$files = @("license.txt", "readme.markdown", "todo.ps1xml", "todo.psd1", "todo.psm1", "todo_cfg.ps1")

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

# Try and compile the .dll to make the magic happen.
try
{
    Write-Verbose "Adding Build Utilities"
    Add-Type -AssemblyName "Microsoft.Build.Utilities.v3.5"
    $msbuild = [Microsoft.Build.Utilities.ToolLocationHelper]::GetPathToDotNetFrameworkFile("msbuild.exe", "VersionLatest")

    Write-Host $msbuild

    & $msbuild /p:Configuration=Release /p:TargetVersion=v3.5 /fileLogger ".\todotxtlib.net\todotxtlib.net.3.5\todotxtlib.net.3.5.csproj" 
}
catch {
    throw "There was a problem compiling the dll. {0} Error: {1}" -f [Environment]::NewLine, $Error[0]
    break;
}

Write-Verbose "Copy the compiled dll to our staging directory."
Copy-Item -path .\todotxtlib.net\todotxtlib.net.3.5\bin\Release\todotxtlib.net.dll -destination $StagingPath -force

if ($ModifyProfile)
{
    $options = @()
    $options += new-Object System.Management.Automation.Host.ChoiceDescription ("&Yes","Continue")
    $options += new-Object System.Management.Automation.Host.ChoiceDescription ("&No","Exit")
    $choices = [System.Management.Automation.Host.ChoiceDescription[]]($Options)

    # if we weren't given the files.
    if (!$TODO_FILE -and $DONE_FILE)
    {
        Write-Verbose "Finding DropboxFolder"
        $DropboxFolder = Get-DropboxFolder
        Write-Debug "$DropboxFolder"

        $todofile = Test-Path $DropboxFolder\todo\todo.txt
        $donefile = Test-Path $DropboxFolder\todo\done.txt

        if ($todofile)
        {
            Write-Host "Todo File Located!" -foregroundcolor:Green
            Write-Host "Do you wish to use the file located at $DropboxFolder\todo\todo.txt ?"
            $Selection = $host.ui.PromptForChoice($caption,$message,$Choices,0)
            switch ($Selection)
            {
                0 {[string] $TODO_FILE = "$DropboxFolder\todo\todo.txt"}
                1 { $prompt = Read-Host "Please indicate the location of the todo.txt you wish to use?" }
            }
        }
        else {
            $prompt = Read-Host "Please indicate the location of the todo.txt you wish to use?"
        }

        if ($donefile)
        {
            Write-Host "Done File Located!" -foregroundcolor:Green
            Write-Host "Do you wish to use the file located at $DropboxFolder\todo\done.txt ?"
            $Selection = $host.ui.PromptForChoice($caption,$message,$Choices,0)
            switch ($Selection)
            {
                0 {[string] $DONE_FILE = "$DropboxFolder\todo\done.txt"}
                1 { $prompt = Read-Host "Please indicate the location of the done.txt you wish to use?" }
            }
        }
        else {
            $prompt = Read-Host "Please indicate the location of the done.txt you wish to use?"
        }
    }

    if ($TODO_FILE -and $DONE_FILE)
    {
        # Build our string builder. Super efficiency! A++
        Write-Verbose "Saving the PowerShell Profile"
        $stringBuilder = New-Object System.Text.StringBuilder

        # Check that the profile exists.
        if (Test-Path $profile)
        {
            # Get the current profile content
            [string[]] $profilecontent = Get-Content $profile

            # Doing a loop to preserve line breaks. :D
            foreach ($line in $profilecontent)
            {
                [void] $stringBuilder.append("$line")
                [void] $stringBuilder.append([Environment]::NewLine)
            }
            $debugString = $stringBuilder.toString()
            Write-Host "$debugString"
        }
        else {
            # No File. Need to create one. Borrowed straight from the example of new-item. http://technet.microsoft.com/library/hh849795.aspx
            new-item -path $profile -itemtype file -force
        }

        [void] $stringBuilder.append([Environment]::NewLine)
        [void] $stringBuilder.append("Import-Module todo")
        [void] $stringBuilder.append([Environment]::NewLine)
        [void] $stringBuilder.append("Set-Variable -Name TODO_FILE -Value '{0}'" -f $TODO_FILE )
        [void] $stringBuilder.append([Environment]::NewLine)
        [void] $stringBuilder.append("Set-Variable -Name DONE_FILE -Value '{0}'" -f $DONE_FILE )
        [void] $stringBuilder.append([Environment]::NewLine)
        $newprofile = $stringBuilder.toString();

        # Set the profile
        Write-Verbose "Saving the profile."
        Set-Content -Path $PROFILE -Value $newprofile
    }
}


Write-Host ""
Write-Host "Todo.txt deployed - you'll need to restart PowerShell" -NoNewLine
if (!$ModifyProfile) {Write-Host "and call 'Import-Module todo' to load it"}