@echo off

REM This script hasn't been fully tested yet. 
exit /b 255

REM #############################################################################
REM # gensessions.cmd - Non-Interactive Session File Generator for X2Go         #
REM # Copyright (C) 2025  Stefan Baur <X2GO-ML-1@baur-itcs.de>                  #
REM #                                                                           #
REM # This program is free software: you can redistribute it and/or modify      #
REM # it under the terms of the GNU General Public License as published by      #
REM # the Free Software Foundation, either version 3 of the License, or         #
REM # (at your option) any later version.                                       #
REM #                                                                           #
REM # This program is distributed in the hope that it will be useful,           #
REM # but WITHOUT ANY WARRANTY; without even the implied warranty of            #
REM # MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the             #
REM # GNU General Public License for more details.                              #
REM #                                                                           #
REM # You should have received a copy of the GNU General Public License         #
REM # along with this program.  If not, see <https://www.gnu.org/licenses/>.    #
REM #############################################################################


REM This is a script to generate a per-user session file from a template.
REM You might want to use this instead of an X2Go Session Broker.
REM The downside of this approach is that users need to have write
REM permission on the session file, so they can make changes to it.
REM
REM You could call this script either from your login script or from a
REM CMD file before starting X2GoClient.
REM
REM We assume X2GoClient is provided via a read-only LAN share and this
REM script, along with other X2Go-related startup scripts, is placed in
REM its parent directory, NOT in the x2goclient folder itself.

REM If you are using X2Go in a security-conscious environment, you SHOULD
REM NOT use the same user names in the X2Go environment that you are using
REM in your internal domain/realm, i.e. if you are john.doe@contoso.com,
REM and that is your login for your internal network, you should be using
REM something entirely different and anonymous/pseudonymous for your X2Go
REM environment. Otherwise, you are leaking information about account names
REM to potential adversaries that may have gained access to your DMZ/X2Go
REM environment, making their job of hacking your internal network a tad
REM bit easier.
REM You could, for example, use obfuscated login names or use generic ones from
REM a static mapping table, i.e. if john.doe@contoso.com has a numeric UID
REM of 1050 on your internal network, you could map it directly or add a fixed
REM number to that, say, 25, so he might be user1075@x2go.example.com in your 
REM X2Go environment.
REM

IF NOT EXIST "%~dp0\session-template" (
	IF NOT EXIST "%USERPROFILE%\.x2goclient\sessions" (
		echo "ERROR: No session template and no previous session config. Unable to continue."
		exit /b 1
	) ELSE (
		echo "WARNING: Session template not found, using previously generated session configuration."
		exit /b 2
	)

) ELSE (
	REM TODO add code to switch between otpstring, usermap or plain local user
	REM EITHER call the obfuscator script here - note that this requires a perl interpreter in your path
	IF EXIST "%~dp0\otpstring" (
		REM load the OTPSTRING from the file
		for /f "tokens=1" %%f in ("%~dp0\otpstring") do set OTPSTRING=%%f
		for /f "tokens=1" %%g in ('perl .\username-obfuscator.pl %USERNAME%' %OTPSTRING%) do set REMOTEUSERNAME=%%g
	) ELSE (
		echo "ERROR: No otpstring file found in folder "%~dp0". Unable to continue."
		exit /b 1
	)
	REM OR read the remote user name from a file that performs static mapping, like so:
	IF EXIST "%~dp0\usermap" (
		REM NOTE: if you have disabled fast user switching, you can skip this line and hard-code ENTRYNUM=1
		for /f "delims=: tokens=1" %%g in ('reg query HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\SessionData\ /s ^| findstr /i "LoggedOnSAMUser" ^| findstr /i /n "%COMPUTERNAME%\%USERNAME%"') do set ENTRYNUM=%%g
		REM fetch SID string from matching entry
		for /f "tokens=3" %%i in ('reg query HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\SessionData\%ENTRYNUM%\ /v LoggedOnUserSID') do set NUMUID="%%i
		REM scan usermap file for a matching SID
		for /f "tokens=1,2" %%m in ("%~dp0\usermap") do (
			REM once we have a match, set our REMOTEUSERNAME variable and exit the for loop
			IF "%%m" equ "%%NUMID%%" (
				set REMOTEUSERNAME=%%n
				exit /b
			)
		)
		IF
	) ELSE (
		echo "ERROR: No usermap file found in folder "%~dp0". Unable to continue."
		exit /b 1
	)
	REM if you do not wish to do either, uncomment the line below to default 
	REM to local user name = remote user name
	REM set REMOTEUSERNAME=%USERNAME%

	REM initialize session file
	IF type NUL >"%USERPROFILE%\.x2goclient\sessions" (

		REM replace "INSERTUSERPROFILE" in template file with %USERPROFILE value,
		REM replace "INSERTUSERNAME" in template file with REMOTEUSERNAME value,
		REM and write the line to the user's profile
		REM

		setlocal ENABLEDELAYEDEXPANSION
		for /f "delims=" %%i in ('type "%~dp0\session-template" ^& break ^> "%USERPROFILE%\.x2goclient\sessions" ') do (
			set "myline=%%i"
			set escup=%USERPROFILE:\=\\%
			call set "myline=!myline:INSERTUSERPROFILE=%%escup%%!"
			call set "myline=!myline:INSERTUSERNAME=%%REMOTEUSERNAME%%!"
			echo !myline! >>"%USERPROFILE%\.x2goclient\sessions" 
		)
		endlocal
	) ELSE (
		echo "ERROR: Could not create '%USERPROFILE%\.x2goclient\sessions' file. Unable to continue."
	)
)
