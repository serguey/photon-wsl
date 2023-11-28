@echo off

setlocal enableextensions
setlocal enabledelayedexpansion

cd "%~dp0"

set "wslImage=mosh"
set "addr=%1"

if "%1"=="" set /p addr="Enter address: " 
if "!addr!"=="" (
    echo.No address
    exit /b 1
)
set "addr=!addr!"
title %addr%  2>NUL

wsl -d %wslImage% --cd ~ -- /bin/bash -c "LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 /usr/bin/mosh -4 --no-ssh-pty --experimental-remote-ip=local --ssh='ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR' -- %addr% tmux -2 new -AD -s root -c $(getent passwd root | cut -d: -f6) $(getent passwd root | cut -d: -f7)"


