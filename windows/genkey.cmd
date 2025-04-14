@echo off

REM #############################################################################
REM # genkey.cmd - Non-Interactive SSH Key Pair Generator for X2Go              #
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

REM If you are using X2Go in a security-conscious environment, you SHOULD
REM NOT use AD or LDAP authentication against your internal domain/realm.
REM To make life easier for your users, you SHOULD use some alternate means
REM of single-sign-on (SSO) - an easy way for this is using SSH private/public
REM key pairs.
REM
REM This script checks for the presence of an SSH private key file named
REM 'x2gokey' in the %USERPROFILE% directory. If it does not exist, but
REM the ssh-keygen.exe tool can be found in the x2goclient subdirectory,
REM it will run the tool and generate a passwordless 521-bit ecdsa key
REM pair.
REM
REM You could call this script either from your login script or from a
REM CMD file before starting X2GoClient.
REM
REM We assume X2GoClient is provided via a read-only LAN share and this
REM script, along with other X2Go-related startup scripts, is placed in
REM its parent directory, NOT in the x2goclient folder itself.

IF NOT EXIST %USERPROFILE%\x2gokey (
	IF NOT EXIST "%~dp0\x2goclient\ssh-keygen.exe" (
		echo "ERROR: Keygen Tool not found, exiting."
	) ELSE (
		REM NOTE: if you have disabled fast user switching, you can skip this line and hard-code ENTRYNUM=1
		for /f "delims=: tokens=1" %%g in ('reg query HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\SessionData\ /s ^| findstr /i "LoggedOnSAMUser" ^| findstr /i /n "%COMPUTERNAME%\%USERNAME%"') do set ENTRYNUM=%%g
		REM TODO - add obfuscator or usermap matching here, use result instead of LEGALNAME
		for /f "tokens=2*" %%n in ('reg query HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\SessionData\%ENTRYNUM%\ /v LoggedOnDisplayName') do set LEGALNAME="%%o"
		echo "INFO: Creating public/private key pair."
		"%~dp0\x2goclient\ssh-keygen.exe"  -q -b 521 -t ecdsa -N "" -f "%USERPROFILE%\x2gokey" -C %LEGALNAME%
		IF NOT EXIST %USERPROFILE%\x2gokey (
			echo "ERROR: Could not create public/private key pair."
		) ELSE (
			echo "INFO: Created public/private key pair."
		)
	)
) ELSE (
		echo "INFO: Private key already present, nothing to do."
)
