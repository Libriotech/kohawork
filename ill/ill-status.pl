#!/usr/bin/perl

# Copyright 2015 Magnus Enger Libriotech
#
# This file is part of Koha.
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
use C4::Branch;
use C4::Items qw { GetItemnumberFromBarcode GetItemnumbersForBiblio ModItem };
use C4::Koha;
use C4::Members;
use C4::Members::Attributes qw( GetBorrowerAttributeValue );
use C4::Output;
use C4::Context;
use Koha::ILLRequests;
use Koha::ILLRequest::Backend::NNCIPP qw(
    SendItemShipped SendItemShippedAsHome SendItemReceived SendItemReceivedAsOwner
    SendRenewItem SendCancelRequestItem SendCancelRequestItemAsOwner
);
use URI::Escape;

my $input   = CGI->new;
my $status  = $input->param('status');
my $barcode = $input->param('barcode');

my ( $template, $borrowernumber, $cookie ) = get_template_and_user( {
    template_name => 'ill/ill-status.tt',
    query         => $input,
    type          => 'intranet',
    flagsrequired => { ill => '*' },
} );

if ( $barcode && $status && $status eq 'REJECT' ) {

    # Owner library rejects a RequestItem it has received

    my $reject_reason = $input->param('reject_reason');

    # Find the right request, based on the barcode
    # my $itemnumber = GetItemnumberFromBarcode( $barcode );
    # my $biblionumber = GetBiblionumberFromItemnumber( $itemnumber );

    # Find all requests for the given barcode
    my $illRequests = Koha::ILLRequests->new;
    my $requests = $illRequests->search({
        'remote_barcode' => $barcode,
        'status'         => 'NEW',
    });
    if ( scalar @{ $requests } == 0 ) {

        $template->param(
            'status'        => $status,
            'barcode'       => $barcode,
            # 'itemnumber'    => $itemnumber,
            # 'biblionumber'  => $biblionumber,
            'reject_reason' => $reject_reason,
            'error'         => 'NOTFOUND',
        );

    } else {

        my $request = $requests->[0];
        # Change the status
        $request->editStatus({ 'status' => 'REJECT' });
        # Get the full details
        $request->getFullDetails( { brw => 1 } );

        # Send a CancelRequestItem message to the library that ordered the item
        my $response = SendCancelRequestItemAsOwner({
            'request'       => $request,
            'barcode'       => $barcode,
            'reject_reason' => $reject_reason,
        });
        if ( $response->{'success'} == 1 ) { # FIXME This means we got a 200 response, but it could contain a Problem
            # Response looks OK
            $request->editStatus({ 'status' => 'REJECTED' });
        }

        # Get full details for all NEW requests for the biblio in question
        my $requests_details;
        foreach my $rq ( @{$requests} ) {
            push @{$requests_details}, $rq->getFullDetails( { brw => 1 } );
        }

        $template->param(
            'status'   => $status,
            'request'  => $request,
            'requests' => $requests_details,
            'response' => $response,
            'barcode'  => $barcode,
            # 'itemnumber'   => $itemnumber,
            # 'biblionumber' => $biblionumber,
        );

    }

} elsif ( $barcode && $status && $status eq 'CANCEL' ) {

    # Home library tries to cancel a RequestItem it has sent out

    # Find the right request, based on the barcode
    # my $itemnumber = GetItemnumberFromBarcode( $barcode );
    # my $biblionumber = GetBiblionumberFromItemnumber( $itemnumber );

    # Find the right request
    my $illRequests = Koha::ILLRequests->new;
    my $requests = $illRequests->search({
        'remote_barcode' => $barcode,
        'status'         => 'ORDERED',
    });
    # There should only be one with the given status anyway...
    if ( scalar @{ $requests } == 0 ) {

        $template->param(
            'barcode' => $barcode,
            'error'   => 'NOTFOUND',
        );

    } else {

        my $request = $requests->[0];

        $request->editStatus({ 'status' => 'CANCEL' });
        # Get the full details
        $request->getFullDetails( { brw => 1 } );

        # Send an CancelRequestItem message to the library that we ordered the item from
        my $response = SendCancelRequestItem({
            'request' => $request,
            'barcode' => $barcode,
        });

        if ( $response->{'data'} ) {
            # Response looks OK
            $request->editStatus({ 'status' => 'CANCELLED' });
        }

        $template->param(
            'status'       => $status,
            'request'      => $request,
            'response'     => $response,
            'barcode'      => $barcode,
            # 'itemnumber'   => $itemnumber,
            # 'biblionumber' => $biblionumber,
        );

    }

} elsif ( $barcode && $status && $status eq 'RENEWREQ' ) {

    # Find the right request, based on the barcode
    # my $itemnumber = GetItemnumberFromBarcode( $barcode );
    # my $biblionumber = GetBiblionumberFromItemnumber( $itemnumber );
    
    # Find the right request
    my $illRequests = Koha::ILLRequests->new;
    my $requests = $illRequests->search({
        'remote_barcode' => $barcode,
        'status'         => 'RECEIVED',
    });
    # There should only be one with the given status anyway...
    my $request = $requests->[0];

    $request->editStatus({ 'status' => 'RENEWREQ' });
    # Get the full details
    $request->getFullDetails( { brw => 1 } );

    # Send a RenewItem message to the library that we ordered the item from
    my $response = SendRenewItem({
        'request' => $request,
        'barcode' => $barcode,
    });

    if ( $response && $response->{'problem'} == 0 ) {
        use Data::Dumper;
        warn Dumper $response->{'data'};
        $request->editStatus({ 'status' => 'RENEWED' });
    } else {
        $request->editStatus({ 'status' => 'NOTRENEWED' });
    }

    $template->param(
        'status'   => $status,
        'request'  => $request,
        'response' => $response,
        'barcode'  => $barcode,
    );

} elsif ( $barcode && $status && $status eq 'RECEIVED' ) {

    # Find all requests for the given biblionumber
    my $illRequests = Koha::ILLRequests->new;
    my $requests = $illRequests->search({
        'remote_barcode' => $barcode, # Set based on info in ItemShipped
        'status'         => 'SHIPPING',
    });
    # There should only be one anyway...
    my $request = $requests->[0];

    my $response;
    if ( $request ) {

        # We are the Home Library, notifing the Owner Library that we have 
        # recieved the item they sent us, based on the RequestItem we sent them221

        $request->editStatus({ 'status' => 'RECEIVED' });
        # Get the full details
        $request->getFullDetails( { brw => 1 } );

        # Update the item with the barcode from the physical item we have received
        my $biblionumber = $request->status->getProperty('biblionumber');
        my $itemnumbers = GetItemnumbersForBiblio( $biblionumber );
        # There should only be one
        my $itemnumber = $itemnumbers->[0];
        ModItem({ barcode => $barcode }, $biblionumber, $itemnumber);

        # Send an ItemReceived message to the library that we ordered the item from
        $response = SendItemReceived({
            'request' => $request,
            'barcode' => $barcode,
        });

    } else {
    
        my $requests = $illRequests->search({
            'remote_barcode' => $barcode, # Set based on info in ItemShipped
            'status'         => 'SHIPPED',
        });
        # There should only be one anyway...
        my $request = $requests->[0];
    
        if ( $request ) {

            # We are the Owner Library, notifying the Home Library that 
            # we have received the document they sent us in return

            $request->editStatus({ 'status' => 'COMP' });
            # Get the full details
            $request->getFullDetails( { brw => 1 } );

            # Send an ItemReceived message to the library that ordered the item from us
            $response = SendItemReceivedAsOwner({
                'request' => $request,
                'barcode' => $barcode,
            });

        }

    }

    $template->param(
        'status'   => $status,
        'request'  => $request,
        'response' => $response,
        'barcode'  => $barcode,
    );

} elsif ( $barcode && $status && $status eq 'SHIPPED' ) {

    # Find the right request, based on the barcode
    # my $itemnumber = GetItemnumberFromBarcode( $barcode );
    # my $biblionumber = GetBiblionumberFromItemnumber( $itemnumber );

    # Find all requests for the given biblionumber
    my $illRequests = Koha::ILLRequests->new;
    my $requests = $illRequests->search({
        # 'biblionumber' => $biblionumber,
        'remote_barcode' => $barcode,
        'status'         => 'NEW',
    });
    # We are looking for the oldest request for this biblionumber, so we use the zero'th one
    my $request = $requests->[0];
    my $requests_details;

    my $response;
    if ( $request ) {
    
        # We are the Owner Library, telling the Home Library that the item they
        # requested has been shipped
    
        # Change the status
        $request->editStatus({ 'status' => 'SHIPPED' });
        # Get the full details
        $request->getFullDetails( { brw => 1 } );

        # Send an ItemShipped message to the library that ordered the item
        $response = SendItemShipped({
            'request' => $request,
            'barcode' => $barcode,
        });

        # Get full details for all NEW requests for the biblio in question
        foreach my $rq ( @{$requests} ) {
            push @{$requests_details}, $rq->getFullDetails( { brw => 1 } );
        }

    } else {

        # We are the Home Library, telling the Owner Library that the item they
        # sent us has been sent back
    
        # Find all requests for the given biblionumber
        my $illRequests = Koha::ILLRequests->new;
        my $requests = $illRequests->search({
            # 'biblionumber' => $biblionumber,
            'remote_barcode' => $barcode,
            'status'         => 'RECEIVED', # FIXME RENEWED
        });
        # We are looking for the oldest request for this biblionumber, so we use the zero'th one
        $request = $requests->[0];

        # Change the status
        $request->editStatus({ 'status' => 'SHIPPED' });
        # Get the full details
        $request->getFullDetails( { brw => 1 } );

        # Send an ItemShipped message to the Owner Library
        $response = SendItemShippedAsHome({
            'request' => $request,
            'barcode' => $barcode,
        });

    }

    $template->param(
        'status'   => $status,
        'request'  => $request,
        'requests' => $requests_details,
        'response' => $response,
        'barcode'  => $barcode,
        # 'itemnumber'   => $itemnumber,
        # 'biblionumber' => $biblionumber,
    );

}

$template->param(
    'statuses' => GetAuthorisedValues( 'ILLSTATUS' ),
    'rejects'  => GetAuthorisedValues( 'ILLREJECT' ),
);

output_html_with_http_headers( $input, $cookie, $template->output );
