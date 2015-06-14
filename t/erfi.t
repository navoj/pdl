# -*-perl-*-

use Test::More tests => 2;

use PDL::LiteF;
use PDL::Math;

use strict;
use warnings;

kill 'INT',$$ if $ENV{UNDER_DEBUGGER}; # Useful for debugging.

approx(pdl(0), pdl(0), 0.01); # set eps

{
my $pa = pdl( 0.01, 0.0 );
ok( all approx( erfi($pa), pdl(0.00886,0.0) ) );

# inplace
$pa->inplace->erfi;
ok( all approx( $pa, pdl(0.00886,0.0) ) );
}
