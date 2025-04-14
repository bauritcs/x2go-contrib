@echo off

REM #############################################################################
REM # gensettings.cmd - Non-Interactive Settings File Generator for X2Go        #
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


REM This is a script to generate a "sane" per-user settings file for X2GoClient.
REM
REM You could call this script either from your login script or from a
REM CMD file before starting X2GoClient.
REM
REM We assume X2GoClient is provided via a read-only LAN share and this
REM script, along with other X2Go-related startup scripts, is placed in
REM its parent directory, NOT in the x2goclient folder itself.

IF NOT EXIST "%USERPROFILE%\.x2goclient" (
	IF md "%USERPROFILE%\.x2goclient" (
		echo "INFO: Created '%USERPROFILE%\.x2goclient'	folder."
	) ELSE (
		echo "ERROR: Could not create '%USERPROFILE%\.x2goclient' folder. Unable to continue."
		exit /b 1
	)
)
IF NOT EXIST "%USERPROFILE%\.x2goclient\settings" (
	IF type NUL >"%USERPROFILE%\.x2goclient\settings" (
		echo "[trayicon]">"%USERPROFILE%\.x2goclient\settings"
		echo "enabled=true">>"%USERPROFILE%\.x2goclient\settings"
		echo "mintotray=true">>"%USERPROFILE%\.x2goclient\settings"
		echo "noclose=true">>"%USERPROFILE%\.x2goclient\settings"
		echo "mincon=true">>"%USERPROFILE%\.x2goclient\settings"
		echo "maxdiscon=true">>"%USERPROFILE%\.x2goclient\settings"
		echo.>>"%USERPROFILE%\.x2goclient\settings"
		echo "[pulse]">>"%USERPROFILE%\.x2goclient\settings"
		echo "norecord=true">>"%USERPROFILE%\.x2goclient\settings"
		echo "disable=false">>"%USERPROFILE%\.x2goclient\settings"
		echo.>>"%USERPROFILE%\.x2goclient\settings"
		echo "[General]">>"%USERPROFILE%\.x2goclient\settings"
		echo "useintx=true">>"%USERPROFILE%\.x2goclient\settings"
		echo "xexec=C:\\program files\\vcxsrv\\vcxsrv.exe">>"%USERPROFILE%\.x2goclient\settings"
		echo "options=-multiwindow -notrayicon -clipboard">>"%USERPROFILE%\.x2goclient\settings"
		echo "onstart=true">>"%USERPROFILE%\.x2goclient\settings"
		echo "noprimaryclip=false">>"%USERPROFILE%\.x2goclient\settings"
		echo "optionswin=-screen 0 %wx%h -notrayicon -clipboard">>"%USERPROFILE%\.x2goclient\settings"
		echo "optionsfs=-fullscreen -notrayicon -clipboard">>"%USERPROFILE%\.x2goclient\settings"
		echo "optionssingle=-multiwindow -notrayicon -clipboard">>"%USERPROFILE%\.x2goclient\settings"
		echo "optionswholedisplay=-nodecoration -notrayicon -clipboard -screen 0 @">>"%USERPROFILE%\.x2goclient\settings"
	) ELSE (
		echo "ERROR: Could not create '%USERPROFILE%\.x2goclient\settings' file. Unable to continue."
		exit /b 1
	)
) ELSE (
		echo "INFO: File '%USERPROFILE%\.x2goclient\sessions' already present. Nothing to do!"
)
