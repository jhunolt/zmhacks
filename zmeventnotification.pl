#!/usr/bin/perl -wT
#
# ==========================================================================
#
# ZoneMinder Event Watch Script, $Date$, $Revision$
# ~ asker
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
#
# ==========================================================================
#
# This script checks for the last LAST_COUNT events that were created since
# last check time and returns the Id and Name. This puts in a framework for 
# doing push notifications or any other action if a new event is detected
#
use strict;
use bytes;

# ==========================================================================
#
# These are the elements you can edit to suit your installation
#
# ==========================================================================

use constant SLEEP_DELAY=>10; # duration in seconds after which this script will check for new events
use constant EVENT_COUNT=>10; # number of latest events to reurn

# Modify this subroutine to process the new events
sub ProcessNewEvents
{
# You will receive a list of new event Id and Name in this subroutine
# since last check. You should process them as fit 

#	my @aref = @_;
#	foreach  (@aref)
#	{
#		my $elem=$_;
#		print ($elem->{Id},":",$elem->{Name},"\n");
#	}
}

# ==========================================================================
#
# Don't change anything below here
#
# ==========================================================================

use lib '/usr/local/lib/x86_64-linux-gnu/perl5';
use ZoneMinder;
use POSIX;
use DBI;
use Data::Dumper;

$| = 1;

$ENV{PATH}  = '/bin:/usr/bin';
$ENV{SHELL} = '/bin/sh' if exists $ENV{SHELL};
delete @ENV{qw(IFS CDPATH ENV BASH_ENV)};

sub Usage
{
    print( "
Usage: zmeventnotification.pl
");
	exit( -1 );
}

logInit();
logSetSignal();

Info( "Event Notification daemon  starting\n" );

my $dbh = zmDbConnect();

# when the script first starts, the last eventcount is 1, which basically means
# return the latest EVENT_COUNT  events recorded. But after that, it will remember the latest event Id
# and only return events greater than this value

my $curId=1;

while( 1 )
{
	my $sql = "(select Id,Name from Events where Id>$curId ORDER BY Id DESC LIMIT ".EVENT_COUNT.") order by Id ASC;";
	my $sth = $dbh->prepare_cached( $sql ) or Fatal( "Can't prepare '$sql': ".$dbh->errstr() );
	Info("Checking for events since last recorded event Id of $curId");
	my $now = time();
	my $res = $sth->execute() or Fatal( "Can't execute: ".$sth->errstr() );
	my @arr=();
	while( my $data = $sth->fetchrow_hashref() )
	{
		Info ("New Event received: ", $data->{Id}," ", $data->{Name});
		$curId=$data->{Id};
		push @arr, $data;
		
        }
	ProcessNewEvents(@arr) if ($#arr>0);
	sleep( SLEEP_DELAY);
}
Info( "Event Notification daemon exiting\n" );
exit();
