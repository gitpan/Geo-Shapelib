package Geo::Shapelib;

use strict;
use Carp;
use vars qw($VERSION @ISA @EXPORT %EXPORT_TAGS @EXPORT_OK $AUTOLOAD);
use vars qw(%ShapeTypes %PartTypes %ft2sqlt);

require Exporter;
require DynaLoader;
use AutoLoader 'AUTOLOAD';

@ISA = qw(Exporter DynaLoader);

$VERSION = '0.11';

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

%ft2sqlt = ('String' => 'text',
	    'Integer' => 'int',
	    'Double' => 'float',
	    'Invalid' => 'text');

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

    use Geo::Shapelib;

or

    use Geo::Shapelib qw/:all/;

    my $shape = new Geo::Shapelib;
    foreach my $i (0..10) {
        push @{$shape->{Shapes}},{SHPType=>POINT,
				  ShapeID=>$i++,
				  Vertices=>[[$i,$i,0,0]]
				 };
      }


=head1 DESCRIPTION

This is a library for reading, creating, and writing shapefiles as
defined by ESRI(r) using Perl.  The Perl code uses Frank Warmerdam's
Shapefile C Library. Get it from
http://gdal.velocet.ca/projects/shapelib/index.html

Currently no methods exist for populating an empty Shape. You need
to do it in your own code. This is the HOWTO:

First you create the shapefile object:

    $shape = new Geo::Shapelib;

the set its attributes:

    $shape->{Name} to be the name (path) of the shapefile, it may contain
    an extension. You may also use the argument in the save method.

    $shape->{Shapetype} to be the (integer) denoting the shapetype. Look
    into this file or some other doc for the numbers.

don't care about these attributes:

    $shape->{NShapes} the number of shapes in your object. Shapefile
    is a collection of shapes. This is automatically deduced from the
    Shapes array.

    $shape->{MinBounds} 

    $shape->{MaxBounds}

then create shapes and put them into the shape

    for many times {
        make $s, a new shape
        push @{$shape->{Shapes}}, $s;
    }

how to create $s? It is a hash.

set

    $s->{SHPType} to be the type of the shape (this needs to be the
    same as the type of the shape, i.e., of the object?)

    $s->{ShapeId} may be left undefined. The save method sets it to
    the index in the Shapes array.

    $s->{Parts} this is a reference to an array of arrays of two
    values, one for each part: the index of the first vertex in the
    vertex array, i.e. the number of vertices in all previous parts in
    this shape; and the type of the part (not the shapetype): Ring (5)
    if the shape is not Multipatch. You may leave this value
    undefined.

    $s->{Vertices} this is a reference to an array of arrays of four
    values, one for each vertex: x, y, z, and m of the vertex. There
    should be at least one vertex in $s. Point has only one vertex.

    $s->{NParts} and $s->{NVertices} may be set but that is usually
    not necessary since they are calculated in the save method. You
    only need to set these if you want to save less parts or vertices
    than there are actually in the Parts or Vertices arrays.

Then you need to have at least some data assigned to each shape.

    $self->{FieldNames} is a reference to the names of the data items,
    i.e., an array.

    $self->{FieldTypes} is a reference to the types of the data items,
    i.e., and array. Type is either 'Integer', 'Double', or 'String'.

    The Types may have optional 'width' and 'decimals' fields defined,
    like: 
        'Integer[:width]'            defaults: width = 10
        'Double[:width[:decimals]]'  defaults: width = 10, decimals = 4
        'String[:width]'             defaults: width = 255

populate the data table:

    for my $i (0..$self->{NShapes}-1) {
        $self->{ShapeRecords}->[$i] = [item1,item2,item3,...];
    }

That's all. Then save it and start your shapefile viewer to look at the result.

An example:

    $shape = new Geo::Shapelib;

    $shape->{Shapetype} = 1;

    $shape->{FieldNames} = ['StationName'];
    $shape->{FieldTypes} = ['String:60'];

    while (<DATA>) {
        chomp;
        ($station,$x,$y) = split /\|/;
        push @{$shape->{Shapes}}, {
                SHPType=>1,
                Vertices=>[[$x,$y]]
	};
        push @{$shape->{ShapeRecords}}, [$station];
    }

    $shape->save('stations');

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

=item <options>:

CombineVertices:

    Default 1, CombineVertices makes each part an array of two elements

UnhashFields:

    Default 1, Makes $self's attributes FieldNames, FieldTypes, and ShapeRecords refs to arrays

LoadAll:

    Default 1, Reads shapes into $self automatically using the get_shape($shape_index) method

ForceStrings:

    Default 0, If 1, sets all FieldTypes to string, may be useful if values are very large ints

=cut

sub new {
	my $package = shift;
	my $self = {};
	bless $self => (ref($package) or $package);

	my $options = shift;
	return $self unless defined $options;

	$self->{Name} = $options unless ref $options;

	$self->{Options} = {CombineVertices => 1, UnhashFields => 1, LoadAll => 1, ForceStrings => 0};
	my $options = shift unless ref $options;
	if ($options) {
	    for (keys %{$self->{Options}}) {
		$self->{Options}->{$_} = $options->{$_} if defined $options->{$_};
	    }
	}

	# Read the specified file

	# Get 'FieldTypes' and 'ShapeRecords' from the dbf
	my $dbf_handle = DBFOpen($self->{Name}, 'rb') or return undef;
	my $dbf = DBFRead($dbf_handle, $self->{Options}{ForceStrings});
	DBFClose($dbf_handle);
	return undef unless $dbf;  # Here, not above, so the dbf always gets closed.
	@$self{keys %$dbf} = values %$dbf;

	# Get 'NShapes', 'Shapetype', 'MinBounds', and 'MaxBounds'
	$self->{SHPHandle} = SHPOpen($self->{Name}, 'rb') or return undef;
	my $info = SHPGetInfo($self->{SHPHandle}) or return undef;  # DESTROY closes SHPHandle
	@$self{keys %$info} = values %$info;
	$self->{ShapetypeString} = $ShapeTypes{ $self->{Shapetype} };

	if($self->{Options}{UnhashFields}) {
		$self->{FieldNames} = [keys %{$self->{FieldTypes}}];
		$self->{FieldTypes} = [values %{$self->{FieldTypes}}];
		my $tmp = [];
		foreach my $record (@{$self->{ShapeRecords}}) {
			push @$tmp, [ @$record{ @{$self->{FieldNames}} } ];
		}
		$self->{ShapeRecords} = $tmp;
	}

	if($self->{Options}{LoadAll}) {
		for (my $which = 0; $which < $self->{NShapes}; $which++) {
			my $shape = $self->get_shape($which) or return undef;
			push @{$self->{Shapes}}, $shape;
		}
	}

	return $self;
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
    $self->{NShapes} = @{$self->{Shapes}} unless defined $self->{NShapes};
    for my $i (0..$self->{NShapes}-1) {
	my $s = $self->{Shapes}->[$i]; 
#	print "\n";
#	for (keys %$s) {
#	    print "$_ = $s->{$_}\n";
#	    if ($s->{$_} and ref($s->{$_}) eq 'ARRAY') {
#		my $n = @{$s->{$_}};
#		print "$n\n";
#	    }
#	}
	my $nParts =  exists $s->{Parts} ? @{$s->{Parts}} : 0;
	if (exists $s->{NParts}) {
	    if ($s->{NParts} > $nParts) {
		carp "WARNING: given NParts is larger than the actual number of Parts";
	    } else {
		$nParts = $s->{NParts};
	    }
	}
	my $nVertices =  exists $s->{Vertices} ? @{$s->{Vertices}} : 0;
	if (exists $s->{NVertices}) {
	    if ($s->{NVertices} > $nVertices) {
		carp "WARNING: given NVertices is larger than the actual number of Vertices";
	    } else {
		$nVertices = $s->{NVertices};
	    }
	}
	my $id = exists $s->{ShapeId} ? $s->{ShapeId} : $i;
	my $shape = _SHPCreateObject($s->{SHPType}, $id, 
				     $nParts, $s->{Parts}, 
				     $nVertices, $s->{Vertices});
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
	    croak "DBFWriteAttribute failed" if $ret == -1;
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
		if (not defined ref $file) {
			# $file is a name that we'll convert to a file handle
			# ref.  Passing open a scalar makes it close when the
			# scaler is destroyed.
			my $fh;
			return undef unless open $fh, ">$file";
			$file = $fh;
		}
		return undef unless ref($file) eq 'GLOB';
		$old_select = select($file);
	}

	printf "Name:  %s\n", ($self->{Name} or '(none)');
	printf "Shapetype:  $self->{Shapetype} ($self->{ShapetypeString})\n";
	printf "MinBounds:  %11f %11f %11f %11f\n", @{$self->{MinBounds}};
	printf "MaxBounds:  %11f %11f %11f %11f\n", @{$self->{MaxBounds}};
	if($self->{Options}{UnhashFields}) {
		print "FieldNames:  ", join(', ', @{$self->{FieldNames}}), "\n";
		print "FieldTypes:  ", join(', ', @{$self->{FieldTypes}}), "\n";
	} else {
		print "FieldTypes:  ", join(', ', %{$self->{FieldTypes}}), "\n";
	}
	print "NShapes:  $self->{NShapes}\n";

	my $sindex = 0;
	my $smax = $self->{NShapes};
	while($sindex < $smax) {
		my $shape;

		if($self->{Options}{LoadAll}) {
			$shape = $self->{Shapes}[$sindex];
		} else {
			$shape = $self->get_shape($sindex) or return undef;
		}

		print "Begin shape $sindex of $smax\n";
		print "\tShapeId: $shape->{ShapeId}\n";
		print "\tSHPType: $shape->{SHPType} ($shape->{SHPTypeString})\n";
		printf "\tMinBounds:  %11f %11f %11f %11f\n", @{$shape->{MinBounds}};
		printf "\tMaxBounds:  %11f %11f %11f %11f\n", @{$shape->{MaxBounds}};
		if($self->{Options}{UnhashFields}) {
			print "\tShapeRecords:  ", join(', ', @{$shape->{ShapeRecords}}), "\n";
		} else {
			print "\tShapeRecords:  ", join(', ', %{$shape->{ShapeRecords}}), "\n";
		}

		my $pindex = 0;
		my $pmax = $shape->{NParts};
		while($pindex < $pmax) {
			my $part = $shape->{Parts}[$pindex];
			print "\tBegin part $pindex of $pmax\n";

			if($self->{Options}{CombineVertices}) {
				print "\t\tPartType:  $part->[1] ($part->[2])\n";
				my $vindex = $part->[0];
				my $vmax = $shape->{Parts}[$pindex+1][0];
				$vmax = $shape->{NVertices} unless defined $vmax;
				while($vindex < $vmax) {
					printf "\t\tVertex:  %11f %11f %11f %11f\n", @{$shape->{Vertices}[$vindex]};
					$vindex++;
				}
			} else {
				print "\t\tPartId:  $part->{PartId}\n";
				print "\t\tPartType:  $part->{PartType} ($part->{PartTypeString})\n";
				foreach my $vertex (@{$part->{Vertices}}) {
					printf "\t\tVertex:  %11f %11f %11f %11f\n", @$vertex;
				}
			}

			print "\tEnd part $pindex of $pmax\n";
			$pindex++;
		}

		print "End shape $sindex of $smax\n";
		$sindex++;
	}

	select $old_select if defined $old_select;
	return 1;
}

# XXX: Doc this method
sub get_shape {
	my ($self, $which) = @_;

	my $shape = SHPReadObject($self->{SHPHandle}, $which, $self->{Options}{CombineVertices}?1:0) or return undef;
	$shape->{SHPTypeString} = $ShapeTypes{ $shape->{SHPType} };
	$shape->{ShapeRecords} = $self->{ShapeRecords}[$which];

	foreach my $part (@{$shape->{Parts}}) {
		if($self->{Options}{CombineVertices}) {
			# CombineVertices makes each part an array of two elements
			$part->[2] = $PartTypes{ $part->[1] };
		} else {
			$part->{PartTypeString} = $PartTypes{ $part->{PartType} };
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

Ari Jolma, ari.jolma@hut.fi

=head1 LIMITATIONS

=head1 SEE ALSO

perl(1).

=cut

