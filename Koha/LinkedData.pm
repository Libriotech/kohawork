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

use Koha::LdMainTemplates;
use Koha::LdQueriesTemplates;
use Koha::RDF;

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
    my $rdf = Koha::RDF->new;
    my $uri = $rdf->mint_uri( 'biblio', $biblionumber );

    # Figure out the type of the record we are looking at, so we can use the
    # proper queries and templates for that type.
    my $type = _get_type_of_record( $uri );

    # Find the main template for this type
    my ( $main_template_id, $main_template ) = _get_main_template( $type );

    my $data_and_templates = _get_data_and_templates( $uri, $main_template_id );

    return ( $main_template, $data_and_templates );

}

=head2 _get_data_and_templates

Based on the URI and the type, query the database for corresponding queries
and templates. Then execute the queries to get the data, and return the data
and the templates.

=cut

sub _get_data_and_templates {

    my ( $uri, $main_template_id ) = @_;
    my $triplestore = C4::Context->triplestore( 'query' );

    my %data_and_templates;
    my $queries_and_templates = _get_queries_and_templates( $main_template_id );
    foreach my $qt ( @{ $queries_and_templates } ) {

        # FIXME Replace a placeholder in the query with the actual URI
        $qt->{'query'} =~ s/__URI__/$uri/g;

        # Get the data from the triplestore and add it to the hash
        my $data = $triplestore->get_sparql( $qt->{'query'} );
        $data_and_templates{ $qt->{'slug'} } = {
            'data' => $data,
            'template' => $qt->{'template'},
        };

    }

    # warn Dumper \%data_and_templates if $debug;
    return \%data_and_templates;

}

=head2 _get_queries_and_templates

Get the queries and the templates, associated with a given main template, and 
return them.

=cut

sub _get_queries_and_templates {

    my ( $main_template_id ) = @_;

    my $qts = Koha::LdQueriesTemplates->search({
        'ld_main_template_id' => $main_template_id,
    })->unblessed;

    return $qts;

}

=head2 _get_main_template

Given a type URI, find the main template for that type.

=cut

sub _get_main_template {

    my ( $type ) = @_;
    my $mt = Koha::LdMainTemplates->find({
        'type_uri' => $type,
    })->unblessed;
    return ( $mt->{'ld_main_template_id'}, $mt->{'main_template'} );

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

    return $d->{type2}->value;

}

=head2 EXPORT

None by default.

=head1 AUTHOR

Magnus Enger, E<lt>magnus@libriotech.noE<gt>

=cut

1;
