<#
.SYNOPSIS

Submit image to the artifact rater web service, then use TTS to interpret the result.

.DESCRIPTION

Speak text using built in MS speech synthesis (SAPI5 .Net engine.) 

.PARAMETER Path
 (default from pipeline)
Input image cropped appropriately.

.INPUTS

System.String. You can pipe the "Path" parameter into the script

.OUTPUTS
Will play sound to speakers

.EXAMPLE
PS> .\Rate-Artifact.ps1 "13.png"

#>
[CmdletBinding()]
param (
	[Parameter(ValueFromPipeline = $true)] [ValidateScript({Test-Path $_ -PathType Leaf})] [string] $path
)
process {
	# Enter your custom parameters here
	#---
	$url = 'https://CHANGE-THIS-URL-development.up.railway.app/upload'
	$voice = "en-us"
	# speed rate between 0.5 and 6.0
	$rate = 1.5
	#---

	if ($url -match 'CHANGE-THIS') {
		[void][console]::beep(900,1000)
		throw "URL to web service not properly set."
	}

	$culture = [CultureInfo] $voice
	$sp = New-Object -ComObject SAPI.SpVoice
	$voiceinfo = $sp.GetVoices() | Where-Object { $_.ID -imatch $voice } | select -First 1
	if ($voiceInfo) {
		$sp.Voice = $voiceInfo
	} else {
		Write-Error "No voice found matching $voice"
		return
	}

	$sp.Rate = [math]::Clamp($rate, 0.5, 6.0);

	$r = $null
	try {
		$r = Invoke-RestMethod -Method Put -Infile $path $url
		# serialize to file
		$jsonpath = (get-item $path).Directory.FullName | Join-Path -ChildPath ([System.IO.Path]::GetFileNameWithoutExtension($path) + '.json')
		$r | ConvertTo-Json -Depth 30 | Set-Content $jsonpath
		# Default message: scor with one decimal place, main and sub rounded to integer
		[void]$sp.Speak('{0}<silence msec="1000"/>Main {1}<silence msec="500"/>Sub {2}' -f @($r.score.ToString('n1', $culture), $r.main_score.ToString('n0', $culture),$r.sub_score.ToString('n0', $culture)), 8)
	} catch {
		$_.Exception.GetType()
		$_
		$_.Exception.Response
		Write-Error "Failed $result"
		[void][console]::beep(320,300); [void][console]::beep(320,300)
	}
}

