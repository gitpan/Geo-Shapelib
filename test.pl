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

my $shapefile = 'test_shape';

my $shape = new Geo::Shapelib { 
    Name => $shapefile,
    Shapetype => POINT,
    FieldNames => ['Name','Code','Founded'],
    FieldTypes => ['String:50','String:10','Integer:8']
    };

print "ok 2\n";

while (<DATA>) {
    chomp;
    ($station,$code,$founded,$x,$y) = split /\|/;
    push @{$shape->{Shapes}}, {
	Vertices=>[[$x,$y]]
	};
    push @{$shape->{ShapeRecords}}, [$station,$code,$founded];
}

$shape->dump("$shapefile.dump");

print "ok 3\n";

$shape->save();

print "ok 4\n";

my $shape2 = new Geo::Shapelib $shapefile;

print "ok 5\n";

($shape->{Shapes}->[2]->{Vertices}->[0]->[1] == 
 $shape2->{Shapes}->[2]->{Vertices}->[0]->[1] and 
 $shape->{Shapes}->[2]->{Vertices}->[0]->[1] == 6722622) ? print "ok 6\n" : print "not ok 6\n";

system "rm -f $shapefile.*";



__DATA__
Helsinki-Vantaan Lentoasema|HVL|19780202|3387419|6692222
Helsinki Kaisaniemi        |HK|19580201|3385926|6675529
Hyvinkää Mutila            |HM|19630302|3379813|6722622
Nurmijärvi Rajamäki        |HR|19340204|3376486|6715764
Vihti Maasoja              |VM|19230502|3356766|6703481
Porvoo Järnböle            |PJ|19450202|3426574|6703254
Porvoon Mlk Bengtsby       |PMB|19670202|3424354|6684723
Orimattila Käkelä          |OK|19560202|3432847|6743998
Tuusula Ruotsinkylä        |TR|19750402|3388723|6696784
