@echo off

if not "%1" == "/SETENV" setlocal

set PATH=%~dp0perl\site\bin;%~dp0perl\bin;%~dp0c\bin;%PATH%

set TERM=
set PERL_JSON_BACKEND=
set PERL_YAML_BACKEND=
set PERL5LIB=
set PERL5OPT=
set PERL_MM_OPT=
set PERL_MB_OPT=

if "%1" == "/SETENV" goto END

if not "%1" == "" "%~dp0perl\bin\perl.exe" %* & goto ENDLOCAL

echo ----------------------------------------------
echo  Welcome to Strawberry Perl Portable Edition!
echo  * URL - http://www.strawberryperl.com/
echo  * see README.TXT for more info
echo ----------------------------------------------
perl -MConfig -e "printf("""Perl executable: %%s\nPerl version   : %%vd / $Config{archname}\n\n""", $^X, $^V)" 2>nul
if ERRORLEVEL==1 echo FATAL ERROR: 'perl' does not work; check if your strawberry pack is complete!

cmd /K

:ENDLOCAL
endlocal

:END
