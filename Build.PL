use strict;
use warnings;
use Module::Build;

warn "For MS Windows only\n" and exit 0 if $^O ne 'MSWin32';

my $class = Module::Build->subclass(
    class => 'My::Builder',
    code  => <<'CODE',
sub ACTION_xtest {
    my $self = shift;
    $self->depends_on(qw[build manifest distmeta]);
    $self->test_files(qw[t xt]);
    $self->depends_on('test');
    return;
}
CODE
);

my $builder = $class->new(
    module_name         => 'Perl::Dist::Strawberry',
    license             => 'perl',
    dist_author         => 'KMX <kmx@cpan.org>',
    dist_version_from   => 'lib/Perl/Dist/Strawberry.pm',
    create_license      =>  1,
    create_readme       =>  1,
    share_dir           => { dist => 'share' },
    script_files        => [ 'script/perldist_strawberry' ],
    configure_requires  => {
        'Module::Build'         => '0.38',
    },
    requires            => {
        'perl'                  => '5.012',
        'Module::Build'         => '0.38',
    },
    build_requires      => {
        'Test::More'            => '0.86',
        'Archive::Tar'          => 0,
        'Archive::Zip'          => 0,
        'Data::Dump'            => 0,
        'Data::UUID'            => 0,
        'Digest::SHA1'          => 0,
        'ExtUtils::MakeMaker'   => 0,
        'File::Basename'        => 0,
        'File::Copy'            => 0,
        'File::Copy::Recursive' => 0,
        'File::Find::Rule'      => 0,
        'File::Glob'            => 0,
        'File::Path'            => '2.04',
        'File::ShareDir'        => 0,
        'File::Slurp'           => 0,
        'File::Spec'            => '3.2701',
        'File::pushd'           => 0,
        'Getopt::Long'          => 0,
        'IO::Capture'           => 0,
        'IPC::Run3'             => 0,
        'LWP::UserAgent'        => 0,
        'Pod::Usage'            => 0,
        'Portable::Dist'        => '1.05',
        'Storable'              => 0,
        'Template'              => 0,
        'Text::Diff'            => 0,
        'Text::Patch'           => 0,
        'URI::file'             => 0,
        'Win32::TieRegistry'    => 0,
        'Win32::File::Object'   => 0,
    },
    meta_merge => {
        resources => {
            repository  => 'http://svn.ali.as/cpan/trunk/Perl-Dist-Strawberry/',
            homepage    => 'http://strawberryperl.com/',
            bugtracker  => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Perl-Dist-Strawberry',
            MailingList => "http://groups.google.com/group/perl.win32.vanilla",
            Chat        => "irc://irc.perl.org/#win32",
        },
        no_index => {
            directory => [ 'share', 'HelperCA.dll_src' ],
        }
    },
);

$builder->create_build_script();
