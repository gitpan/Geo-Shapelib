package Geo::Shapelib;

use strict;
use Carp;
use Tree::R;
use vars qw($VERSION @ISA @EXPORT %EXPORT_TAGS @EXPORT_OK $AUTOLOAD);
use vars qw(%ShapeTypes %PartTypes);

require Exporter;
require DynaLoader;
use AutoLoader 'AUTOLOAD';

@ISA = qw(Exporter DynaLoader);

$VERSION = '0.17';

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

    my $shapefile = new Geo::Shapelib { 
        Name => 'stations',
        Shapetype => POINT,
        FieldNames => ['Name','Code','Founded'];
        FieldTypes => ['String:50','String:10','Integer:8'];
    };

    while (<DATA>) {
        chomp;
        my($station,$code,$founded,$x,$y) = split /\|/;
        push @{$shapefile->{Shapes}},{ Vertices => [[$x,$y,0,0]] };
        push @{$shapefile->{ShapeRecords}}, [$station,$code,$founded];
    }

    $shapefile->save();


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

    $shapefile = new Geo::Shapelib { 
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

    $shapefile->{NShapes} is the number of shapes in your
    object. Shapefile is a collection of shapes. This is automatically
    deduced from the Shapes array.

    $shapefile->{MinBounds} is set by shapelib C functions.

    $shapefile->{MaxBounds} is set by shapelib C functions.

Create the shapes and respective shape records and put them into the
shape:

    for many times {
        make $s, a new shape as a reference to a hash
        push @{$shapefile->{Shapes}}, $s;
	make $r, a shape record as a reference to an array
	push @{$shapefile->{ShapeRecords}}, $r;
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

    $shapefile = new Geo::Shapelib "myshapefile", {<options>};

This one creates a new, blank Perl shapefile object:

    $shapefile = new Geo::Shapelib {<options>};

{<options>} is optional in both cases, an example (note the curly braces):

   $shapefile = new Geo::Shapelib { 
       Name => $shapefile,
       Shapetype => POINT,
       FieldNames => ['Name','Code','Founded'],
       FieldTypes => ['String:50','String:10','Integer:8']
   };

   $shapefile = new Geo::Shapelib "myshapefile" { 
       Rtree => 1
   };

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

Rtree:

    Default is 0. If 1, creates an R-tree of the shapes into an
    element Rtree. (Requires LoadAll.)


When a shapefile is read from files they end up in a bit different
kind of data structure than what is expected by the save method for
example and what is described above. These flags enable the
conversion, they are not normally needed.

CombineVertices:

    Default is 1. CombineVertices makes each part an array of two elements.

UnhashFields:

    Default is 1. Makes $self's attributes FieldNames, FieldTypes refs
    to lists, and ShapeRecords a list of lists.


The default is to load all data into Perl variables in the
constructor.  With these options the data can be left into the files
to be loaded on-demand.

LoadRecords:

    Default is 1. Reads shape records into $self->{ShapeRecords}
    automatically in the constructor using the
    get_record($shape_index) method

LoadAll:

    Default is 1. Reads shapes (the geometry data) into
    $self->{Shapes} automatically in the constructor using the
    get_shape($shape_index) method


=cut

sub new {
    my $package = shift;
    my $filename;
    my $options = shift;
    unless (ref $options) {
	$filename = $options;
	$options = shift;
    }
    croak "usage: new Geo::Shapelib <filename>, {<options>};" if (defined $options and not ref $options);
    
    my $self = {};
    bless $self => (ref($package) or $package);
    
    $self->{Name} = $filename if $filename;
    
    my %defaults = ( Name => 'shapefile',
		     Shapetype => 'POINT',
		     FieldNames => [],
		     FieldTypes => [],
		     CombineVertices => 1, 
		     UnhashFields => 1, 
		     LoadRecords => 1, 
		     LoadAll => 1, 
		     ForceStrings => 0,
		     Rtree => 0 );
    
    for (keys %defaults) {
	next if defined $self->{$_};
	$self->{$_} = $defaults{$_};
    }
    
    if (defined $options and ref $options) {
	for (keys %$options) {
	    croak "unknown constructor option for Geo::Shapelib: $_" unless defined $defaults{$_}
	}
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
    
    # Get 'NShapes', 'FieldTypes' and 'ShapeRecords' from the dbf
    my $dbf_handle = DBFOpen($self->{Name}, 'rb');
    unless ($dbf_handle) {
	carp("DBFOpen $self->{Name} failed!");
	return undef;
    }
    $self->{NShapes} = DBFGetRecordCount($dbf_handle);
    $self->{FieldNames} = '';
    $self->{FieldTypes} = ReadDataModel($dbf_handle, $self->{ForceStrings});

    if ($self->{LoadRecords}) {
	$self->{ShapeRecords} = ReadData($dbf_handle, $self->{ForceStrings});
    }

    DBFClose($dbf_handle);
    #return undef unless $dbf;  # Here, not above, so the dbf always gets closed.
    
    # Get 'Shapetype', 'MinBounds', and 'MaxBounds'
    $self->{SHPHandle} = SHPOpen($self->{Name}, 'rb');
    unless ($self->{SHPHandle}) {
	carp("SHPOpen $self->{Name} failed!");
	return undef;
    }
    my $info = SHPGetInfo($self->{SHPHandle});  # DESTROY closes SHPHandle
    unless ($info) {
	carp("SHPGetInfo failed!");
	return undef;
    }
    @$self{keys %$info} = values %$info;
    $self->{ShapetypeString} = $ShapeTypes{ $self->{Shapetype} };
    
    if ($self->{UnhashFields}) {
	($self->{FieldNames}, $self->{FieldTypes}) = data_model($self);
	if ($self->{LoadRecords}) {
	    for my $i (0..$self->{NShapes}-1) {
		$self->{ShapeRecords}->[$i] = get_record_arrayref($self, $i, undef, 1);
	    }
	}
    }
    
    if ($self->{LoadAll}) {
	for (my $i = 0; $i < $self->{NShapes}; $i++) {
	    my $shape = get_shape($self, $i, 1);
	    push @{$self->{Shapes}}, $shape;
	}
    }
    
    $self->Rtree() if $self->{Rtree};
    
    return $self;
}

=pod

=head1 METHODS

=head2 data_model

Returns data model converted into two arrays. 

If in a constructor a filename is given, then the data model is read
from the dbf file and stored as a hashref in the attribute FieldTypes.
This converts the hashref into two arrays: FieldNames and respective
FieldTypes. These arrayrefs are stored in attributes of those names if
UnhashFields is TRUE.

=cut

sub data_model {
    my $self = shift;
    my @FieldNames;
    my @FieldTypes;
    while (my($name,$type) = each %{$self->{FieldTypes}}) {
	push @FieldNames,$name;
	push @FieldTypes,$type;
    }
    return (\@FieldNames,\@FieldTypes);
}

=pod

=head2 get_shape(shape_index, from_file)

Returns a shape nr. shape_index+1 (first index is 0). The shape is
read from a file even if array Shapes exists if from_file is TRUE.

Option CombineVertices is in operation here.

Use this method to get a shape unless you know what you are doing.

=cut

sub get_shape {
    my ($self, $i, $from_file) = @_;
    if (!$from_file and $self->{Shapes}) {

	return $self->{Shapes}->[$i];

    } else {

	my $shape = SHPReadObject($self->{SHPHandle}, $i, $self->{CombineVertices}?1:0) or return undef;

	# $shape->{ShapeRecords} = $self->{ShapeRecords}[$i];

	if($self->{CombineVertices}) {
	    # CombineVertices makes each part an array of two elements
	    for my $part (@{$shape->{Parts}}) {
		$part->[2] = $PartTypes{ $part->[1] };
	    }
	}
	return $shape;

    }
}

=pod

=head2 get_record(shape_index, from_file)

Returns the record which belongs to shape nr. shape_index+1 (first
index is 0). The record is read from a file even if array ShapeRecords
exists if from_file is TRUE.

Use this method to get a record of a shape unless you know what you
are doing.

=cut

sub get_record {
    my ($self, $i, $from_file) = @_;
    if (!$from_file and $self->{ShapeRecords}) {

	return $self->{ShapeRecords}->[$i];

    } else {

	my $dbf_handle = DBFOpen($self->{Name}, 'rb');
	unless ($dbf_handle) {
	    carp("DBFOpen $self->{Name} failed!");
	    return undef;
	}
	my $rec = ReadRecord($dbf_handle, $self->{ForceStrings}, $i);
	DBFClose($dbf_handle);
	return $rec;

    }
}

=pod

=head2 get_record_arrayref(shape_index, FieldNames, from_file)

Returns the record as an arrayref which belongs to shape
nr. shape_index+1 (first index is 0). The parameter FieldNames may be
undef but if defined, it is used as the array according to which the
record array is sorted. This in case the ShapeRecords contains
hashrefs.  The record is read from a file even if array ShapeRecords
exists if from_file is TRUE.

Use this method to get a record of a shape unless you know what you
are doing.

=cut

sub get_record_arrayref {
    my ($self, $i, $FieldNames, $from_file) = @_;
    my $rec = get_record($self, $i, $from_file);
    if (ref $rec eq 'HASH') {
	my @rec;
	$FieldNames = $self->{FieldNames} unless defined $FieldNames;
	for (@$FieldNames) {
	    push @rec,$rec->{$_};
	}
	return \@rec;
    }
    return $rec;
}

=pod

=head2 Rtree and editing the shapefile

Building a R-tree for the shapes:

    $shapefile->Rtree();

This is automatically done if Rtree-option is set when a shapefile is
loaded from files.

You can then use methods like (there are not yet any wrappers for
these).

    my @shapes;
    $shapefile->{Rtree}->query_point(@xy,\@shapes); # or
    $shapefile->{Rtree}->query_completely_within_rect(@rect,\@shapes); # or
    $shapefile->{Rtree}->query_partly_within_rect(@rect,\@shapes);

To get a list of shapes (indexes to the shape array), which you can
feed for example to the select_vertices function.

    for my $shape (@shapes) {
	my $vertices = $shapefile->select_vertices($shape,@rect);
	my $n = @$vertices;
	print "you selected $n vertices from shape $shape\n";
    }

The shapefile object remembers the selected vertices and calling the
function

    $shapefile->move_selected_vertices($dx,$dy);

moves the vertices. The bboxes of the affected shapes, and the R-tree,
if one exists, are updated automatically. To clear all selections from
all shapes, call:

    $selected->clear_selections();

=cut

sub Rtree {
    my $self = shift @_;
    $self->{NShapes} = @{$self->{Shapes}} unless defined $self->{NShapes} and $self->{Shapes};
    $self->{Rtree} = new Tree::R @_;
    for my $sindex (0..$self->{NShapes}-1) {
	my $shape = get_shape($self, $sindex);
	my @rect;
	@rect[0..1] = @{$shape->{MinBounds}}[0..1];
	@rect[2..3] = @{$shape->{MaxBounds}}[0..1];

	$self->{Rtree}->insert($sindex,@rect);
    }
}

sub clear_selections {
    my($self) = @_;
    for my $shape (@{$self->{Shapes}}) {
	$shape->{SelectedVertices} = [];
    }
}

sub select_vertices {
    my($self,$shape,$minx,$miny,$maxx,$maxy) = @_;
    unless (defined $shape) {
	for my $sindex (0..$self->{NShapes}-1) {
	    $self->select_vertices($sindex);
	}
	return;
    }
    $shape = $self->{Shapes}->[$shape];
    my @vertices;
    unless (defined $maxy) {
	@vertices = (0..$shape->{NVertices}-1);
	$shape->{SelectedVertices} = \@vertices;
	return \@vertices;
    }
    my $v = $shape->{Vertices};
    my $i;
    for ($i = 0; $i < $shape->{NVertices}; $i++) {
	next unless 
	    $v->[$i]->[0] >= $minx and
	    $v->[$i]->[0] <= $maxx and
	    $v->[$i]->[1] >= $miny and
	    $v->[$i]->[1] <= $maxy;
	push @vertices,$i;
    }
    $shape->{SelectedVertices} = \@vertices;
    return \@vertices;
}

sub move_selected_vertices {
    my($self,$dx,$dy) = @_;
    return unless $self->{NShapes};

    my $count = 0;
    for my $sindex (0..$self->{NShapes}-1) {
	my $shape = $self->{Shapes}->[$sindex];
	next unless $shape->{SelectedVertices} and @{$shape->{SelectedVertices}};

	my $v = $shape->{Vertices};
	for my $vindex (@{$shape->{SelectedVertices}}) {
	    $v->[$vindex]->[0] += $dx;
	    $v->[$vindex]->[1] += $dy;
	}

	my @rect;
	for my $vertex (@{$shape->{Vertices}}) {
	    $rect[0] = defined($rect[0]) ? min($vertex->[0],$rect[0]) : $vertex->[0];
	    $rect[1] = defined($rect[1]) ? min($vertex->[1],$rect[1]) : $vertex->[1];
	    $rect[2] = defined($rect[2]) ? max($vertex->[0],$rect[2]) : $vertex->[0];
	    $rect[3] = defined($rect[3]) ? max($vertex->[1],$rect[3]) : $vertex->[1];
	}

	@{$shape->{MinBounds}}[0..1] = @rect[0..1];
	@{$shape->{MaxBounds}}[0..1] = @rect[2..3];
	$count++;
    }

    if ($self->{Rtree}) {
	if ($count < 10) {
	    for my $sindex (0..$self->{NShapes}-1) {
		my $shape = $self->{Shapes}->[$sindex];
		next unless $shape->{SelectedVertices} and @{$shape->{SelectedVertices}};
		
		# update Rtree... 	
		
		#delete $sindex from it
		print STDERR "remove $sindex\n";
		$self->{Rtree}->remove($sindex);
	    }
	    for my $sindex (0..$self->{NShapes}-1) {
		my $shape = $self->{Shapes}->[$sindex];
		next unless $shape->{SelectedVertices} and @{$shape->{SelectedVertices}};
		
		my @rect = (@{$shape->{MinBounds}}[0..1],@{$shape->{MaxBounds}}[0..1]);
		
		# update Rtree... 	
		
		# add $sindex to it
		print STDERR "add $sindex\n";
		$self->{Rtree}->insert($sindex,@rect);
	    }
	} else {
	    $self->Rtree;
	}
    }

    $self->{MinBounds}->[0] = $self->{Shapes}->[0]->{MinBounds}->[0];
    $self->{MinBounds}->[1] = $self->{Shapes}->[0]->{MinBounds}->[1];
    $self->{MaxBounds}->[0] = $self->{Shapes}->[0]->{MaxBounds}->[0];
    $self->{MaxBounds}->[1] = $self->{Shapes}->[0]->{MaxBounds}->[1];
    for my $sindex (1..$self->{NShapes}-1) {
	my $shape = $self->{Shapes}->[$sindex];
	$self->{MinBounds}->[0] = min($self->{MinBounds}->[0],$shape->{MinBounds}->[0]);
	$self->{MinBounds}->[1] = min($self->{MinBounds}->[1],$shape->{MinBounds}->[1]);
	$self->{MaxBounds}->[0] = max($self->{MaxBounds}->[0],$shape->{MaxBounds}->[0]);
	$self->{MaxBounds}->[1] = max($self->{MaxBounds}->[1],$shape->{MaxBounds}->[1]);
    }
}

sub min {
    $_[0] > $_[1] ? $_[1] : $_[0];
}

sub max {
    $_[0] > $_[1] ? $_[0] : $_[1];
}

sub set_sizes {
    my($self) = @_;
    $self->{NShapes} = @{$self->{Shapes}} unless defined $self->{NShapes} and $self->{Shapes};
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

=head2 Saving the shapefile

    $shapefile->save($filename);

The argument $shapefile is optional, the internal attribute
$shapefile->{Name} is used if $filename is not specified. If $filename
is specified it also becomes the new name.

$filename may contain an extension, it is removed and .shp etc. are used instead.

=cut

sub save {
    my($self,$filename) = @_;
    $self->{NShapes} = @{$self->{Shapes}} unless defined $self->{NShapes} and $self->{Shapes};
    croak "refusing to save an empty shapefile" unless $self->{NShapes};
    $filename = $self->{Name} unless defined $filename;
    $filename =~ s/\.\w+$//;
    my $handle = SHPCreate($filename.'.shp', $self->{Shapetype});
    croak "SHPCreate failed" unless $handle;
    $self->set_sizes();
    for my $i (0..$self->{NShapes}-1) {
	my $s = get_shape($self, $i);
	my $shape = _SHPCreateObject($s->{SHPType}, $s->{ShapeId}, 
				     $s->{NParts}, $s->{Parts}, 
				     $s->{NVertices}, $s->{Vertices});
	croak "SHPCreateObject failed" unless $shape;
	SHPWriteObject($handle, -1, $shape);
	SHPDestroyObject($shape);
    }
    SHPClose($handle);
    $handle = DBFCreate($filename.'.dbf');
    croak "DBFCreate failed" unless $handle;

    my $fn = $self->{FieldNames};
    my $ft = $self->{FieldTypes};
    unless ($fn) {
	($fn, $ft) = data_model($self);
    }
    my @ftypes;
    for my $f (0..$#$fn) {
	my $type = 0;
	my $width;
	my $decimals = 0;
        my ($ftype, $fwidth, $fdeci) = split(/[:;,]/, $ft->[$f]);
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
	my $ret = _DBFAddField($handle, $fn->[$f], $type, $width, $decimals);
	croak "DBFAddField failed for field $fn->[$f] of type $ft->[$f]" if $ret == -1;
    }
    for my $i (0..$self->{NShapes}-1) {
	my $ret = 1;
	my $rec = get_record_arrayref($self, $i, $fn);
	for my $f (0..$#$fn) {
	    next unless $ftypes[$f];
	  SWITCH: {
	      if ($ftypes[$f] == 1) { 
		  $ret = DBFWriteStringAttribute($handle, $i, $f, $rec->[$f]) if exists $rec->[$f];
		  last SWITCH; 
	      }
	      if ($ftypes[$f] == 2) { 
		  $ret = DBFWriteIntegerAttribute($handle, $i, $f, $rec->[$f]) if exists $rec->[$f];
		  last SWITCH; 
	      }
	      if ($ftypes[$f] == 3) { 
		  $ret = DBFWriteDoubleAttribute($handle, $i, $f, $rec->[$f]) if exists $rec->[$f];
		  last SWITCH; 
	      }
	  }
	    croak "DBFWriteAttribute(field = $fn->[$f], ftype = $ftypes[$f], value = $rec->[$f]) failed" unless $ret;
	}
	last unless $ret;
    }
    DBFClose($handle);
    $self->{Name} = $filename;
}

=pod

=head2 Dump

$shapefile->dump($to);

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
    my $fn = $self->{FieldNames};
    my $ft = $self->{FieldTypes};
    unless ($fn) {
	($fn, $ft) = data_model($self);
    }
    print "Field names:  ", join(', ', @$fn), "\n";
    print "Field types:  ", join(', ', @$ft), "\n";
    $self->{NShapes} = @{$self->{Shapes}} unless defined $self->{NShapes} and $self->{Shapes};
    print "Number of shapes:  $self->{NShapes}\n";
    
    my $sindex = 0;
    while($sindex < $self->{NShapes}) {
	my $shape = get_shape($self, $sindex);
	my $rec = get_record_arrayref($self, $sindex, $fn);
	
	print "Begin shape ",$sindex+1," of $self->{NShapes}\n";
	print "\tShape id: $shape->{ShapeId}\n";
	print "\tShape type: $shape->{SHPType} ($ShapeTypes{$shape->{SHPType}})\n";
	printf "\tMin bounds:  %11f %11f %11f %11f\n", @{$shape->{MinBounds}} if $shape->{MinBounds};
	printf "\tMax bounds:  %11f %11f %11f %11f\n", @{$shape->{MaxBounds}} if $shape->{MaxBounds};
	
	print "\tShape record:  ", join(', ', @$rec), "\n";
	
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
	
	print "End shape ",$sindex+1," of $self->{NShapes}\n";
	$sindex++;
    }
    
    select $old_select if defined $old_select;
    return 1;
}

sub DESTROY {
    my $self = shift;
    SHPClose($self->{SHPHandle}) if defined $self->{SHPHandle};
}

1;
__END__


=head1 AUTHOR

Ari Jolma, ari.jolma at tkk.fi

=head1 LIMITATIONS

=head1 SEE ALSO

perl(1).

=cut

