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

#Filter down to only sip channels
foreach my $chan (keys %{$chans}) {
	delete $chans->{$chan} unless ($chan =~ /^SIP/);
}

die "Could not get list of channels" unless ($chans);

while (my ($chan, $info) = each %{$chans}) {

	my $stat = $astman->chan_status($chan);
	die "Could not stat channel $chan" unless ($stat);

	#Compare the outputs of chan_status and channels
	#Channels does not have the channel key
	delete $stat->{'Channel'};

	#channels vs chan_status
	my @notinstat = grep { !($info->{$_} ~~ $stat->{$_}) } keys %{$info};
	#chan_status vs channels
	my @notininfo = grep { !($stat->{$_} ~~ $info->{$_}) } keys %{$stat};

	if (@notinstat || @notininfo) {
		die "The following keys did not match from channels: @notinstat\nThe following keys did not match from chan_status: @notininfo\n";
	} else {
		print "Hashes match for channel $chan\n";
	}
}

#set_var and get_var tests
foreach my $chan (keys %{$chans}) {
	my %vars = (	TestVar1 => 1,
			TestVar2 => 2,
			TestVar3 => 3,
			TestVar4 => 4,
			TestVar5 => 5 );

	#Set channel variables
	print "Setting channel variables on $chan\n";
	while (my ($var, $val) = each %vars) {
		die "Unable to set $var to $val on $chan" unless ($astman->set_var($chan, $var, $val));
	}
	print "Channel variables set OK on $chan\n";

	#Retrieve and verify values
	print "Retrieving channel variables on $chan\n";
	while (my ($var, $val) = each %vars) {
		die "Unable to get $var on $chan" unless ($val ~~ $astman->get_var($chan, $var));
	}
	print "All channel variables match up OK on $chan\n";

}

#DTMF Tests
foreach my $chan (keys %{$chans}) {
	die "Unable to que DTMF on $chan" unless ($astman->play_dtmf($chan, 1));
	print "Queued DTMF 1 on $chan OK\n";

	my @digits = ( 1, 2, 3, 4, 5, 6, 7, 8, 9 );
	die "Unable to que DTMF on $chan" unless ($astman->play_digits($chan, \@digits));
	print "Queued DIGITS @digits on $chan OK\n";

}

#Bug in Asterisk 1.8 causes this to fail Issue #18285
#Submitted patch that fixes this in Asterisk
#Texting test
#foreach my $chan (keys %{$chans}) {
#	die "Unable to send text on $chan" unless ($astman->text($chan, "Hello There"));
#	print "Sent text on $chan OK\n";
#}

#muting tests
if (defined($astman->amiver()) && $astman->amiver() >= 1.1) {

	foreach my $chan (keys %{$chans}) {
		die "Unable to mute $chan" unless ($astman->mute_chan($chan));
		print "Muted $chan OK\n";

		die "Unable to unmute $chan" unless ($astman->unmute_chan($chan));
		print "UnMuted $chan OK\n";
	}

} else {
	print "Skipped muting tests because AMI version requirment not met\n";
}

#monitor tests
foreach my $chan (keys %{$chans}) {
	die "Unable to start monitor on $chan" unless ($astman->monitor($chan,'testfile1.wav'));
	print "Started monitor on $chan started OK\n";

	die "Unable to pause monitor on $chan" unless ($astman->monitor_pause($chan));
	print "Paused monitor on $chan OK\n";

	die "Unable to unpause monitor on $chan" unless ($astman->monitor_unpause($chan));
	print "Unpaused monitor on $chan OK\n";

	die "Unable to change monitor on $chan" unless ($astman->monitor_change($chan,'testfile2.wav'));
	print "Changed monitor on $chan OK\n";

	die "Unable to stop monitor on $chan" unless ($astman->monitor_stop($chan));
	print "Stopped monitor on $chan OK\n";

}

#chan_timeout test
foreach my $chan (keys %{$chans}) {
	die "Unable to set timeout on $chan" unless ($astman->chan_timeout($chan, 3600));
	print "Set timeout on $chan OK\n";
}

#Bug in Asterisk 1.8 breaks this Issue #18230
#transfer test
#if (defined($astman->amiver()) && $astman->amiver() >= 1.1) {
#	foreach my $chan (keys %{$chans}) {
#		die "Unable to transfer $chan" unless ($astman->transfer($chan, 11, 'mohtest'));
#		print "Transfered $chan OK\n";
#	}
#} else {
#	print "Skipping texting test, AMI version requirment not met\n";
#}

#parktest
foreach my $chan (keys %{$chans}) {
	die "Unable to Park $chan" unless ($astman->park($chan, $chan));
	print "Parked $chan OK\n";
}

#hangup test
foreach my $chan (keys %{$chans}) {
	die "Unable to hangup $chan" unless ($astman->hangup($chan));
	print "Hungup $chan OK\n";
}
