@cls
call ..\build.bat
rem perl -Mblib ..\script\perldist_strawberry -cpan_url file://z:/strawberry_build/_cpan-mirror/ -job ..\share\64bit-5.14.4.1.pp -nointeractive -norestorepoints
rem perl -Mblib ..\script\perldist_strawberry -cpan_url file://z:/strawberry_build/_cpan-mirror/ -job ..\share\32bit-5.14.4.1.pp -nointeractive -norestorepoints
perl -Mblib ..\script\perldist_strawberry -cpan_url file://z:/strawberry_build/_cpan-mirror/ -job ..\share\64bit-5.16.3.1.pp -nointeractive -norestorepoints
perl -Mblib ..\script\perldist_strawberry -cpan_url file://z:/strawberry_build/_cpan-mirror/ -job ..\share\32bit-5.16.3.1.pp -nointeractive -norestorepoints
pause
