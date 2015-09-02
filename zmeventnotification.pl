#!/usr/bin/perl -wT
#
# ==========================================================================
#
# ZoneMinder Event Watch Script, $Date$, $Revision$
#
# A very light weight event notification daemon
# Uses shared memory to detect new events (polls SHM)
# Also opens a websocket connection at a configurable port
# so events can be reported
# Any client can connect to this web socket and handle it further
# for example, send it out via APNS/GCM or any other mechanism
#
# This is a much  faster and low overhead method compared to zmfilter
# as there is no DB overhead nor SQL searches for event matches

# ~ PP
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
use strict;
use bytes;
use Net::WebSocket::Server;

# ==========================================================================
#
# These are the elements you can edit to suit your installation
#
# ==========================================================================

use constant SLEEP_DELAY=>5; # duration in seconds after which we will check for new events
use constant MONITOR_RELOAD_INTERVAL => 300;
use constant EVENT_NOTIFICATION_PORT=>9000; # port for Websockets connection



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
    	print( "This daemon is not meant to be invoked from command line\n");
	exit( -1 );
}

logInit();
logSetSignal();

Info( "Event Notification daemon  starting\n" );

my $dbh = zmDbConnect();
my %monitors;
my $monitor_reload_time = 0;
my $wss;
my $evt_str="";

initSocketServer();
Info( "Event Notification daemon exiting\n" );
exit();


sub checkEvents()
{

	my $eventFound = 0;
	$evt_str="";
	if ( (time() - $monitor_reload_time) > MONITOR_RELOAD_INTERVAL )
    	{
		Debug ("Reloading Monitors...\n");
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
				Info( "New event $last_event reported for ".$monitor->{Name}."\n");
				$monitor->{LastState} = $state;
				$monitor->{LastEvent} = $last_event;
				$evt_str = $evt_str.$monitor->{Name}.":".$monitor->{Id}.":".$last_event.",";
				$eventFound = 1;
			}
			
		}
	}
	return ($eventFound);
}

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
        next if ( !zmMemVerify( $monitor ) ); # Check shared memory ok

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

sub initSocketServer
{
	checkEvents();
	Info ("Web Socket Event Server listening on port ".EVENT_NOTIFICATION_PORT."\n");
	$wss = Net::WebSocket::Server->new(
		listen => EVENT_NOTIFICATION_PORT,
		tick_period => SLEEP_DELAY,
		on_tick => sub {
			if (checkEvents())
			{
				print ("EVENT: $evt_str\n");
				#	my ($serv) = @_;
				#	$_->send_utf8(time) for $serv->connections;
			}
		},
	)->start;
}
