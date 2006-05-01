#
# $Id: Write.pm,v 1.7 2006/05/01 17:58:17 gomor Exp $
#
package Net::Write;

require v5.6.1;

use strict;
use warnings;
use Carp;

our $VERSION = '0.81';

if ($^O =~ /cygwin|mswin32/i) {
   eval(
      'use Net::Pcap;'
   );
   if ($@) { croak("Error while eval: $@\n") }
}
else {
   eval(
      'require DynaLoader;'.
      ''.
      'our @ISA = qw(DynaLoader);'.
      ''.
      'bootstrap Net::Write $VERSION;'
   );
   if ($@) { croak("Error while eval: $@\n") }
}

1;

__END__

=head1 NAME

Net::Write - an interface to open and send raw frames to network

=head1 DESCRIPTION

B<Net::Write> provides a portable interface to open a network interface, and be able to write raw data directly to the network. It juste provides three methods when a B<Net::Write> object has been created for an interface: B<open>, B<send>, B<close>.

It is possible to open a network interface to send frames at layer 2 (you craft a frame from link layer), or at layer 3 (you craft a frame from network layer), or at layer 4 (you craft a frame from transport layer).

NOTE: not all operating systems support all layer opening. Currently, Windows only supports opening and sending at layer 2. Other Unix systems should be able to open and send at all layers.

See also B<Net::Write::Layer2>, B<Net::Write::Layer3>, B<Net::Write::Layer4> for specific information on opening network interfaces at these layers.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See Copying file in the source distribution archive.

=head1 RELATED MODULES

L<Net::Packet>, L<Net::RawIP>, L<Net::RawSock>

=cut
