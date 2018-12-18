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
    my $x = 1;
    my $z = 1 + $x;

=head1 DESCRIPTION

=head1 AUTHORS

=over 4

=item * Gonzalo Diethelm C<< gonzus AT cpan DOT org >>

=back

=head1 THANKS

=over 4

=item * Ben Tyler for the inspiration

=back
