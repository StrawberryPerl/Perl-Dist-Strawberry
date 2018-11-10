### job description for building strawberry perl

#Available '<..>' macros:
# <package_url>   is placeholder for http://strawberryperl.com/package
# <dist_sharedir> is placeholder for Perl::Dist::Strawberry's distribution sharedir
# <image_dir>     is placeholder for c:\strawberry

{
  app_version     => '5.22.1.1', #BEWARE: do not use '.0.0' in the last two version digits
  bits            => 32,
  beta            => 0,
  app_fullname    => 'Strawberry Perl',
  app_simplename  => 'strawberry-perl',
  build_job_steps => [
    ### NEXT STEP ###########################
    {
        plugin  => 'Perl::Dist::Strawberry::Step::BinaryToolsAndLibs',
        install_packages => {
            #tools
            'dmake'         => '<package_url>/kmx/32_tools/32bit_dmake-4.12.2-bin_20140810.zip',
            'pexports'      => '<package_url>/kmx/32_tools/32bit_pexports-0.44-bin_20100110.zip',
            'patch'         => '<package_url>/kmx/32_tools/32bit_patch-2.5.9-7-bin_20100110_UAC.zip',
            #gcc, gmake, gdb & co.
            'gcc-toolchain' => { url=>'<package_url>/kmx/32_gcctoolchain/mingw64-w32-gcc4.9.2_20150513.zip', install_to=>'c' },
            'gcc-license'   => '<package_url>/kmx/32_gcctoolchain/mingw64-w32-gcc4.9.2_20150513-lic.zip',
            #libs
            'bzip2'         => '<package_url>/kmx/32_libs/gcc49-2015Q2/32bit_bzip2-1.0.6-bin_20150519.zip',
            'libdb'         => '<package_url>/kmx/32_libs/gcc49-2015Q2/32bit_db-6.1.23-bin_20150519.zip',
            'libexpat'      => '<package_url>/kmx/32_libs/gcc49-2015Q2/32bit_expat-2.1.0-bin_20150519.zip',
            'libfreeglut'   => '<package_url>/kmx/32_libs/gcc49-2015Q2/32bit_freeglut-2.8.1-bin_20150519.zip',
            'libfreetype'   => '<package_url>/kmx/32_libs/gcc49-2015Q2/32bit_freetype-2.5.5-bin_20150519.zip',
            'libgdbm'       => '<package_url>/kmx/32_libs/gcc49-2015Q4/32bit_gdbm-1.10-bin_20151102.zip',
            'libgiflib'     => '<package_url>/kmx/32_libs/gcc49-2015Q2/32bit_giflib-5.1.1-bin_20150519.zip',
            'libgmp'        => '<package_url>/kmx/32_libs/gcc49-2015Q2/32bit_gmp-6.0.0-bin_20150519.zip',
            'libjpeg'       => '<package_url>/kmx/32_libs/gcc49-2015Q2/32bit_jpeg-9a-bin_20150519.zip',
            'libgd'         => '<package_url>/kmx/32_libs/gcc49-2015Q2/32bit_libXpm-3.5.11-bin_20150519.zip',
            'libffi'        => '<package_url>/kmx/32_libs/gcc49-2015Q2/32bit_libffi-3.2.1-bin_20150519.zip',
            'liblibXpm'     => '<package_url>/kmx/32_libs/gcc49-2015Q2/32bit_libgd-2.1.1-bin_20150519.zip',
            'liblibiconv'   => '<package_url>/kmx/32_libs/gcc49-2015Q2/32bit_libiconv-1.14-bin_20150519.zip',
            'liblibpng'     => '<package_url>/kmx/32_libs/gcc49-2015Q2/32bit_libpng-1.6.17-bin_20150519.zip',
            'liblibssh2'    => '<package_url>/kmx/32_libs/gcc49-2015Q2/32bit_libssh2-1.5.0-bin_20150519.zip',
            'liblibxml2'    => '<package_url>/kmx/32_libs/gcc49-2015Q2/32bit_libxml2-2.9.2-bin_20150519.zip',
            'liblibxslt'    => '<package_url>/kmx/32_libs/gcc49-2015Q2/32bit_libxslt-1.1.28-bin_20150519.zip',
            'libmpc'        => '<package_url>/kmx/32_libs/gcc49-2015Q2/32bit_mpc-1.0.3-bin_20150519.zip',
            'libmpfr'       => '<package_url>/kmx/32_libs/gcc49-2015Q2/32bit_mpfr-3.1.2-bin_20150519.zip',
            'libopenssl'    => '<package_url>/kmx/32_libs/gcc49-2015Q4/32bit_openssl-1.0.2e-bin_20151211.zip',
            'libpostgresql' => '<package_url>/kmx/32_libs/gcc49-2015Q2/32bit_postgresql-9.4.1-bin_20150519.zip',
            'libt1lib'      => '<package_url>/kmx/32_libs/gcc49-2015Q2/32bit_t1lib-5.1.2-bin_20150519.zip',
            'libtiff'       => '<package_url>/kmx/32_libs/gcc49-2015Q2/32bit_tiff-4.0.3-bin_20150519.zip',
            'libxz'         => '<package_url>/kmx/32_libs/gcc49-2015Q2/32bit_xz-5.2.1-bin_20150519.zip',
            'libzlib'       => '<package_url>/kmx/32_libs/gcc49-2015Q2/32bit_zlib-1.2.8-bin_20150519.zip',
            #special cases
            'libmysql'      => '<package_url>/kmx/32_libs/gcc44-2011/32bit_mysql-5.1.44-bin_20100304.zip',       # the latest DLL binary is missing some exports
        },
    },
    ### NEXT STEP ###########################
    {
       plugin => 'Perl::Dist::Strawberry::Step::FilesAndDirs',
       commands => [
         { do=>'removefile', args=>[ '<image_dir>/c/i686-w64-mingw32/lib/libglut.a', '<image_dir>/c/i686-w64-mingw32/lib/libglut32.a' ] }, #XXX-32bit only workaround
         { do=>'movefile',   args=>[ '<image_dir>/c/lib/libdb-6.1.a', '<image_dir>/c/lib/libdb.a' ] }, #XXX ugly hack
         { do=>'removefile', args=>[ '<image_dir>/c/bin/gccbug', '<image_dir>/c/bin/ld.gold.exe', '<image_dir>/c/bin/ld.bfd.exe' ] },
       ],
    },
    ### NEXT STEP ###########################
    {
        plugin     => 'Perl::Dist::Strawberry::Step::InstallPerlCore',
        url        => 'http://search.cpan.org/CPAN/authors/id/S/SH/SHAY/perl-5.22.1.tar.gz',
        cf_email   => 'strawberry-perl@project', #IMPORTANT: keep 'strawberry-perl' before @
        perl_debug => 0,    # can be overridden by --perl_debug=N option
        perl_64bitint => 1, # ignored on 64bit, can be overridden by --perl_64bitint | --noperl_64bitint option
        #buildoptextra => '-D__USE_MINGW_ANSI_STDIO',
        patch => { #DST paths are relative to the perl src root
            '<dist_sharedir>/msi/files/perlexe.ico'             => 'win32/perlexe.ico',
            '<dist_sharedir>/perl-5.22/win32_config.gc.tt'      => 'win32/config.gc',
            '<dist_sharedir>/perl-5.22/perlexe.rc.tt'           => 'win32/perlexe.rc',
            '<dist_sharedir>/perl-5.22/win32_config_H.gc'       => 'win32/config_H.gc', # enables gdbm/ndbm/odbm
            '<dist_sharedir>/perl-5.22/win32_FindExt.pm'        => 'win32/FindExt.pm',  # enables gdbm/ndbm/odbm
        },
        license => { #SRC paths are relative to the perl src root
            'Readme'   => '<image_dir>/licenses/perl/Readme',
            'Artistic' => '<image_dir>/licenses/perl/Artistic',
            'Copying'  => '<image_dir>/licenses/perl/Copying',
        },
    },
    ### NEXT STEP ###########################
    {
        plugin => 'Perl::Dist::Strawberry::Step::UpgradeCpanModules',
        exceptions => [
          # possible 'do' options: ignore_testfailure | skiptest | skip
          # e.g. { do=>'ignore_testfailure', distribution=>'ExtUtils-MakeMaker-6.72' },
          { do=>'ignore_testfailure', distribution=>'Pod-Simple-3.31' },
        ]
    },
    ### NEXT STEP ###########################
    {
        plugin => 'Perl::Dist::Strawberry::Step::InstallModules',
        modules => [
            # IPC related
            { module=>'IPC-Run', skiptest=>1 }, #XXX-FIXME trouble with 'Terminating on signal SIGBREAK(21)'
            { module=>'Capture::Tiny', ignore_testfailure=>1 },
            qw/ IPC-Run3 IPC-System-Simple /,

            { module=>'LWP::UserAgent', skiptest=>1 }, # XXX-HACK: 6.08 is broken

            # gdbm / db related
            qw/ BerkeleyDB DB_File DBM-Deep /,

            #removed from core in 5.20
            { module=>'B::Lint', ignore_testfailure=>1 }, #XXX-TODO https://rt.cpan.org/Public/Bug/Display.html?id=101115
            qw/ Archive::Extract CPANPLUS CPANPLUS::Dist::Build File::CheckTree Log::Message Module::Pluggable Object::Accessor Text::Soundex Term::UI Pod::LaTeX Tree::DAG_Node /,

            # pkg-config related
            { module=>'PkgConfig', makefilepl_param=>'--script=pkg-config' },
            'ExtUtils::PkgConfig',

            # win32 related
            'Win32API::Registry',
            { module=>'Win32::TieRegistry', ignore_testfailure=>1 }, #XXX-TODO: ! Testing Win32-TieRegistry-0.26 failed
            { module=>'Win32::OLE',         ignore_testfailure=>1 }, #XXX-TODO: ! Testing Win32-OLE-0.1711 failed
            { module=>'Win32::GuiTest',     skiptest=>1 },
            { module=>'Win32::API',         ignore_testfailure=>1 }, #XXX-TODO: https://rt.cpan.org/Public/Bug/Display.html?id=107450
            'Win32::Exe',
            qw/ Win32-EventLog Win32-Process Win32-WinError Win32-File-Object Win32-UTCFileTime /,
            qw/ Win32-ShellQuote Win32::Console Win32::Console::ANSI Win32::Job Win32::Daemon Win32::ServiceManager Win32::Service /,
            '<package_url>/kmx/perl-modules-patched/Sys-Syslog-0.33_patched.tar.gz', #XXX-XXX https://rt.cpan.org/Public/Bug/Display.html?id=104710

            # term related
            qw/ Term::ReadKey /,
            { module=>'Term::ReadLine::Perl', env=>{ PERL_MM_NONINTERACTIVE=>1 } },

            # compression
            { module=>'Archive::Zip', ignore_testfailure=>1 }, #XXX-TODO: https://rt.cpan.org/Public/Bug/Display.html?id=101442
            qw/ IO-Compress-Lzma Compress-unLZMA Archive::Extract /,

            # file related
            qw/ File-Find-Rule File-HomeDir File-Listing File-Remove File-ShareDir File-Which File-Copy-Recursive File::Map /,
            qw/ File::Slurp File::Slurper /,
            qw/ IO::All Path::Tiny Path::Class /,

            # math related
            { module=>'Math-BigInt-GMP', ignore_testfailure=>1 }, #XXX-TODO: https://rt.cpan.org/Public/Bug/Display.html?id=96113
            qw/ Math-Round Math-GMP /,
            { module=>'Math-MPFR', ignore_testfailure=>1 }, #XXX-TODO: https://rt.cpan.org/Public/Bug/Display.html?id=109297
            qw/ Math-MPC /,
            qw/ Math::Pari /, # fails on 64bit
            qw/ ExtUtils::F77 /,

            # SSL & SSH & telnet
            qw/ Net-SSLeay /,
            { module=>'IO-Socket-SSL', skiptest=>1 }, # XXX-HACK: https://rt.cpan.org/Public/Bug/Display.html?id=95328
            qw/ Net-SSH2 Net::Telnet /,

            # network
            qw/ IO::Socket::IP IO::Socket::INET6 IO::Socket::Socks /,
            qw/ HTTP-Server-Simple /,
            qw/ LWP::UserAgent /,
            { module=>'LWP-Protocol-https', ignore_testfailure=>1 },    #XXX-TODO LWP-Protocol-https-6.04
            qw/ Crypt-SSLeay /, # must be after LWP-Protocol-https
            qw/ Mojolicious /,
            { module=>'WWW::Mechanize', skiptest=>1 }, # tests hang

            # data/text processing
            { module=>'IO::Stringy', ignore_testfailure=>1 },
            qw/ Text-Diff Text-Patch Text::CSV Text::CSV_XS Tie::Array::CSV Excel::Writer::XLSX Spreadsheet::ParseXLSX Spreadsheet::WriteExcel Spreadsheet::ParseExcel /,

            # database stuff
            qw/ DBI DBD-ODBC DBD-SQLite DBD-CSV DBD-ADO DBIx-Class DBIx-Simple /,
            { module=>'DBD::Pg' }, #XXX-TODO fails with -D__USE_MINGW_ANSI_STDIO (e.g. long double build)
            { module=>'DBD::mysql', makefilepl_param=>'--mysql_config=mysql_config' },
            { module=>'DBD::Oracle', makefilepl_param=>'-V 12.1.0.2.0', env=>{ ORACLE_HOME=>'c:\ora12instant32' }, skiptest=>1 }, ## requires Oracle Instant Client 32bit!!!

            # crypto related
            { module =>'Convert-PEM', ignore_testfailure=>1 },                                  #XXX-TODO ! Testing Convert-PEM-0.08 failed
            qw/ Convert-PEM /,

            # crypto
            qw/ Crypt::OpenSSL::Bignum Crypt::OpenSSL::Random Crypt-OpenSSL-RSA Crypt::OpenSSL::DSA Crypt::OpenSSL::X509 /,
            'KMX/Crypt-OpenSSL-AES-0.03.tar.gz',      #XXX-CHECK patched https://metacpan.org/pod/Crypt::OpenSSL::AES  https://rt.cpan.org/Public/Bug/Display.html?id=77605
            #Crypt-SMIME ?
            qw/ Crypt::Blowfish Crypt::CAST5_PP Crypt::DES Crypt::DES_EDE3 Crypt::DSA Crypt::IDEA Crypt::Rijndael Crypt::Twofish Crypt::Serpent Crypt::RC6 /,
            qw/ Crypt::CBC /,
            qw/ Digest-MD2 Digest-MD5 Digest-SHA Digest-SHA1 Crypt::RIPEMD160 Digest::Whirlpool Digest::HMAC Digest::CMAC /,
            'Alt::Crypt::RSA::BigInt',                                                          #XXX-TODO: a hack Crypt-RSA without Math::PARI - https://metacpan.org/release/Crypt-RSA
            qw/ Crypt-DSA Crypt::DSA::GMP /,
            qw/ Crypt::Random /, #fails on 64bit

            # tests fail on 5.18.x
            { module =>'Crypt::OpenPGP' },
            { module =>'<package_url>/kmx/perl-modules-patched/Module-Signature-0.79_patched.tar.gz' },

            # date/time
            qw/ DateTime Date::Format DateTime::Format::DateParse DateTime::TimeZone::Local::Win32 Time::Moment /,

            # e-mail
            qw/ Email::MIME::Kit Email::Sender Email::Simple Email::Valid Email::Stuffer Mail::Send /,
            qw/ Net::SMTPS Net::SMTP Net::IMAP::Client Net::POP3 /,
            { module=>'Net::DNS', skiptest=>1 }, # tests might hang due to network issues

            # graphics
            { module=>'GD', ignore_testfailure=>1 },                    #XXX-TODO ! Testing GD-2.53 failed
            { module=>'Imager', ignore_testfailure=>1 },                #XXX-TODO ! Testing Imager-0.98 failed
            qw/ Imager-File-GIF Imager-File-JPEG Imager-File-PNG Imager-File-TIFF Imager-Font-FT2 Imager-Font-W32 /,
            { module=>'OpenGL', ignore_testfailure=>1 },

            # XML & co.
            qw/ XML-LibXML XML-LibXSLT XML-Parser XML-SAX XML-Simple XML::Twig /,

            # XML/SOAP webservices
            { module=>'Log::Report', ignore_testfailure=>1 },           #XXX_TODO fails on 5.19.11
            qw/ SOAP-Lite /,
            #qw/ XML::Compile::SOAP12 XML::Compile::SOAP11 XML::Compile::WSDL11 /,

            # YAML, JSON & co.
            qw/ JSON JSON::XS Cpanel::JSON::XS JSON::MaybeXS YAML YAML::Tiny YAML::XS /,

            # utils
            qw/ App::cpanminus App::cpanoutdated App::pmuninstall pler App-local-lib-Win32Helper App-module-version /,

            # par & ppm
            qw/ PAR PAR::Dist::FromPPD PAR::Dist::InstallPPD PAR::Repository::Client /,
            # The build path in ppm.xml is derived from $ENV{TMP}. So set TMP to a dedicated location inside of the
            # distribution root to prevent it being locked to the temp directory of the build machine.
            { module=>'<package_url>/kmx/perl-modules-patched/PPM-11.11_03.tar.gz', env=>{ TMP=>'<image_dir>\ppm' } },

            # exceptions
            qw/ Try-Tiny Carp::Always autodie /,

            # templates
            qw/ Template Template-Tiny /,

            # OO - moose, moo & co.
            qw/ Moose MooseX-Types MooseX::Types::Structured /,
            { module=>'MooseX::Declare', ignore_testfailure=>1 },       #XXX-TODO https://rt.cpan.org/Public/Bug/Display.html?id=97690
            qw/ MooseX::ClassAttribute MooseX::Role::Parameterized MooseX::NonMoose Moo /,

            # OO - others
            qw/ Class::Accessor Class::Accessor::Lite Class::XSAccessor Class::Tiny Object::Tiny /,

            # dumpers
            qw/ Data::Dump Data::Printer /,
            { module=>'Data-Dump-Streamer', ignore_testfailure=>1 },    #XXX-TODO ! Testing Data-Dump-Streamer-2.37 failed

            # misc
            { module=>'Alien::Tidyp', buildpl_param=>'--srctarball=http://strawberryperl.com/package/kmx/testing/tidyp-1.04.tar.gz' },
            qw/ CPAN::SQLite FCGI /,
            qw/ IO::String /,
            qw/ V Modern::Perl Unicode::UTF8 Perl::Tidy /,
            qw/ FFI::Raw /,

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
       msi_upgrade_code    => '45F906A2-F86E-335B-992F-990E8BEABC13', #BEWARE: fixed value for all 32bit releases (for ever)
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
         { do=>'apply_tt',   args=>[ '<dist_sharedir>/portable/portable.perl.tt',       '<image_dir>/portable.perl', {gcchost=>'i686-w64-mingw32', gccver=>'4.9.2'} ] },
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
            'fftw3'         => '<package_url>/kmx/32_libs/gcc49-2015Q2/32bit_fftw-3.3.4-bin_20150519.zip',
            'gnuplot'       => '<package_url>/kmx/32_libs/gcc49-2015Q2/32bit_gnuplot-4.6.5-bin_20150519.zip',
            'gsl'           => '<package_url>/kmx/32_libs/gcc49-2015Q2/32bit_gsl-1.16-bin_20150519.zip',
            'hdf4'          => '<package_url>/kmx/32_libs/gcc49-2015Q2/32bit_hdf-4.2.11-bin_20150519.zip',
            'hdf5'          => '<package_url>/kmx/32_libs/gcc49-2015Q2/32bit_hdf5-1.8.14-bin_20150519.zip',
            'plplot'        => '<package_url>/kmx/32_libs/gcc49-2015Q2/32bit_plplot-5.11.0-bin_20150519.zip',
            'proj'          => '<package_url>/kmx/32_libs/gcc49-2015Q2/32bit_proj-4.9.1-bin_20150519.zip',
            'szip'          => '<package_url>/kmx/32_libs/gcc49-2015Q2/32bit_szip-2.1-bin_20150519.zip',
            'talib'         => '<package_url>/kmx/32_libs/gcc49-2015Q2/32bit_ta-lib-0.4.0-bin_20150519.zip',
            'netcdf'        => '<package_url>/kmx/32_libs/gcc49-2015Q2/32bit_netcdf-4.3.2-bin_20150519.zip',
            'lapack'        => '<package_url>/kmx/32_libs/gcc49-2015Q2/32bit_lapack-3.5.0-bin_20150519.zip',
            'cfitsio'       => '<package_url>/kmx/32_libs/gcc49-2015Q2/32bit_cfitsio-3.37-bin_20150519.zip',
        },
    },
    ### NEXT STEP ###########################
    {
        disable => $ENV{SKIP_PDL_STEP}, ### hack
        plugin => 'Perl::Dist::Strawberry::Step::InstallModules',
        # modules specific to PDL edition
        modules => [
          { module => 'Devel::REPL', ignore_testfailure => 1 },
          qw/Lexical::Persistence Astro::FITS::Header Astro::FITS::CFITSIO /,
          { module => 'Inline::C', ignore_testfailure => 1 },
          { module => 'PDL',
            #makefilepl_param => 'PDLCONF=<dist_sharedir>\pdl\perldl2.conf',
            ignore_testfailure => 1,
            env => {
              PLPLOT_LIB     => '<image_dir>\c\share\plplot',
              PLPLOT_DRV_DIR => '<image_dir>\c\share\plplot',
            },
          },
          qw/ PDL::IO::CSV PDL::IO::DBI /, # PDL::IO::Image PDL::DateTime
          qw/ PDL::LinearAlgebra PDL::Stats /,
          { module=>'PDL::Graphics::Prima', ignore_testfailure => 1 },
          { module=>'PDL::Graphics::Gnuplot', skiptest=>1 },
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
       disable => $ENV{SKIP_PDL_STEP}, ### hack
       plugin => 'Perl::Dist::Strawberry::Step::OutputLogZIP', # no options needed
    },
  ],
}
