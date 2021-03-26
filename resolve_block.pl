#!/usr/bin/perl -w
use strict;

use Net::DNS;
use Net::DNS::Async;
use IO::Zlib;

my $block = $ARGV[0] || '17.1';

my $fh = IO::Zlib->new("x.x.$block.out.gz", 'wb9') || die "Cannot open rdns.out.gz for writing: $!";

my $res  = new Net::DNS::Resolver(nameservers => [qw(208.67.222.222 208.67.220.220)], recurse => 0);
#my $res  = new Net::DNS::Resolver(nameservers => [qw(8.8.8.8 8.8.4.4)], recurse => 0);
my $adns = new Net::DNS::Async(QueueSize => 3072, Retries => 3, Resolver => $res);

print "Scanning of x.x.$block\n";
foreach my $i (0..255) {
  foreach my $j (1..9,11..126,128..223) {
    next if ($j == 172 && $i > 32 && $i <= 16);
    next if ($j == 192 && $i == 168);
    next if ($j == 169 && $i == 254);
    next if ($j == 198 && ($i == 18 || $i == 19));
    $adns->add(\&write_out, "$j.$i.$block");
  }
}

$adns->await();

$fh->close();

sub write_out {
  my $response = shift;

  if (!defined($response)) {
    return;
  }

  my ($question) = $response->question;
  my $ip = arpa2ip($question->qname);
  my $i = 0;
  foreach my $rr ($response->answer) {
    print $rr->string . "\n";
    next unless($rr->type eq 'PTR');
    $i++;
    printf("MULTIPLE %s\n", $rr->string) if ($i > 1);
    #print OUT arpa2ip($rr->name) . ', ' . $rr->rdatastr . "\n";
    printf $fh "%s,%s,%s\n", time, $ip, $rr->rdatastr;
  }
}

sub arpa2ip {
  my $arpa = shift;
  $arpa =~ s/\A(\d+)\.(\d+)\.(\d+)\.(\d+)\.in-addr\.arpa\z/$4.$3.$2.$1/io;
  return $arpa;
}

# vim: ts=2 sw=2 et ai si
