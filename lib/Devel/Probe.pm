package Devel::Probe;
use strict;
use warnings;

use Storable qw(dclone);
use XSLoader;
use Carp qw(croak);

our $VERSION = '0.000004';
XSLoader::load( 'Devel::Probe', $VERSION );

sub import {
    my ($class) = @_;
    Devel::Probe::install();
}

use constant {
    NONE => 0,
    ONCE => 1,
    PERMANENT => 2,
};

sub config {
    my ($config) = @_;

    Devel::Probe::disable();
    return unless $config;

    foreach my $action (@{ $config->{actions} }) {
        if ($action->{action} eq 'enable') {
            Devel::Probe::enable();
            next;
        }
        if ($action->{action} eq 'disable') {
            Devel::Probe::disable();
            next;
        }
        if ($action->{action} eq 'clear') {
            Devel::Probe::clear();
            next;
        }
        if ($action->{action} eq 'define') {
            my $file = $action->{file};
            next unless $file;

            my $type = $action->{type} // ONCE;
            if ($type ne ONCE && $type ne PERMANENT) {
                croak sprintf("'%s' is not a valid probe type: try Devel::Probe::ONCE|PERMANENT", $type);
            }
            foreach my $line (@{ $action->{lines} // [] }) {
                Devel::Probe::add_probe($file, $line, $type);
            }
            next;
        }
    }
}

sub dump {
    return dclone(Devel::Probe::_internal_probe_state());
}

1;
__END__

=pod

=encoding utf8

=head1 NAME

Devel::Probe - Quick & dirty code probes for Perl

=head1 VERSION

Version 0.000004

=head1 SYNOPSIS

    use Devel::Probe;
    ...
    Devel::Probe::trigger(sub {
        my ($file, $line) = @_;
        # probe logic
    });
    Devel::Probe::config(%config);
    ...
    Devel::Probe::enable();
    ...
    Devel::Probe::disable();

=head1 DESCRIPTION

Use this module to allow the possibility of creating probes for some lines in
your code.

The probing code is installed when you import the module, and it is disabled.
In these conditions, the probe code is light enough that it should cause no
impact at all in your CPU usage.

=head1 FUNCTIONS

=over 4

=item * C<trigger(\&coderef)>

Specify a piece of Perl code that will be called for every probe that triggers.

=item * C<config(\%config)>

Specify a configuration for the module, including what lines in your code will
cause probes to be triggered.  This call will always disable the module as a
first action, so you always need to explicitly enable it again, either from the
configuration itself or in a further call to C<enable()>.

=item * C<add_probe(file, line, type)>

Manually add a probe; this is what gets called from C<config()>.

=item * C<enable()> / C<disable()>  / C<is_enabled()>

Dynamically activate and deactivate probing, and check this status.

=item * C<install()> / C<remove()> / C<is_installed()>

Install or remove the probe handling code, and check this status.  When you
import the module, C<install()> is called automatically for you.

=item * C<clear()>

Remove all probes.

=item * C<dump()>

Print all probes to stderr.

=back

=head1 CONFIGURATION

An example configuration hash looks like this:

    my %config = (
        actions => [
            { action => 'disable' },
            { action => 'clear' },
            { action => 'define' ... },
            { action => 'dump' },
            { action => 'enable' },
        ],
    );

Possible actions are:

=over 4

=item * C<disable>: disable probing.

=item * C<clear>: clear current list of probes.

=item * C<dump>: dump current list of probes to stderr.

=item * C<enable>: enable probing.

=item * C<define>: define a new probe.  A full define action looks like:

    my %define = (
        action => 'define',
        type => PROBE_TYPE,
        file => 'file_name',
        lines => [ 10, 245, 333 ],
    );

The type field is optional and its default value is C<once>.  Possible values
are:

=over 4

=item * C<once>: the probe will trigger once and then will be destroyed right
after that.

=item * C<permanent>: the probe will trigger every time that line of code is
executed.

=back

=back

=head1 EXAMPLE

This will invoke the C<trigger> callback the first time line 21 executes, and
take advantage of C<PadWalker> to dump the local variables.

    use Data::Dumper qw(Dumper);
    use PadWalker qw(peek_my);
    use Devel::Probe;

    Devel::Probe::trigger(sub {
        my ($file, $line) = @_;
        say Dumper(peek_my(1)); # 1 to jump up one level in the stack;
    });

    my %config = (
        actions => [
            { action => 'define', # type is 'once' by default
              file => 'probe my_cool_script.pl', lines => [ 21 ] },
        ],
    );
    Devel::Probe::config(\%config);
    Devel::Probe::enable();
    my $count;
    while (1) {
        $count++;
        my $something_inside_the_loop = $count * 2; # line 21
        sleep 5;
    }
    Devel::Probe::disable();

=head1 SUGGESTIONS

One typical use case would be to have a signal handler associated with a
specific signal, which when triggered would disable the module, read the
configuration from a given place, reconfigure the module accordingly and then
enable it.

Another use case could be a similar kind of control using remote endpoints to
deal with reconfiguring, disabling and enabling the module.

=head1 TODO

=over 4

=item

Probes are stored in a hash of file names; per file name, there is a hash
of line numbers (with the probe type as a value).  It is likely this can be
made more performant with a better data structure, but that needs profiling.

=back

=head1 AUTHORS

=over 4

=item * Gonzalo Diethelm C<< gonzus AT cpan DOT org >>

=item * Ben Tyler C<< btyler AT cpan DOT org >>

=back
