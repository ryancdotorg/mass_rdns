#!/usr/bin/perl -w
use strict;

open(OUT, '>', 'tmp.out') || die "Unable to open tmp.out: $!";

while (my $line = <STDIN>) {
  chomp $line;
  next unless ($line =~ /\A(\d+),(\d+\.\d+\.\d+\.\d+),(.*)\z/);
  my ($time, $ip, $host) = ($1, $2, $3);
  print "$line\n";
  print OUT pack('N', $time);
  print OUT pack('N', ip2int($ip));
  foreach my $part (split(/\./, $host)) {
    print OUT pack('C', length($part));
    print OUT $part;
  }
  print OUT "\0";
}

close(OUT);

sub ip2int {
  my @octets = split(/\./, shift);
  return ($octets[0]<<24)+($octets[1]<<16)+($octets[2]<<8)+$octets[3];
}

# vim: ts=2 sw=2 et ai si
