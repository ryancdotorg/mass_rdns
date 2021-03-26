#!/usr/bin/perl -w
use strict;

use Amazon::SQS::Simple;
use Data::Dumper;

my $access_key = '...';
my $secret_key = '...';

my $JOB_NAME = $ARGV[0] || 'mass-rdns-test-01';


my $sqs = new Amazon::SQS::Simple($access_key, $secret_key);

#foreach my $queue (@{$sqs->ListQueues()}) {
  #print Dumper $queue;
#  my $a = $queue->GetAttributes();
#  printf("Endpoint:  %s\n", $queue->Endpoint());
#  printf("~Messages: %s\n", $a->{'ApproximateNumberOfMessages'});
#  printf("Timeout:   %s\n", $a->{'VisibilityTimeout'});
#}

#exit 0;
my $q = $sqs->CreateQueue($JOB_NAME);

my $a = $q->GetAttributes();

print $a->{'ApproximateNumberOfMessages'} . "\n";
# vim: ts=2 sw=2 et ai si
