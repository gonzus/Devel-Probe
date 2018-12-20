package Devel::Probe;
use strict;
use warnings;

use XSLoader;

our $VERSION = '0.000001';

XSLoader::load( 'Devel::Probe', $VERSION );

sub import {
    my ($class, @opts) = @_;

    croak('Invalid argument to import, it takes key-value pairs. FOO => BAR')
        if 1 == @opts % 2;

    $SIG{'HUP'} = \&Devel::Probe::check;

    my %options = @opts;
    Devel::Probe::install(\%options);
}

1;
__END__

=pod

=encoding utf8

=head1 NAME

Devel::Probe - Quick & dirty code probes for Perl

=head1 VERSION

Version 0.000001

=head1 SYNOPSIS

    use Devel::Probe;
    # or
    use Devel::Probe (check => 0);
    # or
    use Devel::Probe (check => 1);
    ...

    Devel::Probe::trigger(sub {
        my ($file, $line) = @_;
        # probe logic
    });

=head1 DESCRIPTION

Use this module to allow the possibility of creating probes for some lines in
your code.

By default the probing is disabled, but if you import the module with C<check
=E<gt> 1>, it will immediately check for a configuration file, as when reacting
to C<SIGHUP> (see below).  Using C<check =E<gt> 0> is equivalent to the
default, but explicit.

When your process receives a C<SIGHUP>, this module will check for the
existence of a configuration file (C</tmp/devel-probe-config.cfg> by default).
If that file exists, it must contain a list of directives for the probing.
Therefore, if the configuration file enables probing, after sending C<SIGHUP>
to the process it will act as if you had used the module with C<check =E<gt>
1>.

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
    use Devel::Probe (check => 1);

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
