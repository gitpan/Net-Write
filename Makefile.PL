use ExtUtils::MakeMaker;

WriteMakefile(
   NAME          => 'Net::Write',
   LICENSE       => 'Artistic',
   VERSION_FROM  => 'lib/Net/Write.pm',
   ABSTRACT_FROM => 'lib/Net/Write.pm',
   PREREQ_PM     => {
      Class::Gomor => 0,
      Socket6      => 0,
      Net::Pcap    => '0.12',
   },
   AUTHOR        => 'GomoR <perl@gomor.org>',
);
