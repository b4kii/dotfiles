# Creating powershell config

### Steps (just a reminder)

#### Create directories:

```
mkdir ~/.config/powershell
```

#### Create profile file:
```
nvim .config/powershell/user_profile.ps1 (put user config here)

nvim $PROFILE.CurrentUserCurrentHost
    . $env:USERPROFILE\.config\powershell\user_profile.ps1 (place this in file)
```
---

#### Oh my posh:
```
Install-Module posh-git -Scope CurrentUser -Force
Install-Module oh-my-posh -Scope CurrentUser -Force
```
---

#### Save theme in user profile:
```
Set-PoshPrompt powerlevel10_rainbow
```
---

### In case of slow prompt:
```
Add-MpPreference -ExclusionProcess "oh-my-posh.exe"
    or 
Add-MpPreference -ExclusionPath "$env:POSH_PATH\oh-my-posh.exe"
```
