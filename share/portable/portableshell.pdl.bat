@echo off

set drive=%~dp0
set drivep=%drive%
if #%drive:~-1%# == #\# set drivep=%drive:~0,-1%

set PATH=%drivep%\perl\site\bin;%drivep%\perl\bin;%drivep%\c\bin;%PATH%
rem env variables
set TERM=
set HOME=%~dp0data
set PLPLOT_LIB=%~dp0c\share\plplot
set PLPLOT_DRV_DIR=%~dp0c\share\plplot
rem avoid collisions with other perl stuff on your system
set PERL_JSON_BACKEND=
set PERL_YAML_BACKEND=
set PERL5LIB=
set PERL5OPT=
set PERL_MM_OPT=
set PERL_MB_OPT=

if not #%1# == ## "%drivep%\perl\bin\perl.exe" %* & goto END

echo ----------------------------------------------
echo  Welcome to Strawberry Perl PDL Edition!
echo  * URL - http://strawberryperl.com + http://pdl.perl.org
echo  * to launch perl script run:      perl c:\my\scripts\pdl-test.pl
echo  * to start PDL console run:       pdl2
echo  * to update PDL run:              cpanm PDL
echo  * to install extra module run:    cpanm PDL::Any::Module
echo           or if previous fails:    ppm PDL::Any::Module
echo  * or you can use dev tools like:  gcc, g++, gfortran, gmake
echo  * see README.TXT for more info
echo ----------------------------------------------
perl -MConfig -MPDL -e "printf("""Perl executable: %%s\nPerl version   : %%vd / $Config{archname}\nPDL version    : %%s\n""", $^X, $^V, $PDL::VERSION)" 2>nul
if ERRORLEVEL==1 echo.&echo FATAL ERROR: 'perl' does not work; check if your strawberry pack is complete!
echo.
cmd /K

:END
