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

my $shapefile = 'example/test';

my $shape = new Geo::Shapelib { 
    Name => $shapefile,
    Shapetype => POINT,
    FieldNames => ['Name','Code','Founded'],
    FieldTypes => ['String:50','String:10','Integer:8']
    };

while (<DATA>) {
    chomp;
    ($station,$code,$founded,$x,$y) = split /\|/;
    push @{$shape->{Shapes}}, {
	Vertices=>[[$x,$y]]
	};
    push @{$shape->{ShapeRecords}}, [$station,$code,$founded];
}

$shape->save();

$shape = new Geo::Shapelib $shapefile;

$shape->dump('dump1');

$shape = new Geo::Shapelib 'example/stations', {Name => 'example/test'};

$shape->dump('dump2');

$shape = new Geo::Shapelib 'example/test', {UnhashFields=>0};

$shape->dump('dump3');

for (1..3) {
    open F,"dump$_" or die $!;
    @{$d[$_]} = <F>;
    close F;
}
$ok = 1;
for (0..$#{$d[1]}) {
#    print "$d[1]->[$_]$d[2]->[$_]$d[3]->[$_]\n";
    $ok = 0 if $d[1]->[$_] ne $d[2]->[$_] or $d[1]->[$_] ne $d[3]->[$_];
}
print $ok ? "ok 2\n" : "not ok 2\n";

#system "rm -f dump?";



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
