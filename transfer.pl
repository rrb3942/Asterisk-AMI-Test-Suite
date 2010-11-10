#!/usr/bin/perl

use Asterisk::AMI::Common;
use Data::Dumper;

use strict;
use warnings;

my $astman = Asterisk::AMI::Common->new( PeerAddr => '192.168.56.3',
					 username => 'test',
					 secret => 'work');

die "Unable to connect to asterisk" unless ($astman);

#Channel information tests, channels() and chan_status()
my $chans = $astman->channels();

die "Could not get list of channels" unless ($chans);

#transfer test
foreach my $chan (keys %{$chans}) {
	next unless ($chan =~ /^SIP/);
	die "Unable to transfer $chan" unless ($astman->transfer($chan, 11, 'mohtest'));
	print "Transfered $chan OK\n";
}
