package Koha::Signs;

use C4::Context;
use Modern::Perl;

use base qw( Exporter );

# set the version for version checking
our @EXPORT = qw(

  AddStream
  EditStream
  GetStream
  GetAllStreams
  DeleteStream

  AddSign
  EditSign
  GetSign
  GetAllSigns
  DeleteSign

  AttachStreamToSign
  GetStreamsAttachedToSign
  AddParamsForAttachedStream
  GetParams
  ReplaceParamsInSQL
  DetachStreamFromSign

  RunSQL

);

my $dbh = C4::Context->dbh;

# Streams

sub AddStream {

  my ( $name, $report ) = @_;

  my $sth=$dbh->prepare("INSERT INTO sign_streams SET name = ?, saved_sql_id = ?");
  return $sth->execute( $name, $report );

}

sub EditStream {

  my ( $name, $report, $sign_stream_id ) = @_;

  my $sth = $dbh->prepare("UPDATE sign_streams SET name = ?, saved_sql_id = ? WHERE sign_stream_id = ?");
  return $sth->execute( $name, $report, $sign_stream_id );

}

sub GetStream {

  my ( $sign_id ) = @_;

  return unless $sign_id;

  my $query = "SELECT s.*, sq.report_name, sq.savedsql
               FROM sign_streams AS s, saved_sql AS sq
               WHERE s.saved_sql_id = sq.id
                 AND s.sign_stream_id = ?";
  my $sth = $dbh->prepare($query);
  $sth->execute($sign_id);
  return $sth->fetchrow_hashref();

}

sub GetAllStreams {

  my $query = "SELECT s.*, sq.report_name, sq.savedsql
               FROM sign_streams AS s, saved_sql AS sq
               WHERE s.saved_sql_id = sq.id
               ORDER BY s.name";
  my $sth = $dbh->prepare($query);
  $sth->execute();
  return $sth->fetchall_arrayref({});

}

sub DeleteStream {

  my ( $sign_stream_id ) = @_;

  return unless $sign_stream_id;

  my $sth = $dbh->prepare('DELETE FROM sign_streams WHERE sign_stream_id = ?');
  return $sth->execute($sign_stream_id);

}

# Signs

sub AddSign {

  my ( $branchcode, $name, $webapp, $swatch, $idleafter, $pagedelay ) = @_;

  my $sth=$dbh->prepare("INSERT INTO signs SET branchcode = ?, name = ?, webapp = ?, swatch = ?, idleafter = ?, pagedelay = ?");
  return $sth->execute( $branchcode, $name, $webapp, $swatch, $idleafter, $pagedelay );

}

sub EditSign {

  my ( $branchcode, $name, $webapp, $swatch, $idleafter, $pagedelay, $sign_id ) = @_;

  my $sth = $dbh->prepare("UPDATE signs SET branchcode = ?, name = ?, webapp = ?, swatch = ?, idleafter = ?, pagedelay = ? WHERE sign_id = ?");
  return $sth->execute( $branchcode, $name, $webapp, $swatch, $idleafter, $pagedelay, $sign_id );

}

sub GetSign {

  my ( $sign_id ) = @_;

  return unless $sign_id;

  my $query = "SELECT s.*, b.branchname
               FROM signs as s LEFT JOIN branches as b
               ON s.branchcode = b.branchcode
               WHERE s.sign_id = ?";
  my $sth = $dbh->prepare($query);
  $sth->execute($sign_id);
  return $sth->fetchrow_hashref();

}

sub GetAllSigns {

  my $query = "SELECT s.*, b.branchname
               FROM signs as s LEFT JOIN branches as b
               ON s.branchcode = b.branchcode
               ORDER BY s.name";
  my $sth = $dbh->prepare($query);
  $sth->execute();
  return $sth->fetchall_arrayref({});

}

sub DeleteSign {

  my ( $sign_id ) = @_;

  return unless $sign_id;

  my $sth = $dbh->prepare('DELETE FROM signs WHERE sign_id = ?');
  return $sth->execute($sign_id);

}

# Streams attached to signs

# Returns the ID of the connection between sign and stream
sub AttachStreamToSign {

  my ( $sign_stream_id, $sign_id ) = @_;

  return unless $sign_stream_id || $sign_id;

  my $sth = $dbh->prepare( 'INSERT INTO signs_to_streams SET sign_stream_id = ?, sign_id = ?' );
  $sth->execute( $sign_stream_id, $sign_id );
  return $dbh->last_insert_id( undef, undef, 'signs_to_streams', 'sign_to_stream_id' );

}

sub AddParamsForAttachedStream {

  my ( $sign_to_stream_id, $params ) = @_;
  return unless $sign_to_stream_id;
  my $sth = $dbh->prepare( 'UPDATE signs_to_streams SET params = ? WHERE sign_to_stream_id = ?' );
  return $sth->execute( $params, $sign_to_stream_id );

}

# Returns the string of params for a given stream-attached-to-sign
sub GetParams {

  my ( $sign_to_stream_id ) = @_;

  return unless $sign_to_stream_id;

  my $query = 'SELECT params FROM signs_to_streams WHERE sign_to_stream_id = ?';
  my $sth = $dbh->prepare( $query );
  $sth->execute( $sign_to_stream_id );
  return $sth->fetchrow_array();

}

sub ReplaceParamsInSQL {

  my ( $sql, $params ) = @_;

  return unless $sql || $params;
  return $sql unless $sql =~ m/<</;

  foreach my $param ( split /&/, $params ) {
    my ( $key, $value ) = split /=/, $param;
    # FIXME Handle spaces
    # FIXME How do we get our hands on the branchcode stored in the sign?
    $sql =~ s/<<$key>>/$value/g;
  }
  return $sql;

}

sub GetStreamsAttachedToSign {

  my ( $sign_id ) = @_;

  return unless $sign_id;

  my $query = 'SELECT s.*, sts.sign_to_stream_id, sts.params, sq.report_name, sq.savedsql
               FROM sign_streams AS s, signs_to_streams AS sts, saved_sql AS sq
               WHERE s.sign_stream_id = sts.sign_stream_id
                 AND s.saved_sql_id = sq.id
                 AND sts.sign_id = ?
               ORDER BY s.name';
  my $sth = $dbh->prepare( $query );
  $sth->execute( $sign_id );
  return $sth->fetchall_arrayref({});

}

sub DetachStreamFromSign {

  my ( $sign_to_stream_id ) = @_;

  return unless $sign_to_stream_id;

  my $sth = $dbh->prepare( 'DELETE FROM signs_to_streams WHERE sign_to_stream_id = ?' );
  return $sth->execute( $sign_to_stream_id );

}

sub RunSQL {

  my ( $query ) = @_;

  return unless $query;

  my $sth = $dbh->prepare($query);
  $sth->execute();
  return $sth->fetchall_arrayref({});

}

1;
