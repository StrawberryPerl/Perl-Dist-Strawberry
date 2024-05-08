use v5.18;
use warnings;

# stolen from IPC::Run3
package MYIPC::Run3 {
    use Carp       qw( croak );
    use File::Spec qw();
    use File::Temp qw( tempfile );
    use POSIX      qw( dup dup2 );
    use constant is_win32 => 0 <= index $^O, "Win32";

    BEGIN {
        if (is_win32) {
            eval "use Win32 qw( GetOSName ); 1" or die $@;
        }
    }

    # We cache the handles of our temp files in order to
    # keep from having to incur the (largish) overhead of File::Temp
    my %fh_cache;
    my $fh_cache_pid = $$;

    sub _binmode {
        my ($fh, $mode, $what) = @_;

        # if $mode is not given, then default to ":raw", except on Windows,
        # where we default to ":crlf";
        # otherwise if a proper layer string was given, use that,
        # else use ":raw"
        my $layer
            = !$mode
            ? (is_win32      ? ":crlf" : ":raw")
            : ($mode =~ /^:/ ? $mode   : ":raw");

        binmode $fh, ":raw" unless $layer eq ":raw";   # remove all layers first
        binmode $fh, $layer or croak "binmode $layer failed: $!";
    }

    sub _spool_data_to_child {
        my ($type, $source, $binmode_it) = @_;

        # If undef (not \undef) passed, they want the child to inherit
        # the parent's STDIN.
        return undef unless defined $source;

        my $fh;
        if (!$type) {
            open $fh, "<", $source or croak "$!: $source";
            _binmode($fh, $binmode_it, "STDIN");
        }
        elsif ($type eq "FH") {
            $fh = $source;
        }
        else {
            $fh = $fh_cache{in} ||= tempfile;
            truncate $fh, 0;
            seek $fh, 0, 0;
            _binmode($fh, $binmode_it, "STDIN");
            my $seekit;
            if ($type eq "SCALAR") {

                # When the run3()'s caller asks to feed an empty file
                # to the child's stdin, we want to pass a live file
                # descriptor to an empty file (like /dev/null) so that
                # they don't get surprised by invalid fd errors and get
                # normal EOF behaviors.
                return $fh unless defined $$source;    # \undef passed

                $seekit = length $$source;
                print $fh $$source or die "$! writing to temp file";

            }
            elsif ($type eq "ARRAY") {
                print $fh @$source or die "$! writing to temp file";
                $seekit = grep length, @$source;
            }
            elsif ($type eq "CODE") {
                my $parms = [];    # TODO: get these from $options
                while (1) {
                    my $data = $source->(@$parms);
                    last unless defined $data;
                    print $fh $data or die "$! writing to temp file";
                    $seekit = length $data;
                }
            }

            seek $fh, 0, 0
                or croak "$! seeking on temp file for child's stdin"
                if $seekit;
        }

        croak "run3() can't redirect $type to child stdin" unless defined $fh;

        return $fh;
    }

    sub _fh_for_child_output {
        my ($what, $type, $dest, $options) = @_;

        my $fh;
        if ($type eq "SCALAR" && $dest == \undef) {
            $fh = $fh_cache{nul} ||= do {
                open $fh, ">", File::Spec->devnull;
                $fh;
            };
        }
        elsif ($type eq "FH") {
            $fh = $dest;
        }
        elsif (!$type) {
            open $fh, $options->{"append_$what"} ? ">>" : ">", $dest
                or croak "$!: $dest";
        }
        else {
            $fh = $fh_cache{$what} ||= tempfile;
            seek $fh, 0, 0;
            truncate $fh, 0;
        }

        my $binmode_it = $options->{"binmode_$what"};
        _binmode($fh, $binmode_it, uc $what);

        return $fh;
    }

    sub _read_child_output_fh {
        my ($what, $type, $dest, $fh, $options) = @_;

        return if $type eq "SCALAR" && $dest == \undef;

        seek $fh, 0, 0 or croak "$! seeking on temp file for child $what";

        if ($type eq "SCALAR") {

            # two read()s are used instead of 1 so that the first will be
            # logged even it reads 0 bytes; the second won't.
            my $count = read $fh, $$dest, 10_000,
                $options->{"append_$what"} ? length $$dest : 0;
            while (1) {
                croak "$! reading child $what from temp file"
                    unless defined $count;

                last unless $count;

                $count = read $fh, $$dest, 10_000, length $$dest;
            }
        }
        elsif ($type eq "ARRAY") {
            if ($options->{"append_$what"}) {
                push @$dest, <$fh>;
            }
            else {
                @$dest = <$fh>;
            }
        }
        elsif ($type eq "CODE") {
            local $_;
            while (<$fh>) {
                $dest->($_);
            }
        }
        else {
            croak "run3() can't redirect child $what to a $type";
        }

    }

    sub _type {
        my ($redir) = @_;

        return "FH" if eval {
            local $SIG{'__DIE__'};
            $redir->isa("IO::Handle");
        };

        my $type = ref $redir;
        return $type eq "GLOB" ? "FH" : $type;
    }

    sub _max_fd {
        my $fd = dup(0);
        POSIX::close $fd;
        return $fd;
    }

    my $run_call_time;
    my $sys_call_time;
    my $sys_exit_time;

    sub run3 {
        my $options = @_ && ref $_[-1] eq "HASH" ? pop : {};

        my ($cmd, $stdin, $stdout, $stderr) = @_;

        if (ref $cmd) {
            croak "run3(): empty command"     unless @$cmd;
            croak "run3(): undefined command" unless defined $cmd->[0];
            croak "run3(): command name ('')" unless length $cmd->[0];
        }
        else {
            croak "run3(): missing command"   unless @_;
            croak "run3(): undefined command" unless defined $cmd;
            croak "run3(): command ('')"      unless length $cmd;
        }

        foreach (qw/binmode_stdin binmode_stdout binmode_stderr/) {
            if (my $mode = $options->{$_}) {
                croak
                    qq[option $_ must be a number or a proper layer string: "$mode"]
                    unless $mode =~ /^(:|\d+$)/;
            }
        }

        my $in_type  = _type $stdin;
        my $out_type = _type $stdout;
        my $err_type = _type $stderr;

        if ($fh_cache_pid != $$) {

            # fork detected, close all cached filehandles and clear the cache
            close $_ foreach values %fh_cache;
            %fh_cache     = ();
            $fh_cache_pid = $$;
        }

        # This routine proceeds in stages so that a failure in an early
        # stage prevents later stages from running, and thus from needing
        # cleanup.

        my $in_fh = _spool_data_to_child $in_type, $stdin,
            $options->{binmode_stdin}
            if defined $stdin;

        my $out_fh = _fh_for_child_output "stdout", $out_type, $stdout, $options
            if defined $stdout;

        my $tie_err_to_out
            = defined $stderr && defined $stdout && $stderr eq $stdout;

        my $err_fh = $tie_err_to_out ? $out_fh : _fh_for_child_output "stderr",
            $err_type, $stderr, $options
            if defined $stderr;

        # this should make perl close these on exceptions
        #    local *STDIN_SAVE;
        local *STDOUT_SAVE;
        local *STDERR_SAVE;

        my $saved_fd0 = dup(0) if defined $in_fh;

        # open STDIN_SAVE,  "<&STDIN"#  or croak "run3(): $! saving STDIN"
        #     if defined $in_fh;
        open STDOUT_SAVE, ">&STDOUT"
            or croak "run3(): $! saving STDOUT"
            if defined $out_fh;
        open STDERR_SAVE, ">&STDERR"
            or croak "run3(): $! saving STDERR"
            if defined $err_fh;

        my $errno;
        my $ok;
        my $error;
        {    # catch block
            local $@;
            $error = $@ || 'Error' unless eval {    # try block
                   # The open() call here seems to not force fd 0 in some cases;
                   # I ran in to trouble when using this in VCP, not sure why.
                   # the dup2() seems to work.
                dup2(fileno $in_fh, 0)

                    #        open STDIN,  "<&=" . fileno $in_fh
                    or croak "run3(): $! redirecting STDIN" if defined $in_fh;

                # close $in_fh or croak "$! closing STDIN temp file"
                #     if ref $stdin;

                open STDOUT, ">&" . fileno $out_fh
                    or croak "run3(): $! redirecting STDOUT"
                    if defined $out_fh;

                open STDERR, ">&" . fileno $err_fh
                    or croak "run3(): $! redirecting STDERR"
                    if defined $err_fh;

                my $r
                    = ref $cmd
                    ? system {$cmd->[0]} is_win32
                        ? map {

                        # Probably need to offer a win32 escaping
                        # option, every command may be different.
                        (my $s = $_) =~ s/"/"""/g;
                        $s = qq{"$s"};
                        $s;
                        } @$cmd
                        : @$cmd
                    : system $cmd;

                $errno = $!; # save $!, because later failures will overwrite it

                croak $!
                    if defined $r
                    && $r == -1
                    && !$options->{return_if_system_error};
                $ok = 1;
                1;
            };
        }

        my @errs;

        if (defined $saved_fd0) {
            dup2($saved_fd0, 0);
            POSIX::close($saved_fd0);
        }

     # open STDIN,  "<&STDIN_SAVE"#  or push @errs, "run3(): $! restoring STDIN"
     #     if defined $in_fh;
        open STDOUT, ">&STDOUT_SAVE"
            or push @errs, "run3(): $! restoring STDOUT"
            if defined $out_fh;
        open STDERR, ">&STDERR_SAVE"
            or push @errs, "run3(): $! restoring STDERR"
            if defined $err_fh;

        croak join ", ", @errs if @errs;

        die $error unless $ok;

        _read_child_output_fh "stdout", $out_type, $stdout, $out_fh, $options
            if defined $out_fh && $out_type && $out_type ne "FH";
        _read_child_output_fh "stderr", $err_type, $stderr, $err_fh, $options
            if defined $err_fh
            && $err_type
            && $err_type ne "FH"
            && !$tie_err_to_out;

        $! = $errno;    # restore $! from system()

        return 1;
    }
    1;
};

use Carp qw( croak );
use Config;
use Data::Dumper          qw(Dumper);
use File::Spec::Functions qw(catfile);
use File::Temp            qw( tempfile );
use FindBin;
use Getopt::Long qw(:config gnu_getopt no_ignore_case);
use Storable     qw(nstore);

warn ">> started '$0'\n";

# parse commandline options
my @spec = (
    'module=s@',
    'install_to=s',
    'url=s',
    'verbose=i',
    'skiptest=i',
    'uninstall=i',
    'ignore_testfailure=i',
    'ignore_uptodate=i',
    'prereqs=i',
    'interactivity=i',
    'makefilepl_param=s',
    'buildpl_param=s',
    'signature=i',
    'out_dumper=s',
    'out_nstore=s',
);
GetOptions(\my %opts, @spec) or die ">> invalid option(s)";

# defaults
$opts{module}             //= [];
$opts{install_to}         //= '';
$opts{url}                //= '';  #'http://cpan.strawberryperl.com';
$opts{verbose}            //= 1;
$opts{uninstall}          //= 0;
$opts{skiptest}           //= 0;   # 1 = do not run 'test' at all
$opts{ignore_testfailure} //= 0;   # 1 = if 'test' fails continue with 'install'
$opts{ignore_uptodate}    //= 0;   # 1 = install no matter what
$opts{prereqs} //= 1;    # 0 = Do not install, 1 = Install, 2 = Ask, 3 = Ignore
$opts{interactivity}    //= 0;    # 1 = allow_build_interactivity
$opts{makefilepl_param} //= '';
$opts{buildpl_param}    //= '';
$opts{signature} //= 0; # 0 = ignore signature, 1 = check signature if available
$opts{out_dumper} //= "install-log.$$.dumper.txt";
$opts{out_nstore} //= "install-log.$$.nstore.txt";

$opts{url} =~ s|/$||;
for (@{$opts{module}}) {
    $_ =~ s/-/::/g unless $_ =~ /[\/\.]/;
}

sub save_output {
    my ($data, $out_nstore, $out_dumper) = @_;

    if ($out_nstore) {
        warn ">> storing results via Storable to '$out_nstore'\n";
        nstore($data, $out_nstore) or die ">> store failed";
    }

    if ($out_dumper) {
        warn ">> storing results via Data::Dumper to '$out_nstore'\n";
        open my $fh, ">", $out_dumper or die ">> open: $!";
        print $fh Dumper($data) or die ">> print: $!";
        close $fh               or die ">> close: $!";
    }
}

die ">> invalid install_to option"
    if $opts{install_to} && $opts{install_to} !~ /(perl|site|vendor)/;
die ">> invalid prereqs option (only 0, 1 or 3 allowed)"
    if defined $opts{prereqs} && $opts{prereqs} !~ /^(0|1|3)$/;
die ">> no modules specified" unless scalar(@{$opts{module}});

my $success = 1;
my $env     = {};
my @args    = ($^X, "$FindBin::Bin/cpanm");

push @args, @{$opts{module}};
push @args, '--verbose'     if $opts{verbose};
push @args, '--notest'      if $opts{skiptest};
push @args, '--force'       if $opts{ignore_testfailure};
push @args, '--reinstall'   if $opts{ignore_uptodate};
push @args, '--interactive' if $opts{interactivity};
push @args, '--uninstall'   if $opts{uninstall};
push @args, '--mirror', $opts{url}, '--mirror-only' if $opts{url};
push @args, '--configure-args',
    ($opts{buildpl_param} || $opts{makefilepl_param})
    if $opts{makefilepl_param} || $opts{buildpl_param};

if ($opts{install_to} eq 'site') {
    $env->{PERL_MM_OPT}
        = "INSTALLDIRS=site UNINST=1";    # INSTALL_BASE=$Config{sitelibexp}
    $env->{PERL_MB_OPT} = "--installdirs=site --uninst=1"
        ;                                 # --install_base=$Config{vendorlibexp}
}
elsif ($opts{install_to} eq 'vendor') {
    $env->{PERL_MM_OPT}
        = "INSTALLDIRS=vendor UNINST=1";    # INSTALL_BASE=$Config{vendorlibexp}
    $env->{PERL_MB_OPT} = "--installdirs=vendor uninst=1"
        ;    # --install_base=$Config{vendorlibexp}
}
elsif ($opts{install_to} eq 'perl' || $opts{install_to} eq 'core') {
    $env->{PERL_MM_OPT}
        = "INSTALLDIRS=perl UNINST=1";    # INSTALL_BASE=$Config{vendorlibexp}
    $env->{PERL_MB_OPT} = "--installdirs=core --uninst=1"
        ;                                 # --install_base=$Config{vendorlibexp}
}
else {
    $env->{PERL_MM_OPT} = 'UNINST=1';
    $env->{PERL_MB_OPT} = '--uninst=1';
}

### --configure-args, --build-args, --test-args, --install-args
# $opts{prereqs}            //= 1; # 0 = Do not install, 1 = Install, 2 = Ask, 3 = Ignore
# $opts{signature}          //= 0; # 0 = ignore signature, 1 = check signature if available

my ($exit_code, $out);
{
    my $rv;
    my %original_env = %ENV;
    local %ENV;
    %ENV = (%original_env, %$env);
    warn ">> ", join ' ', @{$opts{module}}, "\n";
    if (eval 'use IPC::Run3; 1') {
        $rv = IPC::Run3::run3(\@args, \undef, \$out, \$out);
    }
    else {
        warn "Fallback to `MYIPC::Run3`\n";
        $rv = MYIPC::Run3::run3(\@args, \undef, \$out, \$out);
    }
    $exit_code = $? // -666;
    $success   = $rv && $exit_code == 0 ? 1 : 0;
}

say "###\n", $out,           "###";
say "###\n", Dumper(\@args), "###";

my @list = split /[\n\r]+/, $out;
@list = map  { s/[\r\n]*$//; $_ } @list;
@list = grep {/^Successfully (re)?installed (\S+)/} @list;
@list = map  { s/^Successfully (re)?installed (\S+).*$/$2/; $_ } @list;

save_output({installed => \@list, success => $success},
    $opts{out_nstore}, $opts{out_dumper});
die ">> FAILUE [exit_code=$exit_code]\n" unless $success;
warn ">> done!\n";
exit 0;
