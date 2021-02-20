# Credits to https://github.com/shinchiro/mpv-packaging for the upgrade script
#
$script:zipname = "ShareX-portable.zip"

function Check-PowershellVersion {
    $version = $PSVersionTable.PSVersion.Major
    Write-Host "Checking Windows PowerShell version -- $version" -ForegroundColor Green
    if ($version -lt 5)
    {
        Write-Host "Using Windows PowerShell $version is unsupported. Upgrade your Windows PowerShell." -ForegroundColor Red
        throw
    }
}

function Check-Sharex {
    $shx = (Get-Location).Path + "\ShareX.exe"
    $is_exist = Test-Path $shx
    return $is_exist
}

function Get-Latest-Sharex {
    Write-Host "Fetching Releases RSS feed -- " -ForegroundColor Green -NoNewline
    $url = "https://github.com/ShareX/ShareX/releases.atom"
    $result = [xml][System.Net.WebClient]::new().DownloadString($url)
    if ($result.feed.entry[0].title -match 'ShareX (?<version>.+)') {
        Write-Host $Matches.version -ForegroundColor Yellow
        return $Matches.version
    }
    throw "Cannot read latest release info [$($result.feed.entry[0].title)] from $url. Aborting."
}

function Download-Sharex ($remoteTag) {
    Write-Host "Downloading ${script:zipname} ${remoteTag}..." -ForegroundColor Green
    $global:progressPreference = 'Continue'
    $link = "https://github.com/ShareX/ShareX/releases/download/{0}/{1}" -f $remoteTag, $script:zipname
    Invoke-WebRequest -Uri $link -MaximumRedirection 5 -UserAgent ([Microsoft.PowerShell.Commands.PSUserAgent]::FireFox) -OutFile $script:zipname
}

function Extract-Sharex ($zipfile) {
    Write-Host "Extracting " $zipfile -ForegroundColor Green
    Expand-Archive -Path $zipfile -DestinationPath . -Force
}

function ExtractVersionFromFile {
    return (Get-Item ./ShareX.exe).VersionInfo.ProductVersion
}

function Test-Admin
{
    $user = [Security.Principal.WindowsIdentity]::GetCurrent();
    (New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

function Upgrade-Sharex {
    $need_download = $false

    $remoteVersion = Get-Latest-Sharex
    if (Check-Sharex) {
        $localVersion = ExtractVersionFromFile
        if ($localVersion -match $remoteVersion)
        {
            Write-Host "You are already using the latest build -- $remoteVersion" -ForegroundColor Green
        }
        else {
            Write-Host "Newer build available" -ForegroundColor Green
            $need_download = $true
        }
    }
    else {
        Write-Host "ShareX does not exist. " -ForegroundColor Green -NoNewline
        $result = Read-KeyOrTimeout "Download ShareX $remoteVersion ? [Y/n] (default=y)" "Y"
        Write-Host ""
        if ($result -eq "Y") {
            $need_download = $true
        }
    }

    if ($need_download) {
        Download-Sharex "v${remoteVersion}"
        Extract-Sharex $script:zipname
        Remove-Item $script:zipname
    }
}

function Read-KeyOrTimeout ($prompt, $key){
    $seconds = 5
    $startTime = Get-Date
    $timeOut = New-TimeSpan -Seconds $seconds

    Write-Host "$prompt " -ForegroundColor Green

    # Basic progress bar
    [Console]::CursorLeft = 0
    [Console]::Write("[")
    [Console]::CursorLeft = $seconds + 2
    [Console]::Write("]")
    [Console]::CursorLeft = 1

    while (-not [Console]::KeyAvailable) {
        $currentTime = Get-Date
        Start-Sleep -s 1
        Write-Host "#" -ForegroundColor Green -NoNewline
        if ($currentTime -gt $startTime + $timeOut) {
            Break
        }
    }
    if ([Console]::KeyAvailable) {
        $response = [System.Console]::ReadKey($true).Key
        if ($response -eq [ConsoleKey]::Enter) {
            $response = $key
        }
    }
    else {
        $response = $key
    }
    return $response.ToString()
}

<#
.SYNOPSIS

Modifies the Powershell call action in HotkeysConfig.json

.PARAMETER scriptPath
Full path to Rate-Artifact.ps1
#>
function Set-ActionPathInShareX($scriptPath) {
    Write-Host "Setting .ps1 path in ShareX JSON config" -ForegroundColor Green
    $scriptDir = (get-item $scriptPath).Directory.FullName
    $jsonPath = Get-Location | Join-Path -ChildPath ShareX\HotkeysConfig.json
    $search = 'C:\\Tools\\ShareX\\scripts'
    $scriptPrefix = ($scriptDir | ConvertTo-Json) -replace '"', ''

    $arr = (Get-Content -Path $jsonPath -Encoding utf8).Replace($search, $scriptPrefix)
    if (!(Test-Path "C:\Program Files\PowerShell\7\pwsh.exe")) {
        $search_pwsh = ("%ProgramFiles%\PowerShell\7\pwsh.exe" | ConvertTo-Json) -replace '"', ''
        $replace_pwsh = ("%Windows%\System32\WindowsPowerShell\v1.0\powershell.exe" | ConvertTo-Json) -replace '"', ''
        $arr = $arr.Replace($search_pwsh, $replace_pwsh)
    }

    $arr | Set-Content $jsonPath -Encoding utf8
}

function Test-ScriptNeedsURL($scriptPath) {
    $test = Get-Content -Path $scriptPath | %{ $_ -match 'https://CHANGE-THIS-URL' }
    return $test -contains $true
}

function Set-ServerEndpointURL($scriptPath) {
    Add-Type -AssemblyName Microsoft.VisualBasic
    $value = [Microsoft.VisualBasic.Interaction]::InputBox('Please enter the URL for the server. An example is provided below.','Webservice URL Prompt', 'https://CHANGE-THIS-URL-development.up.railway.app/upload')

    (Get-Content -Path $scriptPath).Replace('https://CHANGE-THIS-URL-development.up.railway.app/upload', $value) |
        Set-Content $scriptPath
}


#
# Main script entry point
#
Check-PowershellVersion
Upgrade-Sharex

$ratingscript = Get-Location | Join-Path -ChildPath scripts\Rate-Artifact.ps1
Set-ActionPathInShareX $ratingscript
if (Test-ScriptNeedsURL $ratingscript) {
    Write-Host "Please enter the server URL in the dialog input box." -ForegroundColor Yellow
    Set-ServerEndpointURL $ratingscript
}

Write-Host "Operation completed" -ForegroundColor Magenta

&".\ShareX.exe"
