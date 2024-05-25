# vim: syntax=perl

### job description for building strawberry perl

#Available '<..>' macros:
# <package_url>   is placeholder for http://strawberryperl.com/package
# <dist_sharedir> is placeholder for Perl::Dist::Strawberry's distribution sharedir
# <image_dir>     is placeholder for c:\strawberry

{
  app_version     => '5.39.11.1', #BEWARE: do not use '.0.0' in the last two version digits
  bits            => 64,
  beta            => 0,
  app_fullname    => 'Strawberry Perl (64-bit)',
  app_simplename  => 'strawberry-perl',
  maketool        => 'gmake', # 'dmake' or 'gmake'
  build_job_steps => [
    ### NEXT STEP ###########################
    {
        plugin  => 'Perl::Dist::Strawberry::Step::BinaryToolsAndLibs',
        install_packages => {
            #tools
            #gcc, gmake, gdb & co.
            'gcc-toolchain' => { url => 'file://z|/winlibs.zip', install_to => 'c' },
            #patch => 'https://github.com/StrawberryPerl/build-extlibs/releases/download/dev_gcc10.3_20230313/64bit_patch-2.7.5-bin_20230420.zip',
            'patch'         => '<package_url>/kmx/64_tools/64bit_patch-2.5.9-7-bin_20100110_UAC.zip',
            #special cases
            #'libmysql'      => '<package_url>/kmx/64_libs/gcc71-2017Q2/64bit_mysql-5.7.16-bin_20170517.zip',
            #  gcc13 libs 
            'bzip2'         => 'https://github.com/StrawberryPerl/build-extlibs/releases/download/gcc13.2_ucrt_posix/64bit_bzip2-1.0.6-bin_20240515.zip',
            'db'            => 'https://github.com/StrawberryPerl/build-extlibs/releases/download/gcc13.2_ucrt_posix/64bit_db-6.2.38-bin_20240515.zip',
            'expat'         => 'https://github.com/StrawberryPerl/build-extlibs/releases/download/gcc13.2_ucrt_posix/64bit_expat-2.6.2-bin_20240515.zip',
            'fontconfig'    => 'https://github.com/StrawberryPerl/build-extlibs/releases/download/gcc13.2_ucrt_posix/64bit_fontconfig-2.15.0-bin_20240515.zip',
            'freeglut'      => 'https://github.com/StrawberryPerl/build-extlibs/releases/download/gcc13.2_ucrt_posix/64bit_freeglut-3.4.0-bin_20240515.zip',
            'freetype'      => 'https://github.com/StrawberryPerl/build-extlibs/releases/download/gcc13.2_ucrt_posix/64bit_freetype-2.13.2-bin_20240515.zip',
            'fribidi'       => 'https://github.com/StrawberryPerl/build-extlibs/releases/download/gcc13.2_ucrt_posix/64bit_fribidi-1.0.14-bin_20240515.zip',
            'gdbm'          => 'https://github.com/StrawberryPerl/build-extlibs/releases/download/gcc13.2_ucrt_posix/64bit_gdbm-1.19-bin_20240515.zip',
            'giflib'        => 'https://github.com/StrawberryPerl/build-extlibs/releases/download/gcc13.2_ucrt_posix/64bit_giflib-5.2.2-bin_20240515.zip',
            'gmp'           => 'https://github.com/StrawberryPerl/build-extlibs/releases/download/gcc13.2_ucrt_posix/64bit_gmp-6.3.0-bin_20240515.zip',
            'graphite2'     => 'https://github.com/StrawberryPerl/build-extlibs/releases/download/gcc13.2_ucrt_posix/64bit_graphite2-1.3.14-bin_20240515.zip',
            'harfbuzz'      => 'https://github.com/StrawberryPerl/build-extlibs/releases/download/gcc13.2_ucrt_posix/64bit_harfbuzz-8.4.0-bin_20240515.zip',
            'jpeg'          => 'https://github.com/StrawberryPerl/build-extlibs/releases/download/gcc13.2_ucrt_posix/64bit_jpeg-9c-bin_20240515.zip',
            'libffi'        => 'https://github.com/StrawberryPerl/build-extlibs/releases/download/gcc13.2_ucrt_posix/64bit_libffi-3.4.6-bin_20240515.zip',
            'libgd'         => 'https://github.com/StrawberryPerl/build-extlibs/releases/download/gcc13.2_ucrt_posix/64bit_libgd-2.3.3-bin_20240515.zip',
            'liblibiconv'   => 'https://github.com/StrawberryPerl/build-extlibs/releases/download/gcc13.2_ucrt_posix/64bit_libiconv-1.17-bin_20240515.zip',
            'libidn2'       => 'https://github.com/StrawberryPerl/build-extlibs/releases/download/gcc13.2_ucrt_posix/64bit_libidn2-2.3.7-bin_20240515.zip',
            'libpng'        => 'https://github.com/StrawberryPerl/build-extlibs/releases/download/gcc13.2_ucrt_posix/64bit_libpng-1.6.43-bin_20240515.zip',
            'libssh2'       => 'https://github.com/StrawberryPerl/build-extlibs/releases/download/gcc13.2_ucrt_posix/64bit_libssh2-1.11.0-bin_20240515.zip',
            'libunistring'  => 'https://github.com/StrawberryPerl/build-extlibs/releases/download/gcc13.2_ucrt_posix/64bit_libunistring-1.2-bin_20240515.zip',
            'libxml2'       => 'https://github.com/StrawberryPerl/build-extlibs/releases/download/gcc13.2_ucrt_posix/64bit_libxml2-2.12.6-bin_20240515.zip',
            'libXpm'        => 'https://github.com/StrawberryPerl/build-extlibs/releases/download/gcc13.2_ucrt_posix/64bit_libXpm-3.5.12-bin_20240515.zip',
            'libxslt'       => 'https://github.com/StrawberryPerl/build-extlibs/releases/download/gcc13.2_ucrt_posix/64bit_libxslt-1.1.39-bin_20240515.zip',
            'libwebp'       => 'https://github.com/StrawberryPerl/build-extlibs/releases/download/gcc13.2_ucrt_posix/64bit_libwebp-1.4.0-bin_20240515.zip',
            'mpc'           => 'https://github.com/StrawberryPerl/build-extlibs/releases/download/gcc13.2_ucrt_posix/64bit_mpc-1.3.1-bin_20240515.zip',
            'mpfr'          => 'https://github.com/StrawberryPerl/build-extlibs/releases/download/gcc13.2_ucrt_posix/64bit_mpfr-4.2.1-bin_20240515.zip',
            'openssl'       => 'https://github.com/StrawberryPerl/build-extlibs/releases/download/gcc13.2_ucrt_posix/64bit_openssl-3.3.0-bin_20240515.zip',
            'postgresql'    => 'https://github.com/StrawberryPerl/build-extlibs/releases/download/gcc13.2_ucrt_posix/64bit_postgresql-16.2-bin_20240515.zip',
            'readline'      => 'https://github.com/StrawberryPerl/build-extlibs/releases/download/gcc13.2_ucrt_posix/64bit_readline-8.2-bin_20240515.zip',
            'termcap'       => 'https://github.com/StrawberryPerl/build-extlibs/releases/download/gcc13.2_ucrt_posix/64bit_termcap-1.3.1-bin_20240515.zip',
            'tiff'          => 'https://github.com/StrawberryPerl/build-extlibs/releases/download/gcc13.2_ucrt_posix/64bit_tiff-4.6.0-bin_20240515.zip',
            'xz'            => 'file://c:/shawn/sp_repos/build_extlibs_20240518/extlibs_ucrt_posix/64bit_xz-5.4.6-bin_20240518.zip',  #  temporary
            'zlib'          => 'https://github.com/StrawberryPerl/build-extlibs/releases/download/gcc13.2_ucrt_posix/64bit_zlib-1.3.1-bin_20240515.zip',            
        },
    },
    ### NEXT STEP ###########################
    {
       plugin => 'Perl::Dist::Strawberry::Step::FilesAndDirs',
       commands => [
         { do=>'removefile', args=>[ '<image_dir>/c/i686-w64-mingw32/lib/libglut.a', '<image_dir>/c/i686-w64-mingw32/lib/libglut32.a' ] }, #XXX-32bit only workaround
         { do=>'movefile',   args=>[ '<image_dir>/c/lib/libdb-6.1.a', '<image_dir>/c/lib/libdb.a' ] }, #XXX ugly hack
         { do=>'removefile', args=>[ '<image_dir>/c/bin/gccbug', '<image_dir>/c/bin/ld.gold.exe', '<image_dir>/c/bin/ld.bfd.exe' ] },
         { do=>'removefile_recursive', args=>[ '<image_dir>/c', qr/.+\.la$/i ] }, # https://rt.cpan.org/Public/Bug/Display.html?id=127184
         { do=>'make_rw', args=>[ '<image_dir>/c/include/db.h' ] },     #  band-aid for ro flag on db headers
         { do=>'make_rw', args=>[ '<image_dir>/c/include/db_cxx.h' ] }, 
       ],
    },
    ### NEXT STEP ###########################
    {
        plugin     => 'Perl::Dist::Strawberry::Step::InstallPerlCore',
        url        => 'https://cpan.metacpan.org/authors/id/H/HA/HAARG/perl-5.40.0-RC1.tar.gz',  
        cf_email   => 'strawberry-perl@project', #IMPORTANT: keep 'strawberry-perl' before @
        perl_debug => 0,    # can be overridden by --perl_debug=N option
        perl_64bitint => 1, # ignored on 64bit, can be overridden by --perl_64bitint | --noperl_64bitint option
        #  buildoptextra => '-D__USE_MINGW_ANSI_STDIO',  #  not needed since 5.33.6
        patch => { #DST paths are relative to the perl src root
            '<dist_sharedir>/msi/files/perlexe.ico'             => 'win32/perlexe.ico',
            '<dist_sharedir>/perl-5.36/perlexe.rc.tt'           => 'win32/perlexe.rc',
            #'<dist_sharedir>/perl-5.38/vmem.patch'       => '*',
            #'<dist_sharedir>/perl-5.38/GNUmakefile'      => 'win32/GNUmakefile',
            'config_H.gc'                                 => {
                I_DBM  => 'define',
                I_GDBM => 'define',
                I_NDBM => 'define',
                HAS_BUILTIN_CHOOSE_EXPR => 'define',
                HAS_SYMLINK             => 'define',
            },
            'config.gc'                                 => {  # see Step.pm for list of default updates 
                d_builtin_choose_expr => 'define',
                d_mkstemp             => 'define',
                d_ndbm                => 'define',
                d_symlink             => 'define', # many cpan modules fail tests when defined
                i_db                  => 'define',
                i_dbm                 => 'define',
                i_gdbm                => 'define',
                i_ndbm                => 'define',
                osvers                => '10',
            },
        },
        license => { #SRC paths are relative to the perl src root
            'Readme'   => '<image_dir>/licenses/perl/Readme',
            'Artistic' => '<image_dir>/licenses/perl/Artistic',
            'Copying'  => '<image_dir>/licenses/perl/Copying',
        },
    },
    ### NEXT STEP ###########################
    # {
    #     plugin => 'Perl::Dist::Strawberry::Step::InstallModules',
    #     #  it seems this is needed by a dep in the upgrade script
    #     modules => [qw /IPC::Run3 Syntax::Keyword::Try/]
    # },
    ### NEXT STEP ###########################
    {
        plugin => 'Perl::Dist::Strawberry::Step::UpgradeCpanModules',
        exceptions => [
          # possible 'do' options: ignore_testfailure | skiptest | skip - e.g. 
          #{ do=>'ignore_testfailure', distribution=>'ExtUtils-MakeMaker-6.72' },
          #{ do=>'ignore_testfailure', distribution=>qr/^IPC-Cmd-/ },
          { do=>'ignore_testfailure', distribution=>qr/^Net-Ping-/ }, # 2.72 fails
          { do=>'ignore_testfailure', distribution=>qr/^Archive-Tar-/ }, # 3.02 fails
        ]
    },
    ### NEXT STEP ###########################
    {
        plugin => 'Perl::Dist::Strawberry::Step::InstallModules',
        modules => [
            { module=>'Capture::Tiny', ignore_testfailure=>1 }, #XXX-TODO https://github.com/dagolden/Capture-Tiny/issues/29
            { module=>'Path::Tiny', ignore_testfailure=>1 }, #XXX-TODO 5.30 t/zzz-spec.t fails https://github.com/dagolden/Path-Tiny/issues/228
            'TAP::Harness::Restricted', #to be able to skip only some tests
            # IPC related
            { module=>'IPC-Run', skiptest=>1 }, #XXX-TODO trouble with 'Terminating on signal SIGBREAK(21)' https://metacpan.org/release/IPC-Run
            { module=>'IPC-System-Simple', ignore_testfailure=>1 }, #XXX-TODO t/07_taint.t fails https://metacpan.org/release/IPC-System-Simple
            qw/ IPC-Run3 /,

            # LWP + TLS
            { module=>'Net::SSLeay', ignore_testfailure=>1 }, # openssl-1.1.1 related
            { module=>'Mozilla::CA' }, # optional dependency of IO-Socket-SSL
            { module=>'IO::Socket::SSL', skiptest=>1, env=>{ 'HARNESS_SUBCLASS'=>'TAP::Harness::Restricted', 'HARNESS_SKIP'=>'t/nonblock.t t/mitm.t t/verify_fingerprint.t t/session_ticket.t t/sni_verify.t' } },
            { module=>'LWP', skiptest=>1 }, # XXX-HACK: 6.08 is broken
            { module=>'LWP::Protocol::https', env=>{ 'HARNESS_SUBCLASS'=>'TAP::Harness::Restricted', 'HARNESS_SKIP'=>'t/https_proxy.t' } }, #https://rt.perl.org/Ticket/Display.html?id=132863

            # install cpanm as soon as possible
            qw/ App::cpanminus /,

            # https://github.com/StrawberryPerl/Perl-Dist-Strawberry/issues/80
            'https://cpan.metacpan.org/authors/id/X/XA/XAOC/ExtUtils-Depends-0.8000.tar.gz',  
        ]
    },
    ### NEXT STEP ###########################
    {
        plugin => 'Perl::Dist::Strawberry::Step::InstallModules',
        modules => [

            # gdbm / db related
            qw/ BerkeleyDB DB_File /,
            { #  PR by demerphq to build on 5.38
              module => 'https://github.com/StrawberryPerl/Perl-Dist-Strawberry/releases/download/dev_20230318/DBM-Deep-2.0017.tar.gz',
              env => {MAKEFLAGS => '', TEST_JOBS => '' },
            },

            #removed from core in 5.20
            qw/ Module::Build /,
            { module=>'B::Lint',  ignore_testfailure=>1 }, #XXX-TODO https://rt.cpan.org/Public/Bug/Display.html?id=101115 #XXX-FAIL-5.32.1
            { module=>'Archive::Extract',  ignore_testfailure=>1 }, #XXX-TODO-5.28/64bit
            { module=>'CPANPLUS', env=>{ 'HARNESS_SUBCLASS'=>'TAP::Harness::Restricted', 'HARNESS_SKIP'=>'t/40_CPANPLUS-Internals-Report.t' } },
            #XXX-TODO https://rt.cpan.org/Public/Bug/Display.html?id=116479
            qw/ CPANPLUS::Dist::Build /,
            qw/ File::CheckTree Log::Message Module::Pluggable Object::Accessor Text::Soundex Term::UI Tree::DAG_Node /,

            #  https://github.com/StrawberryPerl/Perl-Dist-Strawberry/issues/92
            { module => 'https://github.com/StrawberryPerl/Perl-Dist-Strawberry/releases/download/dev_20230318/Pod-Parser-1.65_01.tar.gz' },
            # qw /Pod::Latex/, #  disabled - https://github.com/StrawberryPerl/Perl-Dist-Strawberry/issues/75

            # YAML, JSON & co.
            qw/ JSON Cpanel::JSON::XS JSON::XS JSON::MaybeXS YAML YAML::Tiny YAML::XS /,

            # pkg-config related
            { module=>'PkgConfig', makefilepl_param=>'--script=pkg-config' },
            'ExtUtils::PkgConfig',

        ]
    },
    ### NEXT STEP ###########################
    {
        plugin => 'Perl::Dist::Strawberry::Step::InstallModules',
        modules => [
            # win32 related
            { module=>'Win32API::Registry',         ignore_testfailure=>1 }, # https://github.com/StrawberryPerl/Perl-Dist-Strawberry/issues/66
            qw/Win32::TieRegistry/,
            { module=>'Win32::OLE',         skiptest=>1 }, #XXX-TODO: ! Testing Win32-OLE-0.1713 leaves excel dialogues and files hanging around 
            { module=>'Win32::GuiTest',     skiptest=>1 },
            { module=>'Win32::API',         ignore_testfailure=>1 }, #XXX-TODO: https://rt.cpan.org/Public/Bug/Display.html?id=107450
            { module => 'Win32::Exe', env => { MAKEFLAGS => '', TEST_JOBS => ''} },
            { module=>'<package_url>/kmx/perl-modules-patched/Win32-Pipe-0.025_patched.tar.gz' }, #XXX-FIXME
            # File-Remove has symlink test failures under 5.38, is needed by Win32-File-Object
            { module=>'File-Remove', env=>{ 'HARNESS_SUBCLASS'=>'TAP::Harness::Restricted', 'HARNESS_SKIP'=>'t/05_links.t' } },
            qw/ Win32-Daemon Win32-EventLog Win32-Process Win32-File-Object Win32-WinError Win32-UTCFileTime /,
            qw/ Win32-ShellQuote Win32::Console Win32::Job Win32::ServiceManager Win32::Service /,
			# qw/ Win32::Console::ANSI /,  # disable for now - fails tests under UCRT 5.39.10
            { module => 'Win32-Clipboard', ignore_testfailure=>1 },  #  inconsistent failures of tests 7 & 9
            { module=>'<package_url>/kmx/perl-modules-patched/Win32-SerialPort-0.22_patched.tar.gz', skiptest=>1 },
            qw/ Sys::Syslog /,

            # term related
            { module=>'Term::ReadKey', ignore_testfailure=>1 },
            { module=>'Term::ReadLine::Perl', env=>{ PERL_MM_NONINTERACTIVE=>1 } },

            # compression
            { module=>'Archive::Zip', ignore_testfailure=>1 }, #XXX-TODO t/25_traversal.t
            qw/ IO-Compress-Lzma Compress-unLZMA Archive::Extract /,

        ]
    },
    ### NEXT STEP ###########################
    {
        plugin => 'Perl::Dist::Strawberry::Step::InstallModules',
        modules => [
            # file related
            { module=>'File-ShareDir-Install', ignore_testfailure=>1 }, #XXX-TODO-5.28
            { module=>'File::Copy::Recursive', ignore_testfailure=>1 }, #XXX-FAIL-5.32.1
            { module => 'https://github.com/StrawberryPerl/Perl-Dist-Strawberry/releases/download/dev_20230318/File-Find-Rule-0.34_01.tar.gz' }, #  https://github.com/StrawberryPerl/Perl-Dist-Strawberry/issues/88
            qw/ File-HomeDir File-Listing File-ShareDir File-Which File::Map /,
            { module=>'File::Slurp', ignore_testfailure=>1 },
            qw/ File::Slurper /,
            { module=>'IO::All', env=>{ 'HARNESS_SUBCLASS'=>'TAP::Harness::Restricted', 'HARNESS_SKIP'=>'t/link.t' } },  # https://github.com/StrawberryPerl/Perl-Dist-Strawberry/issues/67
            { module=>'Path::Class', env=>{ 'HARNESS_SUBCLASS'=>'TAP::Harness::Restricted', 'HARNESS_SKIP'=>'t/01-basic.t' } }, # https://github.com/StrawberryPerl/Perl-Dist-Strawberry/issues/65 
            qw/ Path::Tiny /,
            # math related
            'Devel::CheckLib',  #this used to fail
            qw/ Math-Round Math-BigInt-GMP Math-GMP Math-MPFR Math-MPC /,
            qw/ ExtUtils::F77 /,

        ]
    },
    ### NEXT STEP ###########################
    {
        plugin => 'Perl::Dist::Strawberry::Step::InstallModules',
        modules => [
            # SSH & telnet
            qw/ Net-SSH2 Net::Telnet /,

            # network
            # https://github.com/StrawberryPerl/Perl-Dist-Strawberry/issues/72
            { module => 'https://github.com/StrawberryPerl/Perl-Dist-Strawberry/releases/download/dev_20230318/Socket6-0.29_02.tar.gz' },
            qw/ IO::Socket::IP IO::Socket::INET6 IO::Socket::Socks /,
            # EV4.32 + perl-5.30 fails XXX-FIXME
            qw/ HTTP-Server-Simple /,
            { module=>'<package_url>/kmx/perl-modules-patched/Crypt-SSLeay-0.72_patched.tar.gz' }, #XXX-FIXME
            { module=>'Mojolicious', env=>{ 'HARNESS_SUBCLASS'=>'TAP::Harness::Restricted', 'HARNESS_SKIP'=>'t/mojolicious/websocket_lite_app.t t/mojo/file.t' } }, #https://github.com/kraih/mojo/issues/1011, https://github.com/StrawberryPerl/Perl-Dist-Strawberry/issues/67
            { module=>'WWW::Mechanize', skiptest=>1 }, # tests hang

        ]
    },
    ### NEXT STEP ###########################
    {
        plugin => 'Perl::Dist::Strawberry::Step::InstallModules',
        modules => [
            # XML & co.

            { module=>'Alien::Libxml2', env=>{ 'PKG_CONFIG_PATH'=>'C:\strawberry\c\lib\pkgconfig' } }, # alien probe needs to find the pkgconfig file 
            qw/ XML-LibXML XML-LibXSLT XML-Parser XML-SAX /,
            { module => 'XML::Simple', env => {MAKEFLAGS => '', TEST_JOBS => ''} },
            { module=>'XML::Twig', ignore_testfailure=>1 }, #XXX-TODO XML-Twig-3.52 fails

            # data/text processing
            { module=>'IO::Stringy', env=>{ 'HARNESS_SUBCLASS'=>'TAP::Harness::Restricted', 'HARNESS_SKIP'=>'t/IO_InnerFile.t' } }, #https://rt.cpan.org/Public/Bug/Display.html?id=103895
            qw/ Text-Diff Text-Patch Text::CSV Text::CSV_XS Tie::Array::CSV Excel::Writer::XLSX Spreadsheet::WriteExcel Spreadsheet::ParseExcel /,
            #  qw /Spreadsheet::ParseXLSX/,  #  failures under 5.39

        ]
    },
    ### NEXT STEP ###########################
    {
        plugin => 'Perl::Dist::Strawberry::Step::InstallModules',
        modules => [

            # database stuff
            { module=>'Module::Find', env=>{ 'HARNESS_SUBCLASS'=>'TAP::Harness::Restricted', 'HARNESS_SKIP'=>'t/07-symlinks.t' } }, # https://github.com/StrawberryPerl/Perl-Dist-Strawberry/issues/67 

            { module=>'Config::Any', env=>{ 'HARNESS_SUBCLASS'=>'TAP::Harness::Restricted', 'HARNESS_SKIP'=>'t/10-branches.t' } }, # https://github.com/StrawberryPerl/Perl-Dist-Strawberry/issues/73 needed for DBIx::Class 
            { module=>'DBD::SQLite', env=>{ 'HARNESS_SUBCLASS'=>'TAP::Harness::Restricted', 'HARNESS_SKIP'=>'t/33_non_latin_path.t' } }, # https://github.com/StrawberryPerl/Perl-Dist-Strawberry/issues/68 
            qw/ DBI DBD-ODBC DBD-CSV DBD-ADO DBIx-Class DBIx-Simple /,
            'https://cpan.metacpan.org/authors/id/T/TU/TURNSTEP/DBD-Pg-3.8.0.tar.gz', ###{ module=>'DBD::Pg' },
            #{ module=>'DBD::mysql' },  #  disable until we sort out more recent mysql (but see https://github.com/StrawberryPerl/Perl-Dist-Strawberry/discussions/157 )
            #  SKIP DBD::Oracle for 5.36 until we can sort out what files to use
            # { module=>'DBD::Oracle', makefilepl_param=>'-V 12.2.0.1.0', env=>{ ORACLE_HOME=>'c:\ora122instant64' }, skiptest=>1 }, ## requires Oracle Instant Client 64bit!!!

        ]
    },
    ### NEXT STEP ###########################
    {
        plugin => 'Perl::Dist::Strawberry::Step::InstallModules',
        modules => [
            # crypto related - DISABLE in 5.39.10 as CryptX is failing
            # { module =>'Convert-PEM', ignore_testfailure=>1 }, #XXX-TODO Convert-PEM-0.08 fails
            # qw/ Convert-PEM /,

            # # crypto
            # qw / Crypt::OpenSSL::DSA /, # https://github.com/StrawberryPerl/Perl-Dist-Strawberry/issues/86
            # #  qw /CryptX/,  #  fails under 5.39
            # qw/ Crypt::OpenSSL::Bignum Crypt-OpenSSL-RSA Crypt-OpenSSL-Random Crypt-OpenSSL-X509 /,
            # qw / Crypt::OpenSSL::AES /,
            # #'KMX/Crypt-OpenSSL-AES-0.05.tar.gz', #XXX-FIXME patched https://metacpan.org/pod/Crypt::OpenSSL::AES  https://rt.cpan.org/Public/Bug/Display.html?id=77605
            # #Crypt-SMIME ?
            # qw/ Crypt::CBC Crypt::Blowfish Crypt::CAST5_PP Crypt::DES Crypt::DES_EDE3 Crypt::DSA Crypt::IDEA Crypt::Rijndael Crypt::Twofish Crypt::Serpent Crypt::RC6 /,
            # qw/ Digest-MD2 Digest-MD5 Digest-SHA Digest-SHA1 Crypt::RIPEMD160 Digest::Whirlpool Digest::HMAC Digest::CMAC /,
            # 'Alt::Crypt::RSA::BigInt',  #hack Crypt-RSA without Math::PARI - https://metacpan.org/release/Crypt-RSA
            # qw/ Crypt-DSA Crypt::DSA::GMP /,

            # qw/ Bytes::Random::Secure Crypt::OpenPGP /,
            # #qw/ Module::Signature /, #XXX-TODO still not able to properly handle CRLF - https://metacpan.org/release/Module-Signature

            # date/time
            { module=>'Test2::Plugin::NoWarnings', ignore_testfailure=>1 }, #otherwise DateTime fails
            qw/ DateTime Date::Format DateTime::Format::DateParse DateTime::TimeZone::Local::Win32 Time::Moment /,

            # e-mail
            qw/ List::MoreUtils::XS List::MoreUtils /, # required by Net::IMAP::Client - https://rt.cpan.org/Public/Bug/Display.html?id=122875
            #  Net::DNS and Net::Domain::TLD are needed for Email::Valid but its metadata is not correctly specified
            { module=>'Net::DNS', skiptest=>1 }, # tests might hang due to network issues
            qw /Net::Domain::TLD/, 
            qw/ Email::MIME::Kit Email::Sender Email::Simple Email::Stuffer Mail::Send /,
            qw /Email::Valid/,  #  Fails under 5.39.10 unless Net::DNS and Net::Domain::TLD are already installed
            qw/ Net::SMTPS Net::SMTP Net::IMAP::Client Net::POP3 /,
            

        ]
    },
    ### NEXT STEP ###########################
    {
        plugin => 'Perl::Dist::Strawberry::Step::InstallModules',
        modules => [
            # graphics
            # 'GD',  #  disable for 5.39.10
          ##{ module=>'http://chorny.net/strawberry/Imager-1.006.zip', ignore_testfailure=>1 }, #https://rt.cpan.org/Ticket/Display.html?id=124001
            { module=>'Imager', ignore_testfailure=>1 }, #https://rt.cpan.org/Ticket/Display.html?id=124001
            qw/ Imager-File-GIF Imager-File-JPEG Imager-File-PNG Imager-File-TIFF Imager-Font-FT2 Imager-Font-W32 /,
            # Disable for now - tests fail when run under gmake but pass under prove. 
            # There have also been no updates since 2016 and local installs work quickly.
            # { module=>'OpenGL', ignore_testfailure=>1 },

            # XML/SOAP webservices
            'Log::Report',
            qw/ HTTP::Daemon SOAP-Lite /,
            #qw/ XML::Compile::SOAP12 XML::Compile::SOAP11 XML::Compile::WSDL11 /,

            # utils
            qw/ App::cpanoutdated App::pmuninstall pler App-module-version App-local-lib-Win32Helper /,

        ]
    },
    ### NEXT STEP ###########################
    {
        plugin => 'Perl::Dist::Strawberry::Step::InstallModules',
        modules => [
            # par & ppm
            qw/ PAR PAR::Dist::FromPPD PAR::Dist::InstallPPD PAR::Repository::Client /,
            # { module => 'PAR::Packer', env => { MAKEFLAGS => '', TEST_JOBS => '' } },
            { module => 'PAR::Packer', ignore_testfailure=>1, env => { MAKEFLAGS => '', TEST_JOBS => '' } },
            
            # The build path in ppm.xml is derived from $ENV{TMP}. So set TMP to a dedicated location inside of the
            # distribution root to prevent it being locked to the temp directory of the build machine.
            { module=>'<package_url>/kmx/perl-modules-patched/PPM-11.11_04.tar.gz', env=>{ TMP=>'<image_dir>\ppm' } }, #XXX-FIXME

            # exceptions
            qw/ Try-Tiny Carp::Always autodie /,

            # templates
            { module=>'Template', env=>{ 'HARNESS_SUBCLASS'=>'TAP::Harness::Restricted', 'HARNESS_SKIP'=>'t/process_dir.t' } }, #XXX-NEW 5.26.0 https://github.com/abw/Template2/pull/67
            qw/ Template-Tiny /,

            # OO - moose, moo & co.
            qw/ Moose MooseX-Types MooseX::Types::Structured /,
            #{ module=>'MooseX::Declare', ignore_testfailure=>1 },       #XXX-PREREQ-ONLY https://rt.cpan.org/Public/Bug/Display.html?id=97690
            qw/ MooseX::ClassAttribute MooseX::Role::Parameterized MooseX::NonMoose Moo /,

            # OO - others
            qw/ Class::Accessor Class::Accessor::Lite Class::XSAccessor Class::Tiny Object::Tiny /,

        ]
    },
    ### NEXT STEP ###########################
    {
        plugin => 'Perl::Dist::Strawberry::Step::InstallModules',
        modules => [
            # dumpers
			qw / Data::Dump /,
            # qw/ Data::Printer /,  #XXX  Win32::Console::ANSI is failing tests 
            { module=>'Data-Dump-Streamer', ignore_testfailure=>1 },    #XXX-TODO ! Testing Data-Dump-Streamer-2.37 failed

            # misc
            #{ module=>'Alien::Tidyp', buildpl_param=>'--srctarball=http://strawberryperl.com/package/kmx/testing/tidyp-1.04.tar.gz' }, #gcc 8.3 failure
            qw/ CPAN::SQLite /,
            { module => 'FCGI', env => { 'HARNESS_SUBCLASS'=>'TAP::Harness::Restricted', 'HARNESS_SKIP'=>'t/02-unix_domain_socket.t' } },
            qw/ IO::String /,
            { module=>'Unicode::UTF8', ignore_testfailure=>1 }, #XXX-TODO-5.28
            qw/ V Modern::Perl Perl::Tidy /,
            qw/ FFI::Raw FFI::Platypus /,
            qw/ PadWalker Devel::vscode /,

            qw/ Devel::NYTProf /,


            #  Task::Kensho deps that have issues
            # https://github.com/StrawberryPerl/Perl-Dist-Strawberry/issues/103
            { module=>'Test::MockObject', env=>{ 'HARNESS_SUBCLASS'=>'TAP::Harness::Restricted', 'HARNESS_SKIP'=>'t/extends.t' } },
            { module => 'https://github.com/StrawberryPerl/Perl-Dist-Strawberry/releases/download/dev_20230318/String-Escape-2010.002.tar.gz' },

            # GUI - not yet
            #qw/IUP/,
        ],

    },
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
         { do=>'removefile', args=>[ '<image_dir>/perl/vendor/lib/Crypt/._test.pl', '<image_dir>/perl/vendor/lib/DBD/testme.tmp.pl' ] },
         { do=>'removefile', args=>[ '<image_dir>/perl/bin/nssm_32.exe.bat', '<image_dir>/perl/bin/nssm_64.exe.bat' ] },
         { do=>'removefile_recursive', args=>[ '<image_dir>/perl', qr/.+\.dll\.AA[A-Z]$/i ] },
         { do=>'removedir', args=>[ '<image_dir>/perl/bin/freeglut.dll' ] }, #XXX OpenGL garbage
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
       disable => $ENV{SKIP_MSI_STEP}, ### hack
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
         { do=>'apply_tt',   args=>[ '<dist_sharedir>/portable/portable.perl.tt',       '<image_dir>/portable.perl', {gcchost=>'x86_64-w64-mingw32', gccver=>'13.1.0'} ] },
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
        disable => $ENV{SKIP_PDL_STEP}, ### hack
        plugin  => 'Perl::Dist::Strawberry::Step::BinaryToolsAndLibs',
        install_packages => {
            'fftw3'         => 'https://github.com/StrawberryPerl/build-extlibs/releases/download/gcc13.2_ucrt_posix/64bit_fftw-3.3.10-bin_20240515.zip',
            'gnuplot'       => 'https://github.com/StrawberryPerl/build-extlibs/releases/download/gcc13.2_ucrt_posix/64bit_gnuplot-6.0.0-bin_20240515.zip',
            'gsl'           => 'https://github.com/StrawberryPerl/build-extlibs/releases/download/gcc13.2_ucrt_posix/64bit_gsl-2.7.1-bin_20240515.zip',
            'hdf4'          => 'https://github.com/StrawberryPerl/build-extlibs/releases/download/gcc13.2_ucrt_posix/64bit_hdf-4.3.0-bin_20240515.zip',
            'hdf5'          => 'https://github.com/StrawberryPerl/build-extlibs/releases/download/gcc13.2_ucrt_posix/64bit_hdf5-1.12.2-bin_20240515.zip',
            'plplot'        => 'https://github.com/StrawberryPerl/build-extlibs/releases/download/gcc13.2_ucrt_posix/64bit_plplot-5.15.0-bin_20240515.zip',
            'szip'          => 'https://github.com/StrawberryPerl/build-extlibs/releases/download/gcc13.2_ucrt_posix/64bit_szip-2.1.1-bin_20240515.zip',
            'talib'         => 'https://github.com/StrawberryPerl/build-extlibs/releases/download/gcc13.2_ucrt_posix/64bit_ta-lib-0.4.0-bin_20240515.zip',
            'netcdf'        => 'https://github.com/StrawberryPerl/build-extlibs/releases/download/gcc13.2_ucrt_posix/64bit_netcdf-c-4.9.2-bin_20240515.zip',
            'lapack'        => 'https://github.com/StrawberryPerl/build-extlibs/releases/download/gcc13.2_ucrt_posix/64bit_lapack-3.12.0-bin_20240515.zip',
        },
    },
    ### NEXT STEP ###########################
    {
       plugin => 'Perl::Dist::Strawberry::Step::FilesAndDirs',
       commands => [
         { do=>'make_rw', args=>[ '<image_dir>/c/include/db.h' ] },     #  band-aid for ro flag on db headers
         { do=>'make_rw', args=>[ '<image_dir>/c/include/db_cxx.h' ] },
       ],
    },
    ### NEXT STEP ###########################
    {
        disable => $ENV{SKIP_PDL_STEP}, ### hack
        plugin => 'Perl::Dist::Strawberry::Step::InstallModules',
        # modules specific to PDL edition
        modules => [
          { module => 'File::Next', ignore_testfailure => 1 }, #XXX-TODO-5.28 / PREREQ-ONLY
          { module => 'Devel::REPL', ignore_testfailure => 1 },
          qw/Lexical::Persistence Astro::FITS::Header /,
          { module => 'Astro::FITS::CFITSIO', ignore_testfailure => 1},  #  only needed for createfile test
          { module => 'Inline::C', ignore_testfailure => 1 },
          { module => 'Module::Compile', ignore_testfailure => 1 }, #XXX-TODO-5.28 / PREREQ-ONLY
       ],
    },
    ### NEXT STEP ###########################
    {
        disable => $ENV{SKIP_PDL_STEP}, ### hack
        plugin => 'Perl::Dist::Strawberry::Step::InstallModules',
        # modules specific to PDL edition
        modules => [
          { module => 'PDL',
            #makefilepl_param => 'PDLCONF=<dist_sharedir>\pdl\perldl2.conf',
            ignore_testfailure => 1,
            env => {
              PLPLOT_LIB     => '<image_dir>\c\share\plplot',
              PLPLOT_DRV_DIR => '<image_dir>\c\share\plplot',
              MAKEFLAGS      => '',
            },
          },
          qw/ PDL::IO::CSV PDL::IO::DBI PDL::DateTime PDL::Stats /, # PDL::IO::Image
          qw/ PDL::LinearAlgebra /,
          ##{ module=>'PDL::Graphics::Gnuplot', skiptest=>1 },
          ##{ module=>'PDL::Graphics::Prima', ignore_testfailure => 1 }, # does not compile with 5.30.1 XXX-FIXME
        ],
    },
    ### NEXT STEP ###########################
    {
       disable => $ENV{SKIP_PDL_STEP}, ### hack
       plugin => 'Perl::Dist::Strawberry::Step::FilesAndDirs',
       commands => [ # files and dirs specific to portable edition
         { do=>'removefile', args=>[ '<image_dir>/README.txt', '<image_dir>/portableshell.bat' ] },
         { do=>'copyfile',   args=>[ '<dist_sharedir>/portable/portableshell.pdl.bat', '<image_dir>/portableshell.bat' ] },
         { do=>'apply_tt',   args=>[ '<dist_sharedir>/portable/README.pdl.txt.tt',     '<image_dir>/README.txt' ] },
         # cleanup (remove unwanted files/dirs)
         { do=>'removefile_recursive', args=>[ '<image_dir>/perl', qr/.+\.dll\.AA[A-Z]$/i ] },
         # cleanup cpanm related files
         { do=>'removedir', args=>[ '<image_dir>/data/.cpanm' ] },
         { do=>'removedir', args=>[ '<image_dir>/perl/site/lib/MSWin32-x86-multi-thread-64int' ] },
         { do=>'removedir', args=>[ '<image_dir>/perl/site/lib/MSWin32-x86-multi-thread' ] },
         { do=>'removedir', args=>[ '<image_dir>/perl/site/lib/MSWin32-x64-multi-thread' ] },
       ],
    },
    ### NEXT STEP ###########################
    {
       disable => $ENV{SKIP_PDL_STEP}, ### hack
       plugin => 'Perl::Dist::Strawberry::Step::OutputPdlZIP', # no options needed
    },
    ### NEXT STEP ###########################
    {
       plugin => 'Perl::Dist::Strawberry::Step::OutputLogZIP', # no options needed
    },
  ],
}
