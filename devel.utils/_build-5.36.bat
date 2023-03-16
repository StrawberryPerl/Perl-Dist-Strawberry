::@cls
::call ..\build.bat test

::set PERL_USE_UNSAFE_INC=1

set SP=z:\sp532
set PATH=%PATH%;%SP%\c\bin;%SP%\perl\bin;%SP%\perl\site\bin
set PERLEXE=%SP%\perl\bin\perl

:: update blib - requires Build.PL to have been run
set OLD_CD=%cd%
cd ..
call Build
cd %OLD_CD%

set SKIP_MSI_STEP=1
set SKIP_PDL_STEP=1
%PERLEXE% -Mblib ..\script\perldist_strawberry -job ..\share\64bit-5.36.0.1.pp -notest_core -beta=0 -nointeractive -norestorepoints -wixbin_dir=z:\sw\wix311 -cpan_url https://cpan.metacpan.org


