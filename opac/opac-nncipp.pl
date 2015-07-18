#!/usr/bin/perl

# Copyright 2015 Magnus Enger Libriotech
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

use CGI;

use C4::Auth;
use C4::Biblio;
use C4::Context;
use C4::Koha;
use C4::Output;
use C4::Branch;
use Koha::Borrowers;
use Koha::ILLRequests;
use Koha::ILLRequest::Backend::NNCIPP qw( send_ItemRequested );
use URI::Escape;

use Data::Dumper; # FIXME Debug

my $cgi = CGI->new();

my ( $template, $borrowernumber, $cookie ) = get_template_and_user(
    {
        template_name   => 'opac-nncipp.tt',
        query           => $cgi,
        type            => 'opac',
        authnotrequired => 0,
    }
);

my ( $error, $message );
my $query        = $cgi->param('query_value');
my $here         = "/cgi-bin/koha/opac-nncipp.pl";
my $op           = $cgi->param('op');
my $biblionumber = $cgi->param('biblionumber');
my $bibliodata   = GetBiblioData( $biblionumber );
my $borrower     = Koha::Borrowers->new->find( $borrowernumber )
    || die "You're logged in as the database user. We don't support that.";

# Default: Display "Order | Cancel" links for the given biblionumber

if ( $op eq 'order' && $biblionumber ne '' ) {

    # Add a ILL request for the given biblionumber and logged in user

    my $illRequest   = Koha::ILLRequests->new;
    my $request = $illRequest->request({
        'biblionumber' => $biblionumber,
        'branch'       => $borrower->{'branchcode'},
        'borrower'     => $borrowernumber,
    });
    # $illRequest->save;
    # warn Dumper $illRequest;

    if ( $request ) {
        my $request_id = $request->{'status'}->{'id'};
        $message = { message => 'order_success', request_id => $request_id };
        send_ItemRequested( $request_id, $bibliodata, $borrower );
    } else {
        # FIXME
    }
    $message = { message => 'order_success', order_number => 123 };

}

$template->param(
    query_value  => $query,
    error        => $error,
    message      => $message,
    op           => $op,
    biblionumber => $biblionumber,
    biblio       => $bibliodata,
);

output_html_with_http_headers( $cgi, $cookie, $template->output );
