use Test::More qw(no_plan); # TODO Set the number
use Digest::MD5 qw( md5_hex );
use Modern::Perl;

BEGIN {use_ok('Koha::Signs') }
use Koha::Signs;

my $md5       = md5_hex( time() );
my $name1     = "some name $md5";
my $name2     = "second name $md5";
my $name3     = "third name $md5";
my $report1   = 1;
my $parameter = "limit=3&dummy=$md5";

### Streams

# AddStream
my $sign_stream_id;
ok( $sign_stream_id = AddStream( $name1, $report1 ), "AddStream" );

# GetStream
my $stream;
ok( $stream = GetStream( $sign_stream_id ), "GetStream (sign_stream_id = $sign_stream_id) ok" );
like( $stream->{'saved_sql_id'}, qr/$report1/, "GetSign saved_sql_id ok" );
like( $stream->{'name'},         qr/$name1/,   "GetSign name ok" );

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
ok( $editedstream = GetStream( $sign_stream_id ),    "GetStream after EditStream ok" );
like( $editedstream->{'saved_sql_id'}, qr/$report1/, "GetStream after EditStream saved_sql_id ok" );
like( $editedstream->{'name'},         qr/$name3/,   "GetStream after EditStream name ok" );

### Signs

my $sign_name                = "some sign name $md5";
my $sign_webapp              = 0;
my $sign_webapp_changed      = 0;
my $sign_swatch              = '';
my $sign_swatch_changed      = 'c';
my $sign_transition          = 'fade';
my $sign_transition_changed  = 'pop';
my $sign_idleafter           = '5';
my $sign_idleafter_changed   = '10';
my $sign_pagedelay           = '5';
my $sign_pagedelay_changed   = '10';

# AddSign
my $sign_id;
ok( $sign_id = AddSign( $sign_name, $sign_webapp, $sign_swatch, $sign_transition, $sign_idleafter, $sign_pagedelay ), "AddSign" );

# GetSign
my $sign;
ok( $sign = GetSign( $sign_id ), "GetSign (sign_id = $sign_id) ok" );
like( $sign->{'name'},       qr/$sign_name/,       "GetSign name ok" );
like( $sign->{'webapp'},     qr/$sign_webapp/,     "GetSign webapp ok" );
like( $sign->{'swatch'},     qr/$sign_swatch/,     "GetSign swatch ok" );
like( $sign->{'transition'}, qr/$sign_transition/, "GetSign transition ok" );
like( $sign->{'idleafter'},  qr/$sign_idleafter/,  "GetSign idleafter ok" );
like( $sign->{'pagedelay'},  qr/$sign_pagedelay/,  "GetSign pagedelay ok" );

# GetAllSigns
my $signs;
ok( $signs = GetAllSigns, "GetAllSigns ok" );
my $num_of_signs = @{$signs};
cmp_ok( $num_of_signs, ">", 0, "GetAllSigns found at least one sign" );
foreach my $sign ( @{$signs} ) {
    if ( $sign->{'sign_id'} == $sign_id ) {
        like( $sign->{'name'},       qr/$sign_name/,       "GetAllSigns name ok" );
        like( $sign->{'webapp'},     qr/$sign_webapp/,     "GetAllSigns webapp ok" );
        like( $sign->{'swatch'},     qr/$sign_swatch/,     "GetAllSigns swatch ok" );
        like( $sign->{'transition'}, qr/$sign_transition/, "GetAllSigns transition ok" );
        like( $sign->{'idleafter'},  qr/$sign_idleafter/,  "GetAllSigns idleafter ok" );
        like( $sign->{'pagedelay'},  qr/$sign_pagedelay/,  "GetAllSigns pagedelay ok" );
    }
}

# EditSign
my $editedsign;
ok( EditSign( $sign_name, $sign_webapp_changed, $sign_swatch_changed, $sign_transition_changed, $sign_idleafter_changed, $sign_pagedelay_changed, $sign_id ), "EditSign ok" );
ok( $editedsign = GetSign( $sign_id ), "GetSign on edited sign ok" );
like( $editedsign->{'name'},       qr/$sign_name/,               "GetSign after EditSign name ok" );
like( $editedsign->{'webapp'},     qr/$sign_webapp_changed/,     "GetSign after EditSign webapp ok" );
like( $editedsign->{'swatch'},     qr/$sign_swatch_changed/,     "GetSign after EditSign swatch ok" );
like( $editedsign->{'transition'}, qr/$sign_transition_changed/, "GetSign after EditSign transition ok" );
like( $editedsign->{'idleafter'},  qr/$sign_idleafter_changed/,  "GetSign after EditSign idleafter ok" );
like( $editedsign->{'pagedelay'},  qr/$sign_pagedelay_changed/,  "GetSign after EditSign pagedelay ok" );

### Attaching streams to signs

# AttachStreamToSign
my $sign_to_stream_id;
ok( $sign_to_stream_id = AttachStreamToSign( $sign_stream_id, $sign_id ), "AttachStreamToSign ok for sign_stream_id = $sign_stream_id, sign_id = $sign_id" );

# AddParamsForAttachedStream
ok( AddParamsForAttachedStream( $sign_to_stream_id, $parameter ), "AddParamsForAttachedStream ok for sign_to_stream_id = $sign_to_stream_id" );

# GetParams
is( GetParams( $sign_to_stream_id ), $parameter, "GetParams ok for sign_to_stream_id = $sign_to_stream_id" );

# ReplaceParamsInSQL
like ( $stream->{'savedsql'}, qr/<</, 'query contains <<' );
unlike( ReplaceParamsInSQL( $stream->{'savedsql'}, $parameter ), qr/<</, 'ReplaceParamsInSQL removed << from query' );

# GetStreamsAttachedToSign
my $attatchedstreams;
ok( $attatchedstreams = GetStreamsAttachedToSign( $sign_id ), "GetStreamsAttachedToSign ok for sign_id = $sign_id" );
my $num_of_attached_streams = @{$attatchedstreams};
cmp_ok( $num_of_attached_streams, ">", 0, "GetStreamsAttachedToSign found at least one stream" );
foreach my $attatchedstream ( @{$attatchedstreams} ) {
    if ( $attatchedstream->{'sign_stream_id'} == $sign_stream_id ) {
        like( $attatchedstream->{'saved_sql_id'}, qr/$report1/, "GetStreamsAttachedToSign found a sign with our saved_sql_id" );
        like( $attatchedstream->{'name'},         qr/$name3/,   "GetStreamsAttachedToSign found a sign with our name" );
    }
}

# GetStreamsAttachedToSignWithRecords
ok( GetStreamsAttachedToSignWithRecords( $sign_id ), "GetStreamsAttachedToSignWithRecords ok for sign_id = $sign_id" );

### Clean up

# DetachStreamFromSign
ok ( DetachStreamFromSign( $sign_stream_id, $sign_id ), "DetachStreamFromSign ok" );

# DeleteStream
ok( DeleteStream( $sign_stream_id ), "DeleteStream ok" );
ok( ! GetStream( $sign_stream_id ),  "GetStream - stream is gone" );

# DeleteSign
ok( DeleteSign( $sign_id ), "DeleteSign ok" );
ok( ! GetSign( $sign_id ),  "GetSign - sign is gone" );
