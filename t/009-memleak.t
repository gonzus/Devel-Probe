use strict;
use warnings;
use Test::More;
use Devel::Probe;
use Devel::Leak;

my @probe = (__FILE__, 40, Devel::Probe::ONCE);
sub probe_cb { }

leak_test(sub {
        Devel::Probe::install();
        Devel::Probe::remove();
    }, 10000, "no memory leak in install/remove cycle"
);

leak_test(sub {
        Devel::Probe::install();
        Devel::Probe::enable();
        Devel::Probe::disable();
        Devel::Probe::remove();
    }, 10000,  "no memory leak in install/enable/disable/remove cycle"
);

leak_test(sub {
        Devel::Probe::install();
        Devel::Probe::add_probe(@probe);
        Devel::Probe::remove();
    }, 10000,  "no memory leak in install/add_probe/remove cycle"
);

leak_test(sub {
        Devel::Probe::install();
        Devel::Probe::trigger(\&probe_cb);
        Devel::Probe::remove();
    }, 10000, "no memory leak in install/trigger/remove cycle"
);

sub leak_test {
    my ($test_cb, $size, $desc) = @_;
    my $handle;
    my $i = 0;
    my $start_objects = Devel::Leak::NoteSV($handle);
    while($i < $size) {
        $test_cb->();
        $i++;
    }
    # note, never call 'NoteSV' with the $handle again; it will segfault.
    my $end_objects = Devel::Leak::NoteSV($handle);

    is($end_objects, $start_objects, $desc);
}

done_testing;
