package Koha::LinkedData;

# Copyright (c) 2013 Magnus Enger Libriotech.
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
use RDF::Query::Client;
use C4::Context;
use Data::Dumper;

use base 'Exporter';
use version; our $VERSION = qv('1.0.0');

our @EXPORT = (
    qw( get_data_from_uri )
);

# FIXME Make this a syspref!
our $endpoint = 'http://data.libriotech.no/metaquery/';

=head1 NAME

Koha::LinkedData

=head1 DESCRIPTION

Routines for letting Koha interact with Linked Data. 

=head1 FUNCTIONS

=head2 get_data_from_uri

$data = get_data_from_uri( $uri );

Takes a URI as argument and returns a reference to a hash that 
contains the template for the type of the given URI, as well as some
data. 

=cut

sub get_data_from_uri {

    my ( $uri ) = @_;
    my %data;

    ## Get the main template, based on the type of the given URI
    
    my $templatesparql = "SELECT DISTINCT ?template  WHERE {
                              <$uri> a ?type .
                              ?type <http://example.org/hasTemplate> ?template .
                          }";
    my $templatequery = RDF::Query::Client->new( $templatesparql );
    my $templateiterator = $templatequery->execute( $endpoint );
    # Grab the first template (there should not be more than one)
    my $t = $templateiterator->next;

    if ( $t && $t->{template}->literal_value ) {

        $data{'template'} = $t->{template}->literal_value;

        
        ##  Get all the queries and templates based on the type of the given URI
        
        # Get the type query
        # $queries will be an iterator that holds a list of queries, each of which
        # is made up of a slug, a query and a template
        my $typesparql = "SELECT DISTINCT ?slug ?sparql ?template WHERE {
                              <$uri> a ?type .
                              ?type <http://example.org/hasQuery> ?typequery .
                              ?typequery <http://example.org/hasSlug>     ?slug .
                              ?typequery <http://example.org/hasQuery>    ?sparql .
                              ?typequery <http://example.org/hasTemplate> ?template .
                          }";
        my $typequery = RDF::Query::Client->new( $typesparql );
        my $queries = $typequery->execute( $endpoint );
        
        # Simplify the datastructure in $queries a bit
        # This will give us a hash of hashes, with the slugs as keys, 
        # and two keys in the inner hash: sparql and template
        # (It looked like the DISTINCT part of the type query did not
        # work at some point, this operation will have the side effect 
        # of ensuring we are working on unique slugs.)
        my %datapoints;
        while (my $row = $queries->next) {
            my $slug = $row->{slug}->literal_value;
            $datapoints{ $slug } = {
                sparql   => $row->{sparql}->literal_value,
                template => $row->{template}->literal_value,
            };
        }

        ## Iterate over the queries, and collect their data in %datapoints
        
        foreach my $key ( keys %datapoints ) {
            
            # Get the SPARQL query
            my $sparql = $datapoints{ $key }{ 'sparql' };
            
            # Insert the given URI into the query
            $sparql =~ s/__URI__/$uri/;
            
            # Run the query
            my $q = RDF::Query::Client->new( $sparql );
            my @querydata = $q->execute( $endpoint );
            # Add the data to %datapoints with a new key called "data"
            $datapoints{ $key }{ 'data' } = \@querydata;
            
        }
        $data{'data'} = \%datapoints;

    } else {
    
        # We fo not have a specific template for the type of the given URL, 
        # so we resort to a default query and a default template
        my $q = RDF::Query::Client->new( 'SELECT * WHERE {
                                            GRAPH ?g { <' . $uri . '> ?p ?o . }
                                          }' );
        my @defaultdata = $q->execute( $endpoint );
        $data{'data'} = \@defaultdata;
        
    }

    return \%data;

}

1;
