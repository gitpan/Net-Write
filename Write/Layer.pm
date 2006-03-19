#
# $Id: Layer.pm,v 1.4 2006/03/17 11:16:49 gomor Exp $
#
package Net::Write::Layer;

require v5.6.1;

use strict;
use warnings;
use Carp;

require Class::Gomor::Hash;
our @ISA = qw(Class::Gomor::Hash);

our @AS = qw(
   dev
   dst
   protocol
   family
   _io
   _sockaddr
);

__PACKAGE__->buildAccessorsScalar(\@AS);

sub send {
   my $self = shift;
   my $raw  = shift;

   while (1) {
      my $ret = CORE::send($self->_io, $raw, 0, $self->_sockaddr);
      unless ($ret) {
         if ($!{ENOBUFS}) {
            $self->debugPrint(
               2, "send: ENOBUFS returned, sleeping for 1 second"
            );
            sleep 1;
            next;
         }
         elsif ($!{EHOSTDOWN}) {
            $self->debugPrint(2, "send: host is down");
            last;
         }
         carp("@{[(caller(0))[3]]}: send: $!\n");
      }
      last;
   }
}

sub close { shift->_io->close }

sub DESTROY {
   my $self = shift;

   if ($self->_io) {
      $self->close;
      $self->_io(undef);
   }
}

1;

__END__

=head1 NAME

Net::Write::Layer - base class for all LayerN modules

=head1 DESCRIPTION

This is the base class for B<Net::Write::Layer2>, B<Net::Write::Layer3> and B<Net::Write::Layer4> modules.

It just provides those layers with inheritable attributes and methods.

A descriptor is required when you want to send frames over network, this module just create this descriptor, and give the programmer methods to write to the network.

=head1 ATTRIBUTES

Attributes are specific to each LayerN module. Just see perldoc for the wanted LayerN.

=head1 METHODS

=over 4

=item B<new>

Object constructor.

=item B<send> (scalar)

Send the raw data passed as a parameter.

=item B<close>

Close the descriptor.

=back

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See Copying file in the source distribution archive.

=head1 RELATED MODULES

L<Net::Packet>, L<Net::RawIP>, L<Net::RawSock>

=cut
