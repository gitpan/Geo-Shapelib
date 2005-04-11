use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'Geo::Shapelib',
    'VERSION_FROM'	=> 'Shapelib.pm',
    PREREQ_PM           => {Tree::R => 0.01}, # e.g., Module::Name => 1.1

# next 2 lines for external libshp, uncomment if you want to use an external libshp
#    'LIBS'		=> ['-L/usr/local/lib -lshp'], # change if you have libshp somewhere else
#    'INC'		=> '-I/usr/local/include',     # change if you have shapefil.h somewhere else

# next 3 lines for internal libshp, comment out if you want to use an external libshp
    'LIBS'		=> [''],                       
    'MYEXTLIB'          => 'shapelib/libshp$(LIB_EXT)',# internal libshp
    'INC'		=> '-I./',

    'DEFINE'		=> '-ggdb',
    clean               => {'FILES' => 'stations.* example/test.*'},
    
);

sub MY::postamble {
'
$(MYEXTLIB): shapelib/Makefile
	cd shapelib && $(MAKE) $(PASTHRU)
';
}
