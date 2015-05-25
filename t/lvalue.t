use strict;
use warnings;

use English;

use Test::More;
use Test::Exception;

use PDL::LiteF;
use PDL::Lvalue;

BEGIN { 
    if ( PDL::Lvalue->subs and !$PERLDB) {
	plan tests => 3;
    } else {
	plan skip_all => "no lvalue sub support";
    }
} 

$| = 1;

ok (PDL::Lvalue->subs('slice'));

my $pa = sequence 10;
lives_ok {
	$pa->slice("") .= 0;
};

is($pa->max, 0);
