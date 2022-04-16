# Creating powershell config

### Steps (just a reminder)

**Create directories:**

```
.config/powershell

**create profile file:**
.config/powershell/user_profile.ps1

edit $PROFILE.CurrentUserCurrentHost: . $env:USERPROFILE\.config\powershell\user_profile.ps1
```
---

**Oh my posh:**
```

    Install-Module posh-git -Scope CurrentUser -Force
    Install-Module oh-my-posh -Scope CurrentUser -Force

Add to user profile:
Set-PoshPrompt powerlevel10_rainbow
```
---

### In case of slow prompt:
```

Add-MpPreference -ExclusionProcess "oh-my-posh.exe"

or 

Add-MpPreference -ExclusionPath "$env:POSH_PATH\oh-my-posh.exe"
```
