package Devel::Probe;
use strict;
use warnings;

use XSLoader;
use Path::Tiny;

use constant {
    PROBE_CONFIG_NAME  => '/tmp/devel-probe-config.cfg',
    PROBE_SIGNAL_NAME  => 'HUP',
};

our $VERSION = '0.000002';
XSLoader::load( 'Devel::Probe', $VERSION );

my %known_options = map +( $_ => 1 ), qw/
    signal_name
    skip_install
    config_file
    check_config_file
/;

my $config_file = PROBE_CONFIG_NAME;

sub import {
    my ($class, @opts) = @_;

    my %options = @opts;
    foreach my $option (keys %options) {
        die "Unrecognized option $option" unless exists $known_options{$option};
    }

    if ($options{config_file}) {
        $config_file = $options{config_file};
    }
    my $signal_name = $options{signal_name} // PROBE_SIGNAL_NAME;
    $SIG{$signal_name} = \&Devel::Probe::check_config_file;

    if (!$options{skip_install}) {
        Devel::Probe::install();
        check_config_file("_IMPORT_") if $options{check_config_file};
    }
}

sub check_config_file {
    my ($signal_name) = @_;

    printf STDERR ("PROBE check %s %s\n", $signal_name, time());
    Devel::Probe::disable();
    while (1) {
        my $path = Path::Tiny::path($config_file);
        last unless $path && $path->is_file();

        my @lines = $path->lines();
        foreach my $line (@lines) {
            next if $line =~ m/^\s*[#]?\s*$/;
            my @fields = split(' ', $line);
            next unless @fields;
            my $op = shift @fields;
            if ($op eq 'enable') {
                Devel::Probe::enable();
                next;
            }
            if ($op eq 'disable') {
                Devel::Probe::disable();
                next;
            }
            if ($op eq 'dump') {
                Devel::Probe::dump();
                next;
            }
            if ($op eq 'clear') {
                Devel::Probe::clear();
                next;
            }
            if ($op eq 'probe') {
                next unless @fields;

                my $file = shift @fields;
                printf STDERR ("PROBE file [%s]\n", $file);

                next unless @fields;
                foreach my $line (@fields) {
                    printf STDERR ("PROBE line [%d]\n", $line);
                    Devel::Probe::add_probe($file, $line);
                }
                next;
            }
        }
        last;
    }
}


1;
__END__

=pod

=encoding utf8

=head1 NAME

Devel::Probe - Quick & dirty code probes for Perl

=head1 VERSION

Version 0.000002

=head1 SYNOPSIS

    use Devel::Probe;
    # or
    use Devel::Probe (check_config_file => 0);
    # or
    use Devel::Probe (check_config_file => 1);
    # or
    use Devel::Probe (skip_install => 0);
    # or
    use Devel::Probe (skip_install => 1);
    ...

    Devel::Probe::trigger(sub {
        my ($file, $line) = @_;
        # probe logic
    });

=head1 DESCRIPTION

Use this module to allow the possibility of creating probes for some lines in
your code.

By default the probing code is installed when you import the module, but if you
import it with C<skip_install =E<gt> 1> the code is not installed at all
(useful for benchmarking the impact of loading the module with no active
probes).

By default the probing is disabled, but if you import the module with
C<check_config_file =E<gt> 1>, it will immediately check for a configuration
file, as when reacting to a signal (see below).

When your process receives a  specific signal (C<SIGHUP> by default), this
module will check for the existence of a configuration file
(C</tmp/devel-probe-config.cfg> by default).  If that file exists, it must
contain a list of directives for the probing.  If the configuration file
enables probing, after sending a signal to the process it will start checking
for probes.

The directives allowed in the configuration file are:

=over 4

=item * enable

Enable probing.

=item * disable

Disable probing.

=item * clear

Clear current list of probes.

=item * dump

Dump current list of probes to stderr.

=item * probe file line line...

Add a probe for the given file in each of the given lines.

=back

=head1 EXAMPLE

This will invoke the C<trigger> callback whenever line 14 executes, and use
C<PadWalker> to dump the local variables.

    # in my_cool_script.pl
    use Data::Dumper qw(Dumper);
    use PadWalker qw(peek_my);
    use Devel::Probe (check_config_file => 1);

    Devel::Probe::trigger(sub {
        my ($file, $line) = @_;
        say Dumper(peek_my(1)); # 1 to jump up one level in the stack;
    });

    my $count;
    while (1) {
        $count++;
        my $something_inside_the_loop = $count * 2;
        sleep 5;
    }

    # /tmp/devel-probe-config.cfg
    enable
    probe my_cool_script.pl 13

=head1 TODO

=over 4

=item

Probes are stored in a hash of file names; per file name, there is a hash
of line numbers (with 1 or 0 as a value).  It is likely this can be made more
performant with a better data structure, but that needs profiling.

=back


=head1 AUTHORS

=over 4

=item * Gonzalo Diethelm C<< gonzus AT cpan DOT org >>

=item * Ben Tyler C<< btyler AT cpan DOT org >>

=back
