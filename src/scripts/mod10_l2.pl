#!/usr/local/bin/perl -w
$|=1;
$path_navdir_src = $ENV{PATH_NAVDIR_SRC};
$source_navdir = "$path_navdir_src/scripts";

require("$source_navdir/pfsetup.pl");
require("$source_navdir/error_mail.pl");
require("$source_navdir/date.pl");

my $Usage = "\n
USAGE: mod10_l2.pl dirinout tag listfile gpdfile
                  [chanlist [latlonlistfile [keep [rind]]]]
       defaults:      1          none         0     50

  dirinout: directory containing the input and output files.
  tag: string used as a prefix to output files.
  listfile: text file containing a list of MOD10_L2 files to be gridded.
  gpdfile: .gpd file that defines desired output grid.
  chanlist: string specifying channel numbers to be gridded. The default
            is 1, i.e. grid channel 1 only.
  latlonlistfile: text file containing a list of MOD02 files whose latitude
            and longitude data should be used in place of the latlon data
            in the corresponding MOD10_L2 file in listfile. The default is
            \"none\" indicating that the latlon data in each MOD10_L2 file
            should be used without substitution.
  keep: 0: delete intermediate chan, lat, lon, col, and row files (default).
        1: do not delete intermediate chan, lat, lon, col, and row files.
  rind: number of pixels to add around intermediate grid to eliminate
        holes in final grid. Default is 50.\n\n";

#The following symbols are defined in pfsetup.pl and were used only once in
#this module. They appear here to suppress warning messages.

my $junk = $script;

# define a global used by do_or_die and invoke_or_die

$script = "MOD10_L2";

# Set command line defaults

my $dirinout;
my $tag;
my $listfile;
my $gpdfile;
my $chanlist = "1";
my $latlonlistfile = "none";
my $keep = 0;
my $rind = 50;

if (@ARGV < 4) {
    print $Usage;
    exit 1;
}
if (@ARGV <= 8) {
    $dirinout = $ARGV[0];
    $tag = $ARGV[1];
    $listfile = $ARGV[2];
    $gpdfile = $ARGV[3];
    if (@ARGV >= 5) {
	$chanlist = $ARGV[4];
	if (@ARGV >= 6) {
	    $latlonlistfile = $ARGV[5];
	    if (@ARGV >= 7) {
		$keep = $ARGV[6];
		if ($keep ne "0" && $keep ne "1") {
		    print "invalid keep\n$Usage";
		    exit 1;
		}
		if (@ARGV >= 8) {
		    $rind = $ARGV[7];
		}
	    }
	}
    }
} else {
    print $Usage;
    exit 1;
}

print_stderr("\n".
	     "$script: MESSAGE:\n".
	     "> dirinout         = $dirinout\n".
	     "> tag              = $tag\n".
	     "> listfile         = $listfile\n".
	     "> gpdfile          = $gpdfile\n".
	     "> chanlist         = $chanlist\n".
	     "> latlonlistfile   = $latlonlistfile\n".
	     "> keep             = $keep\n".
	     "> rind             = $rind\n");

chdir_or_die($dirinout);

my @list;
open_or_die("LISTFILE", "$listfile");
print_stderr("contents of listfile:\n");
while (<LISTFILE>) {
    push(@list, $_);
    print STDERR "$_";
}
close(LISTFILE);

my @latlonlist;
if ($latlonlistfile ne "none") {
    open_or_die("LATLONLISTFILE", "$latlonlistfile");
    print_stderr("contents of latlonlistfile:\n");
    while (<LATLONLISTFILE>) {
	push(@latlonlist, $_);
	print STDERR "$_";
    }
    close(LATLONLISTFILE);
}

my $hdf;
my $swath_cols = 0;
my $swath_rows = 0;
my $latlon_cols = 0;
my $latlon_rows = 0;
my $lat_cat = "cat ";
my $lon_cat = "cat ";
my $chan_count = length($chanlist);
my @chan_cat;
my @chans;
my $i;
for ($i = 0; $i < $chan_count; $i++) {
    $chan_cat[$i] = "cat ";
    $chans[$i] = sprintf("%02d", substr($chanlist, $i, 1));
}
my $swath_rows_per_scan = 20;
my $this_swath_cols;
my $this_swath_rows;
my $interp_factor;
my $offset = 0;
my $extra_latlon_col = 0;
my $latlon_rows_per_scan = 2;
my $list_index = 0;
foreach $hdf (@list) {
    chomp $hdf;
    my ($filestem) = ($hdf =~ /(.*)\.hdf/);
    my $filestem_lat = $filestem . "_latf_";
    my $filestem_lon = $filestem . "_lonf_";
    do_or_die("rm -f $filestem_lat*");
    do_or_die("rm -f $filestem_lon*");
    for ($i = 0; $i < $chan_count; $i++) {
	my $chan = $chans[$i];
	my $filestem_chan = $filestem . "_ch$chan\_";
	do_or_die("rm -f $filestem_chan*");
	my $get_latlon = "";
	if ($i == 0) {
	    my $hdf_latlon = $hdf;
	    if (scalar(@latlonlist) == 0) {
		$get_latlon = "/get_latlon";
		$interp_factor = 10;
		$offset = 5;
		$extra_latlon_col = 2;
		$latlon_rows_per_scan = 2;
	    } else {
		$interp_factor = 2;
		$hdf_latlon   = $latlonlist[$list_index++];
		my ($filestem_latlon) = ($hdf_latlon =~ /(.*)\.hdf/);
		$filestem_lat = $filestem_latlon . "_latf_";
		$filestem_lon = $filestem_latlon . "_lonf_";
		do_or_die("rm -f $filestem_lat*");
		do_or_die("rm -f $filestem_lon*");
		do_or_die("idl_sh.pl extract_latlon \"'$hdf_latlon'\"");
	    }
	}
	do_or_die("idl_sh.pl extract_chan \"'$hdf'\" $chan " .
		  "$get_latlon");
	my @chan_glob = glob("$filestem_chan*");
	my $chan_file = $chan_glob[0];
	($this_swath_cols, $this_swath_rows) =
	    ($chan_file =~ /$filestem_chan(.....)_(.....)/);
	print "$chan_file contains $this_swath_cols cols and " .
	    "$this_swath_rows rows\n";
	if ($swath_cols == 0) {
	    $swath_cols = $this_swath_cols;
	}
	if ($this_swath_cols != $swath_cols) {
	    diemail("$script: FATAL: " .
		    "inconsistent number of columns in $chan_file");
	}
	$chan_cat[$i] .= "$chan_file ";
	if ($i == 0) {
	    $swath_rows += $this_swath_rows;
	}
    }

    my @lat_glob = glob("$filestem_lat*");
    my $lat_file = $lat_glob[0];
    my ($this_lat_cols, $this_lat_rows) =
	($lat_file =~ /$filestem_lat(.....)_(.....)/);
    print "$lat_file contains $this_lat_cols cols and " .
	  "$this_lat_rows rows\n";
    if ($interp_factor * $this_lat_cols -
	$extra_latlon_col != $this_swath_cols ||
	$interp_factor * $this_lat_rows != $this_swath_rows) {
	diemail("$script: FATAL: " .
		"inconsistent size for $lat_file");
    }
    $lat_cat .= "$lat_file ";
    $latlon_cols = $this_lat_cols;
    $latlon_rows += $this_lat_rows;

    my @lon_glob = glob("$filestem_lon*");
    my $lon_file = $lon_glob[0];
    my ($this_lon_cols, $this_lon_rows) =
	($lon_file =~ /$filestem_lon(.....)_(.....)/);
    print "$lon_file contains $this_lon_cols cols and " .
	  "$this_lon_rows rows\n";
    if ($interp_factor * $this_lon_cols -
	$extra_latlon_col != $this_swath_cols ||
	$interp_factor * $this_lon_rows != $this_swath_rows) {
	diemail("$script: FATAL: " .
		"inconsistent size for $lon_file");
    }
    $lon_cat .= "$lon_file ";
}
$swath_rows = sprintf("%05d", $swath_rows);
$latlon_cols = sprintf("%05d", $latlon_cols);
$latlon_rows = sprintf("%05d", $latlon_rows);

my @chan_files;
for ($i = 0; $i < $chan_count; $i++) {
    my $chan = $chans[$i];
    my $chan_rm = $chan_cat[$i];
    $chan_rm =~ s/cat/rm -f/;
    $chan_files[$i] = "$tag\_ch$chan\_$swath_cols\_$swath_rows.img";
    do_or_die("$chan_cat[$i] >$chan_files[$i]");
    do_or_die("$chan_rm");
}

my $lat_rm = $lat_cat;
my $lon_rm = $lon_cat;

$lat_rm  =~ s/cat/rm -f/;
$lon_rm  =~ s/cat/rm -f/;

my $lat_file  = "$tag\_latf_$latlon_cols\_$latlon_rows.img";
my $lon_file  = "$tag\_lonf_$latlon_cols\_$latlon_rows.img";

do_or_die("$lat_cat  >$lat_file");
do_or_die("$lon_cat  >$lon_file");

do_or_die("$lat_rm");
do_or_die("$lon_rm");

my $latlon_scans = $latlon_rows / $latlon_rows_per_scan;
my $force = ($interp_factor == 1) ? "-r $rind" : "-f";
my $filestem_cols = $tag . "_cols_";
my $filestem_rows = $tag . "_rows_";
do_or_die("rm -f $filestem_cols*");
do_or_die("rm -f $filestem_rows*");
do_or_die("ll2cr -v $force $latlon_cols $latlon_scans $latlon_rows_per_scan " .
	  "$lat_file $lon_file $gpdfile $tag");
if (!$keep) {
    do_or_die("rm -f $lat_file");
    do_or_die("rm -f $lon_file");
}

my @cols_glob = glob("$filestem_cols*");
my $cols_file = $cols_glob[0];
my ($this_cols_cols, $this_cols_scans,
    $this_cols_scan_first, $this_cols_rows_per_scan) =
    ($cols_file =~ /$filestem_cols(.....)_(.....)_(.....)_(..)/);
print "$cols_file contains $this_cols_cols cols,\n" .
    "   $this_cols_scans scans, $this_cols_scan_first scan_first,\n" .
    "   and $this_cols_rows_per_scan rows_per_scan\n";

my @rows_glob = glob("$filestem_rows*");
my $rows_file = $rows_glob[0];
my ($this_rows_cols, $this_rows_scans,
    $this_rows_scan_first, $this_rows_rows_per_scan) =
    ($rows_file =~ /$filestem_rows(.....)_(.....)_(.....)_(..)/);
print "$rows_file contains $this_rows_cols cols,\n" .
    "   $this_rows_scans scans, $this_rows_scan_first scan_first,\n" .
    "   and $this_rows_rows_per_scan rows_per_scan\n";

if ($this_cols_cols != $this_rows_cols ||
    $this_cols_scans != $this_rows_scans ||
    $this_cols_scan_first != $this_rows_scan_first ||
    $this_cols_rows_per_scan != $this_rows_rows_per_scan) {
    diemail("$script: FATAL: " .
	    "inconsistent sizes for $cols_file and $rows_file");
}
my $cr_cols = $this_cols_cols;
my $cr_scans = $this_cols_scans;
my $cr_scan_first = $this_cols_scan_first;
my $cr_rows_per_scan = $this_cols_rows_per_scan;

open_or_die("GPDFILE", "$ENV{PATHMPP}/$gpdfile");
my $line = <GPDFILE>;
$line = <GPDFILE>;
close(GPDFILE);
my ($grid_cols, $grid_rows) = ($line =~ /(\S+)\s+(\S+)/);
$grid_cols = sprintf("%05d", $grid_cols);
$grid_rows = sprintf("%05d", $grid_rows);

if ($interp_factor > 1) {
    my $col_min = -$rind;
    my $col_max = $grid_cols + $rind - 1;
    my $row_min = -$rind;
    my $row_max = $grid_rows + $rind - 1;

    do_or_die("idl_sh.pl interp_colrow " .
	      "$interp_factor $cr_cols $cr_scans $cr_rows_per_scan " .
	      "\"'$cols_file'\" \"'$rows_file'\" " .
	      "$swath_cols \"'$tag'\" " .
	      "grid_check=[$col_min,$col_max,$row_min,$row_max] " .
	      "col_offset=$offset row_offset=$offset");
    do_or_die("rm -f $cols_file");
    do_or_die("rm -f $rows_file");

    $filestem_cols = $tag . "_cols_";
    @cols_glob = glob("$filestem_cols*");
    $cols_file = $cols_glob[0];
    ($this_cols_cols, $this_cols_scans,
     $this_cols_scan_first, $this_cols_rows_per_scan) =
	 ($cols_file =~ /$filestem_cols(.....)_(.....)_(.....)_(..)/);
    print "$cols_file contains $this_cols_cols cols,\n" .
	  "   $this_cols_scans scans, $this_cols_scan_first scan_first,\n" .
	  "   and $this_cols_rows_per_scan rows_per_scan\n";

    $filestem_rows = $tag . "_rows_";
    @rows_glob = glob("$filestem_rows*");
    $rows_file = $rows_glob[0];
    ($this_rows_cols, $this_rows_scans,
     $this_rows_scan_first, $this_rows_rows_per_scan) =
	 ($cols_file =~ /$filestem_cols(.....)_(.....)_(.....)_(..)/);
    print "$rows_file contains $this_rows_cols cols,\n" .
          "   $this_rows_scans scans, $this_rows_scan_first scan_first,\n" .
          "   and $this_rows_rows_per_scan rows_per_scan\n";

    if ($this_cols_cols != $this_rows_cols ||
	$this_cols_scans != $this_rows_scans ||
	$this_cols_scan_first != $this_rows_scan_first ||
	$this_cols_rows_per_scan != $this_rows_rows_per_scan) {
	diemail("$script: FATAL: " .
		"inconsistent sizes for $cols_file and $rows_file");
    }
    $cr_cols = $this_cols_cols;
    $cr_scans = $this_cols_scans;
    $cr_scan_first = $this_cols_scan_first;
    $cr_rows_per_scan = $this_cols_rows_per_scan;
}

if ($swath_cols != $cr_cols) {
    diemail("$script: FATAL: " .
	    "swath_cols: $swath_cols is not equal to cr_cols: $cr_cols");
}
if ($swath_rows_per_scan != $cr_rows_per_scan) {
    diemail("$script: FATAL: " .
	    "swath_rows_per_scan: $swath_rows_per_scan is not equal to cr_rows_per_scan: $cr_rows_per_scan");
}

my $swath_scans = $cr_scans;
my $swath_scan_first = $cr_scan_first;

my $chan_file_param;
my $grid_file_param;
my $t_option = "-t u1";
my $f_option = "-f 255";
for ($i = 0; $i < $chan_count; $i++) {
    my $chan_file = $chan_files[$i];
    my $chan = $chans[$i];
    my $grid_file = "$tag\_ch$chan\_grid\_$grid_cols\_$grid_rows.img";
    do_or_die("fornav 1 -v -m $t_option $f_option " .
	      "-s $swath_scan_first 0 " .
	      "$swath_cols $swath_scans $swath_rows_per_scan " .
	      "$cols_file $rows_file $chan_file " .
	      "$grid_cols $grid_rows $grid_file");
}
if (!$keep) {
    for ($i = 0; $i < $chan_count; $i++) {
	do_or_die("rm -f $chan_files[$i]");
    }
    do_or_die("rm -f $cols_file");
    do_or_die("rm -f $rows_file");
}
