### job description for building strawberry perl

#Available '<..>' macros:
# <package_url>   is placeholder for http://strawberryperl.com/package
# <dist_sharedir> is placeholder for Perl::Dist::Strawberry's distribution sharedir
# <image_dir>     is placeholder for c:\strawberry

{
  app_version     => '5.16.3.1', #BEWARE: do not use '.0.0' in the last two version digits
  bits            => 32,
  beta            => 0,
  app_fullname    => 'Strawberry Perl',
  app_simplename  => 'spp-spec-minimal',
  build_job_steps => [
    ### NEXT STEP ###########################
    {
        plugin  => 'Perl::Dist::Strawberry::Step::BinaryToolsAndLibs',
        install_packages => {
            #tools
            'dmake'         => '<package_url>/kmx/32_tools/32bit_dmake-SVN20091127-bin_20111107.zip',
            #gcc & co.
            'gcc-toolchain' => { url=>'<package_url>/kmx/32_gcctoolchain/mingw64-w32-gcc4.6.3_20121012.zip', install_to=>'c' },
            'gcc-license'   => '<package_url>/kmx/32_gcctoolchain/mingw64-w32-gcc4.6.3_20121012-lic.zip',
            'gfortran'      => '<package_url>/kmx/32_gcctoolchain/mingw64-w32-gfortran4.6.3_20121012.zip',
            #libs
            'libgdbm'       => '<package_url>/kmx/32_libs/gcc46-2012Q4/32bit_gdbm-1.8.3-bin_20121016.zip',
        },
    },
    ### NEXT STEP ###########################
    {
        plugin     => 'Perl::Dist::Strawberry::Step::InstallPerlCore',
        url        => 'http://www.cpan.org/authors/id/R/RJ/RJBS/perl-5.16.3-RC1.tar.gz',
        cf_email   => 'strawberry-perl@project',
        perl_debug => 0,
        patch      => { #DST paths are relative to the perl src root
            '<dist_sharedir>/perl-5.16/win32_config.gc.tt'      => 'win32/config.gc',
            '<dist_sharedir>/perl-5.16/win32_config_H.gc'       => 'win32/config_H.gc',
            '<dist_sharedir>/perl-5.16/win32_config.gc64nox.tt' => 'win32/config.gc64nox',
            '<dist_sharedir>/perl-5.16/win32_config_H.gc64nox'  => 'win32/config_H.gc64nox',
            '<dist_sharedir>/perl-5.16/win32_FindExt.pm'        => 'win32/FindExt.pm',
            '<dist_sharedir>/perl-5.16/NDBM_MSWin32.pl'         => 'ext/NDBM_File/hints/MSWin32.pl',
            '<dist_sharedir>/perl-5.16/ODBM_MSWin32.pl'         => 'ext/ODBM_File/hints/MSWin32.pl',
            '<dist_sharedir>/msi/files/perlexe.ico'             => 'win32/perlexe.ico',
        },
        license => { #SRC paths are relative to the perl src root
            'Readme'   => '<image_dir>/licenses/perl/Readme',
            'Artistic' => '<image_dir>/licenses/perl/Artistic',
            'Copying'  => '<image_dir>/licenses/perl/Copying',
        },
    },
    ### NEXT STEP ###########################
    {
        plugin => 'Perl::Dist::Strawberry::Step::InstallModules',
        modules => [
          #here is a place to (re)install/(up/down)grade modules needed before 'Perl::Dist::Strawberry::Step::UpgradeCpanModules'
          'http://search.cpan.org/CPAN/authors/id/M/MU/MUIR/modules/Text-Tabs%2BWrap-2012.0818.tar.gz', # minicpan related issue XXX-CHECK version
        ],
    },
    ### NEXT STEP ###########################
    {
        plugin => 'Perl::Dist::Strawberry::Step::UpgradeCpanModules',
        exceptions => [
          # match: version=>... distribution=>... cpan_file=>...
          # possible 'do' options: ignore_testfailure | skiptest | skip
          { do=>'ignore_testfailure', distribution => 'CPANPLUS' }, #XXX-TODO: CPANPLUS-0.9128 has test failure
          { do=>'ignore_testfailure', distribution => 'IPC-Cmd' },  #XXX-TODO: IPC-Cmd-0.78 has test failure
        ]
    },
    ### NEXT STEP ###########################
    {
        plugin => 'Perl::Dist::Strawberry::Step::InstallModules',
        # modules specific to portable edition
        modules => [ 'Portable' ],
    },
    ### NEXT STEP ###########################
    {
       plugin => 'Perl::Dist::Strawberry::Step::FilesAndDirs',
       commands => [
         # directories
         { do=>'createdir', args=>[ '<image_dir>/cpan' ] },
         { do=>'createdir', args=>[ '<image_dir>/cpan/sources' ] },
         # templated files
         { do=>'apply_tt', args=>[ '<dist_sharedir>/config-files/CPAN_Config.pm.tt', '<image_dir>/perl/lib/CPAN/Config.pm', {}, 1 ] }, #XXX-temporary empty tt_vars, no_backup=1
         { do=>'apply_tt', args=>[ '<dist_sharedir>/extra-files/DISTRIBUTIONS.txt.tt', '<image_dir>/DISTRIBUTIONS.txt' ] },
         # fixed files
         { do=>'copyfile', args=>[ '<dist_sharedir>/extra-files/licenses/License.rtf', '<image_dir>/licenses/License.rtf' ] },
         # cleanup (remove unwanted files/dirs)
         { do=>'removefile', args=>[ '<image_dir>/c/bin/gccbug' ] },
         { do=>'removefile_recursive', args=>[ '<image_dir>/perl', '*.dll.AAA' ] },
         # files and dirs specific to portable edition
         { do=>'createdir',  args=>[ '<image_dir>/data' ] },
         { do=>'copyfile',   args=>[ '<dist_sharedir>/portable/portable.perl.32-NEW',   '<image_dir>/portable.perl' ] }, # take portable.perl.32 or portable.perl.64
         { do=>'copyfile',   args=>[ '<dist_sharedir>/portable/portableshell.bat',      '<image_dir>/portableshell.bat' ] },
         { do=>'apply_tt',   args=>[ '<dist_sharedir>/portable/README.portable.txt.tt', '<image_dir>/README.portable.txt' ] },
         # special hack moves all extlib DLLs to perl/bin
         { do=>'movedir',    args=>[ '<image_dir>/c/bin/startup', '<image_dir>/perl/bin/startup' ] },
         { do=>'movefile',   args=>[ '<image_dir>/c/bin/dmake.exe', '<image_dir>/perl/bin/dmake.exe' ] },
         { do=>'smartmove',  args=>[ '<image_dir>/c/bin/*_.dll', '<image_dir>/perl/bin' ] },         
       ],
    },
    ### NEXT STEP ###########################
    {
       plugin => 'Perl::Dist::Strawberry::Step::SetupPortablePerl', # no options needed
    },
    ### NEXT STEP ###########################
    {
       plugin => 'Perl::Dist::Strawberry::Step::OutputPortableZIP', # no options needed
    },
    ### NEXT STEP ###########################
    {
       plugin => 'Perl::Dist::Strawberry::Step::OutputLogZIP', # no options needed
    },
  ],
}
