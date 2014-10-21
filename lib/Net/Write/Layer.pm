#
# $Id: Layer.pm 2000 2012-08-31 14:57:05Z gomor $
#
package Net::Write::Layer;
use strict;
use warnings;

use base qw(Exporter Class::Gomor::Array);
our @AS = qw(
   dev
   dst
   protocol
   family
   _io
   _sockaddr
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

sub _setIpProtoIpConstant {
   my $val = 0;
   if (defined(&IPPROTO_IP)) {
      $val = &IPPROTO_IP;
   }
   elsif ($^O eq 'darwin'
      ||  $^O eq 'linux'
      ||  $^O eq 'freebsd'
      ||  $^O eq 'openbsd'
      ||  $^O eq 'netbsd'
      ||  $^O eq 'aix') {
      $val = 0;
   }
   eval "use constant NW_IPPROTO_IP => $val;";
}

sub _setIpProtoIpv6Constant {
   my $val = 0;
   if (defined(&IPPROTO_IPv6)) {
      $val = &IPPROTO_IPv6;
   }
   elsif ($^O eq 'linux'
      ||  $^O eq 'freebsd') {
      $val = 41;
   }
   eval "use constant NW_IPPROTO_IPv6 => $val;";
}

sub _setIpProtoRawConstant {
   my $val = 255;
   if (defined(&IPPROTO_RAW)) {
      $val = &IPPROTO_RAW;
   }
   elsif ($^O eq 'darwin'
      ||  $^O eq 'linux'
      ||  $^O eq 'freebsd'
      ||  $^O eq 'openbsd'
      ||  $^O eq 'netbsd'
      ||  $^O eq 'aix') {
      $val = 255;
   }
   eval "use constant NW_IPPROTO_RAW => $val;";
}

sub _setIpHdrInclConstant {
   my $val = 2;
   if (defined(&IP_HDRINCL)) {
      $val = &IP_HDRINCL;
   }
   elsif ($^O eq 'darwin'
      ||  $^O eq 'freebsd'
      ||  $^O eq 'openbsd'
      ||  $^O eq 'netbsd'
      ||  $^O eq 'linux'
      ||  $^O eq 'aix'
      ||  $^O eq 'cygwin') {
      $val = 2;
   }
   elsif ($^O eq 'hpux') {
      $val = 0x1002;
   }
   eval "use constant NW_IP_HDRINCL => $val;";
}

sub _setAfinet6Constant {
   require Socket6;
   require Socket;
   my $val = 0;
   if (defined(&Socket6::AF_INET6)) {
      $val = &Socket6::AF_INET6;
   }
   elsif (defined(&Socket::AF_INET6)) {
      $val = &Socket::AF_INET6;
   }
   eval "use constant NW_AF_INET6  => $val;";
}

BEGIN {
   my $osname = {
      cygwin  => \&_checkWin32,
      MSWin32 => \&_checkWin32,
   };

   *_check  = $osname->{$^O} || \&_checkOther;
   _setIpProtoIpConstant();
   _setIpProtoIpv6Constant();
   _setIpProtoRawConstant();
   _setIpHdrInclConstant();
   _setAfinet6Constant();
}

no strict 'vars';

use Socket;
use Socket6 qw(getaddrinfo);
use IO::Socket;
use Net::Pcap;

use constant NW_AF_INET   => AF_INET();
use constant NW_AF_UNSPEC => AF_UNSPEC();

use constant NW_IPPROTO_ICMPv4 => 1;
use constant NW_IPPROTO_TCP    => 6;
use constant NW_IPPROTO_UDP    => 17;
use constant NW_IPPROTO_ICMPv6 => 58;

our %EXPORT_TAGS = (
   constants => [qw(
      NW_AF_INET
      NW_AF_INET6
      NW_AF_UNSPEC
      NW_IPPROTO_IP
      NW_IPPROTO_IPv6
      NW_IPPROTO_ICMPv4
      NW_IPPROTO_TCP
      NW_IPPROTO_UDP
      NW_IPPROTO_ICMPv6
      NW_IP_HDRINCL
      NW_IPPROTO_RAW
   )],
);

our @EXPORT_OK = (
   @{$EXPORT_TAGS{constants}},
);

sub _checkWin32 { }

sub _checkOther {
   if ($>) {
      print STDERR "[-] Must be EUID 0 (or equivalent) to open a device for ".
                   "writing.\n";
      return;
   }
}

sub new {
   my $self = shift->SUPER::new(
      @_,
   ) or return;

   _check() or return;

   return $self;
}

sub _croak {
   my ($msg) = @_;
   print STDERR "[-] $msg\n";
   return;
}

sub open {
   my $self = shift;
   my ($hdrincl) = @_;

   my @res = getaddrinfo($self->[$__dst], 0, $self->[$__family], SOCK_STREAM)
      or return _croak("@{[(caller(0))[3]]}: getaddrinfo: $!");

   my ($family, $saddr) = @res[0, 3] if @res >= 5;
   $self->[$___sockaddr] = $saddr;

   socket(my $s, $family, SOCK_RAW, $self->[$__protocol])
      or return _croak("@{[(caller(0))[3]]}: socket: $!");

   my $fd = fileno($s)
      or return _croak("@{[(caller(0))[3]]}: fileno: $!");

   if ($hdrincl) {
      $self->_setIpHdrincl($s, $self->[$__family])
         or return _croak("@{[(caller(0))[3]]}: setsockopt: $!");
   }

   my $io = IO::Socket->new;
   $io->fdopen($fd, 'w')
      or return _croak("@{[(caller(0))[3]]}: fdopen: $!");

   $self->[$___io] = $io;

   return 1;
}

sub send {
   my $self = shift;
   my ($raw) = @_;

   while (1) {
      my $ret = CORE::send($self->_io, $raw, 0, $self->_sockaddr);
      unless ($ret) {
         if ($!{ENOBUFS}) {
            $self->cgDebugPrint(2, "ENOBUFS returned, sleeping for 1 second");
            sleep 1;
            next;
         }
         elsif ($!{EHOSTDOWN}) {
            $self->cgDebugPrint(2, "host is down");
            last;
         }
         print STDERR "[!] @{[(caller(0))[3]]}: $!\n";
         return;
      }
      last;
   }

   return 1;
}

sub close { shift->_io->close }

1;

__END__

=head1 NAME

Net::Write::Layer - base class and constants

=head1 SYNOPSIS

   use Net::Write::Layer qw(:constants);

=head1 DESCRIPTION

This is the base class for B<Net::Write::Layer2>, B<Net::Write::Layer3> and B<Net::Write::Layer4> modules.

It just provides those layers with inheritable attributes, methods and constants.

=head1 ATTRIBUTES

=over 4

=item B<dev>

Network interface to use.

=item B<dst>

Target IPv4 or IPv6 address.

=item B<protocol>

Transport layer protocol to use (TCP, UDP, ...).

=item B<family>

Adresse family to use (NW_AF_INET, NW_AF_INET6).

=back

=head1 METHODS

=over 4

=item B<new>

Object constructor. Returns undef on error.

=item B<open>

Open the descriptor, when you are ready to B<send>. Returns undef on error.

=item B<send> (scalar)

Send the raw data passed as a parameter. Returns undef on failure, true otherwise.

=item B<close>

Close the descriptor.

=back

=head1 CONSTANTS

=over 4

=item B<NW_AF_INET>

=item B<NW_AF_INET6>

=item B<NW_AF_UNSPEC>

Address family constants, for use with B<family> attribute.

=item B<NW_IPPROTO_IP>

=item B<NW_IPPROTO_IPv6>

=item B<NW_IPPROTO_ICMPv4>

=item B<NW_IPPROTO_TCP>

=item B<NW_IPPROTO_UDP>

=item B<NW_IPPROTO_ICMPv6>

Transport layer protocol constants, for use with B<protocol> attribute.

=item B<NW_IP_HDRINCL>

=item B<NW_IPPROTO_RAW>

Mostly used internally.

=back

=head1 SEE ALSO

L<Net::Write::Layer2>, L<Net::Write::Layer3>, L<Net::Write::Layer4>

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006-2012, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
