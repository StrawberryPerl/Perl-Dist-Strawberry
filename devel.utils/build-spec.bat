@cls
call ..\build.bat
perl -Mblib ..\script\perldist_strawberry -cpan_url file://z:/strawberry_build/_cpan-mirror/ -job ..\share\32bit-5.16.0.1-SPP-debug-64int.pp -nointeractive -restorepoints
rem perl -Mblib ..\script\perldist_strawberry -cpan_url file://z:/strawberry_build/_cpan-mirror/ -job ..\share\32bit-5.16.0.1-SPP-64int.pp -nointeractive
rem perl -Mblib ..\script\perldist_strawberry -cpan_url file://z:/strawberry_build/_cpan-mirror/ -job ..\share\32bit-5.16.0.1-SPP-debug.pp -nointeractive
pause
