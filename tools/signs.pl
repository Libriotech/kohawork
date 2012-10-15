#!/usr/bin/perl
#
# Copyright 2012 Magnus Enger Libriotech
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

=head1 NAME

signs.pl - Script for managing digital signs for the OPAC.

=head1 SYNOPSIS

signs.pl

=head1 DESCRIPTION

Allows authorized users to create and manage digital signs for the OPAC.

=cut

use Koha::Signs;
use CGI;
use C4::Auth;
use C4::Branch;
use C4::Context;
use C4::Log;
use C4::Output;
use C4::Reports::Guided;
use Modern::Perl;

my $cgi = new CGI;
my $dbh = C4::Context->dbh;
my $script_name = 'signs.pl';

my ( $template, $loggedinuser, $cookie ) = get_template_and_user(
    {
        template_name   => "tools/signs.tt",
        query           => $cgi,
        type            => "intranet",
        authnotrequired => 0,
        flagsrequired   => { tools => 'edit_digital_signs' },
        debug           => 0,
    }
);

my $op                = $cgi->param('op') || '';
my $sign_id           = $cgi->param('sign_id') || '';
my $sign_stream_id    = $cgi->param('sign_stream_id') || '';
my $sign_to_stream_id = $cgi->param('sign_to_stream_id') || '';
my $parameters        = $cgi->param('parameters') || '';

# Streams

if ( $op eq 'add_stream' ) {

  # TODO Check that there are reports that can be used

  $template->param(
    'op'         => 'stream_form',
    'reports'    => get_saved_reports( { group => 'SIG' } ),
  );

} elsif ( $op eq 'edit_stream' && $sign_stream_id ne '') {

  my $stream = GetStream( $sign_stream_id );

  $template->param(
    'op'          => 'stream_form',
    'stream'      => $stream,
    'reports'     => get_saved_reports( { group => 'SIG' } ),
    'script_name' => $script_name
  );

} elsif ( $op eq 'save_stream' ) {

  if ( $sign_stream_id ne '' ) {
    EditStream( $cgi->param('name'), $cgi->param('report'), $cgi->param('sign_stream_id') );
  } else {
    AddStream( $cgi->param('name'), $cgi->param('report'),  );
  }
  print $cgi->redirect($script_name);

} elsif ( $op eq 'view_stream' && $sign_stream_id ne '' ) {

  my $stream = GetStream( $sign_stream_id );

  $template->param(
    'op'          => 'view_stream',
    'stream'      => $stream,
    'records'     => RunSQL( $stream->{'savedsql'} ),
    'script_name' => $script_name
  );

} elsif ( $op eq 'del_stream' ) {

  my $stream = GetStream( $sign_stream_id );

  $template->param(
    'op'          => 'del_stream',
    'stream'      => $stream,
    'script_name' => $script_name,
  );

} elsif ( $op eq 'del_stream_ok' ) {

  DeleteStream( $sign_stream_id );

  $template->param(
    'op'          => 'del_stream_ok',
    'script_name' => $script_name,
  );

# Signs

} elsif ( $op eq 'add_sign' ) {

  $template->param(
    'op'       => 'sign_form',
    'branches' => GetBranchesLoop,
    'swatches' => C4::Context->preference( 'OPACDigitalSignsSwatches' ),
  );

} elsif ( $op eq 'edit_sign' && $sign_id ne '' ) {

  $template->param(
    'op'          => 'sign_form',
    'sign'        => GetSign( $sign_id ),
    'branches'    => GetBranchesLoop,
    'script_name' => $script_name,
    'swatches' => C4::Context->preference( 'OPACDigitalSignsSwatches' ),
  );

} elsif ( $op eq 'save_sign' ) {

  if ($cgi->param('sign_id')) {
    EditSign( $cgi->param('branchcode'), $cgi->param('name'), $cgi->param('webapp'), $cgi->param('swatch'), $cgi->param('sign_id') );
  } else {
    AddSign(  $cgi->param('branchcode'), $cgi->param('name'), $cgi->param('webapp'), $cgi->param('swatch') );
  }
  print $cgi->redirect($script_name);

} elsif ( $op eq 'view_sign' && $sign_id ne '' ) {

  $template->param(
    'op'          => 'view_sign',
    'sign'        => GetSign( $sign_id ),
    'script_name' => $script_name,
  );


} elsif ( $op eq 'del_sign' && $sign_id ne '' ) {

  $template->param(
    'op'          => 'del_sign',
    'sign'        => GetSign( $sign_id ),
    'script_name' => $script_name,
  );

} elsif ( $op eq 'del_sign_ok' ) {

  DeleteSign( $sign_id );

  $template->param(
    'op'          => 'del_sign_ok',
    'script_name' => $script_name,
  );

# Signs and streams

} elsif ( $op eq 'edit_streams' && $sign_id ne '') {

  $template->param(
    'op'          => 'edit_streams',
    'sign'        => GetSign( $sign_id ),
    'streams'     => GetAllStreams(),
    'attached'    => GetStreamsAttachedToSign( $sign_id ),
    'script_name' => $script_name
  );

} elsif ( $op eq 'attach_stream_to_sign' && $sign_stream_id ne '' && $sign_id ne '' ) {

  my $sign_to_stream_id = AttachStreamToSign( $sign_stream_id, $sign_id );

  # Check if the SQL associated with the stream needs parameters
  my $stream = GetStream( $sign_stream_id );
  if ( $stream->{'savedsql'} =~ m/<</ ) {
    print $cgi->redirect($script_name . '?op=get_params&sign_to_stream_id=' . $sign_to_stream_id . '&sign_stream_id=' . $sign_stream_id );
  } else {
    print $cgi->redirect($script_name . '?op=edit_streams&sign_id=' . $sign_id);
  }

} elsif ( $op eq 'get_params' && $sign_to_stream_id ne '' && $sign_stream_id ne '' ) {

  $template->param(
    'op'                => 'get_params',
    'stream'            => GetStream( $sign_stream_id ),
    'sign_id'           => $sign_id,
    'sign_to_stream_id' => $sign_to_stream_id,
    'params'            => GetParams( $sign_to_stream_id ),
    'script_name'       => $script_name,
  );

} elsif ( $op eq 'save_params' && $sign_to_stream_id ne '' ) {

  AddParamsForAttachedStream( $sign_to_stream_id, $parameters );
  print $cgi->redirect($script_name . '?op=edit_streams&sign_id=' . $sign_id);

} elsif ( $op eq 'detach_stream_from_sign' && $sign_to_stream_id ne '' ) {

  DetachStreamFromSign( $sign_to_stream_id );
  print $cgi->redirect($script_name . '?op=edit_streams&sign_id=' . $sign_id);

} else {

  # TODO Check the setting of OPACDigitalSigns, give a warning if it is off

  $template->param(
    'streams' => GetAllStreams(),
    'signs'   => GetAllSigns(),
    'else'    => 1
  );

}

output_html_with_http_headers $cgi, $cookie, $template->output;

exit 0;

=head1 AUTHORS

Written by Magnus Enger of Libriotech.

=cut
