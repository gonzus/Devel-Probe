use strict;
use warnings;

use Data::Dumper;

use Path::Tiny ();
use JSON::XS   ();
use Test::More;
use Test::Output;

use Devel::Probe (check_config_file => 0);

my @triggered;
my %trigger_lines = (
    default   => [qw/ 26 /],
    once      => [qw/ 27 /],
    permanent => [qw/ 28 /],
);

exit main();

sub run {
    my ($run) = @_;

    @triggered = ();
    my $x = 1;          # probe #1
    my $y = 2;          # probe #2
    my $z = $x + $y;    # probe #3

    my @got;
    my @expected;
    if ($run > 0) {
        foreach my $type (keys %trigger_lines) {
            if (($run == 1) || ($run > 1 && $type eq 'permanent')) {
                push @expected, @{ $trigger_lines{$type} };
            }
        }
        push @got, map { $_->[1] } @triggered;
    }
    @got = sort @got;
    @expected = sort @expected;
    is_deeply(\@got, \@expected, sprintf("probe triggered for run %d in all %d expected lines and nowhere else", $run, scalar @expected));
}

sub config {
    my @defines;
    foreach my $type (keys %trigger_lines) {
        my %define = (
            action => 'define',
            file => 't/007-trigger.t',  # this file
            lines => $trigger_lines{$type},
        );
        if ($type eq 'default') {
            # don't set it explicitly
        } elsif ($type eq 'once') {
            $define{type} = Devel::Probe::PROBE_TYPE_ONCE;
        } elsif ($type eq 'permanent') {
            $define{type} = Devel::Probe::PROBE_TYPE_PERMANENT;
        }
        push @defines, \%define;
    }
    my $config = {
        actions => [
            { action => 'disable' },
            { action => 'clear' },
            @defines,
            { action => 'dump' },
            { action => 'enable' },
        ],
    };
    my $tmp = Path::Tiny->tempfile();
    $tmp->spew(JSON::XS->new->utf8->encode($config));
    Devel::Probe::set_config_name($tmp);

    Devel::Probe::trigger(sub {
        my ($file, $line) = @_;
        push @triggered, [ $file, $line ];
    });

    my $stderr = stderr_from {
        Devel::Probe::check_config_file();
    };
    foreach my $type (keys %trigger_lines) {
        foreach my $line (@{ $trigger_lines{$type} }) {
            like($stderr, qr/dump line \[$line\]/, "probe dump contains line $line, type $type");
        }
    }
}

sub main {
    foreach my $run (0..3) {
        run($run);
        config() if $run == 0;
    }

    done_testing;
    return 0;
}
