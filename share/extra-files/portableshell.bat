@echo off
set drive=%~dp0
set drivep=%drive%
If $#\#$==$#%drive:~-1%#$ set drivep=%drive:~0,-1%
set PATH=%drivep%\perl\site\bin;%drivep%\perl\bin;%drivep%\c\bin;%PATH%
rem env variables
set TERM=dumb
set PERL_JSON_BACKEND=JSON::XS
set PERL_YAML_BACKEND=YAML
rem avoid collisions with other perl stuff on your system
set PERL5LIB=
set PERL5OPT=
set PERL_MM_OPT=
set PERL_MB_OPT=
echo ----------------------------------------------
echo  Welcome to Strawberry Perl Portable Edition!
echo  * URL - http://www.strawberryperl.com/ 
echo  * see README.portable.TXT for more info
echo ----------------------------------------------
perl -e "printf("""Perl executable: %%s\nPerl version   : %%vd\n""", $^X, $^V)" 2>nul
if ERRORLEVEL==1 echo.&echo FATAL ERROR: 'perl' does not work; check if your strawberry pack is complete!
echo.
cmd /K
