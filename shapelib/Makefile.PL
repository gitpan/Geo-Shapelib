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

# for GNU Linux use this:
	      DEFINE    => '-ggdb -Wall -DDEBUG',
# for W2k Visual Studio 6 use this:
#	      DEFINE    => '-ggdb -DDEBUG',

	      clean     => {'FILES' => 'libshp$(LIB_EXT)'},
	      );

sub MY::top_targets {
'
pure_all ::

all :: static

static :: libshp$(LIB_EXT)

libshp$(LIB_EXT): $(O_FILES)

# for GNU Linux use this:
	$(AR) cr libshp$(LIB_EXT) $(O_FILES)
# for W2k Visual Studio 6 use this:
#	$(AR) /OUT:libshp$(LIB_EXT) $(O_FILES)

	$(RANLIB) libshp$(LIB_EXT)
';
}
