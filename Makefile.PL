#
# $Id: Makefile.PL 1636 2009-06-10 18:38:24Z gomor $
#
use ExtUtils::MakeMaker;

WriteMakefile(
   NAME          => 'Net::Write',
   LICENSE       => 'artistic',
   VERSION_FROM  => 'lib/Net/Write.pm',
   ABSTRACT_FROM => 'lib/Net/Write.pm',
   PREREQ_PM     => {
      Class::Gomor => 0,
      Socket6      => 0,
      Net::Pcap    => '0.12',
   },
   AUTHOR        => 'GomoR <gomor-cpan_at_gomor.org>',
);
