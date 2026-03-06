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

Echo:#----------------------------------CheckGenCheck------------------------------------#
Echo:#                                                                                   #
Echo:#         program:  CheckGenCheck                                                   #
Echo:#                                                                                   #
Echo:#         purpose:  Tool to quickly pull info from GenCheck matches                 #
Echo:#                                                                                   #
Echo:#         version:  0.0.1 (.05Mar26.AndrewD)                                        #
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
				SET "errorcheck=-e"
				shift & goto parse
				)
				
			if /I "%Current%"=="-d" (
				SET "detailed=1"
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
REM			shift
REM			goto parse
			Echo: Invalid Option Selected: %Current%
			goto :eof
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
	SET "foundlog=%%~nxA"
	FOR %%D in ('grep "Trace level has been set to tr_LOW" %%A') DO (SET "lowlogging=1")
	Echo %%A:
	Echo.
	if /I "%foundlog:~0,4%"=="igen" (
		if defined detailed (
			FOR /F "tokens=3*" %%X in ('grep "Association handle is valid" %%A') DO (
				Echo %%X %%Y
				)
			FOR /F "tokens=3*" %%X in ('findstr /C:" It took " %%A 2^>nul') DO (
				Echo %%X %%Y
				)
			FOR /F "tokens=3*" %%X in ('grep "seconds before closing the study folder" %%A') DO (
				Echo %%X %%Y
				)
			)
		FOR /F "delims=" %%D in ('grep -A 17 "Importer Time Log :" %%A') DO (
			SET "foundtime=1"
			Echo %%D
			)
		)
	if /I "%foundlog:~0,4%"=="qgen" (
		if defined detailed (
			FOR /F "tokens=3*" %%X in ('grep "Association handle is valid" %%A') DO (
				Echo %%X %%Y
				)
			FOR /F "tokens=3*" %%M in ('grep -A 2 " Query Level = " %%A') DO (
				Echo %%M %%N
				)
			FOR /F "delims=" %%M in ('grep -A 6 "Query filter attributes" %%A ^| findstr /R /V "^[{[<]" 2^>nul') DO (
				Echo %%M %%N
				)
			FOR /F "tokens=3*" %%J in ('grep "Fetch returned " %%A') DO (
				Echo %%J %%K
				)
			FOR /F "tokens=3*" %%J in ('grep "to get response from study server" %%A') DO (
				Echo %%J %%K
				)
			FOR /F "tokens=3*" %%O in ('grep -A 4 "requests C-MOVE to destination AE TITLE" %%A') DO (
				Echo %%O %%P
				)
			FOR /F "tokens=3*" %%J in ('grep "Preprocessing time for this image" %%A') DO (
				Echo %%J %%K
				)
			FOR /F "tokens=3*" %%J in ('grep "Query Server child process finished handling DICOM association" %%A') DO (
				Echo %%J %%K
				)
			)
		)
		FOR /F "delims=" %%D in ('grep -A 21 "QueryServer Time Log" %%A') DO (
			SET "foundtime=1"
			Echo %%D
			)
	if not defined foundtime (
		Echo No time logs found, DICOM association did not terminate in this log
		)
	if defined errorcheck (
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
		)
	Echo.
	Echo: -----------------------
	)
if not defined foundlog (
	Echo GenCheck for !source! did not find any logs
	goto :eof
	)

if defined debug (call :debug)

Echo.
Echo This tool is supplementary to troubleshooting. Confirm all issues with supporting logs!
GOTO :eof

REM Functions

:search

if defined manualsearch (
	Echo.
	Echo Searching for !manualsearch! in matches from GenCheck !source!:
	Echo.
	FOR /F "tokens=3" %%A in ('gencheck !source! !GenFilter! !listmore! !newerthan! !olderthan! ^| grep gen_ ') DO (
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
Echo listmore:     !listmore!
Echo newerthan:    !newerthan!
Echo olderthan:    !olderthan!
Echo lowlogging:   !lowlogging!

exit /b

:help

Echo.
Echo: CheckGenCheck Tool Help Page
Echo.
Echo: Description: Quickly pull information directly from a GenCheck
Echo.
Echo "Usage: CheckGenCheck [-m] <source> [-i|-q] [-d] [-e] [-l <value>] [-s|-ms <search term>] [-nt|-ot <time metric>]"
Echo.
Echo: Options:
Echo: [required] <source>
Echo: [Optional] -m  Specifies <source>
Echo: [Optional] -i  Only search iGens
Echo: [Optional] -q  Only search qGens
Echo: [Optional] -e  Search ERRORs in igen/qgen
Echo: [Optional] -d  Show more details per igen/qgen
Echo: [Optional] -s  Search term through all logs [Testing]
Echo: [Optional] -ms Manual Search [Testing]
Echo: [Optional] -l  Specifies how many log matches to search; default is 10 matches
Echo: [Optional] -nt Filters for logs newer than <time metric>
Echo: [Optional] -ot Filters for logs older than <time metric>
Echo: [Optional] -ms Manual Search [Testing]
Echo: [Optional] -debug

exit /b
