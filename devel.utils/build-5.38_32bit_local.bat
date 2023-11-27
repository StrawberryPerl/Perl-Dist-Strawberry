@cls
call ..\build.bat test

subst Z: C:\spbuild

set SP=d:\berrybrew\5.32.0_64_PDL
set PATH=%SP%\c\bin;%SP%\perl\bin;%SP%\perl\site\bin;Z:\sw\wix311;%PATH%
::set PERLEXE=%SP%\perl\bin\perl


set PERL_USE_UNSAFE_INC=1

set SKIP_MSI_STEP=
set SKIP_PDL_STEP=1
perl -Mblib ..\script\perldist_strawberry -job ..\share\32bit-5.38.1.1.pp -notest_core -beta=0 -interactive -restorepoints -wixbin_dir=z:\sw\wix311 -cpan_url https://cpan.metacpan.org

::set SKIP_MSI_STEP=1
::set SKIP_PDL_STEP=1
::perl -Mblib ..\script\perldist_strawberry -job ..\share\32bit-5.38.1.1.pp -notest_core -beta=0 -noperl_64bitint -app_simplename=strawberry-perl-no64 -nointeractive -norestorepoints -wixbin_dir=z:\sw\wix311
