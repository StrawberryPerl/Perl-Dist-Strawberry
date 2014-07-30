### job description for building strawberry perl

#Available '<..>' macros:
# <package_url>   is placeholder for http://strawberryperl.com/package
# <dist_sharedir> is placeholder for Perl::Dist::Strawberry's distribution sharedir
# <image_dir>     is placeholder for c:\strawberry

{
  app_version     => '5.18.2.2', #BEWARE: do not use '.0.0' in the last two version digits
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
            'gendef'        => '<package_url>/kmx/64_tools/64bit_gendef-rev4724-bin_20120411.zip',
            #gcc & co.
            'gcc-toolchain' => { url=>'<package_url>/kmx/64_gcctoolchain/mingw64-w64-gcc4.7.3_20130526.zip', install_to=>'c' },
            'gcc-license'   => '<package_url>/kmx/64_gcctoolchain/mingw64-w64-gcc4.7.3_20130526-lic.zip',
            'gfortran'      => '<package_url>/kmx/64_gcctoolchain/mingw64-w64-gfortran4.7.3_20130526.zip',
            #libs
            'libdb'         => '<package_url>/kmx/64_libs/gcc47-2014Q1/64bit_db-6.0.30-bin_20140416.zip',
            'libexpat'      => '<package_url>/kmx/64_libs/gcc47-2014Q1/64bit_expat-2.1.0-bin_20140416.zip',
            'libfreeglut'   => '<package_url>/kmx/64_libs/gcc47-2014Q1/64bit_freeglut-2.8.1-bin_20140416.zip',
            'libfreetype'   => '<package_url>/kmx/64_libs/gcc47-2014Q1/64bit_freetype-2.5.3-bin_20140416.zip',
            'libgdbm'       => '<package_url>/kmx/64_libs/gcc47-2014Q1/64bit_gdbm-1.10-bin_20140416.zip',
            'libgiflib'     => '<package_url>/kmx/64_libs/gcc47-2014Q1/64bit_giflib-5.0.5-bin_20140416.zip',
            'libgmp'        => '<package_url>/kmx/64_libs/gcc47-2014Q1/64bit_gmp-5.1.3-bin_20140416.zip',
            'libjpeg'       => '<package_url>/kmx/64_libs/gcc47-2014Q1/64bit_jpeg-9a-bin_20140416.zip',
            'libgd'         => '<package_url>/kmx/64_libs/gcc47-2014Q1/64bit_libgd-2.1.0-bin_20140416.zip',
            'liblibXpm'     => '<package_url>/kmx/64_libs/gcc47-2014Q1/64bit_libXpm-3.5.11-bin_20140416.zip',
            'liblibiconv'   => '<package_url>/kmx/64_libs/gcc47-2014Q1/64bit_libiconv-1.14-bin_20140416.zip',
            'liblibpng'     => '<package_url>/kmx/64_libs/gcc47-2014Q1/64bit_libpng-1.6.10-bin_20140416.zip',
            'liblibssh2'    => '<package_url>/kmx/64_libs/gcc47-2014Q1/64bit_libssh2-1.4.3-bin_20140416.zip',
            'liblibxml2'    => '<package_url>/kmx/64_libs/gcc47-2014Q1/64bit_libxml2-2.9.1-bin_20140416.zip',
            'liblibxslt'    => '<package_url>/kmx/64_libs/gcc47-2014Q1/64bit_libxslt-1.1.28-bin_20140416.zip',
            'libmpc'        => '<package_url>/kmx/64_libs/gcc47-2014Q1/64bit_mpc-1.0.2-bin_20140416.zip',
            'libmpfr'       => '<package_url>/kmx/64_libs/gcc47-2014Q1/64bit_mpfr-3.1.2-bin_20140416.zip',
            'libopenssl'    => '<package_url>/kmx/64_libs/gcc47-2014Q1/64bit_openssl-1.0.1g-bin_20140416.zip',
            'libpostgresql' => '<package_url>/kmx/64_libs/gcc47-2014Q1/64bit_postgresql-9.3.4-bin_20140416.zip',
            'libt1lib'      => '<package_url>/kmx/64_libs/gcc47-2014Q1/64bit_t1lib-5.1.2-bin_20140416.zip',
            'libtiff'       => '<package_url>/kmx/64_libs/gcc47-2014Q1/64bit_tiff-4.0.3-bin_20140416.zip',
            'libxz'         => '<package_url>/kmx/64_libs/gcc47-2014Q1/64bit_xz-5.0.5-bin_20140416.zip',
            'libzlib'       => '<package_url>/kmx/64_libs/gcc47-2014Q1/64bit_zlib-1.2.8-bin_20140416.zip',
            #special cases
            'pthreads'      => '<package_url>/kmx/64_libs/gcc47-2013Q3/64bit_pthreads-2.10.0-bin_20130526.zip',  # built together with gcc toolchain
            'libmysql'      => '<package_url>/kmx/64_libs/gcc44-2011/64bit_mysql-5.1.44-bin_20100304.zip',       # the latest DLL binary is missing some exports
        },
    },
    ### NEXT STEP ###########################
    {
        plugin     => 'Perl::Dist::Strawberry::Step::InstallPerlCore',
        url        => 'http://search.cpan.org/CPAN/authors/id/R/RJ/RJBS/perl-5.18.2.tar.bz2',
        cf_email   => 'strawberry-perl@project', #IMPORTANT: keep 'strawberry-perl' before @
        perl_debug => 0,
        #perl_64bitint not needed on 64bit
        #buildoptextra => '-D__USE_MINGW_ANSI_STDIO',
        patch => { #DST paths are relative to the perl src root
            '<dist_sharedir>/perl-5.18/win32_config.gc.tt'      => 'win32/config.gc',
            ### decoration
            '<dist_sharedir>/msi/files/perlexe.ico'             => 'win32/perlexe.ico',
            '<dist_sharedir>/perl-5.18/perlexe.rc.tt'           => 'win32/perlexe.rc',
            ### GDBM & co.
            '<dist_sharedir>/perl-5.18/win32_config_H.gc'       => 'win32/config_H.gc', # enables gdbm/ndbm/odbm
            '<dist_sharedir>/perl-5.18/win32_FindExt.pm'        => 'win32/FindExt.pm',
            '<dist_sharedir>/perl-5.18/NDBM_MSWin32.pl'         => 'ext/NDBM_File/hints/MSWin32.pl',
            '<dist_sharedir>/perl-5.18/ODBM_MSWin32.pl'         => 'ext/ODBM_File/hints/MSWin32.pl',
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
          { do=>'ignore_testfailure', distribution=>'IPC-Cmd-0.92' },
        ]
    },
    ### NEXT STEP ###########################
    {
        plugin => 'Perl::Dist::Strawberry::Step::InstallModules',
        modules => [
            # IPC related
            { module=>'IPC-Run', skiptest=>1 }, #XXX-FIXME trouble with 'Terminating on signal SIGBREAK(21)'
            qw/ IPC-Run3 IPC-System-Simple /,

            # term related
            '<package_url>/kmx/perl-modules-patched/TermReadKey-2.31_patched.tar.gz', # special version needed XXX-report a bug https://metacpan.org/pod/Term::ReadKey
            { module=>'Term::ReadLine::Perl', env=>{ PERL_MM_NONINTERACTIVE=>1 } },

            # compression
            { module=>'Archive-Zip', ignore_testfailure=>1 },   #XXX-TODO: Archive-Zip-1.33 test FAILS
            qw/ IO-Compress-Lzma Compress-unLZMA /,

            #XXX-HACK
            { module=>'Test::Script', ignore_testfailure=>1 },

            # file related
            { module=>'File-Slurp', ignore_testfailure=>1 },    #XXX-TODO: on 32bit OK
            qw/ File-Find-Rule          File-HomeDir            File-Listing            File-Remove
                File-ShareDir           File-Which              File-Copy-Recursive /,

            # database stuff
            qw/ DBI DBD-ODBC DBD-SQLite DBIx-Simple /,
            { module=>'DBD-ADO', ignore_testfailure=>1 },       #XXX-TODO: DBD-ADO-2.99 test FAILS
            { module=>'DBD-Pg' },
            { module=>'DBD-mysql', ignore_testfailure=>1, makefilepl_param=>'--mysql_config=mysql_config' }, #XXX-TODO: check test failures

            # math related
            qw/ Math-Round Math-BigInt-GMP Math-GMP Math-MPC Math-MPFR /,
            #qw/ Math-Pari /, #fails on 64bit

            # has to go before Module::Signature as it throws an error: Not trusting this module, aborting install
            qw/ HTTP-Server-Simple /,

            # win32 related
            { module=>'Win32API-Registry', ignore_testfailure=>1 }, #XXX-TODO: Win32API-Registry-0.32 test FAILS
            { module=>'Win32-TieRegistry', ignore_testfailure=>1 }, #XXX-TODO: Win32-TieRegistry-0.26 test FAILS
            { module=>'Win32-OLE',         ignore_testfailure=>1 }, #XXX-TODO: test used to fail
            qw/ Win32-API Win32-EventLog Win32-Exe Win32-Process Win32-WinError Win32-File-Object Win32-UTCFileTime /,

            # crypto
            '<package_url>/kmx/perl-modules-patched/Crypt-OpenSSL-Random-0.04_patched.tar.gz',  #XXX-CHECK https://metacpan.org/pod/Crypt::OpenSSL::Random
            '<package_url>/kmx/perl-modules-patched/Crypt-OpenSSL-Bignum-0.04_patched.tar.gz',  #XXX-CHECK https://metacpan.org/pod/Crypt::OpenSSL::Bignum
            '<package_url>/kmx/perl-modules-patched/Crypt-OpenSSL-AES-0.02_patched.tar.gz',     #XXX-CHECK https://metacpan.org/pod/Crypt::OpenSSL::AES
            '<package_url>/kmx/perl-modules-patched/Crypt-OpenSSL-DSA-0.14_patched.tar.gz',     #XXX-CHECK https://metacpan.org/pod/Crypt::OpenSSL::DSA
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

            # dbm related
            qw/ BerkeleyDB DB_File DBM-Deep /,

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
       reloc1_in  => '<dist_sharedir>/relocation/perl1.reloc.txt.initial',
       reloc1_out => '<image_dir>/perl1.reloc.txt',
       reloc2_in  => '<dist_sharedir>/relocation/perl2.reloc.txt.initial',
       reloc2_out => '<image_dir>/perl2.reloc.txt',
    },
    ### NEXT STEP ###########################
    {
       plugin => 'Perl::Dist::Strawberry::Step::OutputZIP', # no options needed
    },
    ### NEXT STEP ###########################
    {
       plugin => 'Perl::Dist::Strawberry::Step::OutputMSM_MSI',
       exclude  => [ # do not include neither to MSM nor to MSI
           #'dirname\subdir1\subdir2',
           #'dirname\file.pm',
           'relocation.pl.bat',
           'update_env.pl.bat',
       ],
       exclude_msm => [ # do not include these to MSM but to MSI
           #qr/^win32\\.*?\.url$/,
           'win32',
           'perl2.reloc.txt',
           'README.txt'
       ],
       msi_upgrade_code    => 'DBA41113-4E91-3FFC-B400-573BB4B80705', #BEWARE: fixed value for all 64bit releases (for ever)
       app_publisher       => 'strawberryperl.com project',
       url_about           => 'http://strawberryperl.com/',
       url_help            => 'http://strawberryperl.com/support.html',
       msi_default_instdir => 'c:\strawberry',
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
              { type=>'shortcut', name=>'CPAN Client', icon=>'<dist_sharedir>\msi\files\cpan.ico', target=>'[d_perl_bin.<MSMID>]cpan.bat', workingdir=>'d_perl_bin.<MSMID>' },
              { type=>'shortcut', name=>'Create local library areas', icon=>'<dist_sharedir>\msi\files\strawberry.ico', target=>'[d_perl_bin.<MSMID>]llw32helper.bat', workingdir=>'d_perl_bin.<MSMID>' },
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
         { do=>'copyfile',   args=>[ '<dist_sharedir>/portable/portable.perl.473.64',   '<image_dir>/portable.perl' ] }, # take portable.perl.32 or portable.perl.64
         { do=>'copyfile',   args=>[ '<dist_sharedir>/portable/portableshell.bat',      '<image_dir>/portableshell.bat' ] },
         { do=>'apply_tt',   args=>[ '<dist_sharedir>/portable/README.portable.txt.tt', '<image_dir>/README.portable.txt' ] },
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
       plugin => 'Perl::Dist::Strawberry::Step::OutputLogZIP', # no options needed
    },
  ],
}
