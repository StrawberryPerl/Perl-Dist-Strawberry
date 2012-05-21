package Perl::Dist::Strawberry;

use 5.012;
use warnings;

use Data::Dump            qw(pp);
use Getopt::Long          qw();
use ExtUtils::MakeMaker   qw();
use File::Path            qw(make_path remove_tree);
use File::Slurp           qw(read_file write_file append_file);
use File::Spec::Functions qw(catfile catdir canonpath splitpath);
use File::Find::Rule;
use File::Glob            qw(:glob);
use Archive::Zip          qw(:ERROR_CODES :CONSTANTS);
use URI::file             qw();
use File::ShareDir        qw();
use Pod::Usage            qw(pod2usage);
use LWP::UserAgent;

# following recommendation from http://www.dagolden.com/index.php/369/version-numbers-should-be-boring/
our $VERSION = "3.003";
$VERSION = eval $VERSION;

sub new {
  my $class = shift;
  return bless {
    global => {
        # set defaults
        target        => 'msi+zip+portable',
        working_dir   => 'c:\strawberry_build',
        image_dir     => 'c:\strawberry',
        cpan_url      => 'http://cpan.strawberryperl.com',
        package_url   => 'http://strawberryperl.com/package/',
        test_modules  => 1,
        test_core     => 0,
        offline       => 0,
        perl_debug    => 0,
        verbosity     => 3,
        interactive   => 1,
        restorepoints => 0,
        output        => {}, #globally storing outputs from each step
        @_,
    } }, $class;
}

sub parse_options {
  my $self = shift;

  $self->global->{argv} = [@_]; #keep original parameters
  local @ARGV = @_;

  Getopt::Long::GetOptions(
    'j|job=s'           => \$self->global->{job},
    'working_dir=s'     => \$self->global->{working_dir},   #<dir>    default: c:\buildtmp
    'wixbin_dir=s'      => \$self->global->{wixbin_dir},    #<dir>    default: undef
    'image_dir=s'       => \$self->global->{image_dir},     #<dir>    default: c:\strawberry (BEWARE: dir will be destroyed!!)
    'cpan_url=s'        => \$self->global->{cpan_url},      #<url>    default: http://cpan.strawberryperl.com (or use e.g. file://C|/cpanmirror/)
    'test_modules!'     => \$self->global->{test_modules},  #<flag>   default: 1 (0 = skip tests when installing perl modules)
    'test_core!'        => \$self->global->{test_core},     #<flag>   default: 0 (0 = skip tests when installing perl core)
    'offline=s'         => \$self->global->{offline},       #<flag>   default: 0 (1 = internet connection unavailable during build)
    'perl_debug=s'      => \$self->global->{perl_debug},    #<flag>   default: 0 (1 = build perl core with debug enabled)
    'verbosity=s'       => \$self->global->{verbosity},     #<level>  default: 2 (you can use values 1/silent to 5/verbose)
    'package_url=s'     => \$self->global->{package_url},   #<url>    default: http://strawberryperl.com/package/ (or use e.g. file://C|/pkgmirror/)
    'interactive!'      => \$self->global->{interactive},   #<flag>   default: 1 (0 = no interactive questions)
    'restorepoints!'    => \$self->global->{restorepoints}, #<flag>   default: 0 (1 = create restorepoint after each finished step)
    'h|help'            => sub { pod2usage(-exitstatus=>0, -verbose=>2) },
  ) or pod2usage(-verbose=>2);
  
  $self->global->{working_dir}     = canonpath($self->global->{working_dir});
  $self->global->{image_dir}       = canonpath($self->global->{image_dir});
  $self->global->{dist_sharedir}   = canonpath(File::ShareDir::dist_dir('Perl-Dist-Strawberry'));
  $self->global->{build_dir}       = canonpath(catdir($self->global->{working_dir}, "build"));
  $self->global->{debug_dir}       = canonpath(catdir($self->global->{working_dir}, "debug"));
  $self->global->{download_dir}    = canonpath(catdir($self->global->{working_dir}, "download"));
  $self->global->{env_dir}         = canonpath(catdir($self->global->{working_dir}, "env"));
  $self->global->{output_dir}      = canonpath(catdir($self->global->{working_dir}, "output"));
  $self->global->{restore_dir}     = canonpath(catdir($self->global->{working_dir}, "restore"));

  # set other computed values
  (my $idq = $self->global->{image_dir}) =~ s|\\|\\\\|g;
  (my $idu = $self->global->{image_dir}) =~ s|\\|/|g;
  $self->global->{image_dir_quotemeta} = $idq;
  $self->global->{image_dir_url}       = "file:///$idu";
  
  if (defined $self->global->{wixbin_dir}) {
    my $d = $self->global->{wixbin_dir};
    unless (-f "$d/candle.exe" && -f "$d/light.exe") {
      die "ERROR: invalid wixbin_dir '$d' (candle.exe+light.exe not found)\n";
    }
  }

}

sub global { # accessor to global data
  return shift->{global};
}

sub do_job {
  my $self = shift;
  my $i;

  my $job = $self->load_jobfile();
  # now we have parsed all commandline params + jobfile options
  
  #ask user couple of questions
  $self->ask_about_dirs; # only ask, die if user do not want to continue
  my $restorepoint = $self->ask_about_restorepoint($self->global->{image_dir}, $job->{bits}); # only ask user, no real restore yet
  $self->ask_about_build_details($restorepoint);
  
  warn "\n### STARTING THE JOB (long running task, go for a coffee) ###\n\n";

  #now long running tasks may start (no user questions anymore)
  $self->create_dirs();
  $self->message(0, "preparing build machine");
  $self->create_buildmachine($job, $restorepoint);
  $self->prepare_build_ENV();

  #check
  $self->message(0, "starting global check");
  $i = 0;
  for (@{$self->{build_job_steps}}) {    
    $self->message(1, "checking [step:$i] ".ref($_));
    $_->check unless $_->{data}->{done}; # dies on error
    $i++;
  }; 

  #run
  $self->message(0, "starting the build");
  write_file(catfile($self->global->{debug_dir}, "global_dump_INITIAL.txt"), pp($self->global)); #debug dump
  $self->build_job_pre(); # dies on error
  $i = 0;
  for (@{$self->{build_job_steps}}) {
    my $me = ref($_);
    $me =~ s/^Perl::Dist::Strawberry::Step:://;
    if ($_->{data}->{done}) {
      # loaded from restorepoint
      $self->message(0, "[step:$i] no need to run '$me'");
    }
    else {
      $self->message(0, "[step:$i] starting '$me'");
      $_->run;  # dies on error
      $_->test; # dies on error
      $_->{data}->{done} = 1; # mark as sucessfully finished      
      $self->message(0, "[step:$i] finished '$me'");
      $self->make_restorepoint("[step:$i/".$self->global->{bits}."bit] $me") if $self->global->{restorepoints};
      $self->message(0, "[step:$i] restorepoint saved");
      write_file(catfile($self->global->{debug_dir}, "global_dump_".time.".txt"), pp($self->global)); #debug dump
    }
    $self->merge_output_into_global($_->{data}); #merge for both restorepoint and really executed step
    $i++;
  }
  $self->build_job_post(); # dies on error
  write_file(catfile($self->global->{debug_dir}, "global_dump_FINAL.txt"), pp($self->global)); #debug dump
  $self->message(0, "build finished");
}

sub build_job_pre {
  my $self = shift;  
  
  if ($self->global->{bits} != 32 && $self->global->{bits} != 64) {
    die "ERROR: invalid 'bits' value [".$self->global->{bits}."]\n";
  }
  #XXX-FIXME maybe add more checks
}

sub build_job_post {
  my $self = shift;
}

sub ask_about_dirs {
  my $self = shift;
  my $idir = $self->global->{image_dir};
  my $wdir = $self->global->{working_dir};
  my $idir_exists = -d $idir ? " - !!!ALREADY EXISTS AND WILL BE REMOVED!!!" : "";
  my $wdir_exists = -d $wdir ? " - already exists and will be reused" : "";  
  my $continue = lc $self->prompt("We are gonna use the following directories during build:\n".
                                  " * $idir$idir_exists\n".
                                  " * $wdir$wdir_exists\n".
                                  "Do you want to continue?", 'y');
  die "QUITTING\n" unless $continue eq 'y';
}

sub ask_about_build_details {
  my ($self, $restorepoint) = @_;
  my ($note1, $note2) = ('', '');
  $note1 = "NOTE: use -restorepoints to enable" if !$self->global->{restorepoints};
  $note2 = "NOTE: use -nointeractive to disable" if $self->global->{interactive};
  my $continue = lc $self->prompt("Important job details:\n".
                                  " * job=".$self->global->{job}."\n".
                                  " * verbosity=".$self->global->{verbosity}."\n".
                                  " * restorepoints=".$self->global->{restorepoints}." $note1\n".
                                  " * interactive=".$self->global->{interactive}."   $note2\n".
                                  " * test_modules=".$self->global->{test_modules}."\n".
                                  " * test_core=".$self->global->{test_core}."\n".
                                  "Do you want to continue?", 'y');
  die "QUITTING\n" unless $continue eq 'y';
}

sub create_dirs {
  my $self = shift;

  my $idir = $self->global->{image_dir};
  if (-d $idir) {
    remove_tree($idir) or die "ERROR: cannot delete '$idir'\n";
  }
  make_path($idir) or die "ERROR: cannot create '$idir'\n";

  my $wdir = $self->global->{working_dir};
  if (!-d $wdir) {
    make_path($wdir) or die "ERROR: cannot create '$wdir'\n";
  }

  #clean other working directories
  !-d $self->global->{build_dir}     or remove_tree($self->global->{build_dir})     or die "ERROR: cannot delete '".$self->global->{build_dir}."'\n";
  !-d $self->global->{debug_dir}     or remove_tree($self->global->{debug_dir})     or die "ERROR: cannot delete '".$self->global->{debug_dir}."'\n";
  !-d $self->global->{env_dir}       or remove_tree($self->global->{env_dir})       or die "ERROR: cannot delete '".$self->global->{env_dir}."'\n";  #XXX-FIXME maybe only warn not die
  make_path($self->global->{build_dir})     or die "ERROR: cannot create '".$self->global->{build_dir}."'\n";
  make_path($self->global->{debug_dir})     or die "ERROR: cannot create '".$self->global->{debug_dir}."'\n";
  make_path(catdir($self->global->{env_dir}, 'temp'));
  make_path(catdir($self->global->{env_dir}, 'AppDataRoaming'));
  make_path(catdir($self->global->{env_dir}, 'AppDataLocal'));
  make_path(catdir($self->global->{env_dir}, 'UserProfile'));
  #create only if not exists
  -d $self->global->{restore_dir} or make_path($self->global->{restore_dir}) or die "ERROR: cannot create '".$self->global->{restore_dir}."'\n";
  -d $self->global->{output_dir}  or make_path($self->global->{output_dir})  or die "ERROR: cannot create '".$self->global->{output_dir}."'\n";
}

sub prepare_build_ENV {
  my $self = shift;

  my ($home_d, $home_p) = splitpath(catfile($self->global->{env_dir}, qw/UserProfile fakefile/));
  my @path = split /;/ms, $ENV{PATH};
  my @new_path = ( catdir($self->global->{image_dir}, qw/perl site bin/),
                   catdir($self->global->{image_dir}, qw/perl bin/),
                   catdir($self->global->{image_dir}, qw/c bin/) );
  foreach my $p (@path) {
    next if not -d $p; # Strip any path that doesn't exist
    # Strip any path outside of the windows directories. This is done by testing for kernel32.dll and win.ini
    next if ! (-f catfile( $p, 'kernel32.dll' ) || -f catfile( $p, 'win.ini' ));
    # Strip any path that contains either unzip or gzip.exe. These two programs cause perl to fail its own tests.
    next if -f catfile( $p, 'unzip.exe' );
    next if -f catfile( $p, 'gzip.exe' );
    push @new_path, $p;
  }
  $self->global->{build_ENV} = {
    LIB               => undef,
    INCLUDE           => undef,
    PERLLIB           => undef,
    PERL5LIB          => undef,
    PERL5OPT          => undef,
    PERL5DB           => undef,
    PERL5SHELL        => undef,
    PERL_MM_OPT       => undef,
    PERL_MB_OPT       => undef,
    PERL_YAML_BACKEND => undef,
    PERL_JSON_BACKEND => undef,
    HOMEDRIVE         => $home_d,
    HOMEPATH          => $home_p,
    TEMP              => catdir($self->global->{env_dir}, 'temp'),
    TMP               => catdir($self->global->{env_dir}, 'temp'),
    APPDATA           => catdir($self->global->{env_dir}, 'AppDataRoaming'),
    LOCALAPPDATA      => catdir($self->global->{env_dir}, 'AppDataLocal'),
    USERPROFILE       => catdir($self->global->{env_dir}, 'UserProfile'),
    COMPUTERNAME      => 'buildmachine',
    USERNAME          => 'builduser',
    TERM              => 'dumb',
    PATH              => join(';', @new_path),
  };
  
  # Create batch file '<debug_dir>/cmd_with_env.bat' for debugging #XXX-FIXME maybe move this somewhere else
  my $env = $self->global->{build_ENV};
  my $set_env = '';
  $set_env .= "set $_=" . (defined $env->{$_} ? $env->{$_} : '') . "\n" for (sort keys %$env);
  write_file(catfile($self->global->{debug_dir}, 'cmd_with_env.bat'), "\@echo off\n\n$set_env\ncmd /K\n");

}

sub create_buildmachine {
  my ($self, $job, $restorepoint) = @_;
  my $h;
  my $counter = 0;
  
  $h = delete $job->{build_job_steps};
  for my $s (@$h) {
    my $p = delete $s->{plugin};
    my $n = eval "use $p; $p->new()";
    die "ERROR: invalid plugin '$p'\n$@" unless $n;
    $n->{boss} = $self;
    $n->{config} = $s;
    $n->{data} = { done=>0, plugin=>$p, output=>undef };
    push @{$self->{build_job_steps}}, $n;
  }
  $counter += scalar(@$h);
    
  # store remaining job data into global-hash
  while (my ($k, $v) = each %$job) {
    $self->global->{$k} = $v;
  }
  # derive output_basename and store int global-hash
  my $basename = "$job->{app_simplename}-$job->{app_version}";
  $basename .= "-beta$job->{beta}" if $job->{beta};
  $basename .= "-$job->{bits}bit";
  $self->global->{output_basename} = $basename; # e.g. strawberryperl-5.14.2.1 or strawberryperl-5.14.2.1-beta2 

  if ($restorepoint) {
    my $i;
    my $start_time = time;
    $self->message(0, "loading RESTOREPOINT=$restorepoint->{restorepoint_info}\n"); # will not be saved in "debug_dir/messages" !!!

    $i = 0;
    for my $data (@{$restorepoint->{build_job_steps}}) {
      if ($data->{done}) {
        die "ERROR: restorepoint has not compatible structure" if !$data->{plugin} || $data->{plugin} ne $self->{build_job_steps}->[$i]->{data}->{plugin};
        $self->{build_job_steps}->[$i]->{data} = $data;
      }
      $i++;
    }

    $self->unzip_dir($restorepoint->{restorepoint_zip_debug_dir}, $self->global->{debug_dir});
    $self->unzip_dir($restorepoint->{restorepoint_zip_image_dir}, $self->global->{image_dir});
    
    $self->message(0, sprintf("RESTOREPOINT loaded in %.2f minutes\n", (time-$start_time)/60));
  }
  else {
    $self->message(0, "new build machine created, total steps=$counter");
  }
}

sub merge_output_into_global {
  my ($self, $data) = @_;
  return unless defined $data && ref $data eq 'HASH';
  return unless $data->{output};
  while (my ($k, $v) = each %{$data->{output}}) {
    if (exists $self->global->{output}->{$k}) {
      if (!ref $v) {
        $self->message(2, "WARNING: replacing global->{output}->{$k} with scalar");
        $self->global->{output}->{$k} = $v;
      }
      elsif (ref $self->global->{output}->{$k} eq 'HASH' && ref $v eq 'HASH') {
        $self->message(2, "INFO: merging hashes global->{output}->{$k}");
        $self->global->{output}->{$k} = { %{$self->global->{output}->{$k}}, %$v };
      }
      elsif (ref $self->global->{output}->{$k} eq 'ARRAY' && ref $v eq 'ARRAY') {
        $self->message(2, "INFO: merging arrays global->{output}->{$k}");
        push @{$self->global->{output}->{$k}}, @$v;
      }
      else {
        $self->message(2, "WARNING: skipping merge for global->{output}->{$k}");
      }      
    }
    else {
      $self->global->{output}->{$k} = $v;
    }
  }
}

sub load_jobfile {
  my $self = shift;
  if(!defined $self->global->{job}) {
    warn "ERROR: undefined jobfile (probably mission -job param)\n";
    warn "       use --help option to see more info\n\n";
    die;
  }
  my $ppfile = $self->resolve_name($self->global->{job});
  die "ERROR: non existing jobfile '$ppfile'\n" unless -f $ppfile;
  my $job = do($ppfile);
  die "ERROR: load jobfile '$ppfile' failed\n$@" if $@;
  return $job;
}

sub prompt {
  my $self = shift;
  if ($self->global->{interactive}) {
    return ExtUtils::MakeMaker::prompt("\n$_[0]", $_[1]); # simply proxying all calls to EU::MM's prompt
  }
  else {
    print "\n$_[0]", ' ', $_[1], "\n";
    return $_[1];
  }
}

sub message {
  my ($self, $level, @msg) = @_;
  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
  my $time = sprintf("%02d/%02d/%02d-%02d:%02d:%02d",$year+1900,$mon,$mday,$hour,$min,$sec);
  my $log = catfile($self->global->{debug_dir}, 'messages.txt');
  write_file($log, "### log started: ".scalar(localtime)."\n\n") unless -f $log;
  push @msg, "\n" unless $msg[$#msg] =~ /\n$/;
  if ($level==0) {
    # print always with timestamp
    warn "##$time## ", @msg;
  }
  elsif (!defined $self->global->{verbosity} || $level <= $self->global->{verbosity}) {
    warn "    ", @msg;
  }
  append_file($log, "$time\tlevel:$level\t", @msg);
}

sub resolve_name {
  my ($self, $name) = @_;
  if ($name =~ /^<(.*?)>/) {
    my $r = $self->global->{$1};
    $name =~ s/^<(.*?)>/$r/;
  }
  if ($name =~ m|^[a-zA-Z0-9]+://|) {
    #url
    $name =~ s|([^:]/)/*|$1|g; # // >>> /
  }
  else {
    #filename
    $name = canonpath($name);
  }
  return $name;
}

sub test_url {
  my ($self, $url) = @_;
  my $ua = LWP::UserAgent->new();
  return 1 if $ua->head($url)->code == 200;
  return 0;
}

sub mirror_url {
  my ($self, $url, $dir) = @_;

  # If our caller was install_par, don't display anything.
  my $no_display_trace = (caller 0)[3] eq 'install_par' ? 1 : 0;

  # Check if the file already is downloaded.
  my $file = $url;
  $file =~ s|^.+\/||;# Delete anything before the last forward slash, leaves only the filename.
  my $target = catfile( $dir, $file );

  return $target if $self->global->{offline} and -f $target;

  # Error out - we can't download.
  die "ERROR: Currently offline, cannot download '$url'\n" if $self->global->{offline} and $url !~ /^file:/;

  # Create the directory to download to if required.
  -d $dir or make_path($dir) or die "ERROR: cannot create '$dir'\n";

  # Now download the file.
  $self->message( 2, "* downloading file '$url'") unless $no_display_trace;
  my $ua = LWP::UserAgent->new();
  my $r = $ua->mirror( $url, $target );
  if ( $r->is_error ) {
    $self->message(0, "    Error getting $url:\n" . $r->as_string . "\n" );
    return;
  }
  elsif ( $r->code == HTTP::Status::RC_NOT_MODIFIED ) {
    $self->message(3, "* already up to date") unless $no_display_trace;
  }

  return $target; # downloaded file name 
}

sub zip_dir {
  my ($self, $dir, $zip_filename, $level) = @_;
  $level //= 1;
  $self->message(3, "started: zip_dir('$dir', '$zip_filename', $level)\n");
  die "ERROR: non-existing dir '$dir'" unless -d $dir;
  my @items = File::Find::Rule->in($dir);
  my $zip = Archive::Zip->new();
  for my $fs_name (@items) {
    (my $archive_name = $fs_name) =~ s|^\Q$dir\E[/\\]*||i;
    next if $archive_name eq '';
    my $m = $zip->addFileOrDirectory($fs_name, $archive_name);
    $m->desiredCompressionLevel($level); # 1 = fastest compression
    $m->unixFileAttributes( 0777 ) if $fs_name =~ /\.(exe|bat|dll)$/i; # necessary for correct unzipping on cygwin
  }
  die 'ERROR: ZIP failure' unless ($zip->writeToFileNamed($zip_filename) == AZ_OK);
}

sub unzip_dir {
  my ($self, $zip_filename, $dir) = @_;
  $self->message(3, "started: unzip_dir('$zip_filename', '$dir')\n");
  my $zip = Archive::Zip->new($zip_filename);
  my $rv = $zip->extractTree('', "$dir\\"); # '\\' in the end is important
  die 'ERROR: UNZIP failure' unless ($rv == AZ_OK);
}

sub make_restorepoint {
  my ($self, $text) = @_;
  $self->message(3, "gonna save restorepoint '$text'\n");
  
  my $start_time = time;
  my $zip_image_dir = catfile($self->global->{restore_dir}, time."_image_dir.zip");
  my $zip_debug_dir = catfile($self->global->{restore_dir}, time."_debug_dir.zip");
  my $pp_name = catfile($self->global->{restore_dir}, time."_data.pp");
  $self->zip_dir($self->global->{image_dir}, $zip_image_dir);
  $self->zip_dir($self->global->{debug_dir}, $zip_debug_dir);
  my $now = scalar(localtime);
  (my $a = pp($self->global->{argv})) =~ s/[\r\n]+/\n#/g;
  my $comment = "# time : $now\n".
                "# stage: after '$text'\n".
                "# argv : $a\n\n";

  my %data_to_save = (
    image_dir => $self->global->{image_dir},
    bits => $self->global->{bits},
    restorepoint_info => "$now - saved after '$text'",
    restorepoint_zip_image_dir => $zip_image_dir,
    restorepoint_zip_debug_dir => $zip_debug_dir,
    build_job_steps      => [],
  );
  push @{$data_to_save{build_job_steps}},      $_->{data} for (@{$self->{build_job_steps}});

  write_file($pp_name, $comment.pp(\%data_to_save));

  $self->message(3, sprintf("restorepoint saved in %.2f minutes\n", (time-$start_time)/60));
}

sub ask_about_restorepoint {
  my ($self, $image_dir, $bits) = @_;
  my @points;
  my $list;
  my $i = 0;
  for my $pp (sort(bsd_glob($self->global->{restore_dir}."/*.pp"))) {
    my $d = eval { do($pp) };
    warn "SKIPPING/1 $pp\n" and next unless defined $d && ref($d) eq 'HASH';
    warn "SKIPPING/2 $pp\n" and next unless defined $d->{build_job_steps};
    warn "SKIPPING/3 $pp\n" and next unless defined $d->{restorepoint_info};
    warn "SKIPPING/4 $pp\n" and next unless $d->{restorepoint_zip_image_dir} && -f $d->{restorepoint_zip_image_dir};
    warn "SKIPPING/5 $pp\n" and next unless $d->{restorepoint_zip_debug_dir} && -f $d->{restorepoint_zip_debug_dir};
    warn "SKIPPING/6 $pp\n" and next unless canonpath($d->{image_dir}) eq canonpath($image_dir);
    warn "SKIPPING/7 $pp\n" and next unless $d->{bits} == $bits;
    $list .= "[$i] $d->{restorepoint_info}\n";
    push @points, $d;
    $i++;
  }
  if ($i>0) {
    my $msg = "Restorepoints available in '".$self->global->{restore_dir}."':\n$list".
              "What restorepoint do you want to use? Enter its number:";
    my $p = $self->prompt($msg, 'none');
    return $points[$p] if ($p =~ /\d+/ && $p >= 0 && $p<=$i-1);
    print "No restorepoint chosen\n";
  }
  return undef;
}

1;

=pod

=head1 NAME

Perl::Dist::Strawberry - Build strawberry-perl-like distribution for MS Windows

=head1 DESCRIPTION

Strawberry Perl is a binary distribution of Perl for the Windows operating
system.  It includes a bundled compiler and pre-installed modules that offer
the ability to install XS CPAN modules directly from CPAN.

You can download Strawberry Perl from L<http://strawberryperl.com|http://strawberryperl.com>

The purpose of the Strawberry Perl series is to provide a practical Win32 Perl
environment for experienced Perl developers to experiment with and test the
installation of various CPAN modules under Win32 conditions, and to provide a
useful platform for doing real work.

L<Perl::Dist::Strawberry|Perl::Dist::Strawberry> is just a helper module for 
the main script L<perldist_strawberry|perldist_strawberry> used for building
Strawberry perl release packages (MSI, ZIP).