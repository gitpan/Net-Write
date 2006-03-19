#
# $Id: Layer4.pm,v 1.3 2006/03/17 15:35:58 gomor Exp $
#
package Net::Write::Layer4;

require v5.6.1;

use strict;
use warnings;
use Carp;

require Exporter;
require Net::Write::Layer;
our @ISA = qw(Exporter Net::Write::Layer);

our %EXPORT_TAGS = (
   constants => [qw(
      NW_AF_INET
      NW_AF_INET6
      NW_IPPROTO_ICMPv4
      NW_IPPROTO_TCP
      NW_IPPROTO_UDP
      NW_IPPROTO_ICMPv6
   )],
);

our @EXPORT_OK = (
   @{$EXPORT_TAGS{constants}},
);

use Socket;
use Socket6;
use IO::Socket;

use constant NW_AF_INET => AF_INET();

use constant NW_IPPROTO_ICMPv4 => 1;
use constant NW_IPPROTO_TCP    => 6;
use constant NW_IPPROTO_UDP    => 17;
use constant NW_IPPROTO_ICMPv6 => 58;

BEGIN {
   if ($^O =~ /cygwin|mswin32/i) {
      eval('use constant NW_AF_INET6 => 23;')
   }
   else {
      eval('use constant NW_AF_INET6 => AF_INET6();');
   }

   my $osname = {
      cygwin  => \&_newWin32,
      MSWin32 => \&_newWin32,
   };

   *new  = $osname->{$^O} || \&_newOther;
}

sub _newWin32 { croak("@{[(caller(0))[3]]}: not implemented under Win32\n") }

sub _newOther {
   my $self = shift->SUPER::new(
      protocol => NW_IPPROTO_TCP,
      family   => NW_AF_INET,
      @_,
   );

   croak("@{[(caller(0))[3]]}: you must pass `dst' parameter\n")
      unless $self->dst;

   $self;
}

sub open {
   my $self = shift;

   croak("Must be EUID 0 to open a device for writing\n")
      if $>;

   my @res = getaddrinfo($self->dst, 0, $self->family, SOCK_STREAM)
      or croak("@{[(caller(0))[3]]}: getaddrinfo: $!\n");

   my ($family, $saddr) = @res[0, 3] if @res >= 5;
   $self->_sockaddr($saddr);

   socket(S, $self->family, SOCK_RAW, $self->protocol)
      or croak("@{[(caller(0))[3]]}: socket: $!\n");

   my $fd = fileno(S) or croak("@{[(caller(0))[3]]}: fileno: $!\n");

   my $io = IO::Socket->new;
   $io->fdopen($fd, 'w') or croak("@{[(caller(0))[3]]}: fdopen: $!\n");
   $self->_io($io);

   1;
}

1;

__END__

=head1 NAME

Net::Write::Layer4 - object for a transport layer (layer 4) descriptor

=head1 SYNOPSIS

   use Net::Write::Layer4 qw(:constants);

   # To send a TCP segment to the network
   # Encapsulated within an IPv4 network layer
   my $desc = Net::Write::Layer4->new(
      dst      => $targetIpAddress,
      protocol => NW_IPPROTO_TCP,
      family   => NW_AF_INET,
   );

   $desc->open;
   $desc->send($rawStringToNetwork);
   $desc->close;

=head1 DESCRIPTION

This is the class for creating a layer 4 descriptor.

=head1 ATTRIBUTES

=over 4

=item B<dev>

The string specifying network interface to use.

=item B<dst>

The target IP address we will send frames to.

=back

=head1 METHODS

See B<Net::Write::Layer> for inherited methods.

=head1 CONSTANTS

Load them: use Net::Write::Layer4 qw(:constants);

=over 4

=item B<NW_AF_INET>

=item B<NW_AF_INET6>

Address family constants.

=item B<NW_IPPROTO_TCP>

=item B<NW_IPPROTO_UDP>

=item B<NW_IPPROTO_ICMPv4>

=item B<NW_IPPROTO_ICMPv6>

Protocol type constants.

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
