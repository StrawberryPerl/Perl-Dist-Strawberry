@echo off

set drive=%~dp0
set drivep=%drive%
if #%drive:~-1%# == #\# set drivep=%drive:~0,-1%

set PATH=%drivep%\perl\site\bin;%drivep%\perl\bin;%drivep%\c\bin;%PATH%
rem env variables
set TERM=
rem avoid collisions with other perl stuff on your system
set PERL_JSON_BACKEND=
set PERL_YAML_BACKEND=
set PERL5LIB=
set PERL5OPT=
set PERL_MM_OPT=
set PERL_MB_OPT=

if not #%1# == ## "%drivep%\perl\bin\perl.exe" %* & goto END

echo ----------------------------------------------
echo  Welcome to Strawberry Perl Portable Edition!
echo  * URL - http://www.strawberryperl.com/
echo  * see README.TXT for more info
echo ----------------------------------------------
perl -MConfig -e "printf("""Perl executable: %%s\nPerl version   : %%vd / $Config{archname}\n""", $^X, $^V)" 2>nul
if ERRORLEVEL==1 echo.&echo FATAL ERROR: 'perl' does not work; check if your strawberry pack is complete!
echo.
cmd /K

:END
