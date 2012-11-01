### job description for building strawberry perl

#Available '<..>' macros:
# <package_url>   is placeholder for http://strawberryperl.com/package
# <dist_sharedir> is placeholder for Perl::Dist::Strawberry's distribution sharedir
# <image_dir>     is placeholder for c:\strawberry

{
  app_version     => '5.14.3.1', #BEWARE: do not use '.0.0' in the last two version digits
  bits            => 32,
  beta            => 0,
  app_fullname    => 'Strawberry Perl',
  app_simplename  => 'strawberry-perl-reloc',
  build_job_steps => [
    ### STEP 1 ###########################
    {
        plugin  => 'Perl::Dist::Strawberry::Step::BinaryToolsAndLibs',
        install_packages => {
            #tools
            'dmake'         => '<package_url>/kmx/32_tools/32bit_dmake-SVN20091127-bin_20111107.zip',
            'mingw-make'    => '<package_url>/kmx/32_tools/32bit_gmake-3.82-bin_20110503.zip',
            'pexports'      => '<package_url>/kmx/32_tools/32bit_pexports-0.44-bin_20100110.zip',
            'patch'         => '<package_url>/kmx/32_tools/32bit_patch-2.5.9-7-bin_20100110_UAC.zip',
            'gendef'        => '<package_url>/kmx/32_tools/32bit_gendef-rev4724-bin_20120411.zip',
            #gcc & co.
            'gcc-toolchain' => { url=>'<package_url>/kmx/32_gcctoolchain/mingw64-w32-gcc4.6.3_20121012.zip', install_to=>'c' },
            'gcc-license'   => '<package_url>/kmx/32_gcctoolchain/mingw64-w32-gcc4.6.3_20121012-lic.zip',
            'gfortran'      => '<package_url>/kmx/32_gcctoolchain/mingw64-w32-gfortran4.6.3_20121012.zip',
            #libs
            'libdb'         => '<package_url>/kmx/32_libs/gcc46-2012Q4/32bit_db-5.3.21-bin_20121016.zip',
            'libexpat'      => '<package_url>/kmx/32_libs/gcc46-2012Q4/32bit_expat-2.1.0-bin_20121016.zip',
            'libfreeglut'   => '<package_url>/kmx/32_libs/gcc46-2012Q4/32bit_freeglut-2.8.0-bin_20121016.zip',
            'libfreetype'   => '<package_url>/kmx/32_libs/gcc46-2012Q4/32bit_freetype-2.4.10-bin_20121016.zip',
            'libgdbm'       => '<package_url>/kmx/32_libs/gcc46-2012Q4/32bit_gdbm-1.8.3-bin_20121016.zip',
            'libgd'         => '<package_url>/kmx/32_libs/gcc46-2012Q4/32bit_gd-2.0.35-bin_20121016.zip',       #spec build statically linked with giflib-4.2.0
            'libgiflib'     => '<package_url>/kmx/32_libs/gcc46-2012Q4/32bit_giflib-5.0.1-bin_20121016.zip',
            'libgmp'        => '<package_url>/kmx/32_libs/gcc46-2012Q4/32bit_gmp-5.0.5-bin_20121016.zip',
            'libjpeg'       => '<package_url>/kmx/32_libs/gcc46-2012Q4/32bit_jpeg-8d-bin_20121016.zip',
            'liblibXpm'     => '<package_url>/kmx/32_libs/gcc46-2012Q4/32bit_libXpm-3.5.10-bin_20121016.zip',
            'liblibiconv'   => '<package_url>/kmx/32_libs/gcc46-2012Q4/32bit_libiconv-1.14-bin_20121016.zip',
            'liblibpng'     => '<package_url>/kmx/32_libs/gcc46-2012Q4/32bit_libpng-1.5.13-bin_20121016.zip',
            'liblibssh2'    => '<package_url>/kmx/32_libs/gcc46-2012Q4/32bit_libssh2-1.4.2-bin_20121016.zip',
            'liblibxml2'    => '<package_url>/kmx/32_libs/gcc46-2012Q4/32bit_libxml2-2.9.0-bin_20121016.zip',
            'liblibxslt'    => '<package_url>/kmx/32_libs/gcc46-2012Q4/32bit_libxslt-1.1.27-bin_20121016.zip',
            'libmpc'        => '<package_url>/kmx/32_libs/gcc46-2012Q4/32bit_mpc-1.0.1-bin_20121016.zip',
            'libmpfr'       => '<package_url>/kmx/32_libs/gcc46-2012Q4/32bit_mpfr-3.1.1-bin_20121016.zip',
            'libopenssl'    => '<package_url>/kmx/32_libs/gcc46-2012Q4/32bit_openssl-1.0.1c-bin_20121016.zip',
            'libpostgresql' => '<package_url>/kmx/32_libs/gcc46-2012Q4/32bit_postgresql-9.2.1-bin_20121016.zip',
            'libt1lib'      => '<package_url>/kmx/32_libs/gcc46-2012Q4/32bit_t1lib-5.1.2-bin_20121016.zip',
            'libtiff'       => '<package_url>/kmx/32_libs/gcc46-2012Q4/32bit_tiff-4.0.3-bin_20121016.zip',
            'libxz'         => '<package_url>/kmx/32_libs/gcc46-2012Q4/32bit_xz-5.0.4-bin_20121016.zip',
            'libzlib'       => '<package_url>/kmx/32_libs/gcc46-2012Q4/32bit_zlib-1.2.7-bin_20121016.zip',
            #special cases
            'libmysql'      => '<package_url>/kmx/32_libs/gcc44-2011/32bit_mysql-5.1.44-bin_20100304.zip',      # the latest DLL binary is missing some exports
            'pthreads'      => '<package_url>/kmx/32_libs/gcc46-2012Q4/32bit_pthreads-2.9.0-bin_20121012.zip',  # built together with gcc toolchain
        },
    },
    ### STEP 2 ###########################
    {
        plugin     => 'Perl::Dist::Strawberry::Step::InstallPerlCore',
        url        => 'http://www.cpan.org/authors/id/D/DO/DOM/perl-5.14.3.tar.gz',
        cf_email   => 'strawberry-perl@project',
        perl_debug => 0,
        patch      => { #DST paths are relative to the perl src root
            '<dist_sharedir>/perl-5.14-relocatable/win32_config.gc.tt'      => 'win32/config.gc',
            '<dist_sharedir>/perl-5.14-relocatable/win32_config.gc64nox.tt' => 'win32/config.gc64nox',
            '<dist_sharedir>/perl-5.14-relocatable/win32_config_H.gc'       => 'win32/config_H.gc',
            '<dist_sharedir>/perl-5.14-relocatable/win32_config_H.gc64nox'  => 'win32/config_H.gc64nox',
            '<dist_sharedir>/perl-5.14/win32_FindExt.pm'        => 'win32/FindExt.pm',
            '<dist_sharedir>/perl-5.14/NDBM_MSWin32.pl'         => 'ext/NDBM_File/hints/MSWin32.pl',
            '<dist_sharedir>/perl-5.14/ODBM_MSWin32.pl'         => 'ext/ODBM_File/hints/MSWin32.pl',
        },
        license => { #SRC paths are relative to the perl src root
            'Readme'   => '<image_dir>/licenses/perl/Readme',
            'Artistic' => '<image_dir>/licenses/perl/Artistic',
            'Copying'  => '<image_dir>/licenses/perl/Copying',
        },
    },
    ### STEP 6 ###########################
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
         # URLs
         { do=>'apply_tt', args=>[ '<dist_sharedir>/extra-files/win32/CPAN Module Search.url.tt',                  '<image_dir>/win32/CPAN Module Search.url' ] },
         { do=>'apply_tt', args=>[ '<dist_sharedir>/extra-files/win32/Learning Perl (tutorials, examples).url.tt', '<image_dir>/win32/Learning Perl (tutorials, examples).url' ] },
         { do=>'apply_tt', args=>[ '<dist_sharedir>/extra-files/win32/Live Support (chat).url.tt',                 '<image_dir>/win32/Live Support (chat).url' ] },
         { do=>'apply_tt', args=>[ '<dist_sharedir>/extra-files/win32/Perl 5.14 Documentation.url.tt',             '<image_dir>/win32/Perl 5.14 Documentation.url' ] },
         { do=>'apply_tt', args=>[ '<dist_sharedir>/extra-files/win32/Strawberry Perl Release Notes.url.tt',       '<image_dir>/win32/Strawberry Perl Release Notes.url' ] },
         { do=>'apply_tt', args=>[ '<dist_sharedir>/extra-files/win32/Strawberry Perl Website.url.tt',             '<image_dir>/win32/Strawberry Perl Website.url' ] },
         { do=>'apply_tt', args=>[ '<dist_sharedir>/extra-files/win32/Win32 Perl Wiki.url.tt',                     '<image_dir>/win32/Win32 Perl Wiki.url' ] },
         # cleanup (remove unwanted files/dirs)
         { do=>'removefile', args=>[ '<image_dir>/c/bin/gccbug' ] },
         { do=>'removefile_recursive', args=>[ '<image_dir>/perl', '*.dll.AAA' ] },
       ],
    },
    ### STEP 7 ###########################
    {
       plugin => 'Perl::Dist::Strawberry::Step::CreateRelocationFile',
       reloc1_in  => '<dist_sharedir>/relocation/perl1.reloc.txt.initial',
       reloc1_out => '<image_dir>/perl1.reloc.txt',
       reloc2_in  => '<dist_sharedir>/relocation/perl2.reloc.txt.initial',
       reloc2_out => '<image_dir>/perl2.reloc.txt',
    },
    ### STEP 8 ###########################
    {
       plugin => 'Perl::Dist::Strawberry::Step::OutputZIP', # no options needed
    },
    ### STEP 10 ###########################
    {
        plugin => 'Perl::Dist::Strawberry::Step::InstallModules',
        # modules specific to portable edition
        modules => [ 'Portable' ],
    },
    ### STEP 11 ###########################
    {
       plugin => 'Perl::Dist::Strawberry::Step::SetupPortablePerl', # no options needed
    },
    ### STEP 12 ###########################
    {
       plugin => 'Perl::Dist::Strawberry::Step::FilesAndDirs',
       commands => [ # files and dirs specific to portable edition
         { do=>'removefile', args=>[ '<image_dir>/README.txt', '<image_dir>/perl2.reloc.txt', '<image_dir>/perl1.reloc.txt', '<image_dir>/update_env.pl.bat', '<image_dir>/relocation.pl.bat' ] },
         { do=>'createdir',  args=>[ '<image_dir>/data' ] },
         { do=>'removedir',  args=>[ '<image_dir>/perl/site/bin' ] },
         { do=>'copyfile',   args=>[ '<dist_sharedir>/portable/portable.perl.32',    '<image_dir>/portable.perl' ] }, # take portable.perl.32 or portable.perl.64
         { do=>'copyfile',   args=>[ '<dist_sharedir>/portable/portableshell.bat',   '<image_dir>/portableshell.bat' ] },
         { do=>'apply_tt',   args=>[ '<dist_sharedir>/portable/README.portable.txt.tt', '<image_dir>/README.portable.txt' ] },
       ],
    },
    ### STEP 13 ###########################
    {
       plugin => 'Perl::Dist::Strawberry::Step::OutputPortableZIP', # no options needed
    },
    ### STEP 15 ###########################
    {
       plugin => 'Perl::Dist::Strawberry::Step::OutputLogZIP', # no options needed
    },
  ],
}
