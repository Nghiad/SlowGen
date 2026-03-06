@echo off
setlocal EnableExtensions EnableDelayedExpansion

FOR /F "tokens=*" %%I IN ('hostname') DO (
        SET "hostname=%%I"
        )

FOR /F "tokens=*" %%I IN ('whoami') DO (
        SET "user=%%I"
        )

FOR /F "tokens=*" %%I IN ('now') DO (
        SET "now=%%I"
        )

Echo:#-------------------------------------SlowGen---------------------------------------#
Echo:#                                                                                   #
Echo:#         program:  SlowGen                                                         #
Echo:#                                                                                   #
Echo:#         purpose:  Tool to quickly pull info from a iGens and qGens                #
Echo:#                                                                                   #
Echo:#         version:  0.0.1 (.04Mar26.AndrewD)                                        #
Echo:#                                                                                   #
Echo:#          author:  Andrew Doan                                                     #
Echo:#                                                                                   #
Echo:#-----------------------------------------------------------------------------------#
Echo: Runtime:    !now!
Echo: HostName:   !hostname!
Echo: User:       !user!
Echo:---------------------------------------
Echo.

if "%~1"=="" (
    call :help
	goto :eof
	)

REM Read Input

:parse

if not "%~1"=="" (
	SET "Current=%~1"
	if "%Current%"=="/?" (
		call :help
		goto :eof
		)
	if not "%Current:~0,1%"=="-" (
		SET "source=%~1"
		shift & goto parse
		) else (
			if /I "%Current%"=="-m" (
				SET "source=%~2"
				shift & shift & goto parse
				)

			if /I "%Current%"=="-i" (
				SET "GenFilter=-i"
				shift & goto parse
				)
				
			if /I "%Current%"=="-q" (
				SET "GenFilter=-q"
				shift & goto parse
				)
				
			if /I "%Current%"=="-e" (
				SET "GenFilter=-e"
				shift & goto parse
				)

			if /I "%Current%"=="-s" (
				SET "search=-s %~2"
				shift & shift & goto parse
				)
			
			if /I "%Current%"=="-ms" (
				SET "manualsearch=%~2"
				shift & shift & goto parse
				)
				
			if /I "%Current%"=="-l" (
				SET "listmore=-l %~2"
				shift & shift & goto parse
				)

			if /I "%Current%"=="-nt" (
				SET "newerthan=-nt %~2"
				shift & shift & goto parse
				)

			if /I "%Current%"=="-ot" (
				SET "olderthan=-ot %~2"
				shift & shift & goto parse
				)
			
			if /I "%Current%"=="-debug" (
				SET "debug=1"
				shift & goto parse
				)			
			shift
			goto parse
REM			Echo: Invalid Option Selected: %Current%
REM			goto :eof
			)
	) else (goto :main)

:main

if defined debug (
	call :debug
	@echo on
	)

if not defined source (
	Echo Did not specify source, exiting...
	goto :eof
	)
	
if defined manualsearch (
	call :search
	goto :eof
	)

Echo.
Echo ------ !source! Configurations ------
Echo.
FOR /F "tokens=* delims=" %%I IN ('findstr /I "!source!" "%ALI_SITE_CONFIG_PATH%\*.site" 2^>nul') DO (
	Echo %%I
	)

Echo.
Echo: -------- Log Times --------
Echo.
FOR /F "tokens=3" %%A in ('gencheck !source! !GenFilter! !search! !listmore! !newerthan! !olderthan! ^| grep gen_ ') DO (
	SET "foundlog=1"
	Echo %%A:
	Echo.
	FOR /F "delims=" %%D in ('grep -A 20 "Time Log :" %%A ^| findstr /B /V "#" 2^>nul') DO (
		SET "foundtime=1"
		Echo %%D
		)
	if not defined foundtime (
		Echo No time logs found, DICOM association did not terminate in this log
		)

	Echo.
	Echo ===== Error Check =====
	Echo.
	FOR /F "tokens=1,2,4*" %%D in ('findstr /B "ERROR" %%A ^| grep -v "Could not locate cf variable" 2^>nul') DO (
		SET "founderror=1"
		Echo %%D %%E %%F %%G
		)
	if not defined founderror (
		Echo No ERRORs found in this log
		)
	Echo.
	Echo: -----------------------
	)

if not defined foundlog (
	Echo GenCheck for !source! did not find any logs
	goto :eof
	)

Echo.
Echo This tool is supplementary to troubleshooting. Confirm all issues with supporting logs!
GOTO :eof

REM Functions

:search

if defined manualsearch (
	Echo.
	Echo Searching for !manualsearch! in matches from GenCheck !source!:
	Echo.
	FOR /F "tokens=3" %%A in ('gencheck !source! !GenFilter! !showinfo! !listmore! !newerthan! !olderthan! ^| grep gen_ ') DO (
		FOR %%D in ('grep -i !manualsearch! %%A') DO (
			SET "foundsearch=1"
			Echo %%A
			)
		)
	if not defined foundsearch (
		Echo Did not find !manualsearch! in any logs from GenCheck !source!
		)
	)

exit /b

:debug

Echo source:       !source!
Echo GenFilter:    !GenFilter!
Echo search:       !search!
Echo manualsearch: !manualsearch!
Echo showinfo:     !showinfo!
Echo listmore:     !listmore!
Echo newerthan:    !newerthan!
Echo olderthan:    !olderthan!

exit /b

:help

Echo.
Echo: CheckGenCheck Tool Help Page
Echo.
Echo: Description: Quickly pull information directly from a GenCheck
Echo.
Echo "Usage: CheckGenCheck [-m] <source> [-i|-q|-e] [-l <value>] [-s|-ms <search term>] [-nt|-ot <time metric>]"
Echo.
Echo: Options:
Echo: [required] <source>
Echo: [Optional] -m  Specifies <source>
Echo: [Optional] -i  Only search for iGens
Echo: [Optional] -q  Only search for qGens
Echo: [Optional] -e  Only search for eGens
Echo: [Optional] -s  Search term through all logs [Testing]
Echo: [Optional] -l  Specifies how many log matches to search; default is 10 matches
Echo: [Optional] -nt Filters for logs newer than <time metric>
Echo: [Optional] -ot Filters for logs older than <time metric>
Echo: [Optional] -ms Manual Search [Testing]
Echo: [Optional] -debug

exit /b
