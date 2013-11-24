use 5.012;
use warnings;

use Win32::TieRegistry qw( KEY_READ );

sub _detect_wix_dir {
  my $self = shift;
  for my $v (qw/3.0 3.5 3.6/) {
    my $WIX_REGISTRY_KEY = "HKEY_LOCAL_MACHINE/SOFTWARE/Microsoft/Windows Installer XML/$v";
    # 0x200 = KEY_WOW64_32KEY
    my $r = Win32::TieRegistry->new($WIX_REGISTRY_KEY => { Access => KEY_READ|0x200, Delimiter => q{/} });
    next unless $r;
    my $d = $r->TiedRef->{'InstallRoot'};
    next unless $d && -d $d && -f "$d/candle.exe" && -f "$d/light.exe";
    return $d;
  }
  return;
}
 
warn _detect_wix_dir;

