@echo off

@powershell -NoLogo -ExecutionPolicy Bypass -File "%~dp0Backup-ExistingInstall.ps1"
@powershell -NoLogo -ExecutionPolicy Bypass -File "%~dp0Restore-ToSSD.ps1"