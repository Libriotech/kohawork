#!/usr/bin/perl
#
# Copyright (C) 2013 Magnus Enger Libriotech
# Magnus Enger <magnus@libriotech.no>
#
# based on opac-image.pl
#
# This file is part of Koha.
#
# Koha is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation; either version 2 of the License, or (at your option) any later
# version.
#
# Koha is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Koha; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#
#
#

use strict;
use warnings;

use CGI;
use C4::Auth;
use C4::Context;
use C4::Output;
use Koha::LinkedData2;
use Data::Validate::URI qw(is_uri);

$| = 1;

my $DEBUG = 0;
my $data  = new CGI;

=head1 NAME

opac-browse.pl - Script for browsing semantic data from a triplestore

=head1 SYNOPSIS

opac-browse.pl?uri=http://example.com/some_example

=head1 DESCRIPTION

This script makes it possible to browse semantic/linked data retrieved from a triplestore.

=cut

my $query = new CGI;
my ( $template, $borrowernumber, $cookie ) = get_template_and_user(
    {
        template_name   => "opac-browse.tt",
        query           => $query,
        type            => "opac",
        authnotrequired => ( C4::Context->preference("OpacPublic") ? 1 : 0 ),
        flagsrequired => { borrow => 1 },
    }
);

my $uri = $query->param('uri');
warn "URI: $uri";

if ( is_uri( $uri ) ) {

    $template->{VARS}->{'uri'}        = $uri;
    # my $ld = Koha::LinkedData2->new( C4::Context->preference("OPACBaseURL"), C4::Context->preference("SPARQL_Endpoint") );
    my $ld = Koha::LinkedData2->new( 'http://example.org/', 'http://data.libriotech.no/metaquery/' );
    $template->{VARS}->{'linkeddata'} = $ld->get_data_from_uri( $uri );

} else {

    # TODO Default query that can display some entry points into the 
    # browsing of the data, if no valid URI is given as argument

}

output_html_with_http_headers $query, $cookie, $template->output;

=head1 AUTHOR

Magnus Enger <magnus@libriotech.no>

=cut
