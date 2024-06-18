package Perl::Dist::Strawberry::Step::OutputReleasesJSONSnippet;

use 5.012;
use warnings;
use base 'Perl::Dist::Strawberry::Step';

use Time::Piece;
use JSON::PP;
  
use File::Spec::Functions qw(catfile);

sub run {
  my $self = shift;
    
  my $output_basename = $self->global->{output_basename} // 'perl-output';
  my $json_file = catfile($self->global->{output_dir}, "${output_basename}_releases_snippet.json.");
  
  $self->boss->message(2, "gonna create '$json_file'"); 
  # backup already existing json_file;  
  $self->backup_file($json_file);

  use Data::Printer;
  #p $self;
  my $params = $self->global;
  #p $params;
  
  my $app_version = $params->{app_version};
  my $bits = $params->{bits};
  
  my $t = localtime();
  my $year     = $t->year;
  my $month    = $t->month;
  my $date_ymd = $t->strftime('%Y-%m-%d');
  
  my $name     = "$month $year / $app_version / ${bits}bit";
  my $archname = "MSWin32-x${bits}-multi-thread";
  #  next two if-blocks are unverified as we have not built these types
  if ($params->{perl_64bitint}) {
    $name     .= ' / with USE_64_BIT_INT';
    $archname .= '-64int';
  }
  if ($params->{perl_ldouble}) {
    $name     .= ' / with USE_LONG_DOUBLE';
    $archname .= '-ld';
  }

  #  could use a map but it would be less readable
  my @v_parts = split /,/, $params->{app_rc_version};
  my $numver = $v_parts[0] + 1e-3 * $v_parts[1] + 1e-6 * $v_parts[2] + 1e-9 * $v_parts[3];

  my @editions = grep {$_ =~ /^(zip|portable_zip|msi|pdl_zip)$/} keys %{$params->{output}};

  my $edition_hash = {};
  EDITION:
  foreach my $edition (sort @editions) {
    my $f = $params->{output}{$edition};
    if (!$f or !-e $f) {
      warn "Unable to locate $edition output $f, cannot add to releases.json snippet.";
      next EDITION;
    }

    my $size = -s $f;
    #  could use a proper method...
    my $re_sep = qr|[/\\]|;
    my @path = split $re_sep, $f;
    my $basename = $path[-1];

    my $hash = {
        sha1   => $params->{output}{"${edition}_sha1"}   // $self->sha1_file($f),
        sha256 => $params->{output}{"${edition}_sha256"} // $self->sha256_file($f),
        size   => $size,
        url    => "__XXXX_URL_placeholder__ $basename",
    };
    $edition_hash->{$edition} = $hash; 
  }


  #build snippet
  my $snippet = {
    archname => $archname,
    date     => $date_ymd,
    edition  => $edition_hash,
    name     => $name,
    numver   => $numver,
    relnotes => "https://strawberryperl.com/release-notes/$params->{output_basename}.html",
    version  => $app_version,
  };

  #p $snippet;
  my $json_snippet = JSON::PP->new->utf8->pretty->canonical->encode($snippet);
  open my $fh, '>', $json_file or die "Unable to open $json_file, $!";
  print {$fh} $json_snippet;
  $fh->close;
  
}

1;