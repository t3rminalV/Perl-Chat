#!/usr/bin/perl

use strict;
#use warnings;
use English;
use IO::Socket;
use Sys::Hostname;
use Term::ANSIColor;

my $choice; 
my $host;
my $port = 7070;
my $new_sock;
my $line;
my $kidpid;
my $response;
my $peer;
local $| = 1; 
my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst);
my $quit = 0;
my $discon = 0;
my $error = 0;
my $saves = 0;
my $filename = returntime();
my $addr1=`/sbin/ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}'`;
my $addr = substr($addr1, 0, -6);
my $header = <<END;
###########################################################
##                                                       ##
           Perl Peer-to-Peer Chat Application            

                Written by Adam McKissock                

                      For CE0912A                        

                  IP: $addr                            
##                                                       ##
###########################################################
END

sub menu() 
{
	if ($error == 1)
	{
		print color("red");
		print "Connection to $host failed.\n\n";
		print color("reset");
		$error = 0;
	} 
	elsif ($discon == 0) 
	{
		print "Please select an option:\n\n";
	}
	elsif ($discon == 1)
	{
		print color("red");
		print "\nYou were Disconnected.\n\n";
		print color("reset");
		$discon = 0;
	}
	
	print "1)\t Connect to existing chat\n";
	print "2)\t Create new chat\n";
	if ($saves == 0)
	{
		print "3)\t Toggle Chat saves On\n"
	}
	elsif ($saves == 1)
	{
		print "3)\t Toggle Chat saves Off\n"
	}	
	print "4)\t Exit\n\n";
}

sub validIP() 
{
	if($host =~ m/^(\d\d?\d?)\.(\d\d?\d?)\.(\d\d?\d?)\.(\d\d?\d?)$/ && $1 <= 255 && $2 <= 255 && $3 <= 255 && $4 <= 255)
	{		
		return "true";
	}
	else 
	{
		return "false";
	}
}

sub returntime() 
{
	($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	if ($hour < 10) { $hour = "0$hour"; }
	if ($min < 10) { $min = "0$min"; }
	if ($mday < 10) { $mday = "0$mday"; }
	if ($mon < 10) { $mon = "0$mon"; }

	return "$hour$min-$mday$mon";
}


sub returntime2() 
{
	($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	if ($hour < 10) { $hour = "0$hour"; }
	if ($min < 10) { $min = "0$min"; }
	return "[$hour:$min]";
}

sub existingsession() 
{
	my $sock = new IO::Socket::INET (
		PeerAddr => $host,
		PeerPort => $port,
		Proto => 'tcp',
		Reuse => 1,
		Timeout => 10,
	);
	errorandrun() unless $sock;
	last unless $sock;
	print $sock "HSTNM $addr\n";
	if ($kidpid=fork())  
		{ 
			while (defined ($line = <$sock>))  
			{ 
				$peer = $host;
				if ($line =~ /HSTNM/)
				{
					$line =~ s/HSTNM//;
					#$peername = $line;
					#chomp($peername);
					system ("clear");
					print color("green");
					print "Conversation initiated with [$peer].\n\n";
					print color("reset");
				}
				else 
				{
					savelog($line, "0");
					print color("green");					
					print $line; 
					print color("reset");									
				}
			} 
			kill("TERM", $kidpid);  
		} 
		else  
		{ 
			while (defined ($response = <STDIN>))  
	  		{ 
	  			savelog($response, "1");
				print $sock "$response"; 								
	  		} 
		}
		$discon = 1; 
		$sock->close;
}

sub newsession() 
{
	print "Listening for conversations...\n";
	my $sock = new IO::Socket::INET (
		LocalHost => $addr,
		LocalPort => $port,
		Proto => 'tcp',
		Listen => 5,
		Reuse => 1,
	); 
	die "Could not create socket: $!\n" unless $sock;

	while ($new_sock = $sock->accept())
		{
		    if ($kidpid=fork())  
			{ 
				while (defined ($line = <$new_sock>))  
				{ 
					$peer = $new_sock->peerhost();
					if ($line =~ /HSTNM/)
					{
						$line =~ s/HSTNM//;
						#$peername = $line;
						#chomp($peername);
						system ("clear");
						print color("green");
						print "Conversation incoming from [$peer].\n\n";
						print color("reset");
						print $new_sock "HSTNM\n";
					}
					else 
					{
						savelog($line, "0");
						print color("green");										
						print $line;
						print color("reset");					
					}
				} 
				kill("TERM", $kidpid);  
			} 
			else  
			{ 
				print color("green");
				while (defined ($response = <STDIN>))  
		  		{ 
		  			savelog($response, "1");
					print $new_sock "$response";					
		  		} 
		  		print color("reset");
			} 
			$discon = 1;
			$new_sock->close;
		}	
}

sub errorandrun() 
{
	$error = 1;
	runlooper();
}

sub togglesaves() 
{
	if ($saves == 0)
	{
		$saves = 1;
		system ("clear");
		print $header;
	}
	elsif ($saves == 1)
	{
		$saves = 0;
		system ("clear");
		print $header;
	}
}

sub savelog()
{
	if ($saves == 1)
	{	
		my $timestamp = returntime2();		
		open FILE, "+>>", "$filename" or die $!;	
			if ($_[1] == "1")
			{
				print FILE "$timestamp (you): $_[0]";
			}
			elsif ($_[1] == "0")
			{
				print FILE "$timestamp (partner): $_[0]";
			}
		close FILE;
	}
}

sub go() 
{
	system ("clear");
	print $header;
	menu();
	do {
		$choice = <STDIN>;
		chomp($choice);
		if ($choice == 1) 
		{
			do 
			{
				system ("clear");
				print $header;
				print "Please enter an IPv4 address to attempt communications with.\n";
				$host = <STDIN>;
				chomp($host);
			} while (validIP() eq 'false');
			
				print "Host is valid, attempting to start chat.\n";
				existingsession();
		}
		elsif ($choice == 2) 
		{
			system("clear");
			newsession();
		}
		elsif ($choice == 3)
		{
			togglesaves();
		}
		elsif ($choice == 4) 
		{
			$quit = 1;
		}
		else 
		{
			#Otherwise choice invalid.
			print "Invalid choice\n";
		}

	} while (($choice != 1) && ($choice != 2) && ($choice != 3));
}

loop();

sub loop() 
{
	while ($quit == 0)
	{
		go();
	}
}
