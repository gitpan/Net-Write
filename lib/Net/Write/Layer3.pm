#
# $Id: Layer3.pm,v 1.9 2006/11/26 18:40:35 gomor Exp $
#
package Net::Write::Layer3;
use strict;
use warnings;
use Carp;

use Net::Write::Layer qw(:constants);
our @ISA = qw(Net::Write::Layer);
__PACKAGE__->cgBuildIndices;

BEGIN {
   my $osname = {
      cygwin  => \&_newWin32,
      MSWin32 => \&_newWin32,
   };

   *new  = $osname->{$^O} || \&_newOther;
}

no strict 'vars';

sub _newWin32 {
   croak("Not possible to use layer 3 under Windows. Use layer 2 instead.\n");
}

sub _newOther {
   my $self = shift->SUPER::new(
      protocol => NW_IPPROTO_RAW,
      family   => NW_AF_INET,
      @_,
   );

   croak("@{[(caller(0))[3]]}: you must pass `dst' parameter\n")
      unless $self->[$__dst];

   $self;
}

sub open { shift->SUPER::open(1) }

1;

__END__

=head1 NAME

Net::Write::Layer3 - object for a network layer (layer 3) descriptor

=head1 SYNOPSIS

   use Net::Write::Layer qw(:constants);
   use Net::Write::Layer3;

   my $desc = Net::Write::Layer3->new(
      dst      => '192.168.0.1',
      protocol => NW_IPPROTO_RAW,
      family   => NW_AF_INET,
   );

   $desc->open;
   $desc->send('G'x666);
   $desc->close;

=head1 DESCRIPTION

This is the class for creating a layer 3 descriptor.

=head1 ATTRIBUTES

=over 4

=item B<dst>

The target IPv4 or IPv6 address we will send frames to.

=item B<family>

Address family, see B<Net::Write::Layer> CONSTANTS section.

=item B<protocol>

Transport layer protocol to use, see B<Net::Write::Layer> CONSTANTS section.

=back

=head1 METHODS

=over 4

=item B<new>

Object constructor. You MUST pass a valid B<dst> attribute. Default values:

protocol: NW_IPPROTO_RAW

family:   NW_AF_INET

=item B<open>

Open the interface.

=item B<send> (scalar)

Send raw data to the network.

=item B<close>

Close the descriptor.

=back

=head1 CAVEATS

Sending IPv6 frames does not work under BSD systems. They can't do IP_HDRINCL for IPv6.

Does not work at all under Win32 systems. They can't send frames at layer 3.

=head1 SEE ALSO

L<Net::Write::Layer>

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
