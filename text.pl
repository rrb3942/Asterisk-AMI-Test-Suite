#!/usr/bin/perl

use Asterisk::AMI::Common;
use Data::Dumper;

use strict;
use warnings;

my $astman = Asterisk::AMI::Common->new( PeerAddr => '192.168.56.3',
					 username => 'test',
					 secret => 'work');

die "Unable to connect to asterisk" unless ($astman);

#Get our channels
my $chans = $astman->channels();

die "Could not get list of channels" unless ($chans);

#Texting test
foreach my $chan (keys %{$chans}) {
	warn "Unable to send text on $chan" unless ($astman->text($chan, "Hello There"));
	my $reason = $astman->get_var($chan, 'SENDTEXTSTATUS');
	print "Reason on $chan was $reason\n";
	#print "Sent text on $chan OK\n";
}

#monitor tests

#text test

#transfer test

#parktest

#chan_timeout

#last is testing hangup
