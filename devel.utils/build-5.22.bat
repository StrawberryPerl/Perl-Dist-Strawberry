@cls
call ..\build.bat test

set SKIP_MSI_STEP=
set SKIP_PDL_STEP=
perl -Mblib ..\script\perldist_strawberry -job ..\share\32bit-5.22.1.2.pp -test_core -beta=0 -nointeractive -norestorepoints -wixbin_dir=z:\sw\Wix38 -cpan_url file:///z:/_cpan-mirror/
perl -Mblib ..\script\perldist_strawberry -job ..\share\64bit-5.22.1.2.pp -test_core -beta=0 -nointeractive -norestorepoints -wixbin_dir=z:\sw\Wix38 -cpan_url file:///z:/_cpan-mirror/

set SKIP_MSI_STEP=1
set SKIP_PDL_STEP=1
perl -Mblib ..\script\perldist_strawberry -job ..\share\32bit-5.22.1.2.pp -test_core -beta=0 -noperl_64bitint -app_simplename=strawberry-perl-no64 -nointeractive -norestorepoints -wixbin_dir=z:\sw\Wix38 -cpan_url file:///z:/_cpan-mirror/

rem ### EXPERIMENTAL ###
rem set SKIP_MSI_STEP=
rem set SKIP_PDL_STEP=1
rem perl -Mblib ..\script\perldist_strawberry -job ..\share\64bit-5.22.1.2.pp -test_core -beta=0 -perl_ldouble -app_simplename=strawberry-perl-ld -nointeractive -norestorepoints -wixbin_dir=z:\sw\Wix38 -cpan_url file:///z:/_cpan-mirror/
rem perl -Mblib ..\script\perldist_strawberry -job ..\share\#@bit-5.22.1.2.pp -test_core -beta=0 -perl_ldouble -app_simplename=strawberry-perl-ld -nointeractive -norestorepoints -wixbin_dir=z:\sw\Wix38 -cpan_url file:///z:/_cpan-mirror/

pause
