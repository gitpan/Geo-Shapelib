use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'Geo::Shapelib',
    'VERSION_FROM'	=> 'Shapelib.pm',
    'LIBS'		=> ['-L/usr/local/lib -lshp'], # change if you have libshp somewhere else
    'DEFINE'		=> '-ggdb',
    'INC'		=> '-I/usr/local/include', # change if you have shapefil.h somewhere else
);
