#!/usr/bin/perl

# Copyright 2012 Magnus Enger Libriotech
#
# This is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation; either version 2 of the License, or (at your option) any later
# version.
#
# This is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# Koha; if not, write to the Free Software Foundation, Inc., 59 Temple Place,
# Suite 330, Boston, MA  02111-1307 USA
#

use Modern::Perl;
use Test::More qw( no_plan ); # TODO Set the number?
use Test::WWW::Mechanize;
use URI;
use CGI;
use Digest::MD5 qw( md5_hex );
use Data::Dumper;

use C4::Context;

my $user     = $ENV{KOHA_USER};
my $password = $ENV{KOHA_PASS};
my $intranet = $ENV{KOHA_INTRANET_URL};
my $opac     = $ENV{KOHA_OPAC_URL};

# Include a has of time() in names to make them unique between runs
my $md5 = md5_hex( time() );
my $stream_name = "stream $md5";
my $sign_name   = "sign $md5";

BAIL_OUT("You must set the environment variable KOHA_INTRANET_URL to ".
         "point this test to your staff client. If you do not have ".
         "KOHA_CONF set, you must also set KOHA_USER and KOHA_PASS for ".
         "your username and password") unless $intranet;

$intranet =~ s#/$##;
$opac     =~ s#/$##;

my $agent     = Test::WWW::Mechanize->new( autocheck => 1 );
my $opacagent = Test::WWW::Mechanize->new( autocheck => 1 );

diag( 'Random string: ' . $md5 );

# Log in to the Koha staff client
$agent->get_ok( "$intranet/cgi-bin/koha/mainpage.pl", 'connect to intranet' );
$agent->form_name('loginform');
$agent->field( 'password', $password );
$agent->field( 'userid',   $user );
$agent->field( 'branch',   '' );
$agent->click_ok( '', 'login to staff client' );
$agent->get_ok( "$intranet/cgi-bin/koha/mainpage.pl", 'load main page' );

# Go to the tools page
$agent->follow_link_ok( { url_regex => qr/tools-home/i }, 'open Tools page' );

# Digital signs
$agent->follow_link_ok( { text => 'Digital signs' }, 'go to Digital signs' );
$agent->title_like(   qr/Digital signs/, 'title contains Digital signs' );
$agent->content_like( qr/Digital signs/, 'content contains Digital signs' );
$agent->content_like( qr/New sign/,      'content contains New sign' );
$agent->content_like( qr/New stream/,    'content contains New stream' );

### Add stream

$agent->follow_link_ok( { url_regex => qr/op=add_stream/i }, 'open Add stream page' );
$agent->content_like( qr/Add stream/, 'content contains Add stream' );
$agent->content_like( qr/Report/,     'content contains Report' );

# my @report_selects = $agent->grep_selects({
#   # type => qr/option/,
#   id   => qr/^report$/,
# });
# diag( Dumper @report_selects );

$agent->submit_form_ok({
  form_id => 'streamform',
  fields  => {
    'op'     => 'save_stream',
    'name'   => $stream_name,
    'report' => 2, # FIXME Make this dynamic?
  }
}, 'add a new stream' );
$agent->content_like( qr/$stream_name/, 'content contains new stream name' );

# Stream detail page
$agent->follow_link_ok( { text => $stream_name, n => 1 }, 'detail page for stream' );
$agent->content_like( qr/$stream_name/, 'detail page contains stream name' );
$agent->content_like( qr/Based on report/, 'detail page contains Based on report' );

# Find the $sign_stream_id of the stream we just created
my $uri = $agent->uri();
my $query = CGI->new( $uri->query );
my $sign_stream_id = $query->param( 'sign_stream_id' );
diag ( 'sign_stream_id: ', $sign_stream_id );

# Go back to the main digital signs page
$agent->follow_link_ok( { text => 'Digital signs' }, 'go to Digital signs' );

### Edit stream

$agent->follow_link_ok( { text => 'Digital signs' }, 'go to Digital signs' );
$agent->follow_link_ok( { url_regex => qr/edit_stream.*$sign_stream_id/i }, 'click on Edit for stream' );
$agent->content_like( qr/$stream_name/, 'content contains stream name' );
$agent->submit_form_ok({
  form_id => 'streamform',
  fields  => {
    'op'             => 'save_stream',
    'sign_stream_id' => $sign_stream_id,
    'name'           => $stream_name,
    'report'         => 1, # FIXME Make this dynamic?
  }
}, 'edit stream' );
$agent->content_like( qr/$stream_name/, 'content contains stream name' );

### Create sign

$agent->follow_link_ok( { url_regex => qr/op=add_sign/i }, 'open Add sign page' );
$agent->content_like( qr/Add sign/, 'content contains Add sign' );
$agent->submit_form_ok({
  form_id => 'signform',
  fields  => {
    'op'         => 'save_sign',
    'name'       => $sign_name,
    'branchcode' => 'CPL', # FIXME Make this dynamic
    'webapp'     => 1,
    'swatch'     => 'a',
  }
}, 'add a new sign' );
$agent->content_like( qr/$sign_name/, 'content contains new sign name' );

# Sign detail page
$agent->follow_link_ok( { text => $sign_name, n => 1 }, 'detail page for sign' );
$agent->content_like( qr/$sign_name/, 'detail page contains sign name' );

# Find the $sign_id of the sign we just created
my $signuri = $agent->uri();
my $signquery = CGI->new( $signuri->query );
my $sign_id = $signquery->param( 'sign_id' );
diag ( 'sign_id: ', $sign_id );

### Attach stream to sign

$agent->follow_link_ok( { text => 'Digital signs' }, 'go to Digital signs' );
$agent->follow_link_ok( { url_regex => qr/edit_streams&sign_id=$sign_id$/i }, 'click on Edit streams' );
$agent->content_like( qr/Edit streams attached to $sign_name/, 'content contains Edit streams attached to sign name' );
$agent->submit_form_ok({
  form_id => 'attach_stream_to_sign_form',
  fields  => {
    'op'             => 'attach_stream_to_sign',
    'sign_id'        => $sign_id,
    'sign_stream_id' => $sign_stream_id,
  }
}, 'attach stream to sign' );
$agent->content_like( qr/Parameters for $stream_name/, 'content contains Parameters for stream name' );

# Get the sign_to_stream_id
my $signstreamuri = $agent->uri();
my $signstreamquery = CGI->new( $signstreamuri->query );
my $sign_to_stream_id = $signstreamquery->param( 'sign_to_stream_id' );
diag ( 'sign_to_stream_id: ', $sign_to_stream_id );

$agent->submit_form_ok({
  form_id => 'get_params_form',
  fields  => {
    'op'                => 'save_params',
    'sign_to_stream_id' => $sign_to_stream_id,
    'parameters'        => 'limit=3',
  }
}, 'save params' );

$agent->content_like( qr/<td>$stream_name<\/td>/, 'content contains stream name in a table cell' );

### Check the sign and stream in the OPAC

$opacagent->get_ok( "$opac/cgi-bin/koha/opac-sign.pl", 'front page for signs in the opac' );
$opacagent->content_like( qr/$sign_name/, 'OPAC front page contains sign name' );
$opacagent->content_like( qr/viewport/, 'OPAC content contains viewport' );
$opacagent->follow_link_ok( { url_regex => qr/sign=$sign_id$/i }, 'go to our sign' );
$opacagent->content_like( qr/$sign_name/, 'sign contains sign name' );
$opacagent->content_like( qr/$stream_name/, 'sign contains stream name' );
$opacagent->content_like( qr/viewport/, 'OPAC content contains viewport' );
$opacagent->content_contains( 'apple-mobile-web-app-capable', 'OPAC content contains apple-mobile-web-app-capable' );
$opacagent->content_contains( '<div data-role="page" data-theme="a" id="stream_' . $sign_stream_id . '">', 'OPAC content contains data-theme = a' );

### Edit sign

$agent->follow_link_ok( { text => 'Digital signs' }, 'go to Digital signs' );
$agent->follow_link_ok( { url_regex => qr/edit_sign.*$sign_id/i }, 'click on Edit for sign' );
$agent->content_like( qr/$sign_name/, 'content contains sign name' );
$agent->submit_form_ok({
  form_id => 'signform',
  fields  => {
    'op'         => 'save_sign',
    'sign_id'    => $sign_id,
    'name'       => $sign_name,
    'branchcode' => 'CPL', # FIXME Make this dynamic
    'webapp'     => 0,
    'swatch'     => 'c',
  }
}, 'edit sign' );
$agent->content_like( qr/$sign_name/, 'content contains sign name' );

# Check the OPAC
$opacagent->reload();
$opacagent->content_lacks( 'apple-mobile-web-app-capable', 'OPAC content lacks apple-mobile-web-app-capable' );
$opacagent->content_contains( '<div data-role="page" data-theme="c" id="stream_' . $sign_stream_id . '">', 'OPAC content contains data-theme = c' );

### Detach stream from sign

$agent->follow_link_ok( { text => 'Digital signs' }, 'go to Digital signs' );
$agent->follow_link_ok( { url_regex => qr/edit_streams&sign_id=$sign_id$/i }, 'click on Edit streams' );
$agent->content_contains( "<td>$stream_name</td>", 'content contains stream name in a table cell' );
# There should only be one attached stream, so click the first link labelled Detach
$agent->follow_link_ok( { text => 'Detach' }, 'click on Detach' );
$agent->content_lacks( "<td>$stream_name</td>", 'content lacks stream name in a table cell' );

# Check the OPAC
$opacagent->reload();
$opacagent->content_lacks( $stream_name, 'OPAC content lacks stream name' );

### Delete stream

$agent->follow_link_ok( { text => 'Digital signs' }, 'go to Digital signs' );
$agent->follow_link_ok( { url_regex => qr/del_stream.*$sign_stream_id/i }, 'click on Delete for stream' );
$agent->content_like( qr/Confirm deletion of stream/, 'page contains Confirm deletion of stream' );
$agent->content_like( qr/$stream_name/, 'content contains stream name' );

# TODO Cancel delete

# Confirm delete
$agent->submit_form_ok({
  form_id => 'confirm_stream_delete_form',
  fields  => {
    'op'             => 'del_stream_ok',
    'sign_stream_id' => $sign_stream_id,
  }
}, 'confirm delete of stream' );
$agent->content_like( qr/Stream deleted/, 'stream deleted' );

# Check the Edit streams page

$agent->follow_link_ok( { text => 'Digital signs' }, 'go to Digital signs' );
$agent->follow_link_ok( { url_regex => qr/edit_streams&sign_id=$sign_id$/i }, 'click on Edit streams' );
$agent->content_lacks( "<td>$stream_name</td>", 'content lacks stream name in a table cell' );

### Delete sign

$agent->follow_link_ok( { text => 'Digital signs' }, 'go to Digital signs' );
$agent->follow_link_ok( { url_regex => qr/del_sign.*$sign_id/i }, 'click on Delete for sign' );
$agent->content_like( qr/Confirm deletion of sign/, 'page contains Confirm deletion of sign' );
$agent->content_like( qr/$sign_name/, 'content contains sign name' );

# TODO Cancel delete

# Confirm delete
$agent->submit_form_ok({
  form_id => 'confirm_sign_delete_form',
  fields  => {
    'op'      => 'del_sign_ok',
    'sign_id' => $sign_id,
  }
}, 'confirm delete of sign' );
$agent->content_like( qr/Sign deleted/, 'sign deleted' );

$agent->follow_link_ok( { text => 'Digital signs' }, 'go to Digital signs' );
$agent->content_lacks( $sign_name, 'digital signs lacks sign name' );
