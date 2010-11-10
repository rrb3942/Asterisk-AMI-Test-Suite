#!/usr/bin/perl

use Asterisk::AMI::Common;
use Data::Dumper;

use strict;
use warnings;

#Database to replicate
my %database = ( TestFamily => { TestKey1 => 1,
				 TestKey2 => 2,
				 TestKey3 => 3,
				 TestKey4 => 4,
				 TestKey5 => 5 });


my $astman = Asterisk::AMI::Common->new( PeerAddr => '192.168.56.3',
					 username => 'test',
					 secret => 'work');

die "Unable to connect to asterisk" unless ($astman);

#Remove Potential conflicting databases
foreach (keys %database) {
	die "Failed to remove database $_" unless ($astman->db_deltree($_));
}

#Populate database
foreach my $family (keys %database) {
	while (my ($key, $val) = each %{$database{$family}}) {
		die "Unable to insert $family/$key with value $val" unless ($astman->db_put($family, $key, $val));
		print "Inserted $family/$key with value $val\n";
	}
}

#Check values
foreach my $family (keys %database) {
	while (my ($key, $val) = each %{$database{$family}}) {
		my $retval = $astman->db_get($family, $key, $val);

		if (!defined $retval) {
			die "Unable to retrive $family/$key";
		}

		if ($retval != $val) {
			print "db_get value for $family/$key does not match (should be $val was $retval)\n";
		} else {
			print "db_get value for $family/$key matches\n";
		}
	}
}

#Get database via db_show
my $db = $astman->db_show();

die "Unable to retrieve database" unless ($db);
#Compare it to what we think it should be
foreach my $family (keys %database) {
	my %dbfam = %{$db->{$family}};
	while (my ($key, $val) = each %{$database{$family}}) {
		if ($dbfam{$key} != $val) {
			print "db_show value for $family/$key does not match (should be $val was $dbfam{$key})\n";
		} else {
			print "db_show value for $family/$key matches\n";
		}
	}
}

#Delete entries with db_del
foreach my $family (keys %database) {
	foreach my $key (keys %{$database{$family}}) {
		die "Unable to delete $family/$key" unless ($astman->db_del($family, $key));
	}
}

#Check values after delete
foreach my $family (keys %database) {
	while (my ($key, $val) = each %{$database{$family}}) {
		my $retval = $astman->db_get($family, $key, $val);

		if (!defined $retval) {
			print "db_del Succesfully deleted $family/$key\n";
			next;
		}

		if ($retval != $val) {
			print "db_del failed and value for $family/$key does not match (should be $val was $retval)\n";
		} else {
			print "db_del failed and value for $family/$key matches\n";
		}
	}
}

#Re-Populate database for deltree
foreach my $family (keys %database) {
	while (my ($key, $val) = each %{$database{$family}}) {
		die "Unable to insert $family/$key with value $val" unless ($astman->db_put($family, $key, $val));
	}
}

#Final Cleanup
foreach (keys %database) {
	die "Failed to remove database $_" unless ($astman->db_deltree($_));
}

#Check values after delete
foreach my $family (keys %database) {
	while (my ($key, $val) = each %{$database{$family}}) {
		my $retval = $astman->db_get($family, $key, $val);

		if (!defined $retval) {
			print "db_deltree succesfully deleted $family/$key\n";
			next;
		}

		if ($retval != $val) {
			print "db_deltree failed and value for $family/$key does not match (should be $val was $retval)\n";
		} else {
			print "db_deltree failed and value for $family/$key matches\n";
		}
	}
}
