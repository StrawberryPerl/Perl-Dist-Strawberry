#!/usr/bin/perl
#
# Copyright 2012 kmx(at)cpan(dot)org
#
# This code is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#

use strict;
use warnings;
use Getopt::Long;
use File::Temp qw(tempfile tempdir);

use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use Digest::SHA  qw(sha1 sha1_hex sha1_base64 sha256 sha256_hex sha256_base64);
use Data::Dump 'pp';
use File::Glob 'bsd_glob';
use File::Basename;
use File::Spec::Functions qw(canonpath);

sub load_zip {
  my ($filename) = @_;
  my $zip = Archive::Zip->new();
  die 'ZIP read error' unless $zip->read($filename) == AZ_OK;
  my $num = $zip->numberOfMembers();
  my @all = $zip->membersMatching('.*');
  my $all_num = scalar(@all);
  die sprintf("COUNT ERROR: count=%2d all.count=%2d ZIP='%s'\n",$num,$all_num,basename($filename)) if $num != $all_num;

  my $result = {};  
  foreach my $member (@all) {
    my $name = $member->fileName();
    my $content = $zip->contents($member);
    if ($name =~ m|/$| && !defined $content) {
      $result->{$name} = 'DIR';
    }
    else {
      my $content_len = length($content);
      $result->{$name} = sha1_hex($content);
    }
  }
  return $result;
}

sub compare {
  my ($h1, $h2) = @_;
  my %tmp = (%$h2);
  my @result;
  
  for my $k (sort keys %$h1) {
    my $v = delete $tmp{$k};
    if (!defined $v) {
      push @result, "-- $k"; # item was removed from h1
    }
    elsif ($h1->{$k} ne $v) {
      push @result, "!= $k"; # modified item
    }
    else {
      push @result, "== $k"; # identical item
    }
  }
  
  for my $k (sort keys %tmp) {
    push @result, "++ $k"; # item in new in h2
  }
  
  return \@result;
}

sub print_diff {
  my ($list) = @_;
  for (@$list) {
    print "$_\n" unless /^.=/;
    #print "$_\n" unless /^==/;
  }
}

sub find_pairs {
  my ($dir1, $dir2) = @_;

  my @d1 = bsd_glob("$dir1/*.zip");  
  my @d2 = bsd_glob("$dir2/*.zip");
  
  my %h;
  my @result;
  
  for my $z (@d1) {
    $z = canonpath($z);
    my $b = basename($z);
    $b =~ s/^..bit//;
    $b =  '_fftw2' if $b =~ /fftw-2\./;
    $b =  '_fftw3' if $b =~ /fftw-3\./;
    $b =~ s/-\d.*$//;
    warn "duplicate found for '$b' - using '", basename($z),"'\n" if $h{$b};
    $h{$b} = $z;
  }
  
  for my $new (@d2) {
    $new = canonpath($new);
    my $b = basename($new);
    $b =~ s/^..bit//;
    $b =  '_fftw2' if $b =~ /fftw-2\./;
    $b =  '_fftw3' if $b =~ /fftw-3\./;
    $b =~ s/-\d.*$//;   
    my $old = $h{$b};
    if ($old) {
      push @result, [$old, $new];
    }
    else {
      warn "no OLD item found for '$b'\n" and next ;  
    }
  }
    
  return @result;
}

die "usage: dir_old dir_new\n" if @ARGV != 2;

my ($dir_old, $dir_new) = @ARGV;
die "non-existing dir (old) '$dir_old'" unless -d $dir_old;
die "non-existing dir (new) '$dir_new'" unless -d $dir_new;

my @p = find_pairs($dir_old, $dir_new);

for my $i (@p) {
  my ($arch1, $arch2) = @$i;
  my $zip1 = load_zip($arch1);
  my $zip2 = load_zip($arch2);
  my $list = compare($zip1,$zip2);
  warn sprintf("DIFF: OLD='%s' NEW='%s'\n",basename($arch1),basename($arch2));
  print_diff($list);
}

warn "\nTOTAL: ", scalar(@p), " ZIP pairs compared\n";
