use ExtUtils::MakeMaker;

# For Solaris
my $libs = '';
if ($^O =~ /solaris/) {
   $libs .= '-L/lib -ldlpi';
}

WriteMakefile(
   NAME          => 'Net::Write',
   VERSION_FROM  => 'Write.pm',
   PREREQ_PM     => {
      Class::Gomor::Hash => '0.22',
      Socket6            => 0,
      Net::Pcap          => '0.12',
   },
   ABSTRACT_FROM => 'Write.pm',
   LIBS          => $libs,
   AUTHOR        => 'GomoR <perl@gomor.org>',
   OBJECT        => '$(O_FILES)',
);
