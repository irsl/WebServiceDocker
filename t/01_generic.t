#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests=>4;
use Test::MockModule;
use FindBin qw($Bin);
use WebService::Docker::Info;


{
  my $docker_defs = require("$Bin/01_docker_definitions.pl");

  my $module = Test::MockModule->new('WebService::Docker::API');
  $module->mock('networks',   sub { return $docker_defs->{'mocked_networks_response'}; });
  $module->mock('containers', sub { return $docker_defs->{'mocked_containers_response'}; });
  $module->mock('container_info', sub {
     my ($obj, $id) = @_;
     return $docker_defs->{'mocked_container_infos'}->{$id}; 
  });
  $module->mock('network_info', sub {
     my ($obj, $id) = @_;
     return $docker_defs->{'mocked_network_info'}->{$id}; 
  });

  my $docker_info = new WebService::Docker::Info(undef, 1);

  ok(defined($docker_info->{'container_by_name'}->{'mariadb-4'}->{'NetworkList'}->{'172.24.0.5'}));
  is_deeply( 
        $docker_info->get_expose_ports("172.24.0.5"), 
        [
          {
            'family' => 'tcp',
            'container_port' => 3306,
            'host_port' => 3306
          }
        ] 
   );
   ok("/var/lib/docker/containers/568468ea1b56f6420c06f2e4a8da3e01af3aee91719ce6612030ff9afca82510/hosts" eq  $docker_info->get_hosts_file_by_container_name("dfwfw-1"));
   ok(1886 == $docker_info->get_pid_by_container_name("proftpd-test"));

}

