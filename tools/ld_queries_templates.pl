#!/usr/bin/perl

# This file is part of Koha.
#
# Copyright (C) 2017 Magnus Enger
#
# Koha is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# Koha is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Koha; if not, see <http://www.gnu.org/licenses>.

use Modern::Perl;
use CGI qw( -utf8 );
use JSON;

use C4::Auth;
use C4::Output;

use Koha::LdMainTemplates;
use Koha::LdQueriesTemplates;

my $input  = CGI::->new;
my $op     = scalar $input->param('op');

my ( $template, $loggedinuser, $cookie ) = get_template_and_user(
    {   template_name   => "tools/ld_queries_templates.tt",
        query           => $input,
        type            => "intranet",
        authnotrequired => 0,
        # FIXME flagsrequired   => { tools => 'upload_general_files' },
    }
);

my $base_path = '/cgi-bin/koha/tools/ld_queries_templates.pl';
$template->param(
    'op'        => $op,
    'base_path' => $base_path,
);

if ( $op eq 'edit_template' ) {

    # Find the main template we want to edit
    my $ld_main_template_id = scalar $input->param('id');
    my $main_template = Koha::LdMainTemplates->find( $ld_main_template_id );
    $template->param(
        'main_template' => $main_template,
    );

} elsif ( $op eq 'save_template' ) {

    my $ld_main_template_id = scalar $input->param('ld_main_template_id');
    my $main_template;
    if ( $ld_main_template_id && $ld_main_template_id ne '' ) {
        # Find the main template
        $main_template = Koha::LdMainTemplates->find( $ld_main_template_id );
    } else {
        # ... or create a new one
        $main_template = Koha::LdMainTemplate->new();
    }

    # Save the (new) data
    $main_template->set({
        'name'          => scalar $input->param('name'),
        'type_uri'      => scalar $input->param('type_uri'),
        'main_template' => scalar $input->param('main_template'),
    });
    $main_template->store();

    # Redirect to the main screen
    print $input->redirect( $base_path );
    exit;

} elsif ( $op eq "queries" ) {

    my $ld_main_template_id = scalar $input->param('id');
    my $main_template = Koha::LdMainTemplates->find( $ld_main_template_id );

    my @queries = Koha::LdQueriesTemplates->search({
        'ld_main_template_id' => $ld_main_template_id,
    });

    $template->param(
        'main_template' => $main_template,
        'queries'       => \@queries,
    );

} elsif ( $op eq "save_query" ) {

    my $ld_queries_templates_id = scalar $input->param('ld_queries_templates_id');
    my $qt;
    if ( $ld_queries_templates_id && $ld_queries_templates_id ne '' ) {
        # Find the query-and-template
        $qt = Koha::LdQueriesTemplates->find( $ld_queries_templates_id );
    } else {
        # ... or create a new one
        $qt = Koha::LdQueriesTemplate->new();
    }

    # Save the (new) data
    $qt->set({
        'name'                => scalar $input->param('name'),
        'slug'                => scalar $input->param('slug'),
        'query'               => scalar $input->param('query'),
        'template'            => scalar $input->param('template'),
        'ld_main_template_id' => scalar $input->param('ld_main_template_id'),
    });
    $qt->store();

    # Redirect to the main screen
    print $input->redirect( "$base_path?op=queries&id=" . scalar $input->param('ld_main_template_id') );
    exit;

} else {

    # Get all the main templates
    my $main_templates = Koha::LdMainTemplates->search();
    $template->param(
        'main_templates' => $main_templates,
    );

}

output_html_with_http_headers $input, $cookie, $template->output;
