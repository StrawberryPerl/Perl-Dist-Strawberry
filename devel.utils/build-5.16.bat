@cls
call ..\build.bat
rem perl -Mblib ..\script\perldist_strawberry -cpan_url file://z:/strawberry_build/_cpan-mirror/ -job ..\share\32bit-5.16.3.1-SPP-min.pp -interactive -norestorepoints
perl -Mblib ..\script\perldist_strawberry -cpan_url file://z:/strawberry_build/_cpan-mirror/ -job ..\share\32bit-5.16.3.1.pp -nointeractive -norestorepoints
perl -Mblib ..\script\perldist_strawberry -cpan_url file://z:/strawberry_build/_cpan-mirror/ -job ..\share\64bit-5.16.3.1.pp -nointeractive -norestorepoints

pause
