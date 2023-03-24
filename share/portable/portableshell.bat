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

if "%1" == "" goto INTERACTIVE

REM For non-interactive invocations of this batch file, run Perl with all
REM provided argument and return its exit code.  Clear the ERRORLEVEL
REM variable in our local environment to ensure our "exit /b" statement
REM returns the error level from Perl even if there is already an ERRORLEVEL
REM variable in the environment:
REM   https://devblogs.microsoft.com/oldnewthing/20080926-00
set ERRORLEVEL=
"%~dp0perl\bin\perl.exe" %*
exit /b %ERRORLEVEL%

:INTERACTIVE
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
