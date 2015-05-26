use strict;
use Test::More tests => 1;

# check if PDL::NiceSlice clobbers the DATA filehandle
use PDL::LiteF;

use strict;
use warnings;

$| = 1;

use PDL::NiceSlice;

my $data = join '', <DATA>;
like $data, qr/we've got data/;

__DATA__

we've got data
