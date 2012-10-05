use Modern::Perl;
use Test::More qw(no_plan); # TODO Set the number
use Test::Exception;
use C4::Context;

BEGIN {use_ok('Koha::Signs') }
use Koha::Signs;

my $dbh = C4::Context->dbh;

my $name1   = 'some unlikely name';
my $name2   = 'some other name';
my $name3   = 'a changed name';
my $report1 = 1;

# AddStream
ok( AddStream( $name1, $report1 ), "AddStream" );

# Find the sign_id of the sign we just added, for use in further tests
my $query = "SELECT sign_stream_id FROM sign_streams WHERE saved_sql_id = '$report1' AND name = '$name1'";
my $sth = $dbh->prepare($query);
$sth->execute();
my ( $sign_stream_id ) = $sth->fetchrow_array();

# GetStream
my $sign;
ok( $sign = GetStream( $sign_stream_id ), "GetStream (sign_stream_id = $sign_stream_id) ok" );
like( $sign->{'saved_sql_id'}, qr/$report1/, "GetSign saved_sql_id ok" );
like( $sign->{'name'},         qr/$name1/,   "GetSign name ok" );

# GetAllStreams
my $streams;
ok( $streams = GetAllStreams, "GetAllStreams ok" );
my $num_of_streams = @{$streams};
cmp_ok( $num_of_streams, ">", 0, "GetAllStreams found at least one stream" );
foreach my $stream ( @{$streams} ) {
  if ( $stream->{'sign_stream_id'} == $sign_stream_id ) {
    like( $stream->{'saved_sql_id'}, qr/$report1/, "GetAllStreams found a sign with our saved_sql_id" );
    like( $stream->{'name'},         qr/$name1/,   "GetAllStreams found a sign with our name" );
  }
}

# EditStream
my $editedstream;
ok( EditStream( $name3, $report1, $sign_stream_id ), "EditStream ok" );
ok( $editedstream = GetStream( $sign_stream_id ), "GetStream on edited sign ok" );
like( $editedstream->{'saved_sql_id'}, qr/$report1/, "saved_sql_id from GetStream on edited sign ok" );
like( $editedstream->{'name'},         qr/$name3/,   "name from GetStream on edited sign ok" );

# DeleteStream
ok( DeleteStream( $sign_stream_id ), "DeleteStream ok" );
