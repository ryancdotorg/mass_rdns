#!/usr/bin/perl -w
use strict;

#open(IN, '<', 'tmp.out') || die "Unable to open tmp.out: $!";

my $ipref   = 'xxx.xxx';
my $timeref = 0;

my $buf;
while (read(STDIN, $buf, 1)) {
  my $timedelta = unpack('C', $buf);
  if ($timedelta == 255) {
    read(STDIN, $buf, 4) || die "Unexpected EOF";
    $timeref = unpack('N', $buf);
    $timedelta = 0;
    read(STDIN, $buf, 2) || die "Unexpected EOF";
    $ipref = int2halfip(unpack('n', $buf));
  }
  $timeref += $timedelta;
  read(STDIN, $buf, 2) || die "Unexpected EOF";
  my $ip = int2halfip(unpack('n', $buf)) . ".$ipref";
  read(STDIN, $buf, 1) || die "Unexpected EOF";
  my $len = unpack('C', $buf);
  if ($len > 0) {
    read(STDIN, $buf, $len) || die "Unexpected EOF";
  } else {
    $buf = '';
  }
  my $host = $buf;
  print "$timeref,$ip,$host\n";
}

#close(IN);

sub int2ip {
  my $int_ip = shift;
  my @octets;
  foreach my $i (0..3) {
    my $octet = $int_ip & 255;
    $int_ip >>= 8;
    unshift(@octets, $octet);
  }
  return join('.', @octets);
}

sub int2halfip {
  my $int_ip = shift;
  my @octets;
  foreach my $i (0..1) {
    my $octet = $int_ip & 255;
    $int_ip >>= 8;
    unshift(@octets, $octet);
  }
  return join('.', @octets);
}

# vim: ts=2 sw=2 et ai si
