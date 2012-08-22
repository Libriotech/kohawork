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

my $op      = $cgi->param('op') || '';
my $sign_id = $cgi->param('sign_id') || '';

if ( $op eq 'add_sign' ) {

  # FIXME Is it possible to avoid duplicating this code?
  my $branches = GetBranches();
  my @branchloop;
  for my $thisbranch (sort { $branches->{$a}->{branchname} cmp $branches->{$b}->{branchname} } keys %$branches) {
    push @branchloop, {
        value => $thisbranch,
        branchname => $branches->{$thisbranch}->{'branchname'},
    };
  }

  $template->param(
    'branchloop' => \@branchloop,
    'op' => 'sign_form',
  );

} elsif ( $op eq 'edit_sign' && $sign_id ne '') {

  my $sign = GetSign( $sign_id );

  my $branches = GetBranches();
  my @branchloop;
  for my $thisbranch (sort { $branches->{$a}->{branchname} cmp $branches->{$b}->{branchname} } keys %$branches) {
    push @branchloop, {
        value => $thisbranch,
        selected => $thisbranch eq $sign->{'branchcode'},
        branchname => $branches->{$thisbranch}->{'branchname'},
    };
  }

  $template->param(
    'sign' => $sign,
    'branchloop' => \@branchloop,
    'op' => 'sign_form'
  );

} elsif ( $op eq 'save_sign' ) {

  if ($cgi->param('sign_id')) {
    EditSign( $cgi->param('branchcode'), $cgi->param('name'), $cgi->param('sign_id') );
  } else {
    AddSign( $cgi->param('branchcode'), $cgi->param('name') );
  }
  print $cgi->redirect($script_name);

} elsif ( $op eq 'del_sign' ) {

  my $sign = GetSign( $sign_id );

  $template->param(
    'op' => 'del_sign',
    'sign' => $sign,
    'script_name' => $script_name,
  );

} elsif ( $op eq 'del_sign_ok' ) {

  DeleteSign( $sign_id );

  $template->param(
    'op' => 'del_sign_ok',
    'script_name' => $script_name,
  );

} else {

  my $signs = GetAllSigns();

  $template->param(
    'signs' => $signs,
    'else' => 1
  );

}

output_html_with_http_headers $cgi, $cookie, $template->output;

exit 0;

=head1 AUTHORS

Written by Magnus Enger of Libriotech.

=cut
