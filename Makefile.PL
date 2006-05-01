use ExtUtils::MakeMaker;

# For Solaris
my $libs = '';
if ($^O =~ /solaris/) {
   $libs .= '-L/lib -ldlpi';
}

WriteMakefile(
   NAME          => 'Net::Write',
   VERSION_FROM  => 'lib/Net/Write.pm',
   ABSTRACT_FROM => 'lib/Net/Write.pm',
   PREREQ_PM     => {
      Class::Gomor => 0,
      Socket6      => 0,
      Net::Pcap    => '0.12',
   },
   LIBS          => $libs,
   AUTHOR        => 'GomoR <perl@gomor.org>',
   OBJECT        => '$(O_FILES)',
);
