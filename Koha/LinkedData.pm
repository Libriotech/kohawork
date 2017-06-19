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

    my $data_and_templates = _get_data_and_templates( $uri, $type );

    return ( $main_template, $data_and_templates );

}

=head2 _get_data_and_templates

Based on the URI and the type, query the database for corresponding queries
and templates. Then execute the queries to get the data, and return the data
and the templates.

=cut

sub _get_data_and_templates {

    my ( $uri, $type ) = @_;
    my $triplestore = C4::Context->triplestore( 'query' );

    my %data_and_templates;
    my @queries_and_templates = _get_queries_and_templates( $type );
    foreach my $qt ( @queries_and_templates ) {
        # Add the data to the hash
        my $data = $triplestore->get_sparql( $qt->{'query'} );
        $data_and_templates{ $qt->{'slug'} } = {
            'data' => $data,
            'template' => $qt->{'template'},
        };
    }

    warn Dumper \%data_and_templates if $debug;
    return \%data_and_templates;

}

=head2 _get_queries_and_templates

Get the queries and the templates, based on a given type, and return them.

FIXME This should come from the db, but we are faking it, for now.

FIXME The queries need to have placeholders for our /bib/1 URIs.

=cut

sub _get_queries_and_templates {

    my ( $type ) = @_;

    # Series title
    my $query1 = "
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX bibframe: <http://id.loc.gov/ontologies/bibframe/>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
  SELECT ?seriesTitle WHERE  { {
    <http://demo.semweb.bibkat.no/bib/1> rdfs:seeAlso ?graph
    FILTER ( ?type1 != '' )
  } UNION {
    GRAPH ?graph {
      ?graph rdf:type ?type1 .
      ?graph <http://schema.org/mainEntity> ?mainEnt .
      ?mainEnt bibframe:hasSeries ?series .
      ?series <http://purl.org/dc/terms/title> ?seriesTitle .
    }
} }
";
    my $template1 = '
<h4>Series title</h4>
<ul>
[% WHILE ( d = ld_dt.series_title.data.next ) %]
  <li>[% d.seriesTitle.value %]</li>
[% END %]
</ul>
';
    my %qt1 = (
        'slug'     => 'series_title',
        'query'    => $query1,
        'template' => $template1,
    );

    return ( \%qt1 );

}

=head2 _get_main_template

Given a type URI, find the main template for that type.

FIXME This should come from the database, but for now we fake it.

=cut

sub _get_main_template {

    my ( $type ) = @_;
    return '
<h3>Sound recording</h3>
[% ld_dt.series_title.template | eval %]
';

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

    my $triplestore = C4::Context->triplestore( 'query' );
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
