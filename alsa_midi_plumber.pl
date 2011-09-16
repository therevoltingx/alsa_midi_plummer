use warnings;
use strict;


my $APPNAME = "alsa_midi_plumber";
my $VERSION = 0.01;
my @AUTHORS = ( {NAME => 'Miguel Morales', EMAIL => 'therevoltingx@gmail.com'} );

my $VERBOSE = 1;

my $rules_file = $ARGV[0];

if (!$rules_file)
	{
	print_usage();
	exit();
	}
while (1)
{
	printf "Reading rules from: %s.\n", $rules_file;

	my ($inputs, $outputs) = generate_ports();
	open (RULES, $rules_file) || die sprintf "Failed to open: %s\n", $rules_file;
	while (my $line = <RULES>)
		{
		next if $line =~ /^#/;	#skip comments
		next if !$line;		#skip blank lines
		#printf "Processing: %s\n", $line;
		my ($command, $input_string, $output_string) = $line =~ /\((\w*)\ \"(.*)\"\ \"(.*)\"\)/;
		#print "Command: $command\tInput String: $input_string\tOutput String: $output_string\n";
		process($command, $input_string, $output_string, $inputs, $outputs);
		}
	close(RULES);
sleep(3);
}

sub process
{
my ($command, $input_string, $output_string, $inputs, $outputs) = @_;
my @matched_inputs;


my ($top_dev_in, $sub_dev_in) = split(':', $input_string);
my ($top_dev_out_string, $sub_dev_out_string) = split(':', $output_string);
foreach my $id (keys %$inputs)
	{
	#printf "Device Name: %s\n", $inputs->{$id}->{NAME};
	if ($inputs->{$id}->{NAME} =~ /$top_dev_in/i)
		{
		foreach my $sub_dev (@{$inputs->{$id}->{DEVICES}})
			{
			#print Dumper($sub_dev);
 			#print "Name: " . $sub_dev->{NAME} . "\n";
			if ($sub_dev->{NAME} =~ /$sub_dev_in/i)
				{
				printf "Matched Connection: %s:%s - %s:%s\n", $top_dev_in, $sub_dev_in, $inputs->{$id}->{NAME}, $sub_dev->{NAME};
				#connect this port to any matching output ports...
				my $matched_input_port = $id . ":" . $sub_dev->{ID};
				foreach my $out_id (keys %$outputs)
					{
					if ($outputs->{$out_id}->{NAME} =~ /$top_dev_out_string/i)
						{
						foreach my $out_sub_dev (@{$outputs->{$out_id}->{DEVICES}})
							{
							if ($out_sub_dev->{NAME} =~ /$sub_dev_out_string/i)
								{
								printf "Matched Connection: %s:%s - %s:%s\n", $top_dev_out_string, $sub_dev_out_string, $outputs->{$id}->{NAME}, $out_sub_dev->{NAME};
								print "Connecting: " . $inputs->{$id}->{NAME} . ":" .  $sub_dev->{NAME} . 
									"to " . $outputs->{$out_id}->{NAME} . ":". $out_sub_dev->{NAME} . "\n";
								my $connect_string = sprintf "%s:%s %s:%s", $id, $sub_dev->{ID}, $out_id, $out_sub_dev->{ID};
								print "Executing: aconnect $connect_string\n";
								system("aconnect $connect_string");
								}
							}
						}
					}
				}
			}
		#printf "Matched: %s - %s\n", $inputs->{$id}->{NAME}, $top_dev_in;
		}
	}
}

sub generate_ports
{
my %inputs;
my %outputs;
my $current_id;	#keeps track of the section we're in
my @sub_devices;
#print "INPUTS:\n";
open (AC, "aconnect -il|") || die "failed to execute aconnect.";
while (my $line = <AC>)
	{
	#print $line;
	if (my ($top_id, $top_name) = $line =~ /client\ (\d*):\ \'(.*)\'/)
		{
		#print "Top-level client: $top_id, $top_name\n";
		$current_id = $top_id;
		$inputs{$current_id}->{NAME} = $top_name;
		}
	elsif (my ($sub_id, $sub_name) = $line =~ /\ *(\d*)\ *'(.*)'/)
		{
		my %sub_device;
		#print "\tSub-level client: $sub_id, $sub_name\n";	
		$sub_device{NAME} = $sub_name;
		$sub_device{ID} = $sub_id;
		push @{$inputs{$current_id}->{DEVICES}}, \%sub_device;
		}
	}
close (AC);
open (AC, "aconnect -ol|") || die "failed to execute aconnect.";
	#print Dumper(\%inputs);
while (my $line = <AC>)
	{
	#print $line;
	if (my ($top_id, $top_name) = $line =~ /client\ (\d*):\ \'(.*)\'/)
		{
		#print "Top-level client: $top_id, $top_name\n";
		$current_id = $top_id;
		$outputs{$current_id}->{NAME} = $top_name;
		}
	elsif (my ($sub_id, $sub_name) = $line =~ /\ *(\d*)\ *'(.*)'/)
		{
		my %sub_device;
		#print "\tSub-level client: $sub_id, $sub_name\n";	
		$sub_device{NAME} = $sub_name;
		$sub_device{ID} = $sub_id;
		push @{$outputs{$current_id}->{DEVICES}}, \%sub_device;
		}
	}
close(AC);
#print Dumper(\%outputs);
return (\%inputs, \%outputs);
}

sub print_usage
{
printf "%s V. %s\n", $APPNAME, $VERSION;
print "Brought to you by:\n";
foreach (@AUTHORS)
	{
	printf "(%s -> %s)\n", $_->{NAME}, $_->{EMAIL};
	}
}

__END__

=head1 alsa_midi_plumber.pl

Description Goes Here....

