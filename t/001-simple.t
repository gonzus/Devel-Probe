use strict;
use warnings;

use Test::More;

BEGIN {
    use_ok('Devel::Probe');
}

exit main();

sub main {
    my $x = 1;
    my $y = 2;
    my $z = $x + $y;
    printf("%d + %d = %d\n", $x, $y, $z);
    done_testing;
    return 0;
}

