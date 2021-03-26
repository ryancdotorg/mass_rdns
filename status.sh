#!/bin/sh
echo -n "Queued:   "
./check-queue.pl $1
echo -n "Finished: "
../s3cmd-1.0.0/s3cmd ls s3://$1/ | wc -l
