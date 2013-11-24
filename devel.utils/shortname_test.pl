use 5.012;
use warnings;

use File::Find::Rule;
use File::Basename;
use Win32;

sub _random_shortname {
  my @ch = ('A'..'Z', 0..9, split(//,'!@$#^(){}_-'));
  my $r;
  $r .= $ch[int(rand(scalar(@ch)))] for (1..8);
  return $r;
}

sub _get_short_basename {
  my ($self, $name) = @_;
  my $base = basename($name);;
  
  my ($n, $e) = $base =~ /^(.*?)(\..*)?$/;
  if ($n =~ /^[A-Z0-9\Q!$#@^(){}_-\E]{1,8}$/i && (!defined $e || $e =~ /^\.[A-Z0-9\Q!$#@^(){}_-\E]{1,3}$/i)) {
    return $base;
  }
  else {
    $n =~ s/[^A-Z0-9\Q!$#@^(){}_-\E]//gi;
    $n = substr(substr($n, 0, 5) . _random_shortname, 0, 8);
    if (defined $e) {   
      $e =~ s/[^A-Z0-9\Q!$#@^(){}_-\E]//gi;
      $e = substr($e . _random_shortname, 0, 3);
      return "$n.$e";
    }
    return $n;
  }
}

warn _get_short_basename(0, 'c:\sw\d f g h\perlthanks.ddd');
warn _get_short_basename(0, 'c:\sw\d f g h\perlthìšì []*èš ìèš èanks.html');
warn _get_short_basename(0, 'c:\sw\d f g h\ì.html');