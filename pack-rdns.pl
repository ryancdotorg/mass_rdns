#!/usr/bin/perl -w
use strict;

#open(OUT, '>', 'tmp.out') || die "Unable to open tmp.out: $!";

my $ipref   = '65536';
my $timeref = 0;

while (my $line = <STDIN>) {
  chomp $line;
  next unless ($line =~ /\A(\d+),(\d+\.\d+\.\d+\.\d+),(.*)\z/);
  my ($time, $ip, $host) = ($1, $2, $3);
  my $timedelta = $time - $timeref;
  if (ip2int16l($ip) != $ipref || $timedelta > 127 || $timedelta < 0) {
    printf(STDERR "Marker: %10d %15s H: %5d L: %5d R: %5d D: %10d\n", $time, $ip, ip2int16h($ip), ip2int16l($ip), $ipref, $timedelta);
    $ipref = ip2int16l($ip);
    $timeref = $time;
    print STDOUT "\377";
    print STDOUT pack('N', $time);
    print STDOUT pack('n', ip2int16l($ip));
  } else {
    print STDOUT pack('C', $timedelta);
    $timeref += $timedelta;
  }
  print STDOUT pack('n', ip2int16h($ip));
  #foreach my $part (split(/\./, $host)) {
    print STDOUT pack('C', length($host));
    #print STDOUT '.';
    print STDOUT $host;
  #}
  #print STDOUT "\0";
}

close(STDOUT);

sub ip2int {
  my @octets = split(/\./, shift);
  return ($octets[0]<<24)+($octets[1]<<16)+($octets[2]<<8)+$octets[3];
}

sub ip2int16h {
  my @octets = split(/\./, shift);
  return ($octets[0]<<8)+$octets[1];
}

sub ip2int16l {
  my @octets = split(/\./, shift);
  return ($octets[2]<<8)+$octets[3];

}


# vim: ts=2 sw=2 et ai si
