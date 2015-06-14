# -*-perl-*-

use Test::More tests => 1;

use PDL::LiteF;
use PDL::Math;

use strict;
use warnings;

kill 'INT',$$ if $ENV{UNDER_DEBUGGER}; # Useful for debugging.

my $pa = sequence(41) - 20;
$pa /= 4;
#do test on quarter-integers, to make sure we're not crazy.

my $ans_rint = pdl(-5,-5,-4,-4,-4,-4,-4,-3,-3,-3,-2,-2,-2,-2,-2,
-1,-1,-1,0,0,0,0,0,1,1,1,2,2,2,2,2,3,3,3,4,4,4,4,4,5,5);

ok(all(rint($pa)==$ans_rint));
