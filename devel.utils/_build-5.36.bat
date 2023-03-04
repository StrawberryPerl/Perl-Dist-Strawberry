::@cls
::call ..\build.bat test

::set PERL_USE_UNSAFE_INC=1

set SP=z:\sp532
set PATH=%SP%\c\bin;%SP%\perl\bin;%SP%\perl\site\bin;%PATH%

set SKIP_MSI_STEP=1
set SKIP_PDL_STEP=1
perl -Mblib ..\script\perldist_strawberry -job ..\share\64bit-5.36.0.1.pp -test_core -beta=0 -nointeractive -norestorepoints -wixbin_dir=z:\sw\wix311 -cpan_url https://cpan.metacpan.org


