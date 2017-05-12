#!/usr/bin/perl

use Modern::Perl;
use Test::More tests => 4;
use Test::Exception;
use YAML;
use File::Temp qw/ tempfile /;

use C4::Context;

#Make a temporary configuration file for the triplestore
my ($fh, $filename) = tempfile(undef, UNLINK => 1);
my $temp_config = {
    models => {
        test => {
            module => 'RDF::Trine::Store::SPARQL',
            url => 'http://localhost/example/rdf',
            realm => undef,
            username => undef,
            password => undef,
        }
    }
};

#Tell C4::Context to use the temporary configuration file as the triplestore_config
my $context = $C4::Context::context;
$context->{config}->{triplestore_config} = $filename;

subtest 'success' => sub {
    YAML::DumpFile($filename, $temp_config);

    my $context_object = C4::Context->new();
    my $triplestore = $context_object->triplestore("test");
    is(ref $triplestore, 'RDF::Trine::Model', 'C4::Context->new()->triplestore returns RDF::Trine::Model if module equals RDF::Trine::Store::SPARQL');
};

subtest 'missing url' => sub {
    #Reset triplestore context
    delete $context->{triplestore}->{test};

    my $url = delete $temp_config->{models}->{test}->{url};
    YAML::DumpFile($filename, $temp_config);

    my $context_object = C4::Context->new();
    my $triplestore = $context_object->triplestore("test");
    is($triplestore, undef, 'C4::Context->new()->triplestore returns undef if missing url for SPARQL store');

    #Restore url for other tests
    $temp_config->{url} = $url;
};

subtest 'bad module' => sub {
    #Reset triplestore context
    delete $context->{triplestore}->{test};

    $temp_config->{module} = 'Local::RDF::Bad::Module';
    YAML::DumpFile($filename, $temp_config);

    my $context_object = C4::Context->new();
    my $triplestore = $context_object->triplestore("test");
    is($triplestore, undef, 'C4::Context->new()->triplestore returns undef if module equals Local::RDF::Bad::Module');
};

subtest 'missing model name' => sub {
    my $context_object = C4::Context->new();
    dies_ok { $context_object->triplestore } 'C4::Context::triplestore() method dies if no model name provided';
};
