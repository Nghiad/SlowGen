Introduction
=============
SlowGen is an internal tool designed to quickly parse iGens and qGens for slowness. The tool is build to pull specific logs in an import or query workflow to find where delays appear within the workflow. This tool can also search for any logs that start with "ERROR" to quickly check for failures.

=============
Installation
=============
This tool is pending approval to be added into toolkit. Until then, you will need to manually copy this tool and paste it onto a site to use.

Steps:
	1. Connect to a site
	2. Create a new text file in a temporary directory
	3. Copy the full contents of the tool
	4. Paste the entire contents of the tool into the text file
	5. Rename the created file to "SlowGen.bat"
	6. From the temporary directory, use the tool with "SlowGen.bat"
		a) From any directory, call the tool with the UNC path

==============================
SlowGen Tool Help/Usage Page
==============================

Description: Quickly pull information directly from GenCheck matches

Usage: SlowGen [-m|-s] <source> [-f <file>] [-i|-q] [-d] [-e] [-l <value>] [-nt|-ot <time metric>]

Options:
[required] <source>
[Optional] -s  Specifies <source>
[Optional] -f  Specifies specific igen/qgen file to process
[Optional] -e  Search for ERRORs in the igen/qgen
[Optional] -d  Show more details per igen/qgen

Available options from GenCheck:
[Optional] -m  Specifies <source>
[Optional] -i  Only search iGens
[Optional] -q  Only search qGens
[Optional] -l  Specifies how many log matches to search; default is 10 matches
[Optional] -nt Filters for logs newer than <time metric>
[Optional] -ot Filters for logs older than <time metric>


==========
Functions
==========
-       Dumps the time log summary of the iGen or qGen
(-d)    Dumps additional logs highlighting the import/query workflow
(-e)    Search for ERRORs in the iGen or qGen; ignores configuration errors
(-e)    Dump's the source's configurations in all site files
(-e -d) Search for all ERRORs in the iGen or qGen
(-f)    Specifies specific log file to parse


==============================
Commands called in the script
==============================
hostname
whoami
now
GenCheck
findstr
grep
