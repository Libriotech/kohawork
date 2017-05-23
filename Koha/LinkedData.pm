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

use C4::Context;

use Data::Dumper;
use Modern::Perl;
our $debug = 1;

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

    # Figure out the type of the record we are looking at, so we can use the
    # proper queries and templates for that type.
    my $type = _get_type_of_record( $uri );

    # Find the main template for this type
    my $main_template = _get_main_template( $type );

    return ( $main_template );

}

=head2 _get_main_template

Given a type URI, find the main template for that type.

This should of course come from the database, but for now we mock it.

=cut

sub _get_main_template {

    my ( $type ) = @_;
    return '<h3>Sound recording</h3>';

}

=head2 _get_type_of_record

Given a URI, return the rdf:type of that URI.

The Libris data has three levels, and each of those has a type. The SPARQL query
used here returns all three, but for now, we use the middle one.

The SPARQL query used here should perhaps be in a syspref, to account for any
kind of data scheme. (Or maybe we should normalize data in the triplestore to a
standard form that we would always know how to query.)

=cut

sub _get_type_of_record {

    my ( $uri ) = @_;

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
    my $d = $data->next;
    warn Dumper $d if $debug;

    return $d->{type2}->value;

}

=head2 EXPORT

None by default.

=head1 AUTHOR

Magnus Enger, E<lt>magnus@libriotech.noE<gt>

=cut

1;
