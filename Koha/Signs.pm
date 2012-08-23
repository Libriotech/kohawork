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

  my $query = "SELECT s.*
               FROM signs as s
               WHERE s.sign_id = ?";
  my $sth = $dbh->prepare($query);
  $sth->execute($sign_id);
  return $sth->fetchrow_hashref();

}

sub GetAllSigns {

  my $query = "SELECT s.*, sq.report_name as report_name
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

  my ( $branchcode, $name ) = @_;

  my $sth=$dbh->prepare("INSERT INTO decks SET branchcode = ?, name = ?");
  return $sth->execute( $branchcode, $name );

}

sub EditDeck {

  my ( $branchcode, $name, $deck_id ) = @_;

  my $sth = $dbh->prepare("UPDATE decks SET branchcode = ?, name = ? WHERE deck_id = ?");
  return $sth->execute( $branchcode, $name, $deck_id );

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



1;
