@cls
call ..\build.bat test
perl -Mblib ..\script\perldist_strawberry -cpan_url file:///z:/_cpan-mirror/ -job ..\share\32bit-5.16.3.1.pp         -nointeractive -norestorepoints -wixbin_dir=z:\sw\Wix38
perl -Mblib ..\script\perldist_strawberry -cpan_url file:///z:/_cpan-mirror/ -job ..\share\32bit-5.16.3.1-SPP-min.pp -nointeractive -norestorepoints
perl -Mblib ..\script\perldist_strawberry -cpan_url file:///z:/_cpan-mirror/ -job ..\share\64bit-5.16.3.1.pp         -nointeractive -norestorepoints -wixbin_dir=z:\sw\Wix38
pause
