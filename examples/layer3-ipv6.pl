#!/usr/bin/perl
use strict;
use warnings;

my $target = shift || die("Specify an IPv6 address as a parameter\n");

use Net::Packet::Env qw($Env);
$Env->noFrameAutoDesc(1);
$Env->noFrameAutoDump(1);

use Net::Write::Layer qw(:constants);
use Net::Write::Layer3;

my $l3 = Net::Write::Layer3->new(
   dst    => $target,
   family => NW_AF_INET6,
);

use Net::Packet::IPv6;
my $ip6 = Net::Packet::IPv6->new(dst => $target, hopLimit => 3);
$ip6->pack;

use Net::Packet::TCP;
my $tcp = Net::Packet::TCP->new(dst => 22);
$tcp->pack;

use Net::Packet::Frame;
my $frame = Net::Packet::Frame->new(l3 => $ip6, l4 => $tcp);

print $frame->print."\n";

$l3->open;
$l3->send($frame->raw);
$l3->close;
