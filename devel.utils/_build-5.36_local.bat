::@cls
::call ..\build.bat test

::set PERL_USE_UNSAFE_INC=1

subst Z: C:\spbuild

set SP=d:\berrybrew\5.32.1.1_64bit
set PATH=%SP%\c\bin;%SP%\perl\bin;%SP%\perl\site\bin;Z:\sw\wix311;Z:\winlibs\bin;%PATH%
set PERLEXE=%SP%\perl\bin\perl

:: update blib - requires Build.PL to have been run
::set OLD_CD=%cd%
::cd ..
::call Build
::cd %OLD_CD%

call ..\build.bat test

set MAKEFLAGS=-j8
set TEST_JOBS=8


::set SKIP_MSI_STEP=1
::set SKIP_PDL_STEP=1
%PERLEXE% -Mblib ..\script\perldist_strawberry -job ..\share\64bit-5.36.3.1.pp -test_core -beta=0 -interactive -restorepoints -wixbin_dir=z:\sw\wix311 -cpan_url https://cpan.metacpan.org


