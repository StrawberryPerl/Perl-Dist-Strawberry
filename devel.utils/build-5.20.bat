@cls
call ..\build.bat test
perl -Mblib ..\script\perldist_strawberry -cpan_url file:///z:/_cpan-mirror/ -job ..\share\32bit-5.20.1.1.pp -nointeractive -norestorepoints -wixbin_dir=z:\sw\Wix38 -beta=1
perl -Mblib ..\script\perldist_strawberry -cpan_url file:///z:/_cpan-mirror/ -job ..\share\64bit-5.20.1.1.pp -nointeractive -norestorepoints -wixbin_dir=z:\sw\Wix38 -beta=1
perl -Mblib ..\script\perldist_strawberry -cpan_url file:///z:/_cpan-mirror/ -job ..\share\32bit-5.20.1.1.pp -nointeractive -norestorepoints -wixbin_dir=z:\sw\Wix38 -beta=1 -noperl_64bitint -app_simplename=strawberry-perl-no64
pause
