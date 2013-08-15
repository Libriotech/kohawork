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

use Modern::Perl;
use RDF::Trine::Store::SPARQL;

use base qw(Class::Accessor);
Koha::LinkedData->mk_ro_accessors(qw(namespace uribase endpoint));

our $VERSION = '0.01';

sub new {
    my $class           = shift;
    my $uribase         = shift;
    my $sparql_endpoint = shift;
    my $self            = {};
    bless $self, $class;
    $self->{'uribase'}  = $uribase;
    $self->{'endpoint'} = $sparql_endpoint;
    return $self;
}

sub get_data {
    my $self   = shift;
    my $query  = shift;
    my $sparql = RDF::Trine::Store::SPARQL->new( $self->endpoint() );
    $sparql->get_sparql( $query );
}

1;
__END__

=head1 NAME

Koha::LinkedData - Fetch data from a triplestore.

=head1 SYNOPSIS

  use Koha::LinkedData;
  my $ld = Koha::LinkedData->new( $sparql_endpoint )

=head1 DESCRIPTION

Fetch data from a triplesore. 

=head2 EXPORT

None by default.

=head2 get_data

my $data = $ld->get_data( $uri );

=cut

=head1 AUTHOR

Magnus Enger, E<lt>magnus@enger.priv.no<gt>

=cut
