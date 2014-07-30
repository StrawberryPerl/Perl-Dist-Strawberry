@cls
call ..\build.bat test

perl -Mblib ..\script\perldist_strawberry -cpan_url file:///z:/_cpan-mirror/ -job ..\share\32bit-5.20.1.1.pp -nointeractive -restorepoints -wixbin_dir=z:\sw\Wix38 -test_core -beta=2
perl -Mblib ..\script\perldist_strawberry -cpan_url file:///z:/_cpan-mirror/ -job ..\share\64bit-5.20.1.1.pp -nointeractive -restorepoints -wixbin_dir=z:\sw\Wix38 -test_core -beta=2

set SKIP_MSI_STEP=1
set SKIP_PDL_STEP=1
perl -Mblib ..\script\perldist_strawberry -cpan_url file:///z:/_cpan-mirror/ -job ..\share\32bit-5.20.1.1.pp -nointeractive -restorepoints -wixbin_dir=z:\sw\Wix38 -test_core -beta=2 -noperl_64bitint -app_simplename=strawberry-perl-no64

pause
