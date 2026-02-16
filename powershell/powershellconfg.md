# Creating powershell config

### Install starship
```
scoop install starship
```
### Edit powershell config at $env:userprofile\Documents\PowerShell

#### Install Z directory jumper

```
Install-Module -Name z -Force
```

---

#### Install PSReadline

```
Install-Module -Name PSReadLine -AllowPrerelease -Scope CurrentUser -Force -SkipPublisherCheck
```

---

#### Install fzf

```
choco install fzf
Install-Module -Name PSFzf -Scope CurrentUser -Force
```

---

### In case of slow prompt:

```
Add-MpPreference -ExclusionProcess "oh-my-posh.exe"

    or

Add-MpPreference -ExclusionPath "$env:POSH_PATH\oh-my-posh.exe"
```
