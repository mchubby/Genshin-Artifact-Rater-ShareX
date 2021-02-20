### Documentation for PC side

> For the server side, see https://github.com/mchubby/Genshin-Artifact-Rater/wiki

1. Download the zipball and extract
2. Run the FirstTimeSetup.ps1 (either with the context menu or from a powershell prompt in the current directory)
3. You will be prompted for the server URL. Then, ShareX.exe will be launched.
4. Alt-Tab to the game and go to the artifact list
5. Press Alt+Print Screen and select a wide enough rectangle so that any stats will fit in


1 long beep = something wrong happened

2 short beeps = the server query failed, check your dashboard deployment logs to see if /upload was called and if there is a stacktrace mentioning an error.

Otherwise, the speech synthesis should output the result.

The response from the server is saved as a .json file.


### Customizations

Edit `scripts/Rate-Artifact.ps1` to customize the spoken message.

You can also set the voice language and speech rate
```powershell
	$voice = "en-us"
	$rate = 1.5
```

You can also edit the hotkey task in ShareX:

- The shortcut can be changed from Alt + PrtScr
- If you want to preserve the screenshots as full color, remove the image effect processing ('Grayscale') in the shortcut key task settings
- Same if you want to change the output path or name it differently (e.g. by date & time)
