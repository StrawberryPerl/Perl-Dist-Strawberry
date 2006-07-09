
# This is CPAN.pm's systemwide configuration file. This file provides
# defaults for users, and the values can be changed in a per-user
# configuration file. The user-config file is being looked for as
# ~/.cpan/CPAN/MyConfig.pm.

$CPAN::Config = {
  'cpan_home' => File::Spec->catdir( File::Spec->tmpdir, 'cpan' ),
  'make' => q[], # should autodetect from path
  'urllist' => [ q[http://mirrors.kernel.org/CPAN/] ],
  'prerequisites_policy' => q[follow],
  'make_install_arg' => q[UNINST=1],
  'mbuild_install_arg' => q[--uninst 1],
  # wish CPAN.pm would leave these disabled, but it doesn't yet
  'ftp' => q[ ],
  'gpg' => q[ ],
  'gzip' => q[ ],
  'lynx' => q[ ],
  'ncftp' => q[ ],
  'ncftpget' => q[ ],
  'tar' => q[ ],
  'unzip' => q[ ],
  'wget' => q[ ],
};
1;
__END__
