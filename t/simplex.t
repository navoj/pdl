use PDL::LiteF;
use Test::More;
use strict;
use warnings;

eval {
	require PDL::Opt::Simplex;
	PDL::Opt::Simplex->import();
	1;
} or plan skip_all => "PDL::Opt::Simplex not installed: $@";

plan tests => 8;

my $dis = pdl( 0, 1 );
my $func = sub {
    # f = x^2 + (y-1)^2 + 1
    return sumover( ( $_[0] - $dis )**2 ) + 1;
};

{
# first test
my ( $opt, $ssize, $optval ) = PDL::Opt::Simplex::simplex( 
    pdl( [ 2, 2 ] ), pdl( [ 0.01, 0.01 ] ), 1e-4, 1e4, $func,
);

my ( $x, $y ) = $opt->list;

ok( $x < 0.001 );
ok( ( $y - 1 ) < 0.001 );
ok( $ssize < 0.001 );
ok( ( $optval - 1 ) < 0.001 ); 
}

{
# second test
my $logsub = sub {};
my ( $opt, $ssize, $optval ) = PDL::Opt::Simplex::simplex( 
    pdl( [ [ -1, -1 ], [ -1.1, -1 ], [ -1.1, -0.9 ] ] ), pdl( [ 0.01, 0.01 ] ),
    1e-4, 1e4, $func,
);

my ( $x, $y ) = $opt->list;

ok( $x < 0.001 );
ok( ( $y - 1 ) < 0.001 );
ok( $ssize < 0.001 );
ok( ( $optval - 1 ) < 0.001 ); 
}
