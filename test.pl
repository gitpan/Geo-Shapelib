# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..1\n"; }
END {print "not ok 1\n" unless $loaded;}
use Geo::Shapelib qw /:all/;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$shape = new Geo::Shapelib;

$shape->{Shapetype} = 1;

$shape->{FieldNames} = ['ID','Name','Value'];
$shape->{FieldTypes} = ['Integer','String:50','Double'];

$i = 0;
while (<DATA>) {
    chomp;
    ($station,$x,$y) = split /\|/;
    push @{$shape->{Shapes}}, {
	SHPType=>1, 
	ShapeId=>$i, 
	NParts=>0, 
	NVertices=>1, 
	Vertices=>[[$x,$y]]
	};
    push @{$shape->{ShapeRecords}}, [$i,$station,$i];
    $i++;
}

$shape->save('stations');

my $shapefile = 'example/masspntz';

my $shape = new Geo::Shapelib($shapefile);

#$shape->dump();

$shape->save('example/test');

__DATA__
Helsinki-Vantaan Lentoasema|3387419|6692222
Helsinki Kaisaniemi        |3385926|6675529
Hyvinkää Mutila            |3379813|6722622
Nurmijärvi Rajamäki        |3376486|6715764
Vihti Maasoja              |3356766|6703481
Porvoo Järnböle            |3426574|6703254
Porvoon Mlk Bengtsby       |3424354|6684723
Orimattila Käkelä          |3432847|6743998
Tuusula Ruotsinkylä        |3388723|6696784
