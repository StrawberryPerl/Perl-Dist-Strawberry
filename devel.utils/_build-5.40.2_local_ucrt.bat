::@cls
::call ..\build.bat test

::set PERL_USE_UNSAFE_INC=1

subst Z: C:\shawn\sp_repos

set SP=c:\perls\5.38.2.2_PDL
set PATH=%SP%\c\bin;%SP%\perl\bin;%SP%\perl\site\bin;Z:\sw\wix311;Z:\winlibs\bin;%PATH%
set PERLEXE=%SP%\perl\bin\perl

:: update blib - requires Build.PL to have been run
call ..\build.bat test

::set MAKEFLAGS=-j12
set TEST_JOBS=8

:: tests take a long time
set TEST_CORE=-test_core
set TEST_CORE=-notest_core

::set SKIP_MSI_STEP=1
::set SKIP_PDL_STEP=1
%PERLEXE% -Mblib ..\script\perldist_strawberry -job ..\share\64bit-5.40.2.1.pp %TEST_CORE% -beta=1 -interactive -restorepoints -wixbin_dir=z:\sw\wix311 -cpan_url https://cpan.metacpan.org


