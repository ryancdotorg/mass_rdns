#!/usr/bin/perl -w
use strict;

open(IN, '<', 'tmp.out') || die "Unable to open tmp.out: $!";

my $buf;
while (read(IN, $buf, 4)) {
  my $time = unpack('N', $buf);
  read(IN, $buf, 4) || die "Unexpected EOF";
  my $int_ip = unpack('N', $buf);
  my $ip = int2ip($int_ip);
  my $host = '';
  while (1) {
    read(IN, $buf, 1) || die "Unexpected EOF";
    my $len = unpack('C', $buf);
    last if ($len == 0);
    read(IN, $buf, $len);
    $host .= "$buf.";
  }
  print "$time,$ip,$host\n";
}

close(IN);

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

# vim: ts=2 sw=2 et ai si
