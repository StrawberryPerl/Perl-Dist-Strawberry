@cls
call ..\build.bat
rem perl -Mblib ..\script\perldist_strawberry -cpan_url file://z:/strawberry_build/_cpan-mirror/ -job ..\share\32bit-5.17.10.1-minimal.pp -nointeractive -restorepoints
rem perl -Mblib ..\script\perldist_strawberry -cpan_url file://z:/strawberry_build/_cpan-mirror/ -job ..\share\32bit-5.17.11.1-minimal.pp -nointeractive -restorepoints
rem perl -Mblib ..\script\perldist_strawberry -cpan_url file://z:/strawberry_build/_cpan-mirror/ -job ..\share\32bit-5.18.0.2-minimal.pp -nointeractive -restorepoints
perl -Mblib ..\script\perldist_strawberry -cpan_url file://z:/strawberry_build/_cpan-mirror/ -job ..\share\32bit-5.18.0.4-minimal.pp -nointeractive -norestorepoints
pause
