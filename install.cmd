@echo off & setlocal enableextensions enabledelayedexpansion
::: ESC escape sequence
for /F "delims=#" %%E in ('"prompt #$E# & for %%E in (1) do rem"') do set "ESC=%%E"
::: BackSpace sequence
for /F "delims=#" %%E in ('"prompt #$H# & for %%E in (1) do rem"') do set "BS=%%E"
::: LineFeed sequence
(set LF=^
%=Do not remove this line=%
)

::: prepare photon image v1 v2
:: usage:
::  install.cmd <wslImage> <wslLocation> version=1|2 rootfs=4|5
:: first 2 parameters
set "wslImage=%~1" 
set "wslLocation=%~2"
:: проверяет и убирает последний слеш в папке
setlocal
set lastSign=!wslLocation:~-1!
if "!lastSign!"=="\" set "wslLocation=!wslLocation:~0,-1!"
endlocal

:: check them
if "%wslImage%"=="" (call :heredoc "%~f0" usage & exit /b 0)
if "%wslLocation%"=="" (call :heredoc "%~f0" usage & exit /b 0)
if not exist "%wslLocation%" mkdir "%wslLocation%"
if not exist "%wslLocation%" (call :heredoc "%~f0" usage & exit /b 0)

:: parsing arguments
call :parameters %*

if "%rootfs%"=="5.0" (
    set "rootfsFile=photon-rootfs-5.0-dde71ec57.x86_64.tar.gz"
    set "rootfsUri=https://github.com/vmware/photon-docker-image/raw/x86_64/5.0-20230501/docker/photon-rootfs-5.0-dde71ec57.x86_64.tar.gz"
) else if "%rootfs%"=="5" (
    set "rootfsFile=photon-rootfs-5.0-8ae19960d.x86_64.tar.gz"
    set "rootfsUri=https://github.com/vmware/photon-docker-image/raw/x86_64/5.0-20231028/docker/photon-rootfs-5.0-8ae19960d.x86_64.tar.gz"
) else if "%rootfs%"=="4.2" (
    set "rootfsFile=photon-rootfs-4.0-a450604a2.tar.gz"
    set "rootfsUri=https://github.com/vmware/photon-docker-image/raw/x86_64/4.0-20220114/docker/photon-rootfs-4.0-a450604a2.tar.gz"
) else if "%rootfs%"=="4.1" (
    set "rootfsFile=photon-rootfs-4.0-cf9b52506.tar.gz"
    set "rootfsUri=https://github.com/vmware/photon-docker-image/raw/x86_64/4.0-20210917/docker/photon-rootfs-4.0-cf9b52506.tar.gz"
) else if "%rootfs%"=="4.0" (
    set "rootfsFile=photon-rootfs-4.0-1526e30ba.tar.gz"
    set "rootfsUri=https://github.com/vmware/photon-docker-image/raw/x86_64/4.0-20210226/docker/photon-rootfs-4.0-1526e30ba.tar.gz"
) else (
    set "rootfs=4"
    set "rootfsFile=photon-rootfs-4.0-d6e3ca021.tar.gz"
    set "rootfsUri=https://github.com/vmware/photon-docker-image/raw/x86_64/4.0-20231028/docker/photon-rootfs-4.0-d6e3ca021.tar.gz"
)

if "%docker%"=="1" set "docker=24.0.7"
if defined docker set "dockerFile=docker-%docker%.tgz"
if defined docker set "dockerUri=https://download.docker.com/linux/static/stable/x86_64/%dockerFile%"

if "%mosh%"=="1" set "mosh=1.3.2"
if defined mosh set "moshFile=mosh-%mosh%.tar.gz"
if defined mosh set "moshUri=https://mosh.org/%moshFile%"

if defined tmux set "tmux=yes"
if defined tmux set "tmuxFile=tmux.conf.tar.gz"
if defined tmux set "tmuxUri=https://github.com/serguey/photon-wsl/raw/main/%moshFile%"

if defined powerline set "powerline=1.24"
if defined powerline set "powerlineFile=powerline-go-linux-amd64"
if defined powerline set "powerlineUri=https://github.com/justjanne/powerline-go/releases/download/v1.24/%powerlineFile%"

set "wsl=wsl -d %wslImage% -u root --cd ~ -- "

echo.
echo.%ESC%[20G%ESC%[1;34mPhoton %rootfs%%ESC%[1;33m WSL%version% OS post-install checker%ESC%[0;39m
echo.
echo.%ESC%[20G%ESC%[1;34mImage:%ESC%[1;33m %wslImage%%ESC%[0;39m
echo.%ESC%[20G%ESC%[1;34mLocation:%ESC%[1;33m %wslLocation%%ESC%[0;39m
echo.%ESC%[20G%ESC%[1;34mInstall docker:%ESC%[1;33m %docker%%ESC%[0;39m
echo.%ESC%[20G%ESC%[1;34mInstall mosh:%ESC%[1;33m %mosh%%ESC%[0;39m
echo.%ESC%[20G%ESC%[1;34mInstall tmux:%ESC%[1;33m %tmux%%ESC%[0;39m
echo.%ESC%[20G%ESC%[1;34mInstall powerline:%ESC%[1;33m %powerline%%ESC%[0;39m
echo.

call :isImageInstalled
call :status "Check WSL image" "Installed" "Not present" || (
    call :isImagePresent
    call :status "Check rootfs image" "Present" "Not present" || (
        powershell Invoke-WebRequest '%rootfsUri%' -outfile '%rootfsFile%'
        call :status "Downloading rootfs image"
    )
    call :isImagePresent || call :error "Error downloading rootfs" || exit /b 1
    call :startlog "Installing WSL image from rootfs"
    wsl --import %wslImage% "%wslLocation%\%wslImage%" "%rootfsFile%" --version %version%
    call :endlog
    call :status "WSL image from rootfs installed"
)
call :isImageInstalled || call :error "Error installing WSL image" || exit /b 2

call :caption "Configuring wsl.conf"
(
    %wsl% cat ^>/etc/wsl.conf ^<^(^
    echo ^[user] ;^
    echo default = root ;^
    echo ^[interop] ;^
    echo enabled = true ;^
    echo appendWindowsPath = false ;^
    echo ^[network] ;^
    echo generateHosts = true ;^
    echo generateResolvConf = true ;^
    echo hostname = %wslImage% ;^
    echo ^[automount] ;^
    echo enabled = true ;^
    echo mountFsTab = false ;^
    echo root = / ;^
    echo options = \^"metadata,case=off\^" ;^
    echo ^[boot] ;^
    echo systemd = false ;^
    echo command = /startup.sh ;^
    ^)
) >nul 2>nul
call :status

call :startlog "Terminating WSL image"
wsl -t %wslImage%
call :endlog
call :status "WSL image terminated"

call :caption "Starting WSL image"
(
    %wsl% echo Started
) >nul 2>nul
call :status

call :caption "Configuring system profile"
(
    %wsl% ^
    cd /etc/profile.d/ ^&^& ^( ^
    mv -f proxy.sh proxy.sh.disabled ^>/dev/null 2^>/dev/null ;^
    mv -f serial-console.sh serial-console.sh.disabled ^>/dev/null 2^>/dev/null ;^
    true ^)
) >nul 2>nul
call :status

call :caption "Installing dos2unix package"
(
    %wsl% dos2unix -V ^>/dev/null || tdnf -y install dos2unix
) >nul 2>nul
call :status

::: connect disk to copy files
call :caption "Connecting WSL image net share"
:: previous version
:: call :connectNetworkPath "\\wsl$\%wslImage%" wslDisk
:: now
call :connectImage %wslImage% wslDisk
call :status || call :error "Cannot connect WSL image as network share" || exit /b 3

call :caption "Copying startup script"
>"%wslDisk%\startup.sh" call :heredoc "%~f0" startup && (
    %wsl% ^
    dos2unix /startup.sh ^>/dev/null 2^>/dev/null ^&^& ^
    chown root:root /startup.sh ^&^& ^
    chmod u+rwx,g+rx,o+rx /startup.sh
) >nul 2>nul
call :status

::: .profile file
call :caption "Configuring root profile"
>"%wslDisk%\root\.profile" call :heredoc "%~f0" profile && (
    %wsl% ^
    dos2unix .profile ^>/dev/null 2^>/dev/null ^&^& ^
    chown root:root .profile ^&^& ^
    chmod u+rw,g+r .profile
) >nul 2>nul
call :status

::: .bashrc file
call :caption "Configuring bash profile"
>"%wslDisk%\root\.bashrc" call :heredoc "%~f0" bashrc && (
    %wsl% ^
    dos2unix .bashrc ^>/dev/null 2^>/dev/null ^&^& ^
    chown root:root .bashrc ^&^& ^
    chmod u+rw,g+r .bashrc
) >nul 2>nul
call :status

::: .bash_colors file
call :caption "Configuring bash colors"
>"%wslDisk%\root\.bash_colors" call :heredoc "%~f0" bashcolors && (
    %wsl% ^
    dos2unix .bash_colors ^>/dev/null 2^>/dev/null ^&^& ^
    chown root:root .bash_colors ^&^& ^
    chmod u+rw,g+r .bash_colors
) >nul 2>nul
call :status

:: call :caption "Disconnecting WSL image net share"
:: call :disconnectImage %wslDisk%
:: call :status || call :notice "Disconnect manually later"

call :caption "Configuring resolving"
(
    %wsl% /bin/bash -c "sed -i -r -e 's/^hosts:\s.*/hosts: files resolve dns/i' /etc/nsswitch.conf"
) >nul 2>nul
call :status

call :caption "Disable IPv6"
(
    %wsl% ^
    mkdir -p /etc/sysctl.d ^&^& cat ^>/etc/sysctl.d/99-disable-ipv6.conf ^<^(^
    echo net.ipv6.conf.all.disable_ipv6 = 1 ;^
    echo net.ipv6.conf.default.disable_ipv6 = 1 ;^
    echo net.ipv6.conf.lo.disable_ipv6 = 1 ;^
    ^)
) >nul 2>nul
call :status

call :caption "Updating package manager"
(
    %wsl% tdnf -q -y update tdnf ^>/dev/null 2^>/dev/null
) >nul 2>nul
call :status

:: base packages
for %%k in (tzdata ncurses-terminfo nano less curl tar glibc-i18n coreutils-selinux) do ^
call :installPackage "%%k"

:: remove packages
for %%k in (cronie motd cloud-init) do ^
call :removePackage "%%k"

call :startlog "Installing security updates"
(
    %wsl% /bin/bash -c "tdnf -q -y update $(tdnf updateinfo --list --updates | sed -r -e 's/.*\s(\S+)\.rpm$/\1/' -e '/0 updates/s/^.*$/tdnf/' | xargs echo)"
) 
::>nul 2>nul
call :endlog
call :status "Security updates installed"

:: mosh
if defined mosh (

:: save package list to restore later
call :caption "Saving packages list"
>mosh.tmp (
    %wsl% tdnf list --installed 2^>/dev/null ^| cut -f1 -d' '
) 2>nul
call :status

:: mosh compile packages
for %%k in (tar curl build-essential createrepo libevent-devel ncurses-devel openssl-devel zlib-devel) do ^
call :installPackage "%%k"

:: save new list to differ later
call :caption "Saving new packages list"
>mosh.compile.tmp (
    %wsl% tdnf list --installed 2^>/dev/null ^| cut -f1 -d' '
) 2>nul
call :status

:: download
call :startlog "Downloading mosh sources"
(
    %wsl% ^
    curl -L %moshUri% --output %moshFile% ^&^& ^
    tar xvzf %moshFile%
) >nul 2>nul
call :endlog
call :status "Mosh sources downloaded"

:: compile mosh
call :startlog "Compiling mosh binaries"
(
    %wsl% ^
    cd mosh-%mosh%/ ^&^& ^
    ./configure --silent --prefix=/usr ^&^& ^
    make --silent clean ^&^& ^
    make --silent ^&^& ^
    make --silent install ^&^& ^
    make --silent clean
) >nul 2>nul
call :endlog
call :status "Mosh binaries compiled"

:: check binaries installed
call :caption "Mosh binaries installed"
(
    %wsl% ^
    which mosh ^&^& ^
    ^[ -f /usr/bin/mosh ^] ^&^& ^
    mosh --version | grep -q %mosh%
) >nul 2>nul
call :status

:: remove packages for compiling
for /f "usebackq delims=. tokens=1" %%k in (`findstr /V /G:mosh.tmp mosh.compile.tmp`) do ^
call :removePackage "%%k"

:: delete folders and temp files
call :caption "Clean up after compile"
(
    del /f /q mosh.tmp mosh.compile.tmp && %wsl% rm -rf mosh-^*
) >nul 2>nul
call :status

)

::tmux
if defined tmux (

:: tmux packages
for %%k in (tmux xz awk tar) do ^
call :installPackage "%%k"

call :caption "Install tmux configuration"
(
    %wsl% ^
    cd /etc ^&^& ^
    curl -L %tmuxUri% --output /etc/%tmuxFile% ^&^& ^
    tar xvzf %tmuxFile% ^&^& ^
    rm -f %tmuxFile%
) >nul 2>nul
call :status

call :caption "Configuring tmux startup"
(
    %wsl% /bin/bash -c "sed -i -r -e '/tmux/s/# //g' /startup.sh"
) >nul 2>nul
call :status

)

::precompiled powerline-go
if defined powerline (

call :caption "Install precompiled powerline-go"
(
    %wsl% ^
    curl -L %powerlineUri% --output /usr/bin/powerline-go ^&^& ^
    chmod +x /usr/bin/powerline-go
) >nul 2>nul
call :status

)

:: docker
if defined docker (

:: docker pre packages
for %%k in (iptables xz awk tar) do ^
call :installPackage "%%k"

call :caption "Configuring iptables"
(
    %wsl% /bin/bash -c "sed -i -r -e 's/^-A INPUT -j ACCEPT//g' /etc/systemd/scripts/ip4save"
    %wsl% /bin/bash -c "sed -i -r -e 's/^-A OUTPUT.*/-A INPUT -j ACCEPT\n-A OUTPUT -j ACCEPT/g' /etc/systemd/scripts/ip4save"
) >nul 2>nul
call :status

call :caption "Install docker binaries"
(
    %wsl% ^
    curl %dockerUri% --output %dockerFile% ^&^& ^
    tar xvzf %dockerFile% ^&^& ^
    cp docker/* /usr/bin/ ^&^& ^
    mkdir -p /etc/docker ^&^& ^
    rm -rf docker docker*
) >nul 2>nul
call :status

call :caption "Configuring docker daemon"
>"%wslDisk%\etc\docker\daemon.json" call :heredoc "%~f0" docker && (
    %wsl% ^
    dos2unix /etc/docker/daemon.json ^>/dev/null 2^>/dev/null ^&^& ^
    chown root:root /etc/docker/daemon.json ^&^& ^
    chmod u+rw,g+r /etc/docker/daemon.json
) >nul 2>nul
call :status

call :caption "Configuring iptables startup"
(
    %wsl% /bin/bash -c "sed -i -r -e '/iptables/s/# //g' /startup.sh"
) >nul 2>nul
call :status

call :caption "Configuring docker startup"
(
    %wsl% /bin/bash -c "sed -i -r -e '/dockerd/s/# //g' /startup.sh"
) >nul 2>nul
call :status

)

call :caption "Configuring WSL startup"
if not defined docker if not defined tmux (
(
    %wsl% /bin/bash -c "sed -i -r -e '/^command\s*=\s*.*/s//command = /' /etc/wsl.conf"
    %wsl% rm -f /startup.sh ^>/dev/null 2^>/dev/null
) >nul 2>nul
)
call :status

call :caption "Disconnecting WSL image net share"
call :disconnectImage %wslDisk%
call :status || call :notice "Disconnect manually later"

call :startlog "Terminating WSL image"
wsl -t %wslImage%
call :endlog
call :status "WSL image terminated"

call :caption "Starting WSL image"
(
    %wsl% echo Started
) >nul 2>nul
call :status

:: previous version
:: call :caption "Disconnecting WSL image net share"
:: net use %wslDisk% /d >nul 2>nul
:: call :status || call :notice "Disconnect manually later"

exit /b 0

rem ********************************
rem     utility routines
rem ********************************

:installPackage
rem %1 - package
<nul set /p=%ESC%[0;39mInstall package %ESC%[1,33m%~1%ESC%[0,39m
(%wsl% tdnf --installed list %~1 ^>/dev/null 2^>/dev/null) >nul 2>nul
if not errorlevel 1 call :status "." "Present" "Absent"
if not errorlevel 1 exit /b 0
(%wsl% tdnf -q -y install %~1 ^>/dev/null 2^>/dev/null) >nul 2>nul
call :status
exit /b %errorlevel%

:removePackage
rem %1 - package
<nul set /p=%ESC%[0;39mRemove package %ESC%[1,33m%~1%ESC%[0,39m
(%wsl% tdnf --installed list %~1 ^>/dev/null 2^>/dev/null) >nul 2>nul
if errorlevel 1 call :status "." "Present" "Absent"
if errorlevel 1 exit /b 0
(%wsl% tdnf -q -y remove %~1 ^>/dev/null 2^>/dev/null) >nul 2>nul
call :status
exit /b %errorlevel%

:isImageInstalled
wsl -l -q --all >in.file
@<"in.file">"out.file" (for /f "delims=" %%i in ('find/v ""') do @chcp 1251>nul& set x=%%i& cmd/v/c echo[!x:*]^^=!)
type out.file | find "%wslImage%" >nul 2>&1 && set "notfound=0" || set "notfound=1"
del /f /q in.file out.file
exit /b %notfound%

:isImagePresent
if not exist "%rootfsFile%" exit /b 1
exit /b 0

:connectNetworkPath
rem %1 - network path
rem %2 - variable name for disk
setlocal enableextensions enabledelayedexpansion
set "psCommand=net use * "%~1" 2>nul | find ":"" && ^
for /f "usebackq tokens=2" %%i in (`!psCommand!`) do set "disk=%%i"
if "%disk%"=="" (
    set "connected=1"
) else (
    set "connected=0"
) 
endlocal & set "%2=%disk%" & exit /b %connected%

:connectImage
:: connect image as network drive and cd to it and assign drive to variable
:: %1 - image
:: %2 - variable name for disk
pushd \\wsl$\%~1 >nul 2>nul
if errorlevel 1 exit /b %ERRORLEVEL%
set "%2=%CD:~0,2%"
exit /b 0

:disconnectImage
:: disconnect image as previously connected network drive and cd to previous folder
:: %1 - network image drive
popd >nul 2>nul
net use %~1 /d >nul 2>nul
net use | find /I "%~1" >nul 2>nul && exit /b 1
exit /b 0

:parameters
shift & shift
call :args "%~1" "%~2" && goto parameters
if not defined version set "version=1"
if not "%version%"=="2" set "version=1"
:: if not defined rootfs set "rootfs=5"
:: if not "%rootfs%"=="4" set "rootfs=5"
if not defined docker set "docker=0"
if "%docker%"=="0" set "docker="
if not defined mosh set "mosh=0"
if "%mosh%"=="0" set "mosh="
if defined mosh set "tmux=1"
if not defined tmux set "tmux=0"
if "%tmux%"=="0" set "tmux="
if not defined powerline set "powerline=0"
if "%powerline%"=="0" set "powerline="
exit /b 0

:args
setlocal enableextensions enabledelayedexpansion
if "%~1"=="" endlocal & exit /b 1
if not "%~1"=="" endlocal & set "%~1=%~2" & exit /b 0


rem ********************************
rem     output routines
rem ********************************

:status
rem $1 - string description
rem $2 - OK destription
rem $3 - Failed description
set "CHECK=%ERRORLEVEL%"
setlocal
set "OK=%~2"
set "Failed=%~3"
echo|set /p="%ESC%[0;39m"
if not "%~1"=="" echo|set /p="%~1"
if "%~2"=="" set "OK=OK"
if "%~3"=="" set "Failed=Failed"
echo|set /p="%ESC%[70G[ "
if %CHECK% equ 0 (
    echo|set /p="%ESC%[1;32m%OK%"
) else (
    echo|set /p="%ESC%[1;31m%Failed%"
)
echo.%ESC%[0;39m ]
endlocal
exit /b %CHECK% 

:caption
rem $1 - string description
set "CHECK=%ERRORLEVEL%"
echo|set /p="%ESC%[0;39m"
if not "%~1"=="" echo|set /p="%~1"
exit /b %CHECK% 

:startlog
rem $1 - string description
echo|set /p="%ESC%[0;39m"
if not "%~1"=="" echo|set /p="%~1 ....."
echo.%ESC%[1;36m
exit /b 0 

:endlog
set "CHECK=%ERRORLEVEL%"
echo.%ESC%[0;39m
exit /b %CHECK% 

:error
rem %1 - string description
set "CHECK=%ERRORLEVEL%"
echo.%ESC%[10G%ESC%[1;41m*** %~1 ***%ESC%[0;39m
exit /b %CHECK% 

:notice
rem %1 - string description
set "CHECK=%ERRORLEVEL%"
echo.%ESC%[10G%ESC%[1;33m*** %~1 ***%ESC%[0;39m
exit /b %CHECK% 

rem ********************************
rem     heredoc routines
rem ********************************

:heredoc
@echo off
:: no need extra output
rem %1 - file
rem %2 - label
setlocal enableextensions enabledelayedexpansion
set script=%~1
rem to start ::::>label
rem to stop ::::<label
set "startLabel=::::>%~2"
set "stopLabel=::::<%~2"
rem start position
for /f "usebackq delims=: tokens=1" %%i in (`type "%script%" ^| findstr /b /n "%startLabel%"`) do @set "startPosition=%%i"
if not defined startPosition exit /b 1
rem stop position
for /f "usebackq delims=: tokens=1" %%i in (`type "%script%" ^| findstr /b /n "%stopLabel%"`) do @set "stopPosition=%%i"
rem errors
if not defined stopPosition exit /b 2
if %startPosition% equ %stopPosition% exit /b 3
if %startPosition% gtr %stopPosition% exit /b 4
rem lines count
set /a linesCount=stopPosition - startPosition
set /a linesCount=linesCount - 1
if %linesCount% equ 0 exit /b 5
rem unique files
call :uniqueFilename temp0 || exit /b 6
call :uniqueFilename temp1 || exit /b 6
call :uniqueFilename temp2 || exit /b 6
call :uniqueFilename temp3 || exit /b 6
call :uniqueFilename temp4 || exit /b 6
(
rem make empty file
type nul > "%temp0%"
rem another variant
rem >nul copy nul "%temp0%"
rem take part from start position
more +%startPosition% "%script%" > "%temp1%"
rem then compare with emty file printing only count lines
>"%temp2%" fc /t /lb%linesCount% "%temp0%" "%temp1%"
>"%temp3%"<"%temp2%" more +2
>"%temp4%"<"%temp3%" find /v "*****"
type "%temp4%"
rem variant below adds 2 empty lines at the end
rem fc "%temp0%" "%temp1%" /lb %linesCount% /t | find /v "*****" | more +2
)
set "errorCode=%errorlevel%"
rem cleaning
del /f /q "%temp0%" "%temp1%" "%temp2%" "%temp3%" "%temp4%" >nul 2>nul
endlocal & exit /b %errorCode%

:uniqueFilename
rem %1 - variable name
setlocal enableextensions enabledelayedexpansion
for /f "usebackq delims=, tokens=2" %%i in (`tasklist /fo csv /nh ^| find "tasklist"`) do set "n=%random%%%~i"
if not defined n exit /b 1
endlocal & set "%~1=%~dp0%n%.temp"
exit /b 0

rem ********************************
rem     heredocs
rem ********************************

::::>profile
if [ "$BASH" ]; then
  if [ -f ~/.bashrc ]; then
    . ~/.bashrc
  fi
fi
::::<profile

::::>bashrc
# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# don't put duplicate lines in the history. See bash(1) for more options
# ... or force ignoredups and ignorespace
HISTCONTROL=ignoredups:ignorespace

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
        # We have color support; assume it's compliant with Ecma-48
        # (ISO/IEC-6429). (Lack of such support is extremely rare, and such
        # a case would tend to support setf rather than setaf.)
        color_prompt=yes
    else
        color_prompt=
    fi

if [ "$color_prompt" = yes ]; then

PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ \[\e[0m\]'

else

PS1='\[\e[1;31m\]\u@\h [ \[\e[0m\]\w\[\e[1;31m\] ]# \[\e[0m\]'

fi

unset color_prompt

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias lsa='ls -al'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

function _update_ps1() {
    PS1="$(/usr/bin/powerline-go -hostname-only-if-ssh -error $? -jobs $(jobs -p | wc -l))"

    # Uncomment the following line to automatically clear errors after showing
    # them once. This not only clears the error for powerline-go, but also for
    # everything else you run in that shell. Don't enable this if you're not
    # sure this is what you want.

    #set "?"
}

if [ "$TERM" != "linux" ] && [ -f "/usr/bin/powerline-go" ]; then
    PROMPT_COMMAND="_update_ps1; $PROMPT_COMMAND"
fi
::::<bashrc

::::>bashcolors
# script for 256 color bash prompt used by .bashrc

orange=$(tput setaf 172)
peach=$(tput setaf 179)
light_green=$(tput setaf 107)
light_blue=$(tput setaf 104)
white=$(tput setaf 255)
reset=$(tput sgr0)
::::<bashcolors

::::>docker
{
  "hosts": ["tcp://0.0.0.0:2375","unix:///var/run/docker.sock"],
  "debug": false,
  "iptables": true,
  "ip6tables": false,
  "ipv6": false,
  "log-driver": "local",
  "log-opts": {
    "max-size": "5m"
  }
}
::::<docker

::::>startup
#!/bin/sh

# /etc/systemd/scripts/iptables &
# PATH=$PATH:/usr/sbin:/usr/bin:/bin dockerd &
# cd /root && ( DISPLAY=:0 XTERM=screen-256color SHELL=/bin/bash PWD=/root tmux -2u -f /etc/tmux.conf new-session -c /root -s root -d & )
::::<startup

::::>usage

prepare vmware photon os image v1 v2
usage:
  install.cmd <wslImage> <wslLocation> [version=1|2] [rootfs=4[.0|1|2]|5[.0]] [docker=0|1|x.x.x] [mosh=0|1|x.x.x] [tmux=0|1] [powerline=0|1]
  <wslImage> - name of WSL image
  <wslLocation> - folder to host WSL image folder
  version - WSL version (default 1)
  rootfs - photon os version (default 4 latest)
  docker - install docker (default 24.0.7)
  mosh - install mosh (default 1.3.2)
  tmux - install tmux (default with mosh)
  powerline - install powerline-go (default 1.24)
::::<usage
