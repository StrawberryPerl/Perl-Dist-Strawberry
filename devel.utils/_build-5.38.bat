::@cls
::call ..\build.bat test

::set PERL_USE_UNSAFE_INC=1

set SP=z:\sp536
set PATH=Z:\mingw64\bin;%SP%\c\bin;%SP%\perl\bin;%SP%\perl\site\bin;%PATH%
set PERLEXE=%SP%\perl\bin\perl

:: update blib - requires Build.PL to have been run
set OLD_CD=%cd%
cd ..
call Build
cd %OLD_CD%

set MAKEFLAGS=-j8
set TEST_JOBS=8

set SKIP_MSI_STEP=1
set SKIP_PDL_STEP=1
%PERLEXE% -Mblib ..\script\perldist_strawberry -job ..\share\64bit-5.38.0.1.pp -notest_core -beta=0 -nointeractive -restorepoints -wixbin_dir=z:\sw\wix311 -cpan_url https://cpan.metacpan.org


