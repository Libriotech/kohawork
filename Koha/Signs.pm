package Koha::Signs;

use C4::Context;
use Modern::Perl;

use base qw( Exporter );

# set the version for version checking
our @EXPORT = qw(

  AddSign
  EditSign
  GetSign
  GetAllSigns
  DeleteSign

  AddDeck
  EditDeck
  GetDeck
  GetAllDecks
  DeleteDeck

  AttachSignToDeck
  GetSignsAttachedToDeck
  DetachSignFromDeck

  RunSQL

);

my $dbh = C4::Context->dbh;

sub AddSign {

  my ( $name, $report ) = @_;

  my $sth=$dbh->prepare("INSERT INTO signs SET name = ?, saved_sql_id = ?");
  return $sth->execute( $name, $report );

}

sub EditSign {

  my ( $name, $report, $sign_id ) = @_;

  my $sth = $dbh->prepare("UPDATE signs SET name = ?, saved_sql_id = ? WHERE sign_id = ?");
  return $sth->execute( $name, $report, $sign_id );

}

sub GetSign {

  my ( $sign_id ) = @_;

  return unless $sign_id;

  my $query = "SELECT s.*, sq.report_name, sq.savedsql
               FROM signs AS s, saved_sql AS sq
               WHERE s.saved_sql_id = sq.id
                 AND s.sign_id = ?";
  my $sth = $dbh->prepare($query);
  $sth->execute($sign_id);
  return $sth->fetchrow_hashref();

}

sub GetAllSigns {

  my $query = "SELECT s.*, sq.report_name, sq.savedsql
               FROM signs AS s, saved_sql AS sq
               WHERE s.saved_sql_id = sq.id
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

# Decks

sub AddDeck {

  my ( $branchcode, $name, $webapp ) = @_;

  my $sth=$dbh->prepare("INSERT INTO decks SET branchcode = ?, name = ?, webapp = ?");
  return $sth->execute( $branchcode, $name, $webapp );

}

sub EditDeck {

  my ( $branchcode, $name, $webapp, $deck_id ) = @_;

  my $sth = $dbh->prepare("UPDATE decks SET branchcode = ?, name = ?, webapp = ? WHERE deck_id = ?");
  return $sth->execute( $branchcode, $name, $webapp, $deck_id );

}

sub GetDeck {

  my ( $deck_id ) = @_;

  return unless $deck_id;

  my $query = "SELECT d.*, b.branchname
               FROM decks as d LEFT JOIN branches as b
               ON d.branchcode = b.branchcode
               WHERE d.deck_id = ?";
  my $sth = $dbh->prepare($query);
  $sth->execute($deck_id);
  return $sth->fetchrow_hashref();

}

sub GetAllDecks {

  my $query = "SELECT d.*, b.branchname
               FROM decks as d LEFT JOIN branches as b
               ON d.branchcode = b.branchcode
               ORDER BY b.branchname, d.name";
  my $sth = $dbh->prepare($query);
  $sth->execute();
  return $sth->fetchall_arrayref({});

}

sub DeleteDeck {

  my ( $deck_id ) = @_;

  return unless $deck_id;

  my $sth = $dbh->prepare('DELETE FROM decks WHERE deck_id = ?');
  return $sth->execute($deck_id);

}

# Signs attached to decks

sub AttachSignToDeck {

  my ( $deck_id, $sign_id ) = @_;

  return unless $deck_id || $sign_id;

  my $sth = $dbh->prepare('INSERT INTO signs_to_decks SET deck_id = ?, sign_id = ?');
  return $sth->execute($deck_id, $sign_id);

}

sub GetSignsAttachedToDeck {

  my ( $deck_id ) = @_;

  return unless $deck_id;

  my $query = "SELECT s.*, sq.report_name, sq.savedsql
               FROM signs AS s, signs_to_decks AS sd, saved_sql AS sq
               WHERE s.sign_id = sd.sign_id
                 AND s.saved_sql_id = sq.id
                 AND sd.deck_id = ?
               ORDER BY s.name";
  my $sth = $dbh->prepare($query);
  $sth->execute( $deck_id );
  return $sth->fetchall_arrayref({});

}

sub DetachSignFromDeck {

  my ( $deck_id, $sign_id ) = @_;

  return unless $deck_id || $sign_id;

  my $sth = $dbh->prepare('DELETE FROM signs_to_decks WHERE deck_id = ? AND sign_id = ?');
  return $sth->execute( $deck_id, $sign_id );

}

sub RunSQL {

  my ( $query ) = @_;

  return unless $query;

  my $sth = $dbh->prepare($query);
  $sth->execute();
  return $sth->fetchall_arrayref({});

}

1;
