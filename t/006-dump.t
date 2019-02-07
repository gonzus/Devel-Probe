use strict;
use warnings;

use Test::More;

use Devel::Probe;

my $config = {
    actions => [
        { action => 'define', file => "foo", lines => [qw(4 5 6)] },
        { action => 'define', file => "bar", lines => [qw(7 8 9)], type => "permanent" },
    ],
};
Devel::Probe::config($config);
is_deeply(Devel::Probe::dump(), 
    { 
        foo => {
            4 => 1,
            5 => 1,
            6 => 1,
        },
        bar => {
            7 => 2,
            8 => 2,
            9 => 2,
        },
    },
"dump returned a hash representing the probes in the correct state");

done_testing;
