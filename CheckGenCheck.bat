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
	) else (
		SET "source=%~1"
		shift & goto parse
		)
		

REM Read Input

:parse

if "%~1"=="" goto :main

if /I "%~1"=="-h" (
    call :help
    goto :eof
    )

if "%~1"=="/?" (
	call :help
	goto :eof
	)
		
if /I "%~1"=="-m" (
	SET "source=%~2"
	shift & shift & goto parse
	)

if /I "%~1"=="-s" (
	SET "source=%~2"
	shift & shift & goto parse
	)

if /I "%~1"=="-i" (
	SET "GenFilter=-i"
	shift & goto parse
	)
	
if /I "%~1"=="-q" (
	SET "GenFilter=-q"
	shift & goto parse
	)
	
if /I "%~1"=="-e" (
	SET "errorcheck=1"
	shift & goto parse
	)
	
if /I "%~1"=="-d" (
	SET "detailed=1"
	shift & goto parse
	)
	
if /I "%~1"=="-l" (
	SET "listmore=-l %~2"
	shift & shift & goto parse
	)

if /I "%~1"=="-nt" (
	SET "newerthan=-nt %~2"
	shift & shift & goto parse
	)

if /I "%~1"=="-ot" (
	SET "olderthan=-ot %~2"
	shift & shift & goto parse
	)

if /I "%~1"=="-debug" (
	SET "debug=1"
	shift & goto parse
	)
	
shift
goto parse


:main


if not defined source (
	Echo Did not specify source, exiting...
	goto :eof
	)

Echo.
Echo: -------- Log Times --------
Echo.
FOR /F "tokens=3" %%A in ('gencheck !source! !GenFilter! !listmore! !newerthan! !olderthan! ^| grep gen_ ') DO (
	SET "foundlog=%%~nxA"
	FOR %%D in ('grep "Trace level has been set to tr_LOW" %%A') DO (SET "lowlogging=1")
	Echo %%A:
	Echo.
	if /I "!foundlog:~0,4!"=="igen" (
		if defined detailed (
			FOR /F "tokens=3*" %%X in ('grep "Association handle is valid" %%A') DO (
				Echo %%X %%Y
				)
				
REM LOW LEVEL LOGS OR BETTER TIMER LOGS WITH MULTIPLE OR SEARCHES
				
			FOR /F "tokens=3*" %%X in ('findstr /C:" It took " %%A ^| findstr /V /C:"0.000000" 2^>nul') DO (
				Echo %%X %%Y
				)
				
				

			FOR /F "tokens=3*" %%X in ('grep "seconds before closing the study folder" %%A') DO (
				Echo %%X %%Y
				)
			Echo.
			)
		FOR /F "delims=" %%D in ('grep -A 17 "Importer Time Log :" %%A') DO (
			SET "foundtime=1"
			Echo %%D
			)
		)
	if /I "!foundlog:~0,4!"=="qgen" (
		if defined detailed (
			FOR /F "tokens=3*" %%X in ('grep "Association handle is valid" %%A') DO (
				Echo %%X %%Y
				)
			FOR /F "tokens=3,4,5,6,7*" %%M in ('grep -A 2 " Query Level = " %%A') DO (
				Echo %%M %%N %%O %%P %%Q %%R
				SET "querylevel=%%Q"
				)
			Echo.
			if defined lowlogging (
REM LOW LEVEL LOGS
				FOR /F "delims=" %%M in ('grep "Query filter attributes" %%A') DO (
					SET "qfilter=1"
					Echo %%M %%N
					)	
				if defined qfilter (
					FOR /F "delims=" %%M in ('grep -A 16 "Query filter attributes" %%A ^| grep -v "Query\|{\|}\|<\|message:"') DO (
						Echo %%M %%N
						)
					Echo.
					)
				)
			FOR /F "tokens=3*" %%J in ('grep "Fetch returned " %%A ^| grep Stud') DO (
				Echo %%J %%K
				)
			FOR /F "tokens=3*" %%J in ('grep "Total time to initialize PACS" %%A') DO (
				Echo %%J %%K
				)
			FOR /F "tokens=3*" %%J in ('grep "Fetch returned " %%A ^| grep Series') DO (
				Echo %%J %%K
				)
			FOR /F "tokens=3*" %%J in ('grep "Database lookup retrieved " %%A') DO (
				Echo %%J %%K
				)
REM May be high lv logs only?		
			FOR /F "tokens=3*" %%J in ('grep "to get response from study server" %%A') DO (
				Echo %%J %%K
				)
			FOR /F "tokens=3*" %%J in ('grep " ms to complete C-FIND Responses." %%A') DO (
				Echo %%J %%K
				)
			if querylevel="C-MOVE." (
REM C-MOVEs ONLY
				Echo.
				FOR /F "tokens=3*" %%O in ('grep "requests C-MOVE to destination AE TITLE" %%A') DO (
					SET "string=%%O %%P"
					)
				Echo !string!
				FOR /F "tokens=3*" %%O in ('grep "as C-MOVE destination because AE Title Matching is enabled" %%A') DO (
					SET "string=%%O %%P"
					)
				Echo !string!
				Echo.
				FOR /F "tokens=3*" %%J in ('grep "Preprocessing time for this image" %%A') DO (
					Echo %%J %%K
					)
				)
			FOR /F "tokens=3*" %%J in ('grep "Query Server child process finished handling DICOM association" %%A') DO (
				Echo %%J %%K
				)
			Echo.
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
		if defined detailed (
			FOR /F "tokens=1,2,4*" %%D in ('findstr /B "ERROR" %%A 2^>nul') DO (
				SET "founderror=1"
				Echo %%D %%E %%F %%G
				)
		) else (
			FOR /F "tokens=1,2,4*" %%D in ('findstr /B "ERROR" %%A ^| grep -v "Could not locate cf variable" ^| grep -v "'Configuration Error': Failed to read" 2^>nul') DO (
				SET "founderror=1"
				Echo %%D %%E %%F %%G
				)
			)
		if not defined founderror (
			Echo No ERRORs found in this log
			)
		)
	Echo.
	SET "string="
	SET "qfilter="
	SET "querylevel="
	SET "lowlogging="
	Echo: -----------------------
	)

if not defined foundlog (
	Echo GenCheck for !source! did not find any logs
	goto :eof
	)
	
if defined errorcheck (
	Echo.
	Echo ------ !source! Configurations ------
	Echo.
	FOR /F "tokens=5* delims=\: " %%I IN ('findstr /I "!source!" "%ALI_SITE_CONFIG_PATH%\*.site" 2^>nul') DO (
		Echo %%I: %%J
		)
	Echo.
	Echo -------------------------------------
	if not defined detailed (
		Echo.
		Echo Configuration Errors are ignored; use with -d to show all ERRORs
		)
	)

if defined debug (call :debug)

Echo.
Echo This tool is supplementary to troubleshooting. Confirm all issues with supporting logs!
GOTO :eof

REM Functions

:debug

Echo source:       !source!
Echo GenFilter:    !GenFilter!
Echo listmore:     !listmore!
Echo newerthan:    !newerthan!
Echo olderthan:    !olderthan!
Echo lowlogging:   !lowlogging!
Echo foundlog:     !foundlog!
Echo foundtime:    !foundtime!
Echo querylevel:   !querylevel!
Echo qfilter:      !qfilter!
Echo string:       !string!

exit /b

:help

Echo.
Echo: CheckGenCheck Tool Help Page
Echo.
Echo: Description: Quickly pull information directly from a GenCheck
Echo.
Echo "Usage: CheckGenCheck [-m|-s] <source> [-i|-q] [-d] [-e] [-l <value>] [-nt|-ot <time metric>]"
Echo.
Echo: Options:
Echo: [required] <source>
Echo: [Optional] -m  Specifies <source>
Echo: [Optional] -s  Specifies <source>
Echo: [Optional] -i  Only search iGens
Echo: [Optional] -q  Only search qGens
Echo: [Optional] -e  Search ERRORs in igen/qgen
Echo: [Optional] -d  Show more details per igen/qgen
Echo: [Optional] -l  Specifies how many log matches to search; default is 10 matches
Echo: [Optional] -nt Filters for logs newer than <time metric>
Echo: [Optional] -ot Filters for logs older than <time metric>
Echo: [Optional] -debug

exit /b
