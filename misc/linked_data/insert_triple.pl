#!/usr/bin/perl

use C4::Context;

use Data::Dumper;
use Modern::Perl;

my $triplestore = C4::Context->triplestore;

my $s = RDF::Trine::Node::Resource->new( 'http://example.com/one/' );
my $p = RDF::Trine::Node::Resource->new( 'http://example.com/two/' );
my $o = RDF::Trine::Node::Resource->new( 'http://example.com/three/' );

my $st = RDF::Trine::Statement->new( $s, $p, $o );
my $data = $triplestore->add_statement ( $st );

# Alternate way:
# my $hr = {
#     "http://example.com/subject1" => {
#         "http://example.com/predicate1" => [
#             { 'type'=>'literal', 'value'=>"Baz", 'lang'=>"en" },
#         ],
#     },
# };
# my $data = $triplestore->add_hashref( $hr );

say Dumper $data;
