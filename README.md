# FD
Puts letter of current drive to existing environment variable,
or finds disk with given label or file,
or checks file existence.<br>
For DOS, recursive search and long filenames aren't supported.

Usage:<br>
<br>
set var1=a<br>
FD var1<br>
echo Current disk is %var1%:.<br>
set var1=a<br>
FD var1 :\command.com<br>
if not '%var1%' == 'a' echo %var1%:\command.com is found on disk %var1%:.<br>
FD var1 -:fd.com<br>
echo %var1%:fd.com found.<br>
FD var1 -+ms-ramdr.ive<br>
echo Ram disk is probably %var1%:.<br>
FD *:c:\cAmmand.com<br>
if errorlevel 1 echo File c:\cAmmand.com doesn't exist.<br>
FD *+%var1%:\ms-ramdr.ive<br>
if not errorlevel 1 echo Drive %var1%: is probably an MS-DOS RAM disk.

*Public domain*, feel free to use.
