#
# $Id: Layer3.pm,v 1.4 2006/03/17 14:57:57 gomor Exp $
#
package Net::Write::Layer3;

require v5.6.1;

use strict;
use warnings;
use Carp;

require Net::Write::Layer;
our @ISA = qw(Net::Write::Layer);

BEGIN {
   my $osname = {
      cygwin  => \&_newWin32,
      MSWin32 => \&_newWin32,
   };

   *new  = $osname->{$^O} || \&_newOther;
}

use Socket;
use Socket6;
use IO::Socket;

sub _newWin32 { croak("@{[(caller(0))[3]]}: not implemented under Win32\n") }

sub _newOther {
   my $self = shift->SUPER::new(@_);

   croak("@{[(caller(0))[3]]}: you must pass `dst' parameter\n")
      unless $self->dst;

   $self;
}

use constant NW_IPPROTO_IP  => 0;
use constant NW_IP_HDRINCL  => 2;
use constant NW_IPPROTO_RAW => 255;

sub open {
   my $self = shift;

   croak("Must be EUID 0 to open a device for writing\n")
      if $>;

   my @res = getaddrinfo($self->dst, 0, AF_UNSPEC, SOCK_STREAM);
   my ($family, $saddr) = @res[0, 3] if @res >= 5;

   $self->_sockaddr($saddr);

   socket(S, $family, SOCK_RAW, NW_IPPROTO_RAW)
      or croak("@{[(caller(0))[3]]}: socket: $!\n");

   if ($family == AF_INET) {
      setsockopt(S, NW_IPPROTO_IP, NW_IP_HDRINCL, 1)
         or croak("@{[(caller(0))[3]]}: setsockopt: $!\n");
   }

   my $fd = fileno(S) or croak("@{[(caller(0))[3]]}: fileno: $!\n");

   my $io = IO::Socket->new;
   $io->fdopen($fd, 'w') or croak("@{[(caller(0))[3]]}: fdopen: $!\n");
   $self->_io($io);

   1;
}

1;

__END__

=head1 NAME

Net::Write::Layer3 - object for a network layer (layer 3) descriptor

=head1 SYNOPSIS

   require Net::Write::Layer3;

   my $desc = Net::Write::Layer3->new(
      dev => $networkInterface,
      dst => $targetIpAddress,
   );

   $desc->open;
   $desc->send($rawStringToNetwork);
   $desc->close;

=head1 DESCRIPTION

This is the class for creating a layer 3 descriptor.

=head1 ATTRIBUTES

=over 4

=item B<dev>

The string specifying network interface to use.

=item B<dst>

The target IP address we will send frames to.

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
