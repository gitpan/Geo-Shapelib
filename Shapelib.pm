package Geo::Shapelib;

use strict;
use Carp;
use vars qw($VERSION @ISA @EXPORT %EXPORT_TAGS @EXPORT_OK $AUTOLOAD);
use vars qw(%ShapeTypes %PartTypes);

require Exporter;
require DynaLoader;
use AutoLoader 'AUTOLOAD';

@ISA = qw(Exporter DynaLoader);

$VERSION = '0.12';

bootstrap Geo::Shapelib $VERSION;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

# Page 4 of the ESRI Shapefile Technical Description, July 1998
%ShapeTypes = (
	1 => 'Point',
	3 => 'PolyLine',
	5 => 'Polygon',
	8 => 'Multipoint',
	11 => 'PointZ',
	13 => 'PolyLineZ',
	15 => 'PolygonZ',
	18 => 'MultipointZ',
	21 => 'PointM',
	23 => 'PolyLineM',
	25 => 'PolygonM',
	28 => 'MultipointM',
	31 => 'Multipatch',
);

# Page 21 of the ESRI Shapefile Technical Description, July 1998
%PartTypes = (
	0 => 'TriStrip',
	1 => 'TriFan',
	2 => 'OuterRing',
	3 => 'InnerRing',
	4 => 'FirstRing',
	5 => 'Ring',
);

# Create the SUBROUTINES FOR ShapeTypes and PartTypes
# We could prefix these with SHPT_ and SHPP_ respectively
{
    my %typeval = (map(uc,reverse(%ShapeTypes)),map(uc,reverse(%PartTypes)));

    for my $datum (keys %typeval) {
	no strict "refs";       # to register new methods in package
	*$datum = sub { $typeval{$datum}; }
    }
}

# Add Extended Exports
%EXPORT_TAGS = ('constants' => [ map(uc,values(%ShapeTypes)),
				 map(uc,values(%PartTypes))
				 ],
		'types' =>[ qw(%ShapeTypes %PartTypes) ] );
$EXPORT_TAGS{all}=[ @{ $EXPORT_TAGS{constants} },
		    @{ $EXPORT_TAGS{types} } ];

@EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

@EXPORT = qw();


=pod

=head1 NAME

Geo::Shapelib - Perl extension for reading and writing shapefiles as defined by ESRI(r)

=head1 SYNOPSIS

    use Geo::Shapelib qw/:all/;

or

    use Geo::Shapelib qw/:all/;

    my $shape = new Geo::Shapelib { 
        Name => 'stations',
        Shapetype => POINT,
        FieldNames => ['Name','Code','Founded'];
        FieldTypes => ['String:50','String:10','Integer:8'];
    };

    while (<DATA>) {
        chomp;
        my($station,$code,$founded,$x,$y) = split /\|/;
        push @{$shape->{Shapes}},{ Vertices => [[$x,$y,0,0]] };
        push @{$shape->{ShapeRecords}}, [$station,$code,$founded];
    }

    $shape->save();


=head1 DESCRIPTION

This is a library for reading, creating, and writing shapefiles as
defined by ESRI(r) using Perl.  The Perl code uses Frank Warmerdam's
Shapefile C Library (http://shapelib.maptools.org/). The library
is included in this distribution.

Currently no methods exist for populating an empty Shape. You need
to do it in your own code. This is how:

First you include the module into your code. If you want to define the
shape type using its name, import all:

    use Geo::Shapelib qw/:all/;

Create the shapefile object and specify its name and type:

    $shape = new Geo::Shapelib { 
        Name => <filename>, 
        Shapetype => <type from the list>,
        FieldNames => <field name list>,
        FieldTypes => <field type list>
    }

The name (filename, may include path) of the shapefile, the extension
is not used (it is stripped in the save method).

The shape type is an integer. This module defines shape type names as
constants (see below).

The field name list is an array reference of the names of the data
items assigned to each shape.

The field type list is an array reference of the types of the data
items. Field type is either 'Integer', 'Double', or 'String'.

The types may have optional 'width' and 'decimals' fields defined,
like this:

    'Integer[:width]' defaults: width = 10
    'Double[:width[:decimals]]' defaults: width = 10, decimals = 4
    'String[:width]' defaults: width = 255

There are some other attributes which can be defined in the
constructor (see below), they are rarely needed. The shape object will
need or get a couple of other attributes as well. They should be
treated as private:

    $shape->{NShapes} is the number of shapes in your
    object. Shapefile is a collection of shapes. This is automatically
    deduced from the Shapes array.

    $shape->{MinBounds} is set by shapelib C functions.

    $shape->{MaxBounds} is set by shapelib C functions.

Create the shapes and respective shape records and put them into the
shape:

    for many times {
        make $s, a new shape as a reference to a hash
        push @{$shape->{Shapes}}, $s;
	make $r, a shape record as a reference to an array
	push @{$shape->{ShapeRecords}}, $r;
    }

how to create $s? It is a (reference to an) hash.

set:

    $s->{Vertices} this is a reference to an array of arrays of four
    values, one for each vertex: x, y, z, and m of the vertex. There
    should be at least one vertex in $s. Point has only one vertex.

this is often not used:

    $s->{Parts} this is a reference to an array of arrays of two
    values, one for each part: the index of the first vertex in the
    vertex array, i.e. the number of vertices in all previous parts in
    this shape; and the type of the part (not the shapetype): Ring (5)
    if the shape is not Multipatch. You may leave this value
    undefined.

forget these:

    $s->{ShapeId} may be left undefined. The save method sets it to
    the index in the Shapes array. Instead create and use an id field
    in the record.

    $s->{NParts} and $s->{NVertices} may be set but that is usually
    not necessary since they are calculated in the save method. You
    only need to set these if you want to save less parts or vertices
    than there actually are in the Parts or Vertices arrays.

    $s->{SHPType} is the type of the shape and it is automatically set
    to $shape->{Shapetype} unless defined (which you should not do)

The shape record is simply an array reference, for example:

    $r = [item1,item2,item3,...];

That's all. Then save it and start your shapefile viewer to look at
the result.

=head1 EXPORT

None by default.  The following export tags are defined.

=over 8

=item :constants

This exports constant functions for the individual types of shapefile
Types and shapefile part types.  They all return scalar (integer)
values.  The shapetype functions: POINT, ARC, POLYGON, MULTIPOINT,
POINTZ, ARCZ, POLYGONZ, MULTIPOINTZ, POINTM, ARCM, POLYGONM,
MULTIPOINTM, MULTIPATCH are defined.  The shapefile part
types: TRISTRIP, TRIFAN, OUTERRING, INNERRING, FIRSTRING, RING are
defined.

=item :types

Exports two hashs: %ShapeTypes, %PartTypes which map the shapelib type
integers to string values.

=item :all

All possible exports are included.


=back

=head1 CONSTRUCTORS

This one reads in an existing shapefile:

    $shape = new Geo::Shapelib "myshapefile", {<options>};

This one creates a new, blank Perl shapefile object:

    $shape = new Geo::Shapelib {<options>};

{<options>} is optional in both cases

=item Options:

Name:

    Default is "shapefile". The filename (if given) becomes the name
    for the shapefile unless overridden by this.

Shapetype:

    Default "POINT". The type of the shapes. (All non-null shapes in a
    shapefile are required to be of the same shape type.)

FieldNames:

    Default is [].

FieldTypes:

    Default is [].

ForceStrings:

    Default is 0. If 1, sets all FieldTypes to string, may be useful
    if values are very large ints

When a shapefile is read from files they end up in a bit different
kind of data structure than what is expected by the save method for
example and what is described above. These flags enable the
conversion, they are not normally needed.

CombineVertices:

    Default is 1. CombineVertices makes each part an array of two elements.

UnhashFields:

    Default is 1. Makes $self's attributes FieldNames, FieldTypes refs
    to lists, and ShapeRecords a list of lists.

LoadAll:

    Default is 1. Reads shapes into $self automatically in the
    constructor using the get_shape($shape_index) method


=cut

sub new {
	my $package = shift;
	my $filename;
	my $options = shift;
	unless (ref $options) {
	    $filename = $options;
	    $options = shift;
	}

	my $self = {};
	bless $self => (ref($package) or $package);

	$self->{Name} = $filename if $filename;

	my %defaults = ( Name => 'shapefile',
			 Shapetype => 'POINT',
			 FieldNames => [],
			 FieldTypes => [],
			 CombineVertices => 1, 
			 UnhashFields => 1, 
			 LoadAll => 1, 
			 ForceStrings => 0 );

	for (keys %defaults) {
	    next if defined $self->{$_};
	    $self->{$_} = $defaults{$_};
	}
	
	if (ref $options) {
	    for (keys %defaults) {
		next unless defined $options->{$_};
		$self->{$_} = $options->{$_};
	    }
	}
	
	return $self unless $filename;

#	print "\n\n";
#	for (keys %$self) {
#	    print "$_ $self->{$_}\n";
#	}

	# Read the specified file

	# Get 'FieldTypes' and 'ShapeRecords' from the dbf
	my $dbf_handle = DBFOpen($filename, 'rb');
	unless ($dbf_handle) {
	    carp("DBFOpen $filename failed!");
	    return undef;
	}
	my $dbf = DBFRead($dbf_handle, $self->{ForceStrings});
	DBFClose($dbf_handle);
	return undef unless $dbf;  # Here, not above, so the dbf always gets closed.
	@$self{keys %$dbf} = values %$dbf;

	# Get 'NShapes', 'Shapetype', 'MinBounds', and 'MaxBounds'
	$self->{SHPHandle} = SHPOpen($filename, 'rb');
	unless ($self->{SHPHandle}) {
	    carp("SHPOpen $filename failed!");
	    return undef;
	}
	my $info = SHPGetInfo($self->{SHPHandle});  # DESTROY closes SHPHandle
	unless ($info) {
	    carp("SHPGetInfo failed!");
	    return undef;
	}
	@$self{keys %$info} = values %$info;
	$self->{ShapetypeString} = $ShapeTypes{ $self->{Shapetype} };

	if($self->{UnhashFields}) {
#	    print "unhashing\n";
	    my $keys = [];
	    my $values = [];
	    while (my($key,$value) = each %{$self->{FieldTypes}}) {
		push @$keys,$key;
		push @$values,$value;
	    }
	    $self->{FieldNames} = $keys;
	    $self->{FieldTypes} = $values;
	    my $tmp = [];
	    for my $record (@{$self->{ShapeRecords}}) {
		my $values = [];
		for (keys %$record) {
		    push @$values, $record->{$_};
		}
		push @$tmp,$values;
	    }
	    push @{$self->{ShapeRecords}}, $tmp;
	}

	if($self->{LoadAll}) {
		for (my $which = 0; $which < $self->{NShapes}; $which++) {
			my $shape = $self->get_shape($which) or return undef;
			push @{$self->{Shapes}}, $shape;
		}
	}

	return $self;
}

sub set_sizes {
    my($self) = @_;
    $self->{NShapes} = @{$self->{Shapes}} unless defined $self->{NShapes};
    for my $i (0..$self->{NShapes}-1) {
	my $s = $self->{Shapes}->[$i];
	if (defined($s->{SHPType})) {
	    if ($s->{SHPType} != 0 and $s->{SHPType} != $self->{Shapetype}) {
		carp "WARNING: All non-null shapes in a shapefile are required to be of the same shape type.";
	    }
	} else {
	    $s->{SHPType} = $self->{Shapetype};
	}
	my $nParts =  exists $s->{Parts} ? @{$s->{Parts}} : 0;
	if (defined $s->{NParts}) {
	    if ($s->{NParts} > $nParts) {
		carp "WARNING: given NParts is larger than the actual number of Parts";
	    } else {
		$nParts = $s->{NParts};
	    }
	}
	$s->{NParts} = $nParts;
	my $nVertices =  exists $s->{Vertices} ? @{$s->{Vertices}} : 0;
	if (defined $s->{NVertices}) {
	    if ($s->{NVertices} > $nVertices) {
		carp "WARNING: given NVertices is larger than the actual number of Vertices";
	    } else {
		$nVertices = $s->{NVertices};
	    }
	}
	$s->{NVertices} = $nVertices;
	$s->{ShapeId} = defined $s->{ShapeId} ? $s->{ShapeId} : $i;
    }
}

=pod

=head1 METHODS

=head2 Saving the shapefile

    $shape->save($shapefile);

The argument $shapefile is optional, the internal attribute
($shape->{Name}) is used if $shapefile is not specified.

Extension is removed from $shapefile.

=cut

sub save {
    my($self,$shapefile) = @_;
    croak "refusing to save an empty shapefile" unless ($self->{Shapes} and @{$self->{Shapes}});
    $shapefile = $self->{Name} unless defined $shapefile;
    $shapefile =~ s/\.\w+$//;
    my $handle = SHPCreate($shapefile, $self->{Shapetype});
    croak "SHPCreate failed" unless $handle;
    $self->set_sizes();
    for my $i (0..$self->{NShapes}-1) {
	my $s = $self->{Shapes}->[$i];
	my $shape = _SHPCreateObject($s->{SHPType}, $s->{ShapeId}, 
				     $s->{NParts}, $s->{Parts}, 
				     $s->{NVertices}, $s->{Vertices});
	croak "SHPCreateObject failed" unless $shape;
	SHPWriteObject($handle, -1, $shape);
	SHPDestroyObject($shape);
    }
    SHPClose($handle);
    $shapefile =~ s/\.shp$/.dbf/;
    $handle = DBFCreate($shapefile);
    croak "DBFCreate failed" unless $handle;
    my @fn = @{$self->{FieldNames}};
    my @ft = @{$self->{FieldTypes}};
    my @ftypes;
    for my $f (0..$#fn) {
	my $type = 0;
	my $width;
	my $decimals = 0;
        my ($ftype, $fwidth, $fdeci) = split(/[:;,]/, $ft[$f]);
      SWITCH: {
	  if ($ftype eq 'String') { 
	      $type = 1;
	      $width = defined($fwidth)?$fwidth:255;	      
	      last SWITCH; 
	  }
	  if ($ftype eq 'Integer') { 
	      $type = 2;
	      $width = defined($fwidth)?$fwidth:10;
	      last SWITCH; 
	  }
	  if ($ftype eq 'Double') { 
	      $type = 3;
	      $width = defined($fwidth)?$fwidth:10;
	      $decimals = defined($fdeci)?$fdeci:4;
	      last SWITCH; 
	  }
      }
	$ftypes[$f] = $type;
	next unless $type;
	my $ret = _DBFAddField($handle, $fn[$f], $type, $width, $decimals);
	croak "DBFAddField failed for field $fn[$f] of type $ft[$f]" if $ret == -1;
    }
    for my $i (0..$self->{NShapes}-1) {
	my $ret = 1;
	my @rec = @{$self->{ShapeRecords}->[$i]};
	for my $f (0..$#fn) {
	    next unless $ftypes[$f];
	  SWITCH: {
	      if ($ftypes[$f] == 1) { 
		  $ret = DBFWriteStringAttribute($handle, $i, $f, $rec[$f]) if exists $rec[$f];
		  last SWITCH; 
	      }
	      if ($ftypes[$f] == 2) { 
		  $ret = DBFWriteIntegerAttribute($handle, $i, $f, $rec[$f]) if exists $rec[$f];
		  last SWITCH; 
	      }
	      if ($ftypes[$f] == 3) { 
		  $ret = DBFWriteDoubleAttribute($handle, $i, $f, $rec[$f]) if exists $rec[$f];
		  last SWITCH; 
	      }
	  }
	    croak "DBFWriteAttribute(field = $fn[$f], ftype = $ftypes[$f], value = $rec[$f]) failed" unless $ret;
	}
	last unless $ret;
    }
    DBFClose($handle);
}

=pod

=head2 Dump

$shape->dump($to);

$to can be undef (then dump uses STDOUT), filename, or reference to a
filehandle (e.g., \*DUMP).

=cut

sub dump {
	my $self = shift;
	my $file = shift;

	my $old_select;
	if (defined $file) {
		if (not ref $file) {
			# $file is a name that we'll convert to a file handle
			# ref.  Passing open a scalar makes it close when the
			# scaler is destroyed.
			my $fh;
			unless (open $fh, ">$file") {
			    carp("$file: $!"),
			    return undef;
			}
			$file = $fh;
		}
		return undef unless ref($file) eq 'GLOB';
		$old_select = select($file);
	}

	$self->set_sizes;

	printf "Name:  %s\n", ($self->{Name} or '(none)');
	print "Shape type:  $self->{Shapetype} ($ShapeTypes{$self->{Shapetype}})\n";
	printf "Min bounds:  %11f %11f %11f %11f\n", @{$self->{MinBounds}} if $self->{MinBounds};
	printf "Max bounds:  %11f %11f %11f %11f\n", @{$self->{MaxBounds}} if $self->{MaxBounds};
	my @FieldNames;
	my @FieldTypes;
	if(ref($self->{FieldTypes}) eq 'ARRAY') {
	    @FieldNames = @{$self->{FieldNames}};
	    @FieldTypes = @{$self->{FieldTypes}};
	} else {
	    while (my($key,$value) = each %{$self->{FieldTypes}}) {
		push @FieldNames,$key;
		push @FieldTypes,$value;
	    }
	}
	print "Field names:  ", join(', ', @FieldNames), "\n";
	print "Field types:  ", join(', ', @FieldTypes), "\n";
	print "Number of shapes:  $self->{NShapes}\n";

	my $sindex = 0;
	my $smax = $self->{NShapes};
	while($sindex < $smax) {
		my $shape;

		if($self->{LoadAll}) {
			$shape = $self->{Shapes}[$sindex];
		} else {
			$shape = $self->get_shape($sindex) or return undef;
		}

		print "Begin shape ",$sindex+1," of $smax\n";
		print "\tShape id: $shape->{ShapeId}\n";
		print "\tShape type: $shape->{SHPType} ($ShapeTypes{$shape->{SHPType}})\n";
		printf "\tMin bounds:  %11f %11f %11f %11f\n", @{$shape->{MinBounds}} if $shape->{MinBounds};
		printf "\tMax bounds:  %11f %11f %11f %11f\n", @{$shape->{MaxBounds}} if $shape->{MaxBounds};
		my $r = $self->{ShapeRecords}->[$sindex];
		my @r;
		if(ref($r) eq 'ARRAY') {
		    @r = @$r;
		} else {
		    for (@FieldNames) {
			push @r, $r->{$_};
		    }
		}
		print "\tShape record:  ", join(', ', @r), "\n";

		if ($shape->{NParts}) {

		    my $pindex = 0;
		    my $pmax = $shape->{NParts};
		    while($pindex < $pmax) {
			my $part = $shape->{Parts}[$pindex];
			print "\tBegin part ",$pindex+1," of $pmax\n";
			
			if($self->{CombineVertices}) {
			    print "\t\tPartType:  $part->[1] ($part->[2])\n";
			    my $vindex = $part->[0];
			    my $vmax = $shape->{Parts}[$pindex+1][0];
			    $vmax = $shape->{NVertices} unless defined $vmax;
			    while($vindex < $vmax) {
				printf "\t\tVertex:  %11f %11f %11f %11f\n", @{$shape->{Vertices}[$vindex]};
				$vindex++;
			    }
			} else {
			    print "\t\tPart id:  $part->{PartId}\n";
			    print "\t\tPart type:  $part->{PartType} ($PartTypes{$part->{PartType}})\n";
			    for my $vertex (@{$part->{Vertices}}) {
				printf "\t\tVertex:  %11f %11f %11f %11f\n", @$vertex;
			    }
			}
			
			print "\tEnd part ",$pindex+1," of $pmax\n";
			$pindex++;
		    }

		} else {

		    for my $vertex (@{$shape->{Vertices}}) {
			printf "\t\tVertex:  %11f %11f %11f %11f\n", @$vertex;
		    }

		}

		print "End shape ",$sindex+1," of $smax\n";
		$sindex++;
	}

	select $old_select if defined $old_select;
	return 1;
}

# this method reads one shape from the shapefile into the Perl object

sub get_shape {
	my ($self, $which) = @_;

	my $shape = SHPReadObject($self->{SHPHandle}, $which, $self->{CombineVertices}?1:0) or return undef;
	$shape->{ShapeRecords} = $self->{ShapeRecords}[$which];

	for my $part (@{$shape->{Parts}}) {
	    if($self->{CombineVertices}) {
		# CombineVertices makes each part an array of two elements
		$part->[2] = $PartTypes{ $part->[1] };
	    }
	}

	return $shape;
}

sub DESTROY {
	my $self = shift;
	SHPClose($self->{SHPHandle}) if defined $self->{SHPHandle};
}

1;
__END__


=head1 AUTHOR

Ari Jolma, ari.jolma@tkk.fi

=head1 LIMITATIONS

=head1 SEE ALSO

perl(1).

=cut

