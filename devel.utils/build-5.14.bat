@cls
call ..\build.bat
rem perl -Mblib ..\script\perldist_strawberry -cpan_url file://z:/strawberry_build/_cpan-mirror/ -job ..\share\32bit-5.14.3.1.pp -nointeractive
perl -Mblib ..\script\perldist_strawberry -cpan_url file://z:/strawberry_build/_cpan-mirror/ -job ..\share\64bit-5.14.3.1.pp -nointeractive
rem perl -Mblib ..\script\perldist_strawberry -cpan_url file://z:/strawberry_build/_cpan-mirror/ -job ..\share\32bit-5.14.3.1-reloc.pp -nointeractive
pause
