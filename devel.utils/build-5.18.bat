@cls
call ..\build.bat test
perl -Mblib ..\script\perldist_strawberry -job ..\share\64bit-5.18.3.1.pp       -test_core -cpan_url file:///z:/_cpan-mirror/ -nointeractive -norestorepoints -wixbin_dir=z:\sw\Wix38
perl -Mblib ..\script\perldist_strawberry -job ..\share\32bit-5.18.3.1.pp       -test_core -cpan_url file:///z:/_cpan-mirror/ -nointeractive -norestorepoints -wixbin_dir=z:\sw\Wix38
perl -Mblib ..\script\perldist_strawberry -job ..\share\32bit-5.18.3.1-no64.pp  -test_core -cpan_url file:///z:/_cpan-mirror/ -nointeractive -norestorepoints
pause
