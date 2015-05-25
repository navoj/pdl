# -*-perl-*-

use strict;
use warnings;

use Test::More tests => 8;

use PDL::LiteF;
use PDL::Types;
use PDL::Graphics::LUT;

my @names = lut_names();
ok( $#names > -1 );  # 1

my @cols = lut_data( $names[0] );
is( $#cols, 3 );                         # 2
is( $cols[0]->nelem, $cols[1]->nelem );  # 3
is( $cols[2]->get_datatype, $PDL_F );    # 4

# check we can reverse things
my @cols2 = lut_data( $names[0], 1 );
ok( all approx($cols[3]->slice('-1:0'),$cols2[3]) );  # 5

# check we know about the intensity ramps
my @ramps = lut_ramps();
ok( $#ramps > -1 ); # 6

# load in a different intensity ramp
my @cols3 = lut_data( $names[0], 0, $ramps[0] ); 
is( $cols3[0]->nelem, $cols3[1]->nelem ); # 7
ok( all approx($cols[1],$cols3[1]) );      # 8

