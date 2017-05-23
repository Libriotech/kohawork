package Koha::LinkedData;

# Copyright 2017 magnus@libriotech.no
#
# This file is part of Koha.
#
# Koha is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation; either version 3 of the License, or (at your option) any later
# version.
#
# Koha is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Koha; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

use Modern::Perl;
use C4::Context;

# TODO The code in here should probably be moved to Koha::RDF or thereabouts,
# but I'll keep it as a separate module for now, to avoid conflicts.

=head1 NAME

Koha::LinkedData

=head1 SYNOPSIS

  use Koha::LinkedData;
  my $ld = Koha::LinkedData->new();
  my ( $data, $tt ) = $ld->get_data_from_biblionumber( $biblionumber );

=head1 FUNCTIONS

=cut

sub new {
    my ($class, $args) = @_;
    $args = {} unless defined $args;
    return bless ($args, $class);
}

sub get_data_from_biblionumber {

    my ( $self, $biblionumber ) = @_;

    # Mint the URI
    # my $rdf = Koha::RDF->new;
    # my $uri = $rdf->mint_uri('biblio',1);
    # For now, we fake it, so we can get some actual data from the triplestore
    my $uri = 'http://demo.semweb.bibkat.no/bib/1';

    my $triplestore = C4::Context->triplestore;
    my $sparql = "
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX bibframe: <http://id.loc.gov/ontologies/bibframe/>
  SELECT ?type1 ?type2 ?type3 WHERE  { {
    <$uri> rdfs:seeAlso ?graph
    FILTER ( ?type1 != '' )
  } UNION {
    GRAPH ?graph {
      ?graph rdf:type ?type1 .
      ?graph <http://schema.org/mainEntity> ?mainEnt .
      ?mainEnt rdf:type ?type2 .
      ?mainEnt bibframe:instanceOf ?instanceOf .
      ?instanceOf rdf:type ?type3 .
    }
} }
";
    my $data = $triplestore->get_sparql( $sparql );

    my $tt = '
<ul>
[% WHILE ( d = ld_data.next ) %]
  <li>[% d.type1.value %]</li>
  <li>[% d.type2.value %]</li>
  <li>[% d.type3.value %]</li>
[% END %]
</ul>
';

    return ( $data, $tt );

}

=head2 EXPORT

None by default.


=head1 AUTHOR

Magnus Enger, E<lt>magnus@libriotech.noE<gt>

=cut

1;

__END__
