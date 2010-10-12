use Module::Build;

die "OS unsupported\n" unless 'MSWin32' eq $^O;

my $class = Module::Build->subclass(
	class => 'My::Builder',
	code  => <<'END_CODE',
sub ACTION_authortest {
    my ($self) = @_;

    $self->depends_on('build');
    $self->depends_on('manifest');
    $self->depends_on('distmeta');

    $self->test_files( qw< t xt/author > );
    $self->depends_on('test');

    return;
}


sub ACTION_releasetest {
    my ($self) = @_;

    $self->depends_on('build');
    $self->depends_on('manifest');
    $self->depends_on('distmeta');

    $self->test_files( qw< t xt/author xt/release > );
    $self->depends_on('test');

    return;
}


sub ACTION_manifest {
    my ($self, @arguments) = @_;

    if (-e 'MANIFEST') {
        unlink 'MANIFEST' or die "Can't unlink MANIFEST: $!";
    }

    return $self->SUPER::ACTION_manifest(@arguments);
}
END_CODE
);


my $builder = $class->new(
	module_name         => 'Perl::Dist::Strawberry',
	license             => 'perl',
	dist_author         => 'Curtis Jewell <CSJewell@cpan.org>',
	dist_version_from   => 'lib/Perl/Dist/Strawberry.pm',
	create_license      => 1,
	create_readme       => 1,
	configure_requires => {
		'Module::Build'             => '0.36',
	},
	requires => {
		'perl'                       => '5.010',
		'Perl::Dist::WiX'            => '1.250_100',
		'File::ShareDir::PathClass'  => '1.101620',
	},
	build_requires => {
		'Test::More'                => '0.86',
		'Test::Perl::Dist'          => '0.300',
		'File::Spec'                => '3.2701',
		'File::Path'                => '2.04',
		'File::Remove'              => '1.42',
		'URI::file'                 => '4.20',
		'LWP::Online'               => '1.07',
	},
	meta_merge => {
		resources => {
			homepage    => 'http://csjewell.comyr.com/perl/',
			bugtracker  => 'http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-Dist-Strawberry',
			repository  => 'http://svn.ali.as/cpan/trunk/Perl-Dist-Strawberry/',
			IRC         => 'irc://irc.perl.org/#win32',
		},
	},
	share_dir => {
		dist => 'share',
	},
	script_files => [
		'script/perldist_strawberry'
	],
);

$builder->create_build_script();
