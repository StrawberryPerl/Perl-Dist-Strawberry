@echo off

if not "%1" == "/SETENV" setlocal

set PATH=%~dp0perl\site\bin;%~dp0perl\bin;%~dp0c\bin;%PATH%

set TERM=
set HOME=%~dp0data
set PLPLOT_LIB=%~dp0c\share\plplot
set PLPLOT_DRV_DIR=%~dp0c\share\plplot
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
echo  Welcome to Strawberry Perl PDL Edition!
echo  * URL - https://strawberryperl.com + http://pdl.perl.org
echo  * to launch perl script run:      perl c:\my\scripts\pdl-test.pl
echo  * to start PDL console run:       pdl2
echo  * to update PDL run:              cpanm PDL
echo  * to install extra module run:    cpanm PDL::Any::Module
echo           or if previous fails:    ppm PDL::Any::Module
echo  * or you can use dev tools like:  gcc, g++, gfortran, gmake
echo  * see README.TXT for more info
echo ----------------------------------------------
perl -MConfig -MPDL -e "print(qq{Perl executable: $^X\nPerl version   : $^V / $Config{archname}\nPDL version    : $PDL::VERSION\n\n})" 2>nul
if ERRORLEVEL==1 echo FATAL ERROR: 'perl' does not work; check if your strawberry pack is complete!

cmd /K

:ENDLOCAL
endlocal

:END
