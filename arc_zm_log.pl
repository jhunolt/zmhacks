#!/usr/bin/perl 

#---------------------------------------------------------------------------------------------
#logger to write to ZM
#

use ZoneMinder::Logger qw(:all);

logInit();
$commandline = join " ", @ARGV;
Info("ARC:$commandline");
