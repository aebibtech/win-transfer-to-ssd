@echo off
rem main.cmd
rem Author: Paul Abib S. Camano

if exist "%~dp0Backup-ExistingInstall.ps1" (
  @powershell -NoLogo -ExecutionPolicy Bypass -File "%~dp0Backup-ExistingInstall.ps1"
)


if exist "%~dp0Restore-ToSSD.ps1" (
  @powershell -NoLogo -ExecutionPolicy Bypass -File "%~dp0Restore-ToSSD.ps1"
)