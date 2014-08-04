@cls
call ..\build.bat test

set SKIP_MSI_STEP=
set SKIP_PDL_STEP=
rem perl -Mblib ..\script\perldist_strawberry -job ..\share\64bit-5.20.1.1.pp -notest_core -beta=6 -nointeractive -restorepoints -wixbin_dir=z:\sw\Wix38 -cpan_url file:///z:/_cpan-mirror/
perl -Mblib ..\script\perldist_strawberry -job ..\share\32bit-5.20.1.1.pp -notest_core -beta=6 -nointeractive -restorepoints -wixbin_dir=z:\sw\Wix38 -cpan_url file:///z:/_cpan-mirror/

set SKIP_MSI_STEP=1
set SKIP_PDL_STEP=1
perl -Mblib ..\script\perldist_strawberry -job ..\share\32bit-5.20.1.1.pp -notest_core -beta=6 -noperl_64bitint -app_simplename=strawberry-perl-no64 -nointeractive -restorepoints -wixbin_dir=z:\sw\Wix38 -cpan_url file:///z:/_cpan-mirror/

pause
