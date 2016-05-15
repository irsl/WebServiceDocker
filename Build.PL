#!/usr/bin/perl

use strict;
use warnings;
use Module::Build;

  Module::Build->new(
      module_name        => 'WebService::Docker::Info',
      build_requires     => {
          'Test::More'  => '0',
      },
  )->create_build_script;
