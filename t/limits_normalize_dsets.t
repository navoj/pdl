use PDL;

use Test::More tests => 21;
use Test::Exception;

use strict;
use warnings;

my $got = 0;
eval{require PDL::Slatec;};
if(!$@) {$got = 1}

if($got) {
  eval{require PDL::Graphics::Limits;};
  if($@) {$got = 0}
  }

unless($got) {
  for(1..21){print "ok $_ - skipped\n"}
  exit;
  }

*normalize_dsets = \&PDL::Graphics::Limits::normalize_dsets;
*parse_vecspecs = \&PDL::Graphics::Limits::parse_vecspecs;

# so can use _eq_array w/ piddles.
{
  package PDL;
  use overload 'eq' => \&PDL::eq,
    'bool' => sub { $_[0]->and } ;
}

my $x1 = pdl( 1, 2 );
my $y1 = pdl( 1, 2 );

my $xn = pdl( 0.5, 0.5 );
my $xp = pdl( 0.25, 0.25 );

my $x2 = pdl( 2, 3 );
my $y2 = pdl( 2, 4 );

my %errs = ( en => undef, ep => undef );
my %attr = ( KeyCroak => 1 );

my @rdsets = (
	    { MinMax => [ [ '', ''],
			  [ '', '']
			],
	      Vectors => [ { data => $x1 },
			 {
			  data => $y1 }
			 ]
	    },

	    { MinMax => [ [ '', ''],
			  [ '', '']
			],
	      Vectors => [ { data => $x2 },
			 {
			  data => $y2 }
			 ]
	    },
	  );

my $args = { %attr, KeySpec => [ { data => 'x' }, { data => 'y' }, ] };

{
	my @udsets = ( [ $x1, $y1 ],
		    [ $x2, $y2 ] );
	my @dsets = normalize_dsets( { %attr }, @udsets );


	my %d1 = %{$dsets[0]};
	for (keys(%d1)) {
	    print "1: $_: $d1{$_}\n";
	    my @d1 = @{$d1{$_}};
	    print "  @d1\n";
	    }
	my %d2 = %{$dsets[1]};
	for (keys(%d2)) {
	    print "2: $_: $d2{$_}\n";
	    my @d2 = @{$d2{$_}};
	    print "  @d2\n";
	    }

	ok( _eq_array( \@dsets, \@rdsets ), "array" );
}


{
	my @udsets = ( [ { x => $x1, y => $y1 },
		      { x => $x2, y => $y2 } ] );
	my @dsets = normalize_dsets( $args, @udsets );
	ok( _eq_array( \@dsets, \@rdsets ), "hash" );
}


{
	my @udsets = ( [ { x => $x1, y => $y1 },
		      { x => $x2, y => $y2, z => 0 } ] );
	my @dsets = normalize_dsets( $args, @udsets );
	ok( _eq_array( \@dsets, \@rdsets ), "hash, extra data" );
}


{
	my @udsets = (  [ $x1, $y1 ],
		     [ { x => $x2, y => $y2 } ] );
	my @dsets = normalize_dsets( $args, @udsets );
	ok( _eq_array( \@dsets, \@rdsets ), "array and hash" );
}

#############################################################

{
	my @udsets = (  $x1, $y1, [ { x => $x2, y => $y2 } ] );
	throws_ok {
		my @dsets = normalize_dsets( $args,, @udsets );
	} qr/same dimensionality/, "dimensions not equal";
}

{
	my @udsets = (  [ $x1, $y1 ], [ $x1, { x => $x2, y => $y2 } ] );
	throws_ok {
		my @dsets = normalize_dsets( $args, @udsets )
	} qr/unexpected data type/, "bad arg mix";
}

{
	my @udsets = ( [ $x1, $y1 ], [ { x => $x2, y => $y2 } ] );
	lives_ok {
		my @dsets = normalize_dsets( $args, @udsets );
	} "array hash combo";
}

#############################################################

{
	my @udsets = (  [ $x1, $y1 ] );
	my @dsets = normalize_dsets( { %attr, Trans => [ \&log ] }, @udsets );

	is_deeply( $dsets[0]{Vectors}, [
			       { data => $x1, trans => \&log },
			       { data => $y1 },
				]
		    , "array: global x trans" );
}

{
	my @udsets = (  [ [ $x1, \&log ], $y1 ] );
	my @dsets = normalize_dsets( { %attr }, @udsets );
	is_deeply( $dsets[0]{Vectors}, [
			       { data => $x1, trans => \&log },
			       { data => $y1 },
				]
		    , "array: local x trans" );
}

{
	my @udsets = (  [ [ $x1, \&log ], $y1 ] );
	my @dsets = normalize_dsets( { %attr, Trans => [ \&sin ]}, @udsets );
	is_deeply( $dsets[0]{Vectors}, [
			       { data => $x1, trans => \&log },
			       { data => $y1 },
				]
		    , "array: local override x trans" );
}

{
	my @udsets = (  [ [ $x1, undef, undef, undef ], $y1 ] );
	my @dsets = normalize_dsets( { %attr, Trans => [ \&sin ]}, @udsets );
	is_deeply( $dsets[0]{Vectors}, [
			       { data => $x1 },
			       { data => $y1 },
				]
		    , "array: local undef x trans" );
}

#############################################################

my $keys = [ qw( x y ) ];
my %keys = ( KeySpec => parse_vecspecs( $keys ) );
{
	my $udsets = [  { x => $x1, y => $y1 } ];
	my @dsets = normalize_dsets( { %attr, %keys, Trans => [ \&log ] }, $udsets );
	is_deeply( $dsets[0]{Vectors}, [
			       { data => $x1, trans => \&log },
			       { data => $y1 },
				]
		    , "hash: global x trans" );
}


{
	my $udsets = [ { x => $x1, trans => \&log , y => $y1 } => ( '&trans' ) ];
	my @dsets = normalize_dsets( { %attr, %keys }, $udsets );
	is_deeply( $dsets[0]{Vectors}, [
			       { data => $x1, trans => \&log },
			       { data => $y1 },
				]
		    , "hash: local x trans 1" );
}


{
	my $udsets = [ { x => $x1, trans => \&log , y => $y1 } => qw( x&trans y ) ];
	my @dsets = normalize_dsets( { %attr, KeySpec => [] }, $udsets );
	is_deeply( $dsets[0]{Vectors}, [
			       { data => $x1, trans => \&log },
			       { data => $y1 },
				]
		    , "hash: local x trans 2" );
}

{
	my $udsets = [ { x => $x1, trans => \&log , y => $y1 } => qw( x&trans y ) ];
	my @dsets = normalize_dsets( { %attr, KeySpec => [], Trans => [\&sin] }, $udsets );
	is_deeply( $dsets[0]{Vectors}, [
			       { data => $x1, trans => \&log },
			       { data => $y1 },
				]
		    , "hash: local override x trans" );
}

{
	my $udsets = [ { x => $x1, trans => undef , y => $y1 } => qw( x&trans y ) ];
	my @dsets = normalize_dsets( { %attr, KeySpec => [], Trans => [\&sin] }, $udsets );
	is_deeply( $dsets[0]{Vectors}, [
			       { data => $x1 },
			       { data => $y1 },
				]
		    , "hash: local undef x trans 1" );
}

{
	my $udsets = [ { x => $x1, y => $y1 } => qw( x& y ) ];
	my @dsets = normalize_dsets( { %attr, KeySpec => [], Trans => [\&sin] }, $udsets );
	is_deeply( $dsets[0]{Vectors}, [
			       { data => $x1 },
			       { data => $y1 },
				]
		    , "hash: local undef x trans 2" );
}


#############################################################

{
	my @udsets = ( [ [ $x1, $xn ], $y2 ] );
	my @dsets = normalize_dsets( { %attr }, @udsets );
	my $exp = [ { data => $x1, errn => $xn, errp => $xn }, { data => $y2, } ];
	is_deeply( $dsets[0]{Vectors}, $exp, "array: symmetric errors" );
}

{
	my @udsets = ( [ [ $x1, $xn, $xp ], $y2 ] );
	my @dsets = normalize_dsets( { %attr }, @udsets );
	my $exp = [ { data => $x1, errn => $xn, errp => $xp }, { data => $y2, } ];
	is_deeply( $dsets[0]{Vectors}, $exp, "array: asymmetric errors 1" );
}

{
	my @udsets = ( [ [ $x1, undef, $xp ], $y2 ] );
	my @dsets = normalize_dsets( { %attr }, @udsets );
	my $exp = [ { data => $x1, errp => $xp }, { data => $y2, } ];
	is_deeply( $dsets[0]{Vectors}, $exp, "array: asymmetric errors 2" );
}

{
	my @udsets = ( [ [ $x1, $xn, undef ], $y2 ] );
	my @dsets = normalize_dsets( { %attr }, @udsets );
	my $exp = [ { data => $x1, errn => $xn }, { data => $y2, } ];
	is_deeply( $dsets[0]{Vectors}, $exp, "array: asymmetric errors 3" );
}

############################################

sub __deep_check {
    my($e1, $e2) = @_;
    my @Data_Stack;
    my $ok = 0;

    my $eq;
    {
        # Quiet uninitialized value warnings when comparing undefs.
        no warnings;

        if( $e1 eq $e2 ) {
            $ok = 1;
        }
        else {
            if( UNIVERSAL::isa($e1, 'ARRAY') and
                UNIVERSAL::isa($e2, 'ARRAY') )
            {
                $ok = _eq_array($e1, $e2);
            }
            elsif( UNIVERSAL::isa($e1, 'HASH') and
                   UNIVERSAL::isa($e2, 'HASH') )
            {
                $ok = _eq_hash($e1, $e2);
            }
            elsif( UNIVERSAL::isa($e1, 'REF') and
                   UNIVERSAL::isa($e2, 'REF') )
            {
                push @Data_Stack, { type => 'REF', vals => [$e1, $e2] };
                $ok = __deep_check($$e1, $$e2);
                pop @Data_Stack if $ok;
            }
            elsif( UNIVERSAL::isa($e1, 'SCALAR') and
                   UNIVERSAL::isa($e2, 'SCALAR') )
            {
                push @Data_Stack, { type => 'REF', vals => [$e1, $e2] };
                $ok = __deep_check($$e1, $$e2);
            }
            else {
                push @Data_Stack, { vals => [$e1, $e2] };
                $ok = 0;
            }
        }
    }

    return $ok;
}

############################################

sub _eq_array  {
    my($a1, $a2) = @_;
    return 1 if $a1 eq $a2;
    my @Data_Stack;

    my $DNE;
    my $ok = 1;
    my $max = $#$a1 > $#$a2 ? $#$a1 : $#$a2;
    for (0..$max) {
        my $e1 = $_ > $#$a1 ? $DNE : $a1->[$_];
        my $e2 = $_ > $#$a2 ? $DNE : $a2->[$_];

        push @Data_Stack, { type => 'ARRAY', idx => $_, vals => [$e1, $e2] };
        $ok = __deep_check($e1,$e2);
        pop @Data_Stack if $ok;

        last unless $ok;
    }
    return $ok;
}

#############################################

sub _eq_hash {
    my($a1, $a2) = @_;
    return 1 if $a1 eq $a2;
    my @Data_Stack;

    my $DNE;
    my $ok = 1;
    my $bigger = keys %$a1 > keys %$a2 ? $a1 : $a2;
    foreach my $k (keys %$bigger) {
        my $e1 = exists $a1->{$k} ? $a1->{$k} : $DNE;
        my $e2 = exists $a2->{$k} ? $a2->{$k} : $DNE;

        push @Data_Stack, { type => 'HASH', idx => $k, vals => [$e1, $e2] };
        $ok = __deep_check($e1, $e2);
        pop @Data_Stack if $ok;

        last unless $ok;
    }

    return $ok;
}


