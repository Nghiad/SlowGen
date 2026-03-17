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
Echo:#         purpose:  Tool to quickly pull info from GenCheck matches                 #
Echo:#                                                                                   #
Echo:#         version:  1.0.0 (.17Mar26.AndrewD)                                        #
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
		if "!source:~0,1!"=="-" (
			SET "source="
			goto parse )
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
	
if /I "%~1"=="-f" (
	SET "file=%~2"
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
	
shift
goto parse

:main
	
if defined file (
	if not exist !file! (
		Echo Invalid input file to process, exiting...
		goto :eof
		) else (
			FOR %%i IN ("!file!") DO (
				SET "foundlog=%%~nxi"
				)
			FOR /F "tokens=2 delims=_" %%T IN ("!foundlog!") DO (
				SET "source=%%T"
				)
			goto :SingleSearch
			)
	)
	
if not defined source (
	Echo Did not specify source, exiting...
	goto :eof
	)

Echo ====================================================================
Echo.
FOR /F "tokens=3" %%A in ('gencheck !source! !GenFilter! !listmore! !newerthan! !olderthan! ^| grep gen_ ') DO (
	SET "foundlog=%%~nxA"
	FOR %%D in ('grep "Trace level has been set to tr_LOW" %%A') DO (SET "lowlogging=1")
	Echo.
	Echo %%A :
	Echo.
	Echo ======== Overview ========
	if defined lowlogging ( Echo Logging Level:    LOW ) else ( Echo Logging Level:    HIGH )
	FOR /F "tokens=3" %%D in ('grep "TRACE_FILE_SIZE" %%A') DO (
		SET "logstart=%%D"
		)
	if /I "!foundlog:~0,4!"=="igen" (
		FOR /F "tokens=3" %%D in ('grep "Importer Time Log :" %%A') DO (
			SET "logend=%%D"
			)
		) else if /I "!foundlog:~0,4!"=="qgen" (
			FOR /F "tokens=3" %%D in ('grep "QueryServer Time Log" %%A') DO (
				SET "logend=%%D"
				)
			)
	if defined logstart (
		Echo Log start time:   !logstart:~0,-1!
		)
	if defined logend (
		Echo Log end time:     !logend:~0,-1!
		)
		
	FOR /F %%T in ('grep -c "Received a DICOM message of type" %%A') DO (
		IF %%T NEQ 0 (
			Echo Images imported:  %%T
			)
		)
		
	FOR /F "tokens=3,4,5,6,7*" %%M in ('grep " Service Type = " %%A') DO (
		SET "querylevel=%%Q"
		FOR /F "tokens=7" %%J in ('grep "Database lookup retrieved " %%A') DO (
			Echo Returned Matches: %%J
			Echo.
			)

		Echo Query Level = %%Q
		if "!querylevel!"=="C-MOVE." (
			FOR /F "tokens=17" %%J in ('grep "requests C-MOVE to destination AE TITLE" %%A') DO (
				SET "DestinationAET=%%J"
				)
			Echo:    Destination AETitle: !DestinationAET!
			FOR /F "tokens=7,10" %%S in ('grep "as C-MOVE destination because AE Title Matching is enabled" %%A') DO (
				SET "DestinationAEID=%%S"
				SET "DestinationHost=%%T"
				)
			Echo:    Destination AEID:    !DestinationAEID!
			Echo:    Destination Host:    !DestinationHost!
			)
		)

	if /I "!foundlog:~0,4!"=="igen" (
		Echo.
		if defined detailed (
			Echo ======== Workflow ========
			FOR /F "tokens=3*" %%X in ('grep "About to establish a DICOM association with source" %%A') DO (
				Echo %%X %%Y
				)			
			FOR /F "tokens=3*" %%X in ('grep "Association handle is valid" %%A') DO (
				Echo %%X %%Y
				)
			Echo.

			FOR /F "tokens=3,4*" %%X in ('findstr /B /C:"[ImporterChild.m," %%A ^| findstr /C:"Received a DICOM message of type" /C:"bytes received" /C:"secs to process the image in memory" /C:"secs to parse header and add image file to PACS" /C:"About to handle next image" 2^>nul') DO (
				Echo %%X %%Y %%Z
				if "%%Y"=="Importer" (
					Echo.
					)
				)
			FOR /F "tokens=3*" %%X in ('grep "seconds before closing the study folder" %%A') DO (
				Echo %%X %%Y
				)
			Echo.
			)
		Echo ======== Time Summary ========	
		FOR /F "delims=" %%D in ('grep -A 17 "Importer Time Log :" %%A') DO (
			SET "foundtime=1"
			Echo %%D
			)
		)
		
	if /I "!foundlog:~0,4!"=="qgen" (
		if defined detailed (
			if defined lowlogging (
				FOR /F "tokens= 4,5,6" %%M in ('grep "Query filter attributes" %%A') DO (
					SET "qfilter=1"
					Echo %%M %%N %%O
					)	
				if defined qfilter (
					FOR /F "delims=" %%M in ('grep -A 16 "Query filter attributes" %%A ^| grep -v "Query\|{\|}\|<\|message:\|\[ALI"') DO (
						Echo %%M
						)
					)
				)
			Echo.
			Echo ======== Workflow ========
			FOR /F "tokens=3*" %%X in ('grep "Association handle is valid" %%A') DO (
				Echo %%X %%Y
				)
			FOR /F "tokens=3,4,5,6,7*" %%M in ('grep -A 3 " Query Level = " %%A ^| grep -i -v "!source!"') DO (
				Echo %%M %%N %%O %%P %%Q %%R
				)
			Echo.

			FOR /F "tokens=3*" %%J in ('grep "Fetch returned " %%A ^| grep Stud') DO (
				Echo %%J %%K
				)
			FOR /F "tokens=3*" %%J in ('grep "Fetch returned " %%A ^| grep Series') DO (
				Echo %%J %%K
				)
			FOR /F "tokens=3*" %%J in ('grep "Database lookup retrieved " %%A') DO (
				Echo %%J %%K
				)
			FOR /F "tokens=3*" %%J in ('grep "Total time to initialize PACS" %%A') DO (
				Echo %%J %%K
				)				
			FOR /F "tokens=3*" %%J in ('grep "to get response from study server" %%A') DO (
				Echo %%J %%K
				)
			FOR /F "tokens=3*" %%J in ('grep " ms to complete C-FIND Responses." %%A') DO (
				Echo %%J %%K
				)

			if "!querylevel!"=="C-MOVE." (
				if defined lowlogging (
					Echo.
					FOR /F "tokens=3*" %%J in ('grep " Requesting association with AE title " %%A') DO (
						Echo %%J %%K
						)
					FOR /F "tokens=3*" %%J in ('grep " ms for association request to be completed by SCU" %%A') DO (
						Echo %%J %%K
						)
					Echo.
					
					FOR /F "tokens=3,4,5,6,7*" %%J in ('findstr /C:"Preprocessing time for this image" /C:" ms to send a C-STORE-RQ" /C:" ms to receive a C-STORE-RSP" %%A 2^>nul') DO (
						Echo %%J %%K %%L %%M %%N %%O
						IF %%N=="receive" (Echo.)
						)
					Echo.
					
					FOR /F "tokens=3-9" %%J in ('grep " ms for Association Release to go through" %%A') DO (
						Echo %%J %%K %%L %%M %%N %%O %%P to release the C-STORE DICOM Association
						)
					FOR /F "tokens=3*" %%J in ('grep -A 3 " ms to complete C-MOVE Responses." %%A ^| grep -i -v "!source!"') DO (
						Echo %%J %%K
						)
					
					)
				)

			FOR /F "tokens=3*" %%J in ('grep "Query Server child process finished handling DICOM association" %%A') DO (
				Echo %%J %%K
				)
			Echo.
			)
		Echo ======== Time Summary ========	
		FOR /F "delims=" %%D in ('grep -A 21 "QueryServer Time Log" %%A') DO (
			SET "foundtime=1"
			Echo %%D
			)
		)

	if not defined foundtime (
		Echo No time logs found, DICOM association did not terminate in this log
		)
	if defined errorcheck (
		Echo.
		Echo ======== Error Check ========
		Echo.
		if defined detailed (
			FOR /F "tokens=1,2,4*" %%D in ('findstr /B "ERROR" %%A 2^>nul') DO (
				SET "founderror=1"
				Echo %%D %%E %%F %%G
				)
		) else (
			FOR /F "tokens=1,2,4*" %%D in ('findstr /B "ERROR" %%A ^| grep -v "Could not locate cf variable" ^| grep -v "'Configuration Error': Failed to read" ^| grep -v "Invalid privilege value" 2^>nul') DO (
				SET "founderror=1"
				Echo %%D %%E %%F %%G
				)
			)
		if not defined founderror (
			Echo No ERRORs found in this log
			)
		)

	SET "string="
	SET "foundtime="
	SET "qfilter="
	SET "querylevel="
	SET "lowlogging="
	SET "founderror="
	SET "DestinationAET="
	SET "DestinationAEID="
	SET "DestinationHost="
	SET "logstart="
	SET "logend="
	Echo.
	Echo ====================================================================
	)

if not defined foundlog (
	Echo GenCheck for !source! did not find any logs
	goto :eof
	)

if defined errorcheck (
	if not defined detailed (
		Echo.
		Echo Configuration Errors are ignored; use with -d to show all ERRORs
		)
	Echo.
	Echo !source! Configurations:
	Echo.
	FOR /F "tokens=5* delims=\: " %%I IN ('findstr /I "!source!" "%ALI_SITE_CONFIG_PATH%\*.site" 2^>nul') DO (
		Echo %%I: %%J
		)
	Echo.
	Echo ====================================================================
	)

Echo.
Echo This tool is supplementary to troubleshooting. Confirm all issues with supporting logs!
GOTO :eof

:SingleSearch

Echo ====================================================================
Echo.
FOR %%D in ('findstr /C:"Trace level has been set to tr_LOW" !file! 2^>nul') DO (SET "lowlogging=1")
Echo !file! :
Echo.
Echo ======== Overview ========
if defined lowlogging ( Echo Logging Level:    LOW ) else ( Echo Logging Level:    HIGH )
FOR /F "tokens=3" %%D in ('grep "TRACE_FILE_SIZE" !file!') DO (
	SET "logstart=%%D"
	)
if /I "!foundlog:~0,4!"=="igen" (
	FOR /F "tokens=3" %%D in ('grep "Importer Time Log :" !file!') DO (
		SET "logend=%%D"
		)
	) else if /I "!foundlog:~0,4!"=="qgen" (
		FOR /F "tokens=3" %%D in ('grep "QueryServer Time Log" !file!') DO (
			SET "logend=%%D"
			)
		)
if defined logstart (
	Echo Log start time:   !logstart:~0,-1!
	)
if defined logend (
	Echo Log end time:     !logend:~0,-1!
	)

FOR /F %%T in ('grep -c "Received a DICOM message of type" !file!') DO (
	IF %%T NEQ 0 (
		Echo Images imported:  %%T
		)
	)
FOR /F "tokens=3,4,5,6,7*" %%M in ('grep " Service Type = " !file!') DO (
	SET "querylevel=%%Q"
	FOR /F "tokens=7" %%J in ('grep "Database lookup retrieved " !file!') DO (
		IF %%J NEQ 0 (
			Echo Returned Matches: %%J
			Echo.
			)
		)
	Echo Query Level = %%Q
	if "!querylevel!"=="C-MOVE." (
		FOR /F "tokens=17" %%J in ('grep "requests C-MOVE to destination AE TITLE" !file!') DO (
			SET "DestinationAET=%%J"
			)
		Echo:    Destination AETitle: !DestinationAET!
		FOR /F "tokens=7,10" %%S in ('grep "as C-MOVE destination because AE Title Matching is enabled" !file!') DO (
			SET "DestinationAEID=%%S"
			SET "DestinationHost=%%T"
			)
		Echo:    Destination AEID:    !DestinationAEID!
		Echo:    Destination Host:    !DestinationHost!
		)
	)

if /I "!foundlog:~0,4!"=="igen" (
	Echo.
	if defined detailed (
		Echo ======== Workflow ========
		FOR /F "tokens=3*" %%X in ('grep "About to establish a DICOM association with source" !file!') DO (
			Echo %%X %%Y
			)
		FOR /F "tokens=3*" %%X in ('grep "Association handle is valid" !file!') DO (
			Echo %%X %%Y
			)
		Echo.	
		FOR /F "tokens=3,4*" %%X in ('findstr /B /C:"[ImporterChild.m," !file! ^| findstr /C:"Received a DICOM message of type" /C:"bytes received" /C:"secs to process the image in memory" /C:"secs to parse header and add image file to PACS" /C:"About to handle next image" 2^>nul') DO (
			Echo %%X %%Y %%Z
			if "%%Y"=="Importer" (
				Echo.
				)
			)
		FOR /F "tokens=3*" %%X in ('grep "seconds before closing the study folder" !file!') DO (
			Echo %%X %%Y
			)
		)
		
	Echo.	
	Echo ======== Time Summary ========	
	FOR /F "delims=" %%D in ('grep -A 17 "Importer Time Log :" !file!') DO (
		SET "foundtime=1"
		Echo %%D
		)
	)

if /I "!foundlog:~0,4!"=="qgen" (
	if defined detailed (
		if defined lowlogging (
			FOR /F "tokens= 4,5,6" %%M in ('grep "Query filter attributes" !file!') DO (
				SET "qfilter=1"
				Echo %%M %%N %%O
				)	
			if defined qfilter (
				FOR /F "delims=" %%M in ('grep -A 16 "Query filter attributes" !file! ^| grep -v "Query\|{\|}\|<\|message:\|\[ALI"') DO (
					Echo %%M
					)
				)
			)
		Echo.
		Echo ======== Workflow ========
		FOR /F "tokens=3*" %%X in ('grep "Association handle is valid" !file!') DO (
			Echo %%X %%Y
			)
		FOR /F "tokens=3,4,5,6,7*" %%M in ('grep -A 3 " Query Level = " !file! ^| grep -i -v "!source!"') DO (
			Echo %%M %%N %%O %%P %%Q %%R
			)
		Echo.

		FOR /F "tokens=3*" %%J in ('grep "Fetch returned " !file! ^| grep Stud') DO (
			Echo %%J %%K
			)
		FOR /F "tokens=3*" %%J in ('grep "Fetch returned " !file! ^| grep Series') DO (
			Echo %%J %%K
			)
		FOR /F "tokens=3*" %%J in ('grep "Database lookup retrieved " !file!') DO (
			Echo %%J %%K
			)
		FOR /F "tokens=3*" %%J in ('grep "Total time to initialize PACS" !file!') DO (
			Echo %%J %%K
			)				
		FOR /F "tokens=3*" %%J in ('grep "to get response from study server" !file!') DO (
			Echo %%J %%K
			)
		FOR /F "tokens=3*" %%J in ('grep " ms to complete C-FIND Responses." !file!') DO (
			Echo %%J %%K
			)

		if "!querylevel!"=="C-MOVE." (
			if defined lowlogging (
				Echo.
				FOR /F "tokens=3*" %%J in ('grep " Requesting association with AE title " !file!') DO (
					Echo %%J %%K
					)
				FOR /F "tokens=3*" %%J in ('grep " ms for association request to be completed by SCU" !file!') DO (
					Echo %%J %%K
					)
				Echo.
				
				FOR /F "tokens=3,4,5,6,7*" %%J in ('findstr /C:"Preprocessing time for this image" /C:" ms to send a C-STORE-RQ" /C:" ms to receive a C-STORE-RSP" !file! 2^>nul') DO (
					Echo %%J %%K %%L %%M %%N %%O
					IF %%N=="receive" (Echo.)
					)
				Echo.
				
				FOR /F "tokens=3-9" %%J in ('grep " ms for Association Release to go through" !file!') DO (
					Echo %%J %%K %%L %%M %%N %%O %%P to release the C-STORE DICOM Association
					)
				FOR /F "tokens=3*" %%J in ('grep -A 3 " ms to complete C-MOVE Responses." !file! ^| grep -i -v "!source!"') DO (
					Echo %%J %%K
					)
				
				)
			)

		FOR /F "tokens=3*" %%J in ('grep "Query Server child process finished handling DICOM association" !file!') DO (
			Echo %%J %%K
			)
		)
	Echo.
	Echo ======== Time Summary ========	
	FOR /F "delims=" %%D in ('grep -A 21 "QueryServer Time Log" !file!') DO (
		SET "foundtime=1"
		Echo %%D
		)
	)

if not defined foundtime (
	Echo No time logs found, DICOM association did not terminate in this log
	)

if defined errorcheck (
	Echo.
	Echo ========= Error Check =========
	Echo.
	if defined detailed (
		FOR /F "tokens=1,2,4*" %%D in ('findstr /B "ERROR" !file! 2^>nul') DO (
			SET "founderror=1"
			Echo %%D %%E %%F %%G
			)
	) else (
		FOR /F "tokens=1,2,4*" %%D in ('findstr /B "ERROR" !file! ^| grep -v "Could not locate cf variable" ^| grep -v "'Configuration Error': Failed to read" ^| grep -v "Invalid privilege value" 2^>nul') DO (
			SET "founderror=1"
			Echo %%D %%E %%F %%G
			)
		)
	if not defined founderror (
		Echo No ERRORs found in this log
		)
	)

if not defined foundlog (
	Echo GenCheck for !source! did not find any logs
	goto :eof
	)

if defined errorcheck (
	if not defined detailed (
		Echo.
		Echo Configuration Errors are ignored; use with -d to show all ERRORs
		)
	Echo.
	Echo ========= !source! Configurations =========
	Echo.
	FOR /F "tokens=5* delims=\: " %%I IN ('findstr /I "!source!" "%ALI_SITE_CONFIG_PATH%\*.site" 2^>nul') DO (
		Echo %%I: %%J
		)
	Echo.
	Echo ====================================================================
	)

Echo.
Echo This tool is supplementary to troubleshooting. Confirm all issues with supporting logs!
GOTO :eof

:help

Echo.
Echo: SlowGen Tool Help Page
Echo.
Echo: Description: Quickly pull information directly from a GenCheck
Echo.
Echo: Usage: SlowGen [-m^|-s {source}] [-f {file}] [-i^|-q] [-d] [-e] [-l {value}] [-nt^|-ot {time metric}]
Echo.
Echo: Required:
Echo: [-s {source}]  Search for igen/qgen for this source
Echo:     OR
Echo: [-f {file}]    Parse specified log
Echo.
Echo: Options:
Echo: [-e]  Search for ERRORs in the igen/qgen
Echo: [-d]  Show more details per igen/qgen
Echo.
Echo: Available options from GenCheck:
Echo: [-m]  {source}
Echo: [-i]  Only search iGens
Echo: [-q]  Only search qGens
Echo: [-l]  Specifies how many log matches to search; default is 10 matches
Echo: [-nt] Filters for logs newer than {time metric}
Echo: [-ot] Filters for logs older than {time metric}

exit /b
