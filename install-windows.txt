# Work Agent Starter Pack installer (Windows PowerShell).
# What this does: downloads the pack and unpacks it into Documents\WorkAgent\pack.
# What it does NOT do: no admin rights, no changes outside that folder, no accounts touched.
# Read it before you run it. It is plain text.
$ErrorActionPreference = 'Stop'

$Base = if ($env:WORKAGENT_BASE_URL) { $env:WORKAGENT_BASE_URL } else { 'https://kazba22.github.io/wa-get-3r2mqx5p' }
$Dest = if ($env:WORKAGENT_DIR) { $env:WORKAGENT_DIR } else { Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'WorkAgent' }
$Code = $env:WORKAGENT_CODE

if ($Code) { $Url = "$Base/p/$Code/pack.zip" } else { $Url = "$Base/pack.zip" }

Write-Host 'Work Agent Starter Pack'
Write-Host "Installing into: $Dest"

$Tmp = Join-Path ([IO.Path]::GetTempPath()) ("wa-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $Tmp | Out-Null
try {
  $Zip = Join-Path $Tmp 'pack.zip'
  try { Invoke-WebRequest -Uri $Url -OutFile $Zip -UseBasicParsing }
  catch { Write-Host 'Download failed. Check your internet connection and your access code (if you were given one).'; exit 1 }

  New-Item -ItemType Directory -Force -Path $Dest | Out-Null
  $OldVersion = ''
  $VerFile = Join-Path $Dest 'pack\VERSION'
  if (Test-Path $VerFile) { $OldVersion = (Get-Content $VerFile -Raw).Trim() }

  $New = Join-Path $Dest 'pack.new'
  if (Test-Path $New) { Remove-Item $New -Recurse -Force }
  Expand-Archive -Path $Zip -DestinationPath $New -Force
  $Pack = Join-Path $Dest 'pack'
  if (Test-Path $Pack) { Remove-Item $Pack -Recurse -Force }
  Move-Item $New $Pack
  New-Item -ItemType Directory -Force -Path (Join-Path $Dest 'profile') | Out-Null

  $NewVersion = 'unknown'
  $NewVerFile = Join-Path $Pack 'VERSION'
  if (Test-Path $NewVerFile) { $NewVersion = (Get-Content $NewVerFile -Raw).Trim() }
  if ($OldVersion) { Write-Host "Updated: $OldVersion -> $NewVersion (your profile folder was not touched)" } else { Write-Host "Installed version: $NewVersion" }

  $Start = Join-Path $Pack 'onboarding\AGENT-START.md'
  if (-not (Test-Path $Start)) { Write-Host "Something is wrong: $Start is missing."; exit 1 }

  Write-Host ''
  Write-Host 'Done. Last step: open Aside, start a new task, and paste this:'
  Write-Host ''
  Write-Host "Read the file $Start and follow it exactly. Ask me to approve access to the folder $Dest if needed. Do not send any message or change any account."
  Write-Host ''
  Write-Host "(Do not have Aside yet? Install it from aside.com/download and connect your Claude subscription in Settings > Models > Providers first. See $Pack\onboarding\1-student-quickstart.md)"
}
finally { if (Test-Path $Tmp) { Remove-Item $Tmp -Recurse -Force -ErrorAction SilentlyContinue } }
