@cls
call ..\build.bat test

set SKIP_MSI_STEP=
set SKIP_PDL_STEP=
perl -Mblib ..\script\perldist_strawberry -job ..\share\32bit-5.22.0.1.pp -notest_core -beta=2 -nointeractive -restorepoints -wixbin_dir=z:\sw\Wix38 -cpan_url file:///z:/_cpan-mirror/
perl -Mblib ..\script\perldist_strawberry -job ..\share\64bit-5.22.0.1.pp -notest_core -beta=2 -nointeractive -restorepoints -wixbin_dir=z:\sw\Wix38 -cpan_url file:///z:/_cpan-mirror/

rem set SKIP_MSI_STEP=1
rem set SKIP_PDL_STEP=1
rem perl -Mblib ..\script\perldist_strawberry -job ..\share\32bit-5.22.0.1.pp -notest_core -beta=0 -noperl_64bitint -app_simplename=strawberry-perl-no64 -nointeractive -norestorepoints -wixbin_dir=z:\sw\Wix38 -cpan_url file:///z:/_cpan-mirror/

pause
