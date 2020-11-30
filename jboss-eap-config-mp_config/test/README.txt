Tests for Microprofile Config configuration module

Prerequisites:

These tests require libxml2 (for xmllint) and bats
 $ dnf install libxml2 bats

Running the tests:
 $ bats test/mp-config.bats

You can get additional output by running:
 $ bats --tap test/mp-config.bats

 (See the bats manpage for more information.)

