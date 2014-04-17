### job description for building strawberry perl

#Available '<..>' macros:
# <package_url>   is placeholder for http://strawberryperl.com/package
# <dist_sharedir> is placeholder for Perl::Dist::Strawberry's distribution sharedir
# <image_dir>     is placeholder for c:\strawberry

{
  app_version     => '5.19.10.4', #BEWARE: do not use '.0.0' in the last two version digits
  bits            => 64,
  beta            => 0,
  app_fullname    => 'Strawberry Perl (64-bit)',
  app_simplename  => 'strawberry-perl',
  build_job_steps => [
    ### NEXT STEP ###########################
    {
        plugin  => 'Perl::Dist::Strawberry::Step::BinaryToolsAndLibs',
        install_packages => {
            #tools
            'dmake'         => '<package_url>/kmx/64_tools/64bit_dmake-SVN20091127-bin_20111107.zip',
            'mingw-make'    => '<package_url>/kmx/64_tools/64bit_gmake-3.82-bin_20110503.zip',
            'pexports'      => '<package_url>/kmx/64_tools/64bit_pexports-0.44-bin_20100110.zip',
            'patch'         => '<package_url>/kmx/64_tools/64bit_patch-2.5.9-7-bin_20100110_UAC.zip',
            #gcc & co.
            'gcc-toolchain' => { url=>'<package_url>/kmx/64_gcctoolchain/mingw64-w64-gcc4.8.2_20140407.zip', install_to=>'c' },
            'gcc-license'   => '<package_url>/kmx/64_gcctoolchain/mingw64-w64-gcc4.8.2_20140407-lic.zip',
            #libs
            'libdb'         => '<package_url>/kmx/64_libs/gcc48-2014Q1/64bit_db-6.0.30-bin_20140417.zip',
            'libexpat'      => '<package_url>/kmx/64_libs/gcc48-2014Q1/64bit_expat-2.1.0-bin_20140417.zip',
            'libfreeglut'   => '<package_url>/kmx/64_libs/gcc48-2014Q1/64bit_freeglut-2.8.1-bin_20140417.zip',
            'libfreetype'   => '<package_url>/kmx/64_libs/gcc48-2014Q1/64bit_freetype-2.5.3-bin_20140417.zip',
            'libgdbm'       => '<package_url>/kmx/64_libs/gcc48-2014Q1/64bit_gdbm-1.10-bin_20140417.zip',
            'libgiflib'     => '<package_url>/kmx/64_libs/gcc48-2014Q1/64bit_giflib-5.0.5-bin_20140417.zip',
            'libgmp'        => '<package_url>/kmx/64_libs/gcc48-2014Q1/64bit_gmp-5.1.3-bin_20140417.zip',
            'libjpeg'       => '<package_url>/kmx/64_libs/gcc48-2014Q1/64bit_jpeg-9a-bin_20140417.zip',
            'libgd'         => '<package_url>/kmx/64_libs/gcc48-2014Q1/64bit_libXpm-3.5.11-bin_20140417.zip',
            'liblibXpm'     => '<package_url>/kmx/64_libs/gcc48-2014Q1/64bit_libgd-2.1.0-bin_20140417.zip',
            'liblibiconv'   => '<package_url>/kmx/64_libs/gcc48-2014Q1/64bit_libiconv-1.14-bin_20140417.zip',
            'liblibpng'     => '<package_url>/kmx/64_libs/gcc48-2014Q1/64bit_libpng-1.6.10-bin_20140417.zip',
            'liblibssh2'    => '<package_url>/kmx/64_libs/gcc48-2014Q1/64bit_libssh2-1.4.3-bin_20140417.zip',
            'liblibxml2'    => '<package_url>/kmx/64_libs/gcc48-2014Q1/64bit_libxml2-2.9.1-bin_20140417.zip',
            'liblibxslt'    => '<package_url>/kmx/64_libs/gcc48-2014Q1/64bit_libxslt-1.1.28-bin_20140417.zip',
            'libmpc'        => '<package_url>/kmx/64_libs/gcc48-2014Q1/64bit_mpc-1.0.2-bin_20140417.zip',
            'libmpfr'       => '<package_url>/kmx/64_libs/gcc48-2014Q1/64bit_mpfr-3.1.2-bin_20140417.zip',
            'libopenssl'    => '<package_url>/kmx/64_libs/gcc48-2014Q1/64bit_openssl-1.0.1g-bin_20140417.zip',
            'libpostgresql' => '<package_url>/kmx/64_libs/gcc48-2014Q1/64bit_postgresql-9.3.4-bin_20140417.zip',
            'libt1lib'      => '<package_url>/kmx/64_libs/gcc48-2014Q1/64bit_t1lib-5.1.2-bin_20140417.zip',
            'libtiff'       => '<package_url>/kmx/64_libs/gcc48-2014Q1/64bit_tiff-4.0.3-bin_20140417.zip',
            'libxz'         => '<package_url>/kmx/64_libs/gcc48-2014Q1/64bit_xz-5.0.5-bin_20140417.zip',
            'libzlib'       => '<package_url>/kmx/64_libs/gcc48-2014Q1/64bit_zlib-1.2.8-bin_20140417.zip',
            #special cases
            'libmysql'      => '<package_url>/kmx/64_libs/gcc44-2011/64bit_mysql-5.1.44-bin_20100304.zip',       # the latest DLL binary is missing some exports
        },
    },
    ### NEXT STEP ###########################
    {
        plugin     => 'Perl::Dist::Strawberry::Step::InstallPerlCore',
        #url        => 'http://cpan.metacpan.org/authors/id/A/AR/ARC/perl-5.19.10.tar.gz',
        url        => 'http://search.cpan.org/CPAN/authors/id/A/AR/ARC/perl-5.19.10.tar.bz2',
        cf_email   => 'strawberry-perl@project', #IMPORTANT: keep 'strawberry-perl' before @
        perl_debug => 0,
        #use_64_bit_int not needed on 64bit
        #buildoptextra => '-D__USE_MINGW_ANSI_STDIO',
        patch => { #DST paths are relative to the perl src root
            '<dist_sharedir>/perl-5.20/win32_config.gc.tt'      => 'win32/config.gc',
            ### decoration
            '<dist_sharedir>/msi/files/perlexe.ico'             => 'win32/perlexe.ico',
            '<dist_sharedir>/perl-5.20/perlexe.rc.tt'           => 'win32/perlexe.rc',
            '<dist_sharedir>/perl-5.20/win32_win32.h'           => 'win32/win32.h',     # fixing comments
            '<dist_sharedir>/perl-5.20/installperl'             => 'installperl',       # necessary for nonstandard $Config{dlext}
            #'<dist_sharedir>/perl-5.20/win32_config_H.gc'       => 'win32/config_H.gc', # enables gdbm/ndbm/odbm
            #'<dist_sharedir>/perl-5.20/win32_FindExt.pm'        => 'win32/FindExt.pm',  # enables gdbm/ndbm/odbm
        },
        license => { #SRC paths are relative to the perl src root
            'Readme'   => '<image_dir>/licenses/perl/Readme',
            'Artistic' => '<image_dir>/licenses/perl/Artistic',
            'Copying'  => '<image_dir>/licenses/perl/Copying',
        },
    },
    ### NEXT STEP ###########################
##    {
##        plugin => 'Perl::Dist::Strawberry::Step::InstallModules',
##        modules => [
##          # here is a place to (re)install/(up/down)grade modules needed before 'Perl::Dist::Strawberry::Step::UpgradeCpanModules'
##          # e.g. { install_to=>'perl', module=>'Module::Name' },
##        ],
##    },
    ### NEXT STEP ###########################
    {
        plugin => 'Perl::Dist::Strawberry::Step::UpgradeCpanModules',
        exceptions => [
          # possible 'do' options: ignore_testfailure | skiptest | skip
          # e.g. { do=>'ignore_testfailure', distribution=>'ExtUtils-MakeMaker-6.72' },
        ]
    },
    ### NEXT STEP ###########################
    {
        plugin => 'Perl::Dist::Strawberry::Step::InstallModules',
        modules => [
            # IPC related
            { module=>'IPC-Run', skiptest=>1 }, #XXX-FIXME trouble with 'Terminating on signal SIGBREAK(21)'
            qw/ IPC-Run3 IPC-System-Simple /,

            # xs.dll & d_libname_unique related patch
            ###XXX https://rt.cpan.org/Ticket/Display.html?id=94515 + https://rt.cpan.org/Public/Bug/Display.html?id=92699
            { module=>'<package_url>/kmx/perl-modules-patched/ExtUtils-Depends-0.306_patched.tar.gz', ignore_testfailure=>1 },

            # gdbm related
            '<package_url>/kmx/perl-modules-patched/GDBM_File-1.15.tar.gz',
            '<package_url>/kmx/perl-modules-patched/NDBM_File-1.12.tar.gz',
            '<package_url>/kmx/perl-modules-patched/ODBM_File-1.12.tar.gz',

            #removed from core in 5.20
            qw/Archive::Extract B::Lint CPANPLUS File::CheckTree Log::Message Module::Pluggable Object::Accessor Text::Soundex Term::UI Pod::LaTeX Tree::DAG_Node/,
            { module=>'CPANPLUS::Dist::Build', ignore_testfailure=>1 }, #XXX-TODO: fails on 64bit 5.19.9

            # win32 related
            { module=>'Win32API-Registry', ignore_testfailure=>1 }, #XXX-TODO: Win32API-Registry-0.32 test FAILS
            { module=>'Win32-TieRegistry', ignore_testfailure=>1 }, #XXX-TODO: Win32-TieRegistry-0.26 test FAILS
            { module=>'Win32-OLE',         ignore_testfailure=>1 }, #XXX-TODO: test used to fail
            qw/ Win32-API Win32-EventLog Win32-Exe Win32-Process Win32-WinError Win32-File-Object Win32-UTCFileTime /,
            qw/ Win32-ShellQuote Win32::Console Win32::Console::ANSI Win32::Job Win32::Daemon Win32::ServiceManager Win32::Service /,

            # term related
            '<package_url>/kmx/perl-modules-patched/TermReadKey-2.31_patched.tar.gz', # special version needed XXX-report a bug https://metacpan.org/pod/Term::ReadKey
            { module=>'Term::ReadLine::Perl', env=>{ PERL_MM_NONINTERACTIVE=>1 } },

            # compression
            { module=>'Archive-Zip', ignore_testfailure=>1 },   #XXX-TODO: Archive-Zip-1.33 test FAILS
            qw/ IO-Compress-Lzma Compress-unLZMA /,

            # file related
            { module=>'File-Slurp', ignore_testfailure=>1 },    #XXX-TODO: on 32bit OK
            qw/ File-Find-Rule          File-HomeDir            File-Listing            File-Remove
                File-ShareDir           File-Which              File-Copy-Recursive /,

            # dbm related
            qw/ BerkeleyDB DB_File DBM-Deep /,

            # database stuff
            qw/ DBI DBD-ODBC DBD-SQLite DBIx-Simple /,
            { module=>'DBIx-Class', ignore_testfailure=>1 },    #XXX-TODO: check test failures
            { module=>'DBD-ADO', ignore_testfailure=>1 },       #XXX-TODO: DBD-ADO-2.99 test FAILS
            { module=>'DBD-Pg', ignore_testfailure=>1 },        #XXX-TODO: XXX FIXME!!!!
            { module=>'DBD-mysql', ignore_testfailure=>1, makefilepl_param=>'--mysql_config=mysql_config' }, #XXX-TODO: check test failures

            # math related
            qw/ Math-Round Math-BigInt-GMP Math-GMP Math-MPC Math-MPFR /,
            #qw/ Math-Pari /, #fails on 64bit

            # has to go before Module::Signature as it throws an error: Not trusting this module, aborting install
            qw/ HTTP-Server-Simple /,

            # crypto
            '<package_url>/kmx/perl-modules-patched/Crypt-OpenSSL-Random-0.04_patched.tar.gz',  #XXX-CHECK https://metacpan.org/pod/Crypt::OpenSSL::Random
            '<package_url>/kmx/perl-modules-patched/Crypt-OpenSSL-Bignum-0.04_patched.tar.gz',  #XXX-CHECK https://metacpan.org/pod/Crypt::OpenSSL::Bignum
            '<package_url>/kmx/perl-modules-patched/Crypt-OpenSSL-AES-0.02_patched.tar.gz',     #XXX-CHECK https://metacpan.org/pod/Crypt::OpenSSL::AES
            '<package_url>/kmx/perl-modules-patched/Crypt-OpenSSL-DSA-0.14_patched.tar.gz',     #XXX-CHECK https://metacpan.org/pod/Crypt::OpenSSL::DSA
            '<package_url>/kmx/perl-modules-patched/Crypt-OpenSSL-X509-1.804_patched.tar.gz',   #XXX-CHECK https://metacpan.org/pod/Crypt::OpenSSL::X509 (needs to be reported!!!!!!)
            'Crypt-OpenSSL-RSA',

            'Alt::Crypt::RSA::BigInt',                                                          #XXX-TODO: a hack Crypt-RSA without Math::PARI

            # this is subset of modules we install on64bit
            qw/ Crypt::IDEA Crypt::Blowfish Crypt::Twofish Crypt::DES Crypt::DH /,
            qw/ Crypt::Rijndael Crypt::CAST5_PP Crypt::CBC Crypt::DES_EDE3 Crypt::DSA Crypt::RIPEMD160 /,
            { module =>'Convert-PEM', ignore_testfailure=>1 },                                  #XXX-TODO
            qw/ Class-Loader Convert-ASCII-Armor Sort-Versions Tie-EncryptedHash /,

            #qw/ Crypt::Random /, #fails on 64bit

            # tests fail on 5.18.x
            #{ module =>'Crypt::OpenPGP' },
            #{ module =>'Module::Signature', ignore_testfailure=>1 },

            # digests
            qw/ Digest-BubbleBabble Digest-HMAC Digest-MD2 Digest-SHA1 /,

            # SSL & SSH
            qw/ Net-SSLeay /,
            { module=>'IO-Socket-SSL', ignore_testfailure=>1 },         #XXX-TODO
            qw/ Net-SMTP-TLS Net-SSH2 /,
            { module =>'Crypt-SSLeay', ignore_testfailure=>1 },

            # network
            qw/ LWP::UserAgent LWP-Protocol-https /,

            # graphics
            { module=>'GD', ignore_testfailure=>1 },                    #XXX-TODO
            { module=>'Imager', ignore_testfailure=>1 },                #XXX-TODO
            qw/ Imager-File-GIF Imager-File-JPEG Imager-File-PNG Imager-File-TIFF Imager-Font-FT2 Imager-Font-W32 /,

            # XML & co.
            qw/ XML-LibXML XML-LibXSLT XML-Parser XML-SAX XML-Simple SOAP-Lite /,

            # YAML, JSON & co.
            qw/ JSON JSON-XS YAML YAML-Tiny YAML::XS /,
            #'YAML-Syck', #XXX-TODO: buggy therefore removed

            # utils
            qw/ pler App-local-lib-Win32Helper /,
            { module=>'pip', ignore_testfailure=>1 },                   #XXX-TODO: test fails - The directory 'C:\strawberry\cpan\sources' does not exist

            # par & ppm &cpanm
            qw/ PAR PAR::Dist::FromPPD PAR::Dist::InstallPPD PAR::Repository::Client /,
            # The build path in ppm.xml is derived from $ENV{TMP}. So set TMP to a dedicated location inside of the
            # distribution root to prevent it being locked to the temp directory of the build machine.
            { module=>'<package_url>/kmx/perl-modules-patched/PPM-11.11_03.tar.gz', env=>{ TMP=>'<image_dir>\ppm' } },

            # tiny
            qw/ Capture-Tiny Try-Tiny Template-Tiny /,

            # misc
            qw/ CPAN::SQLite Alien-Tidyp FCGI Text-Diff Text-Patch /,
            qw/ IO::Stringy IO::String String-CRC32 Sub-Uplevel Convert-PEM/,

            # strawberry extras
            qw/ App-module-version /,

            # new modules added to 5.16 (added also to 5.14.3)
            qw/ ExtUtils::F77 /,
            qw/ Data::Dump Data::Printer /,
            qw/ Moose MooseX-Types MooseX::Types::Structured MooseX::Declare MooseX::ClassAttribute MooseX::Role::Parameterized MooseX::NonMoose Moo /,
            { module=>'IO::Socket::IP', ignore_testfailure=>1 },        #XXX-TODO test failures ipv6related - https://rt.cpan.org/Ticket/Display.html?id=83485
            qw/ IO::Socket::INET6 /,
            qw/ WWW::Mechanize Net::Telnet Class::Accessor Date::Format /,
            { module=>'Template', ignore_testfailure=>1 },              #XXX-TODO
            qw/ App-cpanminus /,
            qw/ Mojolicious Text::CSV Text::CSV_XS Excel::Writer::XLSX Perl::Tidy /,

            # trying to include some GUI tools
            #qw/IUP/,
        ],

    },
    ### NEXT STEP ###########################
##    {
##        plugin => 'Perl::Dist::Strawberry::Step::UninstallModules',
##        #modules => [ 'Alien-IUP' ],
##        modules => [],
##    },
    ### NEXT STEP ###########################
    {
        plugin => 'Perl::Dist::Strawberry::Step::FixShebang',
        shebang => '#!perl',
    },
    ### NEXT STEP ###########################
    {
       plugin => 'Perl::Dist::Strawberry::Step::FilesAndDirs',
       commands => [
         # directories
         { do=>'createdir', args=>[ '<image_dir>/cpan' ] },
         { do=>'createdir', args=>[ '<image_dir>/cpan/sources' ] },
         { do=>'createdir', args=>[ '<image_dir>/win32' ] },
         # templated files
         { do=>'apply_tt', args=>[ '<dist_sharedir>/config-files/CPAN_Config.pm.tt', '<image_dir>/perl/lib/CPAN/Config.pm', {}, 1 ] }, #XXX-temporary empty tt_vars, no_backup=1
         { do=>'apply_tt', args=>[ '<dist_sharedir>/extra-files/README.txt.tt', '<image_dir>/README.txt' ] },
         { do=>'apply_tt', args=>[ '<dist_sharedir>/extra-files/DISTRIBUTIONS.txt.tt', '<image_dir>/DISTRIBUTIONS.txt' ] },
         # fixed files
         { do=>'copyfile', args=>[ '<dist_sharedir>/extra-files/licenses/License.rtf', '<image_dir>/licenses/License.rtf' ] },
         { do=>'copyfile', args=>[ '<dist_sharedir>/extra-files/relocation.pl.bat',    '<image_dir>/relocation.pl.bat' ] },
         { do=>'copyfile', args=>[ '<dist_sharedir>/extra-files/update_env.pl.bat',    '<image_dir>/update_env.pl.bat' ] },
         { do=>'copyfile', args=>[ '<dist_sharedir>/extra-files/win32/cpan.ico',       '<image_dir>/win32/cpan.ico' ] },
         { do=>'copyfile', args=>[ '<dist_sharedir>/extra-files/win32/onion.ico',      '<image_dir>/win32/onion.ico' ] },
         { do=>'copyfile', args=>[ '<dist_sharedir>/extra-files/win32/perldoc.ico',    '<image_dir>/win32/perldoc.ico' ] },
         { do=>'copyfile', args=>[ '<dist_sharedir>/extra-files/win32/perlhelp.ico',   '<image_dir>/win32/perlhelp.ico' ] },
         { do=>'copyfile', args=>[ '<dist_sharedir>/extra-files/win32/strawberry.ico', '<image_dir>/win32/strawberry.ico' ] },
         { do=>'copyfile', args=>[ '<dist_sharedir>/extra-files/win32/win32.ico',      '<image_dir>/win32/win32.ico' ] },
         { do=>'copyfile', args=>[ '<dist_sharedir>/extra-files/win32/metacpan.ico',   '<image_dir>/win32/metacpan.ico' ] },
         # URLs
         { do=>'apply_tt', args=>[ '<dist_sharedir>/extra-files/win32/CPAN Module Search.url.tt',                  '<image_dir>/win32/CPAN Module Search.url' ] },
         { do=>'apply_tt', args=>[ '<dist_sharedir>/extra-files/win32/MetaCPAN Search Engine.url.tt',              '<image_dir>/win32/MetaCPAN Search Engine.url' ] },
         { do=>'apply_tt', args=>[ '<dist_sharedir>/extra-files/win32/Learning Perl (tutorials, examples).url.tt', '<image_dir>/win32/Learning Perl (tutorials, examples).url' ] },
         { do=>'apply_tt', args=>[ '<dist_sharedir>/extra-files/win32/Live Support (chat).url.tt',                 '<image_dir>/win32/Live Support (chat).url' ] },
         { do=>'apply_tt', args=>[ '<dist_sharedir>/extra-files/win32/Perl Documentation.url.tt',                  '<image_dir>/win32/Perl Documentation.url' ] },
         { do=>'apply_tt', args=>[ '<dist_sharedir>/extra-files/win32/Strawberry Perl Release Notes.url.tt',       '<image_dir>/win32/Strawberry Perl Release Notes.url' ] },
         { do=>'apply_tt', args=>[ '<dist_sharedir>/extra-files/win32/Strawberry Perl Website.url.tt',             '<image_dir>/win32/Strawberry Perl Website.url' ] },
         # cleanup (remove unwanted files/dirs)
         { do=>'removefile', args=>[ '<image_dir>/c/bin/gccbug', '<image_dir>/perl/vendor/lib/Crypt/._test.pl', '<image_dir>/perl/vendor/lib/DBD/testme.tmp.pl' ] },
         { do=>'removefile_recursive', args=>[ '<image_dir>/perl', qr/.+\.dll\.AA[A-Z]$/i ] },
         # cleanup cpanm related files
         { do=>'removedir', args=>[ '<image_dir>/perl/site/lib/MSWin32-x86-multi-thread-64int' ] },
         { do=>'removedir', args=>[ '<image_dir>/perl/site/lib/MSWin32-x86-multi-thread' ] },
         { do=>'removedir', args=>[ '<image_dir>/perl/site/lib/MSWin32-x64-multi-thread' ] },
       ],
    },
    ### NEXT STEP ###########################
    {
       plugin => 'Perl::Dist::Strawberry::Step::CreateRelocationFile',
       reloc_in  => '<dist_sharedir>/relocation/relocation.txt.initial',
       reloc_out => '<image_dir>/relocation.txt',
    },
    ### NEXT STEP ###########################
    {
       plugin => 'Perl::Dist::Strawberry::Step::OutputZIP', # no options needed
    },
    ### NEXT STEP ###########################
    {
       plugin => 'Perl::Dist::Strawberry::Step::OutputMSI',
       exclude  => [
           #'dirname\subdir1\subdir2',
           #'dirname\file.pm',
           'relocation.pl.bat',
           'update_env.pl.bat',
       ],
       msi_upgrade_code    => 'DBA41113-4E91-3FFC-B400-573BB4B80705', #BEWARE: fixed value for all 64bit releases (for ever)
       app_publisher       => 'strawberryperl.com project',
       url_about           => 'http://strawberryperl.com/',
       url_help            => 'http://strawberryperl.com/support.html',
       msi_root_dir        => 'Strawberry',
       msi_main_icon       => '<dist_sharedir>\msi\files\strawberry.ico',
       msi_license_rtf     => '<dist_sharedir>\msi\files\License-short.rtf',
       msi_dialog_bmp      => '<dist_sharedir>\msi\files\StrawberryDialog.bmp',
       msi_banner_bmp      => '<dist_sharedir>\msi\files\StrawberryBanner.bmp',
       msi_debug           => 0,

       start_menu => [ # if "description" is missing it will be set to the same value as "name"
         { type=>'shortcut', name=>'Perl (command line)', icon=>'<dist_sharedir>\msi\files\perlexe.ico', description=>'Quick way to get to the command line in order to use Perl', target=>'[SystemFolder]cmd.exe', workingdir=>'PersonalFolder' },
         { type=>'shortcut', name=>'Strawberry Perl Release Notes', icon=>'<dist_sharedir>\msi\files\strawberry.ico', target=>'[d_win32]Strawberry Perl Release Notes.url', workingdir=>'d_win32' },
         { type=>'shortcut', name=>'Strawberry Perl README', target=>'[INSTALLDIR]README.txt', workingdir=>'INSTALLDIR' },
         { type=>'folder',   name=>'Tools', members=>[
              { type=>'shortcut', name=>'CPAN Client', icon=>'<dist_sharedir>\msi\files\cpan.ico', target=>'[d_perl_bin]cpan.bat', workingdir=>'d_perl_bin' },
              { type=>'shortcut', name=>'Create local library areas', icon=>'<dist_sharedir>\msi\files\strawberry.ico', target=>'[d_perl_bin]llw32helper.bat', workingdir=>'d_perl_bin' },
         ] },
         { type=>'folder', name=>'Related Websites', members=>[
              { type=>'shortcut', name=>'CPAN Module Search', icon=>'<dist_sharedir>\msi\files\cpan.ico', target=>'[d_win32]CPAN Module Search.url', workingdir=>'d_win32' },
              { type=>'shortcut', name=>'MetaCPAN Search Engine', icon=>'<dist_sharedir>\msi\files\metacpan.ico', target=>'[d_win32]MetaCPAN Search Engine.url', workingdir=>'d_win32' },
              { type=>'shortcut', name=>'Perl Documentation', icon=>'<dist_sharedir>\msi\files\perldoc.ico', target=>'[d_win32]Perl Documentation.url', workingdir=>'d_win32' },
              { type=>'shortcut', name=>'Strawberry Perl Website', icon=>'<dist_sharedir>\msi\files\strawberry.ico', target=>'[d_win32]Strawberry Perl Website.url', workingdir=>'d_win32' },
              { type=>'shortcut', name=>'Learning Perl (tutorials, examples)', icon=>'<dist_sharedir>\msi\files\perldoc.ico', target=>'[d_win32]Learning Perl (tutorials, examples).url', workingdir=>'d_win32' },
              { type=>'shortcut', name=>'Live Support (chat)', icon=>'<dist_sharedir>\msi\files\onion.ico', target=>'[d_win32]Live Support (chat).url', workingdir=>'d_win32' },
         ] },
       ],
       env => {
         #TERM => "dumb",
       },

    },
    ### NEXT STEP ###########################
    {
        plugin => 'Perl::Dist::Strawberry::Step::InstallModules',
        # modules specific to portable edition
        modules => [ 'Portable' ],
    },
    ### NEXT STEP ###########################
    {
       plugin => 'Perl::Dist::Strawberry::Step::SetupPortablePerl', # no options needed
    },
    ### NEXT STEP ###########################
    {
       plugin => 'Perl::Dist::Strawberry::Step::FilesAndDirs',
       commands => [ # files and dirs specific to portable edition
         { do=>'removefile', args=>[ '<image_dir>/README.txt', '<image_dir>/perl2.reloc.txt', '<image_dir>/perl1.reloc.txt', '<image_dir>/relocation.txt',
                                     '<image_dir>/update_env.pl.bat', '<image_dir>/relocation.pl.bat' ] },
         { do=>'createdir',  args=>[ '<image_dir>/data' ] },
         { do=>'apply_tt',   args=>[ '<dist_sharedir>/portable/portable.perl.tt',       '<image_dir>/portable.perl', {gcchost=>'x86_64-w64-mingw32', gccver=>'482'} ] },
         { do=>'copyfile',   args=>[ '<dist_sharedir>/portable/portableshell.bat',      '<image_dir>/portableshell.bat' ] },
         { do=>'apply_tt',   args=>[ '<dist_sharedir>/portable/README.portable.txt.tt', '<image_dir>/README.txt' ] },
         # cleanup cpanm related files
         { do=>'removedir', args=>[ '<image_dir>/perl/site/lib/MSWin32-x86-multi-thread-64int' ] },
         { do=>'removedir', args=>[ '<image_dir>/perl/site/lib/MSWin32-x86-multi-thread' ] },
         { do=>'removedir', args=>[ '<image_dir>/perl/site/lib/MSWin32-x64-multi-thread' ] },
       ],
    },
    ### NEXT STEP ###########################
    {
       plugin => 'Perl::Dist::Strawberry::Step::OutputPortableZIP', # no options needed
    },
    ### NEXT STEP ###########################
    {
       plugin => 'Perl::Dist::Strawberry::Step::CreateReleaseNotes', # no options needed
    },
    ### NEXT STEP ###########################
    {
        plugin  => 'Perl::Dist::Strawberry::Step::BinaryToolsAndLibs',
        install_packages => {        
            'fftw2'         => '<package_url>/kmx/64_libs/gcc48-2014Q1/64bit_fftw-2.1.5-bin_20140417.zip',
            'fftw3'         => '<package_url>/kmx/64_libs/gcc48-2014Q1/64bit_fftw-3.3.4-bin_20140417.zip',
            'gnuplot'       => '<package_url>/kmx/64_libs/gcc48-2014Q1/64bit_gnuplot-4.6.5-bin_20140417.zip',
            'gsl'           => '<package_url>/kmx/64_libs/gcc48-2014Q1/64bit_gsl-1.16-bin_20140417.zip',
            'hdf4'          => '<package_url>/kmx/64_libs/gcc48-2014Q1/64bit_hdf-4.2.10-bin_20140417.zip',
            'hdf5'          => '<package_url>/kmx/64_libs/gcc48-2014Q1/64bit_hdf5-1.8.12-bin_20140417.zip',
            'ncurses'       => '<package_url>/kmx/64_libs/gcc48-2014Q1/64bit_ncurses-5.9-bin_20140417.zip',
            'plplot'        => '<package_url>/kmx/64_libs/gcc48-2014Q1/64bit_plplot-5.10.0-bin_20140417.zip',
            'proj'          => '<package_url>/kmx/64_libs/gcc48-2014Q1/64bit_proj-4.8.0-bin_20140417.zip',
            'szip'          => '<package_url>/kmx/64_libs/gcc48-2014Q1/64bit_szip-2.1-bin_20140417.zip',
            'talib'         => '<package_url>/kmx/64_libs/gcc48-2014Q1/64bit_ta-lib-0.4.0-bin_20140417.zip',
            'netcdf'        => '<package_url>/kmx/64_libs/gcc48-2014Q1/64bit_netcdf-4.3.1.1-bin_20140417.zip',
        },
    },
    ### NEXT STEP ###########################
    {
        plugin => 'Perl::Dist::Strawberry::Step::InstallModules',
        # modules specific to portable edition
        modules => [ 
          qw/Devel::REPL Lexical::Persistence/,
          { module=>'OpenGL', ignore_testfailure=>1 },
          { module=>'Data::Dump::Streamer', ignore_testfailure=>1 },
          { module=>'PDL',    ignore_testfailure=>1 },
        ],
    },
    ### NEXT STEP ###########################
    {
       plugin => 'Perl::Dist::Strawberry::Step::FilesAndDirs',
       commands => [ # files and dirs specific to portable edition
         { do=>'removefile', args=>[ '<image_dir>/README.txt', '<image_dir>/portableshell.bat' ] },
         { do=>'copyfile',   args=>[ '<dist_sharedir>/portable/portableshell.pdl.bat', '<image_dir>/portableshell.bat' ] },
         { do=>'apply_tt',   args=>[ '<dist_sharedir>/portable/README.pdl.txt.tt',     '<image_dir>/README.txt' ] },
         # cleanup cpanm related files
         { do=>'removedir', args=>[ '<image_dir>/data/.cpanm' ] },
         { do=>'removedir', args=>[ '<image_dir>/perl/site/lib/MSWin32-x86-multi-thread-64int' ] },
         { do=>'removedir', args=>[ '<image_dir>/perl/site/lib/MSWin32-x86-multi-thread' ] },
         { do=>'removedir', args=>[ '<image_dir>/perl/site/lib/MSWin32-x64-multi-thread' ] },
       ],
    },
    ### NEXT STEP ###########################
    {
       plugin => 'Perl::Dist::Strawberry::Step::OutputPdlZIP', # no options needed
    },
    ### NEXT STEP ###########################
    {
       plugin => 'Perl::Dist::Strawberry::Step::OutputLogZIP', # no options needed
    },
  ],
}
