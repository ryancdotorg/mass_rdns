#!/usr/bin/perl -w
use strict;

use Amazon::SQS::Simple;

my $access_key = '...';
my $secret_key = '...';

my $JOB_NAME = $ARGV[1] || 'mass-rdns-2011-02';


my $sqs = new Amazon::SQS::Simple($access_key, $secret_key);

my $q = $sqs->CreateQueue($JOB_NAME);

$q->SendMessage($ARGV[0]) || printf("Failed to send %s\n", $ARGV[0]);

#my $msg = $q->ReceiveMessage();

#print $msg->MessageBody() . "\n";
#print $msg->MessageId() . "\n";

#$q->ChangeMessageVisibility($msg->ReceiptHandle(), 10);

# vim: ts=2 sw=2 et ai si
