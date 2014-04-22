### job description for building strawberry perl

#Available '<..>' macros:
# <package_url>   is placeholder for http://strawberryperl.com/package
# <dist_sharedir> is placeholder for Perl::Dist::Strawberry's distribution sharedir
# <image_dir>     is placeholder for c:\strawberry

{
  app_version     => '5.19.11.1', #BEWARE: do not use '.0.0' in the last two version digits
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
        url        => 'http://search.cpan.org/CPAN/authors/id/S/SH/SHAY/perl-5.19.11.tar.gz',
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

            # XXX-HACK: xs.dll & d_libname_unique related patch
            ###XXX https://rt.cpan.org/Ticket/Display.html?id=94515 + https://rt.cpan.org/Public/Bug/Display.html?id=92699
            { module=>'<package_url>/kmx/perl-modules-patched/ExtUtils-Depends-0.306_patched.tar.gz' },

            # gdbm related
            '<package_url>/kmx/perl-modules-patched/GDBM_File-1.15.tar.gz',
            '<package_url>/kmx/perl-modules-patched/NDBM_File-1.12.tar.gz',
            '<package_url>/kmx/perl-modules-patched/ODBM_File-1.12.tar.gz',
            qw/ BerkeleyDB DB_File DBM-Deep /,

            #removed from core in 5.20
            qw/Archive::Extract B::Lint CPANPLUS CPANPLUS::Dist::Build File::CheckTree Log::Message Module::Pluggable Object::Accessor Text::Soundex Term::UI Pod::LaTeX Tree::DAG_Node/,

            # win32 related
            { module=>'Win32API-Registry', ignore_testfailure=>1 }, #XXX-TODO: ! Testing Win32API-Registry-0.32 failed
            { module=>'Win32-TieRegistry', ignore_testfailure=>1 }, #XXX-TODO: ! Testing Win32-TieRegistry-0.26 failed
            { module=>'Win32-OLE',         ignore_testfailure=>1 }, #XXX-TODO: ! Testing Win32-OLE-0.1711 failed
            qw/ Win32-API Win32-EventLog Win32-Exe Win32-Process Win32-WinError Win32-File-Object Win32-UTCFileTime /,
            qw/ Win32-ShellQuote Win32::Console Win32::Console::ANSI Win32::Job Win32::Daemon Win32::ServiceManager Win32::Service /,

            # term related
            '<package_url>/kmx/perl-modules-patched/TermReadKey-2.31_patched.tar.gz', # special version needed XXX-report a bug https://metacpan.org/pod/Term::ReadKey
            { module=>'Term::ReadLine::Perl', env=>{ PERL_MM_NONINTERACTIVE=>1 } },

            # compression
            qw/ Archive-Zip IO-Compress-Lzma Compress-unLZMA Archive::Extract /,

            # file related
            qw/ File-Find-Rule File-HomeDir File-Listing File-Remove File-ShareDir File-Which File-Copy-Recursive File-Slurp /,
            qw/ IO::All Path::Tiny Path::Class /,

            # data/text processing
            qw/ Text-Diff Text-Patch Text::CSV Text::CSV_XS Excel::Writer::XLSX Spreadsheet::ParseXLSX /,

            # database stuff
            qw/ DBI DBD-ODBC DBD-SQLite DBD-ADO DBD-Pg DBIx-Simple /,
            { module=>'DBD-mysql', makefilepl_param=>'--mysql_config=mysql_config' },
            { module=>'DBIx-Class', ignore_testfailure=>1 },    #XXX-TODO ! Testing DBIx-Class-0.08270 failed

            # math related
            qw/ Math-Round Math-BigInt-GMP Math-GMP Math-MPC Math-MPFR /,
            #'http://strawberryperl.com/package/kmx/perl-modules-patched/Math-Pari-2.01080605_patched.tar.gz', #fails on 64bit
            qw/ ExtUtils::F77 /, # fortran

            # network
            qw/ IO::Socket::IP IO::Socket::INET6 /,
            qw/ HTTP-Server-Simple /,
            qw/ LWP::UserAgent /,
            { module=>'LWP-Protocol-https', ignore_testfailure=>1 },    #XXX-TODO LWP-Protocol-https-6.04
            qw/ Mojolicious WWW::Mechanize /,

            # SSL & SSH & telnet
            qw/ Net-SSLeay Crypt-SSLeay IO-Socket-SSL Net-SSH2 Net::Telnet /,

            # crypto related
            { module =>'Convert-PEM', ignore_testfailure=>1 },                                  #XXX-TODO ! Testing Convert-PEM-0.08 failed
            qw/ Convert-PEM /,

            # crypto
            '<package_url>/kmx/perl-modules-patched/Crypt-OpenSSL-Random-0.04_patched.tar.gz',  #XXX-CHECK https://metacpan.org/pod/Crypt::OpenSSL::Random
            '<package_url>/kmx/perl-modules-patched/Crypt-OpenSSL-Bignum-0.04_patched.tar.gz',  #XXX-CHECK https://metacpan.org/pod/Crypt::OpenSSL::Bignum
            '<package_url>/kmx/perl-modules-patched/Crypt-OpenSSL-AES-0.02_patched.tar.gz',     #XXX-CHECK https://metacpan.org/pod/Crypt::OpenSSL::AES
            '<package_url>/kmx/perl-modules-patched/Crypt-OpenSSL-DSA-0.14_patched.tar.gz',     #XXX-CHECK https://metacpan.org/pod/Crypt::OpenSSL::DSA
            '<package_url>/kmx/perl-modules-patched/Crypt-OpenSSL-X509-1.804_patched.tar.gz',   #XXX-CHECK https://metacpan.org/pod/Crypt::OpenSSL::X509 (needs to be reported!!!!!!)
            'Crypt-OpenSSL-RSA',
            qw/ Crypt::Blowfish Crypt::CAST5_PP Crypt::DES Crypt::DES_EDE3 Crypt::DSA Crypt::IDEA Crypt::Rijndael Crypt::Twofish Crypt::Serpent Crypt::RC6 /,
            qw/ Crypt::CBC Crypt::CFB /,
            qw/ Digest-MD5 Digest-SHA Digest-SHA1 Crypt::RIPEMD160 Digest::Whirlpool Digest::HMAC Digest::CMAC /,
            'http://backpan.perl.org/authors/id/G/GA/GAAS/Digest-MD2-2.03.tar.gz',              #XXX-TODO backpan only
            'Alt::Crypt::RSA::BigInt',                                                          #XXX-TODO: a hack Crypt-RSA without Math::PARI
            qw/ Crypt-DSA Crypt::DSA::GMP /,
            #qw/ Crypt::Random /, #fails on 64bit

            # tests fail on 5.18.x
            #{ module =>'Crypt::OpenPGP',    ignore_testfailure=>1 },
            #{ module =>'Module::Signature', ignore_testfailure=>1 },

            # date/time
            qw/ DateTime Date::Format /,

            # e-mail
            qw/ Email::MIME::Kit Email::Sender Email::Simple Email::Valid Email::Stuffer /,
            qw/ Net::SMTPS Net::SMTP Net::IMAP::Client Net::POP3 Net::SSLGlue::POP3 /,

            # graphics
            { module=>'GD', ignore_testfailure=>1 },                    #XXX-TODO ! Testing GD-2.53 failed
            { module=>'Imager', ignore_testfailure=>1 },                #XXX-TODO ! Testing Imager-0.98 failed
            qw/ Imager-File-GIF Imager-File-JPEG Imager-File-PNG Imager-File-TIFF Imager-Font-FT2 Imager-Font-W32 /,

            # XML & co.
            qw/ XML-LibXML XML-LibXSLT XML-Parser XML-SAX XML-Simple XML::Twig /,

            # XML/SOAP webservices
            { module=>'Log::Report', ignore_testfailure=>1 },           #XXX_TODO fails on 5.19.11
            qw/ XML::Compile::SOAP12 XML::Compile::SOAP11 XML::Compile::WSDL11 SOAP-Lite /,

            # YAML, JSON & co.
            qw/ JSON JSON-XS YAML YAML-Tiny YAML::XS /,

            # utils
            qw/ App::cpanminus App::cpanoutdated App::pmuninstall pler App-local-lib-Win32Helper App-module-version /,
            { module=>'pip', ignore_testfailure=>1 },                   #XXX-TODO ! Testing pip-1.19 failed - directory 'C:\strawberry\cpan\sources' does not exist

            # par & ppm
            qw/ PAR PAR::Dist::FromPPD PAR::Dist::InstallPPD PAR::Repository::Client /,
            # The build path in ppm.xml is derived from $ENV{TMP}. So set TMP to a dedicated location inside of the
            # distribution root to prevent it being locked to the temp directory of the build machine.
            { module=>'<package_url>/kmx/perl-modules-patched/PPM-11.11_03.tar.gz', env=>{ TMP=>'<image_dir>\ppm' } },

            # exceptions
            qw/ Capture-Tiny Try-Tiny Carp::Always autodie /,

            # templates
            qw/ Template Template-Tiny /,

            # OO - moose, moo & co.
            qw/ Moose MooseX-Types MooseX::Types::Structured MooseX::Declare MooseX::ClassAttribute MooseX::Role::Parameterized MooseX::NonMoose Moo /,

            # OO - others
            qw/ Class::Accessor Class::Accessor::Lite Class::XSAccessor Class::Tiny Object::Tiny /,

            # dumpers
            qw/ Data::Dump Data::Printer /,
            { module=>'Data-Dump-Streamer', ignore_testfailure=>1 },    #XXX-TODO ! Testing Data-Dump-Streamer-2.37 failed

            # misc
            qw/ CPAN::SQLite Alien-Tidyp FCGI /,
            qw/ IO::Stringy IO::String /,
            qw/ V Modern::Perl Unicode::UTF8 Perl::Tidy /,

            # GUI - not yet
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
