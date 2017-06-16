package Koha::REST::V1::LdMainTemplates;

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

use Mojo::Base 'Mojolicious::Controller';

use Koha::LdMainTemplates;

use Try::Tiny;

sub list {
    my ( $c, $args, $cb ) = @_;

    my $ldmaintemplates;
    my $filter;
    $args //= {};

    for my $filter_param ( keys %$args ) {
        $filter->{$filter_param} = { LIKE => $args->{$filter_param} . "%" };
    }

    return try {
        $ldmaintemplates = Koha::LdMainTemplates->search($filter);
        return $c->$cb( $ldmaintemplates, 200 );
    }
    catch {
        if ( $_->isa('DBIx::Class::Exception') ) {
            return $c->$cb( { error => $_->{msg} }, 500 );
        }
        else {
            return $c->$cb(
                { error => "Something went wrong, check the logs." }, 500 );
        }
    };
}

__END__

sub get {
    my ( $c, $args, $cb ) = @_;

    my $city = Koha::Cities->find( $args->{cityid} );
    unless ($city) {
        return $c->$cb( { error => "City not found" }, 404 );
    }

    return $c->$cb( $city, 200 );
}

sub add {
    my ( $c, $args, $cb ) = @_;

    my $city = Koha::City->new( $args->{body} );

    return try {
        $city->store;
        return $c->$cb( $city, 200 );
    }
    catch {
        if ( $_->isa('DBIx::Class::Exception') ) {
            return $c->$cb( { error => $_->msg }, 500 );
        }
        else {
            return $c->$cb(
                { error => "Something went wrong, check the logs." }, 500 );
        }
    };
}

sub update {
    my ( $c, $args, $cb ) = @_;

    my $city;

    return try {
        $city = Koha::Cities->find( $args->{cityid} );
        $city->set( $args->{body} );
        $city->store();
        return $c->$cb( $city, 200 );
    }
    catch {
        if ( not defined $city ) {
            return $c->$cb( { error => "Object not found" }, 404 );
        }
        elsif ( $_->isa('Koha::Exceptions::Object') ) {
            return $c->$cb( { error => $_->message }, 500 );
        }
        else {
            return $c->$cb(
                { error => "Something went wrong, check the logs." }, 500 );
        }
    };

}

sub delete {
    my ( $c, $args, $cb ) = @_;

    my $city;

    return try {
        $city = Koha::Cities->find( $args->{cityid} );
        $city->delete;
        return $c->$cb( "", 200 );
    }
    catch {
        if ( not defined $city ) {
            return $c->$cb( { error => "Object not found" }, 404 );
        }
        elsif ( $_->isa('DBIx::Class::Exception') ) {
            return $c->$cb( { error => $_->msg }, 500 );
        }
        else {
            return $c->$cb(
                { error => "Something went wrong, check the logs." }, 500 );
        }
    };

}

1;
