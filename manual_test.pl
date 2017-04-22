#!/usr/bin/perl

use strict;
use warnings;
use lib "lib";
use WebService::Docker::API;
use WebService::Docker::Info;
use Data::Dumper;

=lowlevel
my $api = new WebService::Docker::API({"trace"=>1});
print Dumper($api->get("/version"));

print Dumper($api->get("/networks"));

$api = new WebService::Docker::API({"docker_api_version"=>"1.12","trace"=>1});
print Dumper($api->get("/networks"));
=cut

my $info = new WebService::Docker::Info();
print Dumper($info);
