#!/usr/bin/perl -w
use strict;

use Amazon::SQS::Simple;
use Net::Amazon::S3;
use Net::DNS;
use Net::DNS::Async;
use IO::Zlib;

my $access_key = '...';
my $secret_key = '...';

my $JOB_NAME = '...';
my $dns_queue_size = (get_max_open_files() || 1024) / 2;
$dns_queue_size = 2048 if ($dns_queue_size > 2048);
my $fh;
my $max_queue_retries = 5;
my $queue_retries     = 0;

my $sqs = new Amazon::SQS::Simple($access_key, $secret_key);
my $s3  = Net::Amazon::S3->new( { aws_access_key_id => $access_key, aws_secret_access_key => $secret_key, retry => 1 } );

my $q = $sqs->CreateQueue($JOB_NAME) || die "Failed to get queue: $JOB_NAME";
my $b = $s3->bucket($JOB_NAME)    || die "Failed to get bucket: $JOB_NAME";

while (1) {
  my $msg = $q->ReceiveMessage() ;
  unless (defined($msg)) {
    print "Nothing queued.\n";
    exit 1 if ($queue_retries >= $max_queue_retries);
    $queue_retries++;
    sleep 60;
    next;
  }
  $queue_retries = 0;

  my $block = $msg->MessageBody();
  chomp $block;

  next unless($block =~ /\A\d+\.\d+\z/);
  my $rh = $msg->ReceiptHandle();
  $q->ChangeMessageVisibility($rh, 900);

  $fh = IO::Zlib->new("x.x.$block.gz", 'wb9') || die "Cannot open x.x.$block.gz for writing: $!";

  my $res  = new Net::DNS::Resolver(nameservers => [qw(208.67.222.222 208.67.220.220)], recurse => 0);
  my $adns = new Net::DNS::Async(QueueSize => $dns_queue_size, Retries => 3, Resolver => $res);
  my $start_time = time;
  print "Start scan of x.x.$block\n";
  foreach my $i (0..255) {
    # Skip reserved address ranges
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
  my $run_time = time - $start_time;
  print "Scan of x.x.$block completed in ".$run_time." seconds\n";
  $b->add_key_filename( "x.x.$block.gz", "x.x.$block.gz",
                        { content_type => 'application/x-gzip', },
                      ) or die $s3->err . ": " . $s3->errstr;
  print "Uploaded x.x.$block.gz sucessfully\n";
  $q->DeleteMessage($rh);
  print "Marked x.x.$block job done\n";
  sleep 1;
}

sub write_out {
  my $response = shift;

  if (!defined($response)) {
    return;
  }

  my ($question) = $response->question;
  my $ip = arpa2ip($question->qname);
  foreach my $rr ($response->answer) {
    #print $rr->string . "\n";
    next unless($rr->type eq 'PTR');
    #print OUT arpa2ip($rr->name) . ', ' . $rr->rdatastr . "\n";
    printf $fh "%d,%s,%s\n", time, $ip, $rr->rdatastr;
  }
}

sub arpa2ip {
  my $arpa = shift;
  $arpa =~ s/\A(\d+)\.(\d+)\.(\d+)\.(\d+)\.in-addr\.arpa\z/$4.$3.$2.$1/io;
  return $arpa;
}

sub get_max_open_files {
  open(LIMITS, '<', "/proc/$$/limits") || die "Unable to open /proc/$$/limits: $!";
  while (my $line = <LIMITS>) {
    next unless ($line =~ /\AMax open files\s+(\d+)\b/);
    return $1;
  }
  return undef;
}
# vim: ts=2 sw=2 et ai si
