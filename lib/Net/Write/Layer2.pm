#
# $Id: Layer2.pm,v 1.9 2006/10/29 13:27:11 gomor Exp $
#
package Net::Write::Layer2;
use strict;
use warnings;
use Carp;

require Net::Write::Layer;
our @ISA = qw(Net::Write::Layer);
__PACKAGE__->cgBuildIndices;

BEGIN {
   my $osname = {
      cygwin  => [ \&_openWin32, \&_sendWin32, \&_closeWin32, ],
      MSWin32 => [ \&_openWin32, \&_sendWin32, \&_closeWin32, ],
      linux   => [ \&_openOther, \&_sendLinux, undef,         ],
   };

   *open  = $osname->{$^O}->[0] || \&_openOther;
   *send  = $osname->{$^O}->[1] || \&_sendOther;
   *close = $osname->{$^O}->[2] || \&_closeOther;
}

require IO::Socket;
require Net::Write;

no strict 'vars';

sub _openOther {
   my $self = shift;

   croak("Must be EUID 0 to open a device for writing\n")
      if $>;

   croak("@{[(caller(0))[3]]}: you dit not specify dev attribute\n")
      unless $self->dev;

   my $fd = Net::Write::netwrite_open($self->[$__dev])
      or croak("@{[(caller(0))[3]]}: netwrite_open: @{[$self->dev]}: $!\n");

   my $io = IO::Socket->new;
   $io->fdopen($fd, 'w') or croak("@{[(caller(0))[3]]}: fdopen: $!\n");
   $self->[$___io] = $io;

   1;
}

sub _openWin32 {
   my $self = shift;

   my $err;
   my $pd = Net::Pcap::open_live(
      $self->[$__dev],
      1514,
      0,
      1000,
      \$err,
   );
   unless ($pd) {
      croak("@{[(caller(0))[3]]}: open_live: @{[$self->dev]}: $!\n");
   }

   $self->[$___io] = $pd;

   1;
}

sub _sendLinux {
   my $self = shift;
   my ($raw) = @_;

   # Here is the Linux dirty hack (to choose outgoing device, surely)
   my $sin = pack('S a14', 0, $self->[$__dev]);

   while (1) {
      my $ret = CORE::send($self->[$___io], $raw, 0, $sin);
      unless ($ret) {
         if ($!{ENOBUFS}) {
            $self->cgDebugPrint(2, "send: got ENOBUFS, sleeping 1 second");
            sleep 1;
            next;
         }
         elsif ($!{EHOSTDOWN}) {
            $self->cgDebugPrint(2, "send: host is down");
            last;
         }
         carp("@{[(caller(0))[3]]}: send: $!\n");
         return undef;
      }
      last;
   }
   1;
}

sub _sendOther {
   my $self = shift;
   my ($raw) = @_;

   while (1) {
      my $ret = $self->[$___io]->syswrite($raw, length($raw));
      unless ($ret) {
         if ($!{ENOBUFS}) {
            $self->cgDebugPrint(2, "syswrite: got ENOBUFS, sleeping 1 second");
            sleep 1;
            next;
         }
         elsif ($!{EHOSTDOWN}) {
            $self->cgDebugPrint(2, "syswrite: host is down");
            last;
         }
         carp("@{[(caller(0))[3]]}: syswrite: $!\n");
         return undef;
      }
      last;
   }
   1;
}

sub _sendWin32 {
   my $self = shift;
   my ($raw) = @_;

   if (Net::Pcap::sendpacket($self->[$___io], $raw) < 0) {
      carp("@{[(caller(0))[3]]}: send: ".Net::Pcap::geterr($self->[$___io]).
           "\n");
      return undef;
   }
   1;
}

sub _closeWin32 { Net::Pcap::close(shift->[$___io]) }
sub _closeOther { shift->SUPER::close(@_)           }

1;

__END__

=head1 NAME

Net::Write::Layer2 - object for a link layer (layer 2) descriptor

=head1 SYNOPSIS

   require Net::Write::Layer2;

   # Usually, you use it to send ARP frames,
   # that is crafted from ETH layer
   # Under Windows, to send frames, you MUST craft from layer 2
   my $desc = Net::Write::Layer2->new(
      dev => $networkInterface,
   );

   $desc->open;
   $desc->send($rawStringToNetwork);
   $desc->close;

=head1 DESCRIPTION

This is the class for creating a layer 2 descriptor.

=head1 ATTRIBUTES

=over 4

=item B<dev>

The string specifying network interface to use.

Under Unix-like systems, this is in this format: \w+\d+ (example: eth0).

Under Windows systems, this is more complex; example:
\Device\NPF_{0749A9BC-C665-4C55-A4A7-34AC2FBAB70F}

=back

=head1 METHODS

See B<Net::Write::Layer> for inherited methods.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See Copying file in the source distribution archive.

=head1 RELATED MODULES

L<Net::Packet>, L<Net::RawIP>, L<Net::RawSock>

=cut
