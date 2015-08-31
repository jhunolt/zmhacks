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

use constant SLEEP_DELAY=>5; # duration in seconds after which this script will check for new events
use constant EVENT_COUNT=>10; # number of latest events to reurn
use constant MONITOR_RELOAD_INTERVAL => 300;

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
my %monitors;
my $monitor_reload_time = 0;


while (1)
{

	if ( (time() - $monitor_reload_time) > MONITOR_RELOAD_INTERVAL )
    	{
		print ("Reloading Monitors...\n");
		foreach my $monitor (values(%monitors))
		{
			zmMemInvalidate( $monitor );
		}
		loadMonitors();
	}

	foreach my $monitor ( values(%monitors) )
	{ 
		my ( $state, $last_event )
		    = zmMemRead( $monitor,
				 [ "shared_data:state",
				   "shared_data:last_event"
				 ]
		);
		if ($state == STATE_ALARM || $state == STATE_ALERT)
		{
			if ( !defined($monitor->{LastEvent})
                 	     || ($last_event != $monitor->{LastEvent}))
			{
				print "\nNew Event $last_event FOR MONITOR ".$monitor->{Name};
				$monitor->{LastState} = $state;
				$monitor->{LastEvent} = $last_event;
			}
			else
			{
					}
		}
	}
	sleep (SLEEP_DELAY);
}
Info( "Event Notification daemon exiting\n" );
exit();

sub loadMonitors
{
    Debug( "Loading monitors\n" );
    $monitor_reload_time = time();

    my %new_monitors = ();

    my $sql = "SELECT * FROM Monitors
               WHERE find_in_set( Function, 'Modect,Mocord,Nodect' )"
    ;
    my $sth = $dbh->prepare_cached( $sql )
        or Fatal( "Can't prepare '$sql': ".$dbh->errstr() );
    my $res = $sth->execute()
        or Fatal( "Can't execute: ".$sth->errstr() );
    while( my $monitor = $sth->fetchrow_hashref() )
    {
	print ("Found one \n");
        next if ( !zmMemVerify( $monitor ) ); # Check shared memory ok
	print ("Good one \n");

        if ( defined($monitors{$monitor->{Id}}->{LastState}) )
        {
            $monitor->{LastState} = $monitors{$monitor->{Id}}->{LastState};
        }
        else
        {
            $monitor->{LastState} = zmGetMonitorState( $monitor );
        }
        if ( defined($monitors{$monitor->{Id}}->{LastEvent}) )
        {
            $monitor->{LastEvent} = $monitors{$monitor->{Id}}->{LastEvent};
        }
        else
        {
            $monitor->{LastEvent} = zmGetLastEvent( $monitor );
        }
        $new_monitors{$monitor->{Id}} = $monitor;
    }
    %monitors = %new_monitors;
}
