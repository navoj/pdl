use Test::More tests => 53;
use PDL::LiteF;
use Test::Exception;
kill 'INT',$$ if $ENV{UNDER_DEBUGGER}; # Useful for debugging.

approx(pdl(0), pdl(0), 0.01); # set eps

# $a0 = zeroes 3,5;
# $b0 = xvals $a0;
{
my $a = xvals zeroes 3,5;

my $b = yvals zeroes 3,5;

my $c = $a + $b;

ok($c->at(2,2) == 4, 'pdl addition 1');
ok($c->at(2,3) == 5, 'pdl addition 2');
throws_ok {
	$c->at(3,3);
} qr/Position out of range/, 'invalid position';
}

{
my $d = pdl 5,6;

my $e = $d - 1;
ok($e->at(0) == 4, 'pdl - scalar 1');
ok($e->at(1) == 5, 'pdl - scalar 2');
my $f = 1 - $d;
ok($f->at(0) == -4, 'scalar - pdl 1');
ok($f->at(1) == -5, 'scalar - pdl 2');
}

# Now, test one operator from each group
# biop1 tested already
{
my $a = pdl 0,1,2;
my $b = pdl 1.5;

my $c = $a > $b;

ok($c->at(1) == 0, '0 not > 1.5');
ok($c->at(2) == 1, '2 is > 1.5');
}

{
my $a = byte pdl 0,1,3;
my $c = $a << 2;

ok($c->at(0) == 0, '0 left bitshift 2 is 0');
ok($c->at(1) == 4, '1 left bitshift 2 is 4');
ok($c->at(2) == 12,'3 left bitshift 2 is 12');
}

{
my $a = pdl 16,64,9;
my $b = sqrt($a);

ok(all approx($b,(pdl 4,8,3)),'sqrt of pdl(16,64,9)');

# See that a is unchanged.

ok($a->at(0) == 16, 'sqrt orig value ok');
}

{
my $a = pdl 1,0;
my $b = ! $a;
ok($b->at(0) == 0, 'elementwise not 1');
ok($b->at(1) == 1, 'elementwise not 2');
}

{
my $a = pdl 12,13,14,15,16,17;
my $b = $a % 3;

ok($b->at(0) == 0, 'simple modulus 1');
ok($b->at(1) == 1, 'simple modulus 2');
ok($b->at(3) == 0, 'simple modulus 3');
# [ More modulus testing farther down! ]
}

{
# Might as well test this also
ok(all approx((pdl 2,3),(pdl 2,3)),'approx equality 1');
ok(!all approx((pdl 2,3),(pdl 2,4)),'approx equality 2');
}

{
# Simple function tests
my $a = pdl(2,3);
ok(all approx(exp($a), pdl(7.3891,20.0855)), 'exponential');
ok(all approx(sqrt($a), pdl(1.4142, 1.7321)), 'sqrt makes decimal');
}

{
# And and Or

ok(all approx(pdl(1,0,1) & pdl(1,1,0), pdl(1,0,0)), 'elementwise and');
ok(all approx(pdl(1,0,1) | pdl(1,1,0), pdl(1,1,1)), 'elementwise or');
}

{
# atan2
ok (all approx(atan2(pdl(1,1), pdl(1,1)), ones(2) * atan2(1,1)), 'atan2');
}

{
my $a = sequence (3,4);
my $b = sequence (3,4) + 1;

ok (all approx($a->or2($b,0), $a | $b), 'or2');
ok (all approx($a->and2($b,0), $a & $b), 'and2');
ok (all approx($b->minus($a,0), $b - $a), 'explicit minus call');
ok (all approx($b - $a, ones(3,4)), 'pdl subtraction');
}

# inplace tests

{
my $a = pdl 1;
my $sq2 = sqrt 2; # perl sqrt
$a->inplace->plus(1,0);  # trailing 0 is ugly swap-flag
ok(all approx($a, pdl 2), 'inplace plus');
$warning_shutup = $warning_shutup = sqrt $a->inplace;
ok(all approx( $a, pdl($sq2)), 'inplace pdl sqrt vs perl scalar sqrt');
my $b = pdl 4;
ok(all approx( 2, sqrt($b->inplace)),'perl scalar vs inplace pdl sqrt');
}

{
# log10 now uses C library
# check using scalars and piddles
my $a = log10(110);
my $b = log(110) / log(10);
note "a: $a  [ref(\$a)='", ref($a),"']\n";
note "b: $b\n";
ok(abs($a-$b) < 1.0e-5 ,'log10 scalar');
my $a = log10(pdl(110,23));
my $b = log(pdl(110,23)) / log(10);
note "a: $a\n";
note "b: $b\n";
ok(all approx( $a, $b), 'log10 pdl');

# check inplace
ok(all approx( pdl(110,23)->inplace->log10(), $b), 'inplace pdl log10');
}

{
my $data = ones 5;
$data &= 0;
ok(all($data == 0), 'and assign');
$data |= 1;
ok(all($data == 1), 'or assign');

ok(all($data eq $data), 'eq'); # check eq operator
}


#### Modulus checks ####

{
#test signed modulus on small numbers
# short/long/indx/longlong/float/double neg/0/pos % neg/0/pos
my $a = pdl(-7..7);
my $b = pdl(-3,0,3)->transpose;
my $c = cat(pdl("-1 0 -2 " x 5),zeroes(15),pdl("2 0 1 " x 5));
ok all(short($a) % short($b) == short($c)),'short modulus';
ok all(long($a) % long($b) ==  long($c)), 'long modulus';
ok all(indx($a) % indx($b) == indx($c)), 'indx modulus';
ok all(longlong($a) % longlong($b) == longlong($c)), 'longlong modulus';
ok all(float($a) % float($b) == float($c)), 'float modulus';
ok all(double($a) % double($b) == double($c)), 'double modulus';
}

{
#test unsigned modulus
# byte/ushort 0/pos % 0/pos
my $a = xvals(15);
my $b = pdl(0,3)->transpose;
my $c = cat(zeroes(15),pdl("0 1 2 " x 5));
ok all(byte($a) % byte($b)==byte($c)), 'byte modulus';
ok all(ushort($a) % ushort($b)==ushort($c)), 'ushort modulus';
}

#and for big numbers (bigger than INT_MAX=2147483647)
#basically this is exercising the (typecast)(X)/(N) in the macros
$INT_MAX=2147483647;

TODO: {
local $TODO = undef;
$TODO = 'Marking TODO for big modulus for 2.008 release';
require Config;
diag "\$Config{ivsize} = $Config::Config{ivsize}";
diag "\$INT_MAX = $INT_MAX = @{[ sprintf '%x', $INT_MAX ]}";
cmp_ok long($INT_MAX)%1      , '==', 0, "big long modulus: $INT_MAX % 1";
cmp_ok indx($INT_MAX*4)%2    , '==', 0, "big indx modulus: @{[$INT_MAX*4]} % 2";
cmp_ok longlong($INT_MAX*4)%2, '==', 0, "big longlong modulus: @{[$INT_MAX*4]} % 2";
#skip float intentionally here, since float($INT_MAX)!=$INT_MAX
cmp_ok double($INT_MAX*4)%2  , '==', 0, "big double modulus: @{[$INT_MAX*4]} % 2";
}

{
#and do the same for byte (unsigned char) and ushort
$BYTE_MAX = 255;
$USHORT_MAX = 65535;

ok byte($BYTE_MAX)%1 == 0, 'big byte modulus';
ok ushort($USHORT_MAX)%1 == 0, 'big ushort modulus';
}
