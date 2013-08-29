package Koha::LinkedData;

# This file is part of Koha.
#
# Based on Koha::MARC2RDF.pm by Chris Cormack
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

=head1 NAME

Koha::LinkedData - Fetch data from a triplestore.

=head1 SYNOPSIS

  use Koha::LinkedData;
  my $ld = Koha::LinkedData->new( $sparql_endpoint )

=head1 DESCRIPTION

Fetch data from a triplesore, for display in the Koha OPAC. 

=head2 EXPORT

None by default.

=cut

use Modern::Perl;
use RDF::Trine::Store::SPARQL;

use base qw(Class::Accessor);
Koha::LinkedData->mk_ro_accessors(qw(namespace uribase endpoint));

our $VERSION = '0.01';

sub new {
    my $class           = shift;
    my $sparql_endpoint = shift;
    my $self            = {};
    bless $self, $class;
    $self->{'endpoint'} = $sparql_endpoint;
    return $self;
}

=head1 METHODS

=head2 get_data_from_uri

my $data = $ld->get_data_from_uri( $uri );

Takes a URI as argument and returns a reference to a hash that 
contains the template for the type of the given URI, as well as data. 

=cut

sub get_data_from_uri {

    my ( $self, $uri ) = @_;
    my %data;
    my $sparql = RDF::Trine::Store::SPARQL->new( $self->endpoint() );

    ## Get the main template, based on the type of the given URI
    
    my $templatesparql = "SELECT DISTINCT ?template  WHERE {
                              <$uri> a ?type .
                              ?type <http://example.org/hasTemplate> ?template .
                          }";
    my $templateiterator = $sparql->get_sparql( $templatesparql );
    # Grab the first template (there should not be more than one)
    my $t = $templateiterator->next;

    if ( $t && $t->{template}->literal_value ) {

        $data{'template'} = $t->{template}->literal_value;

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
        my $queries = $sparql->get_sparql( $typesparql );
        
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
            my $sparqlquery = $datapoints{ $key }{ 'sparql' };
            
            # Insert the given URI into the query
            $sparqlquery =~ s/__URI__/$uri/;
            $datapoints{ $key }{ 'realquery' } = $sparqlquery;
            
            # Run the query
            my $querydata = $sparql->get_sparql( $sparqlquery );
            my @data;
            # Iterate through the data to create a structure that is
            # easier to use in the templates than $querydata->next
            while ( my $point = $querydata->next ){
                push @data, $point;
            }
            # Add the data to %datapoints with a new key called "data"
            $datapoints{ $key }{ 'data' } = \@data;
            
        }
        $data{'data'} = \%datapoints;

    } else {

        # We do not have a specific template for the type of the given URL,
        # so we resort to a default query and a default template
        my @defaultdata = $sparql->get_sparql( 'SELECT * WHERE {
                                                  GRAPH ?g { <' . $uri . '> ?p ?o . }
                                                }' );
        $data{'data'} = \@defaultdata;
        
    }

    return \%data;

}

1;

=head1 AUTHOR

Magnus Enger, E<lt>magnus@enger.priv.no<gt>

=cut
