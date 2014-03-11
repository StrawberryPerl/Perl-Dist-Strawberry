@rem = '--*-Perl-*--
@echo off
if "%OS%" == "Windows_NT" goto WinNT
"%~dp0perl\bin\perl" -x -S "%0" %1 %2 %3 %4 %5 %6 %7 %8 %9
goto endofperl
:WinNT
"%~dp0perl\bin\perl" -x -S "%0" %*
goto endofperl
@rem ';
#!perl

use 5.008009;
use strict;
use warnings;
use Getopt::Long qw(GetOptions);
use Pod::Usage qw(pod2usage);
use File::Spec::Functions qw(splitpath catfile);
use File::Glob qw(bsd_glob);
use FindBin;

# BEWARE: keep non-core dependencies as low as possible
use Win32::File;

### functions

sub get_replacements_backslash {
    my ($old_location, $new_location) = @_;

    $old_location =~ s{/}{\\}gmx;
    $new_location =~ s{/}{\\}gmx;

    return ("\Q$old_location\E", $new_location);
}

sub get_replacements_doublebackslash {
    my ($old_location, $new_location) = @_;

    $old_location =~ s{\\}{/}gmx;
    $new_location =~ s{\\}{/}gmx;
    $old_location =~ s{/}{\\\\}gmx;
    $new_location =~ s{/}{\\\\}gmx;

    return ("\Q$old_location\E", $new_location);
}

sub get_replacements_slash {
    my ($old_location, $new_location) = @_;

    $old_location =~ s{\\}{/}gmx;
    $new_location =~ s{\\}{/}gmx;

    return ("\Q$old_location\E", $new_location);
}

sub get_replacements_url {
    my ($old_location, $new_location) = @_;

    $old_location =~ s{\\}{/}gmx;
    $new_location =~ s{\\}{/}gmx;

    return ("file:///$old_location", "file:///$new_location");
}

sub relocate_file {
    my ($old_location, $new_location, $quiet, $file, $type) = @_;

    chomp $type;
    print "Relocating file $file using $type relocation\n" if not $quiet;

    my $full_file = catfile($new_location, $file);

    my $contents = read_file($full_file);
    return 0 unless defined $contents;

    my ($old, $new) =
        ('backslash'       eq $type) ? get_replacements_backslash($old_location, $new_location)
      : ('slash'           eq $type) ? get_replacements_slash($old_location, $new_location)
      : ('doublebackslash' eq $type) ? get_replacements_doublebackslash($old_location, $new_location)
      : ('url'             eq $type) ? get_replacements_url($old_location, $new_location)
      : ();

    if (defined $old) {
        $contents =~ s{$old}{$new}gi;
    } else {
        die "Can't do a $type relocation\n" if not $quiet;
        exit(1);
    }

    if ( not -f $full_file ) {
        die "Can't relocate a file $file that isn't a file\n" if not $quiet;
        exit(1);
    }

    my $ok;
    if ( not -w $full_file ) {
        my $flags = get_flags_and_unset_readonly($full_file);
        $ok = write_file($full_file, $contents);
        set_flags($full_file, $flags);
    } else {
        $ok = write_file($full_file, $contents);
    }

    return $ok;
}

sub get_flags_and_unset_readonly {
    my $path = shift;
    my $flags;
    Win32::File::GetAttributes($path, $flags);
    my $newflags = ~((~$flags) | Win32::File::READONLY()); # unset READONLY
    Win32::File::SetAttributes($path, $newflags);
    return $flags;
}

sub set_flags {
    my ($path, $newflags) = @_;
    Win32::File::SetAttributes($path, $newflags);
}

sub read_file {
    my ($path, $quiet) = @_;
    my $file;
    unless (open $file, '<', $path) {
      warn "Can't open '$path': $!" if not $quiet;
      return undef;
    }
    my $content = '';
    while ($file->sysread(my $buffer, 131072, 0)) { $content .= $buffer }
    return $content;
}

sub write_file {
  my ($path, $content, $quiet) = @_;
  my $file;
  unless (open $file, '>', $path) {
    warn "Can't open '$path': $!" if not $quiet;
    return 0;
  }
  unless (defined $file->syswrite($content)) {
    warn "Can't write '$path': $!" if not $quiet;
    return 0;
  }
  return 1;
}

sub relocate {
  my ($new_location, $files, $quiet) = @_;

  if (!$new_location || !-d $new_location) {
      die "Invalid location\n" if not $quiet;
      exit(1);
  }

  if (0 == scalar @$files) {
      for (qw/relocation.txt perl1.reloc.txt perl2.reloc.txt/) {
        push @$files, "$new_location/$_" if -f "$new_location/$_";
      }
  }

  if (0 == scalar @$files) {
      @$files = bsd_glob catfile($new_location, '/*reloc*.txt');
  }

  if (0 == scalar @$files) {
      die "Nothing to relocate\n" if not $quiet;
      exit(1);
  }

  $new_location =~ s{/}{\\}g;

  if ("\\" ne substr $new_location, -1, 1) {
      $new_location .= "\\";
  }

  if ($new_location !~ /^[a-z0-9@!_:+\-\.\[\]\/\\]+$/i) {
      ### workaround: use shortname if there is a space in location name - XXX this does not work
      ### $new_location = Win32::GetShortPathName($new_location);
      die "Invalid characters in directory name '$new_location'\n" if not $quiet;
      exit(1);
  }

  foreach my $file (@$files) {
      my @lines = split /[\r\n]+/, read_file($file);
      my $old_location = shift @lines;
      chomp $old_location;

      if ($old_location ne $new_location) {
        print "\nRelocating files\n  from '$old_location'\n  to '$new_location'\n" if not $quiet;
        foreach my $line (@lines) {
            next if $line eq "\n";
            if (!relocate_file($old_location, $new_location, $quiet, split /:/, $line)) {
                die "Could not relocate $file.\n" if not $quiet;
                exit(1);
            }
        }
        unshift @lines, "$new_location\n";
        write_file($file, join("\n", @lines));
      }
  }

  print "Relocation completed\n" if not $quiet;
}

### main

my @files;
my $quiet = 0;
my $new_location = $FindBin::Bin;

GetOptions('help'       => sub { pod2usage(-exitstatus => 0, -verbose => 2); },
           'file=s'     => \@files,
           'location=s' => \$new_location,
           'quiet'      => \$quiet,
          ) or pod2usage(-verbose => 2);

relocate($new_location, \@files, $quiet);

__END__

=head1 NAME

relocation.pl.bat - Relocates Strawberry Perl

=head1 SYNOPSIS

 relocation.pl.bat [ --help ] [--file relocfile] [--location path] [--quiet]

 Options:
   --help          Gives aid and comfort.
   --file          Gives the location of the file of hints to use to
                   relocate Perl. Defaults to all *reloc*.txt files in
                   the current directory.
   --location      The location to relocate to. Defaults to $FindBin::Bin.
   --quiet         Print nothing.

=head1 AUTHOR

Curtis Jewell E<lt>csjewell@cpan.orgE<gt>, KMX E<lt>kmx@cpan.orgE<gt>

=head1 COPYRIGHT & LICENSE

Copyright 2010 Curtis Jewell

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=cut

:endofperl
