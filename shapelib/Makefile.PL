use ExtUtils::MakeMaker;
$Verbose = 1;

my @incdirs = ('/usr/include','/usr/local/include');
my $incs = '';
foreach (@incdirs) {
    $incs .= " -I$_";
}

WriteMakefile(
	      NAME      => 'Geo::Shapelib::shputils',
	      INC	=> $incs,
	      DEFINE    => '-ggdb -Wall -DDEBUG',
	      clean     => {'FILES' => 'libshp$(LIB_EXT)'},
	      );

sub MY::top_targets {
'
pure_all ::

all :: static

static :: libshp$(LIB_EXT)

libshp$(LIB_EXT): $(O_FILES)
	$(AR) cr libshp$(LIB_EXT) $(O_FILES)
	$(RANLIB) libshp$(LIB_EXT)
';
}
