package Perl::Dist::Strawberry::Step::OutputMSM_MSI;

use 5.012;
use warnings;
use base 'Perl::Dist::Strawberry::Step';

use File::Slurp           qw(read_file write_file);
use File::Copy            qw(copy);
use File::Spec::Functions qw(canonpath catdir catfile);
use File::Path            qw(make_path remove_tree);
use File::Find::Rule;
use File::Basename;
use Data::Dump            qw(pp);
use Data::UUID;
use Template;
use IPC::Run3;
use Digest::SHA1;
use Win32::TieRegistry qw( KEY_READ );

sub new {
  my $class = shift;
  my $self = $class->SUPER::new(@_);
  $self->{data_uuid} = Data::UUID->new();
  $self->{id_counter} = 1000;  
  return $self;
}

sub check {
  my $self = shift;
  #global: app_version
  #global: app_name
  my $bdir = canonpath(catdir($self->global->{build_dir}, 'msm_msi'));
  -d $bdir or make_path($bdir) or die "ERROR: cannot create '$bdir'";
  
  my $d = $self->global->{wixbin_dir} // $self->_detect_wix_dir;
  if (!$d) {
    warn "ERROR: cannot find WiX utils (candle.exe+light.exe) installed\n";
    warn "  you need to install WiX toolset v3.5 from http://wix.sourceforge.net\n";
    warn "  or consider using option -wixbin_dir=<path_to_wix_dir>\n\n";
    die;
  }
  $self->{candle_exe} = canonpath("$d/candle.exe");
  $self->{light_exe} = canonpath("$d/light.exe");

}

sub run {
  my $self = shift;
 
  my $bdir = catdir($self->global->{build_dir}, 'msm_msi');
  
  # compute MSM id from MSM guid
  my $msi_guid = $self->{data_uuid}->create_str(); # get random GUID
  my $msm_guid = $self->{data_uuid}->create_str(); # get random GUID
  (my $msm_id = $msm_guid) =~ s/-/_/g;

  # create WXS parts to be inserted into MSM_main.wxs.tt & MSI_main.wxs.tt 
  my $xml_env = $self->_generate_wxml_for_environment();
  my ($xml_start_menu, $xml_start_menu_icons) = $self->_generate_wxml_for_start_menu($msm_id);
  my ($xml_msm, $xml_msi, $id_list_msm, $id_list_msi) = $self->_generate_wxml_for_directory($self->global->{image_dir});
  #debug:
  write_file("$bdir/debug.xml_msi.xml", $xml_msi);
  write_file("$bdir/debug.xml_msm.xml", $xml_msm);
  write_file("$bdir/debug.xml_start_menu.xml", $xml_start_menu);
  write_file("$bdir/debug.xml_start_menu_icons.xml", $xml_start_menu_icons);

  # prepare MSI/MSM filenames 
  my $output_basename = $self->global->{output_basename} // 'perl-output';
  my $msm_file = catfile($self->global->{output_dir}, "$output_basename.msm");
  my $msi_file = catfile($self->global->{output_dir}, "$output_basename.msi");
  my $wixpdb_file = catfile($self->global->{output_dir}, "$output_basename.wixpdb");

  # compute msi_version which has to be 3-numbers (otherwise major upgrade feature does not work)
  my ($v1, $v2, $v3, $v4) = split /\./, $self->global->{app_version};
  $v3 = $v3*1000 + $v4 if defined $v4; #turn 5.14.2.1 to 5.12.2001
 
  # resolve values (only scalars) from config
  for (keys %{$self->{config}}) {
    if (!ref $self->{config}->{$_}) {
      $self->{config}->{$_} = $self->boss->resolve_name($self->{config}->{$_});
    }
  }
  my %vars = (
    # global info taken from 'boss'
    %{$self->global},
    # OutputMSM_MSI config info    
    %{$self->{config}},
    # the following items are computed
    msi_product_guid => $msi_guid,
    msm_package_guid => $msm_guid,
    msi_random_upgrade_code => $self->{data_uuid}->create_str(), # get random GUID
    msm_package_id   => $msm_id,
    msi_version      => sprintf("%d.%d.%d", $v1, $v2, $v3), # e.g. 5.12.2001
    msi_upgr_version => sprintf("%d.%d.%d", $v1, $v2, 0),   # e.g. 5.12.0
    msm_filename     => $msm_file,
    # WXS data
    xml_msm_dirtree     => $xml_msm,
    xml_msi_dirtree     => $xml_msi,
    xml_env             => $xml_env,
    xml_startmenu       => $xml_start_menu,
    xml_startmenu_icons => $xml_start_menu_icons,
  );

  my $f1 = catfile($self->global->{dist_sharedir}, 'msi\MSM_main.wxs.tt');
  my $f2 = catfile($self->global->{dist_sharedir}, 'msi\MSI_main.wxs.tt');
  my $f3 = catfile($self->global->{dist_sharedir}, 'msi\Variables.wxi.tt');
  my $f4 = catfile($self->global->{dist_sharedir}, 'msi\MSI_strings.wxl.tt');  
  my $t = Template->new(ABSOLUTE=>1);
  write_file(catfile($self->global->{debug_dir}, 'TTvars_OutputMSM_MSI_'.time.'.txt'), pp(\%vars)); #debug dump
  $t->process($f1, \%vars, catfile($bdir, 'MSM_main.wxs')) || die $t->error();
  $t->process($f2, \%vars, catfile($bdir, 'MSI_main.wxs')) || die $t->error();
  $t->process($f3, \%vars, catfile($bdir, 'Variables.wxi')) || die $t->error();
  $t->process($f4, \%vars, catfile($bdir, 'MSI_strings.wxl')) || die $t->error();
  
  my $rv;
  my $candle_exe = $self->{candle_exe};
  my $light_exe = $self->{light_exe};
  
  #XXX-FIXME -sice:ICE08|09|32|61 is a hack to handle:
  #light.exe : error LGHT0217 : Error executing ICE action 'ICE32'. The most common cause of this kind of ICE failure is an incorrectly registered
  #            scripting engine. See http://wix.sourceforge.net/faq.html#Error217 for details and how to solve this problem. The following string
  #            format was not expected by the external UI message logger: "Při instalaci tohoto balíčku zjistil instalační program neočekávanou
  #            chybu. Může to znamenat, že u tohoto balíčku nastaly potíže. Kód chyby je 2738. ".
  #light.exe : error LGHT0217 : Error executing ICE action 'ICE08'. The most common cause of this kind of ICE failure is an incorrectly registered
  #            scripting engine. See http://wix.sourceforge.net/faq.html#Error217 for details and how to solve this problem. The following string
  #            format was not expected by the external UI message logger: "Při instalaci tohoto balíčku zjistil instalační program neočekávanou
  #            chybu. Může to znamenat, že u tohoto balíčku nastaly potíže. Kód chyby je 2738. ".
  #light.exe : error LGHT0217 : Error executing ICE action 'ICE61'. The most common cause of this kind of ICE failure is an incorrectly registered
  #            scripting engine. See http://wix.sourceforge.net/faq.html#Error217 for details and how to solve this problem. The following string
  #            format was not expected by the external UI message logger: "The installer has encountered an unexpected error installing this 
  #            package. This may indicate a problem with this package. The error code is 2738. ".

  my $candle1_cmd = [$candle_exe, "$bdir\\MSM_main.wxs", '-out', "$bdir\\MSM_main.wixobj", '-v'];
  my $light1_cmd  = [$light_exe,  "$bdir\\MSM_main.wixobj", '-out', $msm_file, '-pdbout', "$bdir\\MSM_main.wixpdb", qw/-ext WixUIExtension -ext WixUtilExtension -v -sice:ICE32 -sice:ICE08/];
  my $candle2_cmd = [$candle_exe, "$bdir\\MSI_main.wxs", '-out', "$bdir\\MSI_main.wixobj", '-v'];
  my $light2_cmd  = [$light_exe,  "$bdir\\MSI_main.wixobj", '-out', $msi_file, '-pdbout', "$bdir\\MSI_main.wixpdb", '-loc', "$bdir\\MSI_strings.wxl", qw/-ext WixUIExtension -ext WixUtilExtension -sice:ICE38 -sice:ICE43 -sice:ICE48 -sice:ICE47 -v -sice:ICE32 -sice:ICE08 -sice:ICE09 -sice:ICE61/];

  # backup already existing <output_dir>/*.msm and <output_dir>/*.msi
  $self->backup_file($msi_file);
  $self->backup_file($msm_file);

  $self->boss->message(2, "MSM: gonna run $candle1_cmd->[0]");
  $rv = $self->execute_standard($candle1_cmd, catfile($self->global->{debug_dir}, "MSM_candle.log.txt"));
  die "ERROR: MSM candle" unless(defined $rv && $rv == 0);
  
  $self->boss->message(2, "MSM: gonna run $light1_cmd->[0]");
  $rv = $self->execute_standard($light1_cmd, catfile($self->global->{debug_dir}, "MSM_light.log.txt"));
  die "ERROR: MSM light" unless(defined $rv && $rv == 0);
  
  $self->boss->message(2, "MSI: gonna run $candle2_cmd->[0]");
  $rv = $self->execute_standard($candle2_cmd, catfile($self->global->{debug_dir}, "MSI_candle.log.txt"));
  die "ERROR: MSI candle" unless(defined $rv && $rv == 0);
  
  $self->boss->message(2, "MSI: gonna run $light2_cmd->[0]");
  $rv = $self->execute_standard($light2_cmd, catfile($self->global->{debug_dir}, "MSI_light.log.txt"));
  die "ERROR: MSI light" unless(defined $rv && $rv == 0);
  
  #store results
  $self->{data}->{output}->{msi} = $msi_file;
  $self->{data}->{output}->{msm} = $msm_file;
  $self->{data}->{output}->{msm_sha1} = $self->sha1_file($msm_file);
  $self->{data}->{output}->{msi_sha1} = $self->sha1_file($msi_file); # will change after we sign MSI
  $self->{data}->{output}->{msi_guid} = $msi_guid;
  $self->{data}->{output}->{msm_guid} = $msm_guid;
  $self->{data}->{output}->{msm_id}   = $msm_id;

} 

sub _generate_wxml_for_environment {
  my ($self) = @_;
  my $result = "";
  my $id = 1;
  for (keys %{$self->{config}->{env}}) {    
    $result .= sprintf("        <Environment Id='env_extra_%s' Name='%s' Value='%s' Action='set' System='yes' Permanent='no' />\n", $id++, $_, $self->{config}->{env}->{$_});
  }
  return $result
}

sub _generate_wxml_for_start_menu {
  my ($self, $msm_id) = @_;
  my $menu_result = "";
  my $ico_result = "";
  my $id = 1;
  $self->{start_menu_icons} = {};
  my ($component_id, $component_guid) = $self->_gen_component_id("start_menu_main.shortcut");
  $menu_result .= "          <Component Id='StartF_$component_id' Guid='$component_guid' KeyPath='yes' Feature='feat_StartMenu'>\n";
  $menu_result .= "            <RemoveFolder Id='StartF_$component_id.rm' On='uninstall' />\n";
  $menu_result .= "          </Component>\n";
  for my $item (@{$self->{config}->{start_menu}}) {       
    $menu_result .= $self->_generate_start_menu_folder($item, 0, $msm_id)   if $item->{type} eq 'folder';
    $menu_result .= $self->_generate_start_menu_shortcut($item, 0, $msm_id) if $item->{type} eq 'shortcut';
  }
  for (keys %{$self->{start_menu_icons}}) {
    $ico_result .= "    <Icon Id='$self->{start_menu_icons}->{$_}' SourceFile='$_' />\n";    
  }
  return ($menu_result, $ico_result);
}

sub _generate_wxml_for_directory {
  my ($self, $rootdir) = @_;  
  my $t = $self->_prepare_marked_tree($rootdir);

  my $msi = $self->_tree2xml($t, 'MSI');
  my $id_list_msi = [ @{$self->{component_id_list}} ];
  $self->{component_id_list} = [];

  my $msm = $self->_tree2xml($t, 'MSM');
  my $id_list_msm = [ @{$self->{component_id_list}} ];
  $self->{component_id_list} = [];

  return ($msm, $msi, $id_list_msm, $id_list_msi);  
}

sub _generate_start_menu_shortcut {  # !!!BEWARE!!! this sub is called recursively
  my ($self, $item, $depth, $msm_id) = @_;
  $depth //= 0; 
  my $result = "";
  my $ident = "          " . ("  " x $depth);
  my ($component_id, $component_guid) = $self->_gen_component_id($item->{name}.$depth."start.shortcut");
  my $attr_description = defined $item->{description} ? "Description='$item->{description}'" : "Description='$item->{name}'";
  my $attr_workingdir  = defined $item->{workingdir}  ? "WorkingDirectory='$item->{workingdir}'" : "";
  my $attr_target = $item->{target};
  
  $attr_workingdir =~ s/<MSMID>/$msm_id/g; #XXX-FIXME this is a hack
  $attr_target     =~ s/<MSMID>/$msm_id/g; #XXX-FIXME this is a hack
  
  my $attr_icon = "";
  if (defined $item->{icon}) {
    my $i_file = canonpath($self->boss->resolve_name($item->{icon}));
    my $i_short = "ico_$component_id";    
    $self->{start_menu_icons}->{$i_file} //= $i_short;
    $attr_icon = "Icon='$self->{start_menu_icons}->{$i_file}'";
  }
  $result .= "$ident<Component Id='StartS_$component_id' Guid='$component_guid' Feature='feat_StartMenu'>\n";
  $result .= "$ident  <Shortcut Id='Short_$component_id' Name='$item->{name}' Target='$attr_target'  $attr_description $attr_workingdir $attr_icon/>\n";
  $result .= "$ident  <CreateFolder />\n"; # This is strange but for some reason necessary
  $result .= "$ident</Component>\n";
  return $result;
}

sub _generate_start_menu_folder {  # !!!BEWARE!!! this sub is called recursively
  my ($self, $item, $depth, $msm_id) = @_;
  $depth //= 0; 
  my $result = "";
  my $ident = "          " . ("  " x $depth);
  my ($component_id, $component_guid) = $self->_gen_component_id($item->{name}.$depth."start.folder");
  $result .= "$ident<Directory Id='StartF_$component_id.dir' Name='$item->{name}'>\n";
  $result .= "$ident  <Component Id='StartF_$component_id' Guid='$component_guid' KeyPath='yes' Feature='feat_StartMenu'>\n";
  $result .= "$ident    <RemoveFolder Id='StartF_$component_id.rm' On='uninstall' />\n";
  $result .= "$ident  </Component>\n";
  for my $m (@{$item->{members}}) {       
    $result .= $self->_generate_start_menu_folder($m, $depth+1, $msm_id)   if $m->{type} eq 'folder';
    $result .= $self->_generate_start_menu_shortcut($m, $depth+1, $msm_id) if $m->{type} eq 'shortcut';
  }
  $result .= "$ident</Directory>\n";
  return $result;
}

sub _generate_tree {  # !!!BEWARE!!! this sub is called recursively
  my ($self, $rootdir, $depth) = @_;
  
  my $image_dir = canonpath($self->global->{image_dir});
  $rootdir = canonpath($rootdir);
  (my $short = $rootdir) =~ s/^\Q$image_dir\E[\\]*//;

  $depth = 1 unless defined $depth;
  my $h = { type=>'D', full_name=>$rootdir, short_name=>$short, files=>[], dirs=>[], depth=>$depth };

  my @directories = File::Find::Rule->directory->maxdepth(1)->mindepth(1)->in($rootdir);
  for my $d (sort map { canonpath($_) } @directories) {
    (my $short = $d) =~ s/^\Q$image_dir\E[\\]*//;
    $self->{global_hash}->{$short} = $self->_generate_tree($d, $depth+1);
    push @{$h->{dirs}}, $self->{global_hash}->{$short};
  }
  
  my @files = File::Find::Rule->file->maxdepth(1)->mindepth(1)->in($rootdir);
  for my $f (sort map { canonpath($_) } @files) {
    (my $short = $f) =~ s/^\Q$image_dir\E[\\]*//;
    $self->{global_hash}->{$short} = { type=>'F', full_name=>$f, short_name=>$short, depth=>$depth };
    push @{$h->{files}}, $self->{global_hash}->{$short};
  }
  
  return $h;  
}

sub _mark_tree {  # !!!BEWARE!!! this sub is called recursively
  my ($self, $root, $mark) = @_;
  $root->{mark} = $mark;
  if ($root->{type} eq 'D') {
    $self->_mark_tree($_, $mark) for (@{$root->{dirs}});
    $self->_mark_tree($_, $mark) for (@{$root->{files}});
  }
}

sub _prepare_marked_tree {
  my ($self, $rootdir, $type) = @_;

  $self->boss->message(3, "generate tree - started (takes some time)");
  my $t = $self->_generate_tree($rootdir);  
  $self->boss->message(3, "generate tree - items=", scalar(keys $self->{global_hash}));
  
  # by default all go to MSM
  $self->_mark_tree($t, 'MSM');

  # let us move items matching 'exclude_msm' from MSM to MSI
  my @e;
  for my $i (@{$self->{config}->{exclude_msm}}) {
    if (ref($i) eq 'Regexp') {
      push @e, grep {/$i/} (keys $self->{global_hash});
    }
    else {
      push @e, grep {lc($_) eq lc($i)} (keys $self->{global_hash});
    }
  }
  $self->_mark_tree($self->{global_hash}->{$_}, 'MSI') for (@e);

  # let us completely drop items matching 'exclude' these will be neither in MSM nor MSI
  my @s;
  for my $i (@{$self->{config}->{exclude}}) {
    if (ref($i) eq 'Regexp') {
      push @s, grep {/$i/} (keys $self->{global_hash});
    }
    else {
      push @s, grep {lc($_) eq lc($i)} (keys $self->{global_hash});
    }
  }
  $self->_mark_tree($self->{global_hash}->{$_}, 'EXCLUDE') for (@s);

  return $t;
}

sub _tree2xml {  # !!!BEWARE!!! this sub is called recursively
  my ($self, $root, $mark, $not_root) = @_;
    
  my ($component_id, $component_guid, $dir_id);
  my $result = "";
  my $ident = "    " . "  " x $root->{depth};
  
  # dir-start
  if ($not_root && $root->{mark} eq $mark) {
    $dir_id = $self->_gen_dir_id($root->{short_name});
    my $dir_basename = basename($root->{full_name});
    my $dir_shortname = $self->_get_short_basename($root->{full_name});
    $result .= $ident . qq[<Directory Id="$dir_id" Name="$dir_basename" ShortName="$dir_shortname">\n];
  }
  
  my @f = grep { $_->{mark} eq $mark } @{$root->{files}};
  my @d = grep { $_->{mark} eq $mark } @{$root->{dirs}};
  my $feat = $mark eq 'MSM' ? '' : "Feature='feat_$mark'";
  
  if (defined $dir_id) {
    ($component_id, $component_guid) = $self->_gen_component_id($root->{short_name}."create");
    # put KeyPath to the component as Directory does not have KeyPath attribute
    # if a Component has KeyPath="yes", then the directory this component is installed to becomes a key path
    # see: http://stackoverflow.com/questions/10358989/wix-using-keypath-on-components-directories-files-registry-etc-etc
    $result .= $ident ."  ". qq[<Component Id="$component_id" Guid="{$component_guid}" KeyPath="yes" $feat>\n];
    $result .= $ident ."  ". qq[    <CreateFolder />\n];
    $result .= $ident ."  ". qq[    <RemoveFolder Id="rm.$dir_id" On="uninstall" />\n]; #XXX-TODO not sure about this
    $result .= $ident ."  ". qq[</Component>\n];
  }
  
  if (scalar(@f) > 0) {
    for my $f (@f) {
      my $file_id = $self->_gen_file_id($f->{short_name});
      my $file_basename = basename($f->{full_name});
      my $file_shortname = $self->_get_short_basename($f->{full_name});
      ($component_id, $component_guid) = $self->_gen_component_id($file_shortname."files");
      # in 1file/component scenario set KeyPath on file, not on Component
      # see: http://stackoverflow.com/questions/10358989/wix-using-keypath-on-components-directories-files-registry-etc-etc
      $result .= $ident ."  ". qq[<Component Id="$component_id" Guid="{$component_guid}" $feat>\n];
      $result .= $ident ."  ". qq[  <File Id="$file_id" Name="$file_basename" ShortName="$file_shortname" Source="$f->{full_name}" KeyPath="yes" />\n]; # XXX-TODO consider ReadOnly="yes"
      $result .= $ident ."  ". qq[</Component>\n];
    }
  }
  
  $result .= $self->_tree2xml($_, $mark, 1) for (@d);
  $result .= $ident . qq[</Directory>\n] if $not_root && $root->{mark} eq $mark;
  
  return $result;
}

#XXX-FIXME occasionally Win32::GetShortPathName does not produce valid 8.3 name!!!
#sub _get_short_basename {
#  my ($self, $name) = @_;
#  my $result = basename(Win32::GetShortPathName($name));;
#  $result =~ s/~/!/g; # this replacement is necessary, otherwise wix3 will croak
#  
#  return $result;
#}

sub _random_shortname {
  my $self = shift;
  my @ch = ('A'..'Z', 0..9, split(//,'!@#^(){}_-'));
  my $r;
  $r .= $ch[int(rand(scalar(@ch)))] for (1..8);
  return $r;
}

sub _get_short_basename {
  my ($self, $name) = @_;
  my $base = basename($name);;
  
  my ($n, $e) = $base =~ /^(.*?)(\..*)?$/;
  if ($n =~ /^[A-Z0-9\Q!#@^(){}_-\E]{1,8}$/i && (!defined $e || $e =~ /^\.[A-Z0-9\Q!#@^(){}_-\E]{1,3}$/i)) {
    return $base;
  }
  else {
    $n =~ s/[^A-Z0-9\Q!#@^(){}_-\E]//gi;
    $n = substr(substr($n, 0, 4) . $self->_random_shortname, 0, 8);
    if (defined $e) {   
      $e =~ s/[^A-Z0-9\Q!#@^(){}_-\E]//gi;
      $e = substr(substr($e, 0, 3) . $self->_random_shortname, 0, 3);
      return "$n.$e";
    }
    return $n;
  }
}

sub _gen_component_id {
  my ($self, $subj) = @_;
  my $i = "i" . $self->{id_counter}++;
  my $g = $self->{data_uuid}->create_str(); # get random GUID
  push @{$self->{component_id_list}}, $i;
  return ($i, $g);
}

sub _gen_file_id {
  my ($self, $file) = @_;
  my $r;
  $r = "f_perl_bin_perl_exe"  if lc($file) eq 'perl\bin\perl.exe';
  $r = "f_perl_bin_wperl_exe" if lc($file) eq 'perl\bin\wperl.exe';
  $r = "f_perl1_reloc_txt"    if lc($file) eq 'perl1.reloc.txt';
  $r = "f_perl2_reloc_txt"    if lc($file) eq 'perl2.reloc.txt';
  $r = "f_readme_txt"         if lc($file) eq 'readme.txt';
  $r = "f_relocation_pl"      if lc($file) eq 'relocation.pl.bat';
  return  $r // "f" . $self->{id_counter}++;
}

sub _gen_dir_id {
  my ($self, $dir) = @_;
  my $r;
  $r = "d_c"           if lc($dir) eq 'c';
  $r = "d_c_bin"       if lc($dir) eq 'c\bin';
  $r = "d_perl"        if lc($dir) eq 'perl';
  $r = "d_perl_bin"    if lc($dir) eq 'perl\bin';
  $r = "d_perl_site"   if lc($dir) eq 'perl\site';
  $r = "d_perl_vendor" if lc($dir) eq 'perl\vendor';
  $r = "d_win32"       if lc($dir) eq 'win32';
  return $r // "d" . $self->{id_counter}++;
}

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

1;