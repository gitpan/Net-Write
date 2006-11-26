#!/usr/bin/perl
use strict;
use warnings;

my $target = shift || die("Specify an IPv4 address as a parameter\n");

use Net::Packet::Env qw($Env);
$Env->updateDevInfo($target);
$Env->noFrameAutoDesc(1);
$Env->noFrameAutoDump(1);

use Net::Write::Layer3;

my $l3 = Net::Write::Layer3->new(
   dst => $target,
);

use Net::Packet::IPv4;
my $ip4 = Net::Packet::IPv4->new(dst => $target);
$ip4->pack;

use Net::Packet::TCP;
my $tcp = Net::Packet::TCP->new(dst => 22);
$tcp->pack;

use Net::Packet::Frame;
my $frame = Net::Packet::Frame->new(l3 => $ip4, l4 => $tcp);

print $frame->print."\n";

$l3->open;
$l3->send($frame->raw);
$l3->close;
