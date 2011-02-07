##
## Moregraphics
##
## A plugin that allows to create and delete graphics objects that are
## combined from VMD's graphics primitives.
##
## Authors: 
##   Olaf Lenz <olenz _at_ icp.uni-stuttgart.de>
##   Andreas Mezger
##
package provide moregraphics 0.9

namespace eval ::moregraphics:: {
    #==========================================================
    # NAME    : lshift
    # PURPOSE : shift list and return first element
    # AUTHOR  : Richard Booth
    #           http://www.lehigh.edu/~rvb2
    #           rvb2@lehigh.edu rvbooth@agere.com
    # ---------------------------------------------------------
    # ARGUMENTS :
    #   % inputlist
    #       List to be shifted.
    # RESULTS :
    #   * Sets inputlist to 2nd to last elements of original inputlist
    #   * Returns first element in inputlist
    # NOTES :
    #   * useful for command-line arguments and procedure args processing
    # EXAMPLE-CALL :
    #
    #  while {[llength $argv] > 0} {
    #    set arg [lshift argv]
    #    switch -- $arg {
    #      -lib  {set lib [lshift argv]}
    #      -show {set show 1}
    #      default {lappend tests $arg}
    #    }
    #  }
    #
    #==========================================================
    proc lshift {inputlist} {
	upvar $inputlist argv
	set arg  [lindex $argv 0]
	#set argv [lrange $argv 1 end] ;# below is much faster - lreplace can make use of unshared Tcl_Obj to avoid alloc'ing the result
	set argv [lreplace $argv[set argv {}] 0 0]
	return $arg
    }

    # Generates a graphics with a given color that replaces the first
    # of gids (if anything is in there)
    proc moregraphics {molid color gids args} {
	# set the color
	graphics $molid color $color

	# set the replacement gid
	upvar $gids gids2
	if { [info exists gids2] && [llength $gids2] } then {
	    graphics $molid replace [lshift gids2]
	}

	if { [llength $args] } then {
	    return [eval "graphics $molid $args"] 
	}
	return ""
    }

    # delete <options> gids
    #   delete a list of gids as they are created by the various
    #   commands below.
    #
    # Options:
    # molid <int> [top]
    proc delete args {
	set molid "top"

	if { [lindex $args 0] == "molid" } then {
	    lshift args
	    set molid [lshift args]
	}

	if { $molid == "top" } then { set molid [ molinfo top ] }
	
	foreach arg $args {
	    if { [llength $arg] >= 1 } then {
		foreach gid $arg {
		    if { [graphics $molid exists $gid] } then {
			graphics $molid delete $gid
		    }
		}
	    }
	}
    }

    # doublesphere <options>
    #   generates two slightly shifted spheres
    #
    # Options:
    # molid <int> [top]
    # pos <vec> [{0 0 0}]
    # dir <vec> [{1 0 0}]
    # color1 <colorid> [red]
    # color2 <colorid> [blue]
    # replace <var> <var>
    # radius <float> [1.0]
    # shift <float> [0.01]
    # res <int> [6]
    proc doublesphere args {
	set none {}

	set molid "top"
	set pos {0 0 0}
	set dir {1 0 0}
	set color1 "red"
	set color2 "blue"
	set oldvar mg_oldgids
	set newvar mg_newgids
	set radius 1.0
	set shift 0.01
	set resolution 6

	# Parse options
	while {[llength $args] > 0} {
	    set arg [lshift args]
	    switch -- $arg {
		"molid"      { set molid [lshift args] }
		"pos"        { set pos [lshift args] }
		"dir"        { set dir [lshift args] }
		"color1"     { set color1 [lshift args] }
		"color2"     { set color2 [lshift args] }
		"replace"    { 
		    set oldvar [lshift args]
		    set newvar [lshift args] 
		}
		"radius"     { set radius [lshift args] }
		"shift"      { set shift [lshift args] }
		"resolution" { set resolution [lshift args] }
		default { error "error: doublesphere: unknown option: $arg" }
	    }
	}

	if { $molid == "top" } then { set molid [ molinfo top ] }

	# compute the positions of the individual spheres
	set shiftvec [vecscale [expr 0.5 * $shift] [vecnorm $dir]]
	set pos1 [vecadd $pos $shiftvec]
	set pos2 [vecadd $pos [vecinvert $shiftvec]]
	
	upvar $oldvar oldgids
	upvar $newvar newgids
	
	set gid1 [moregraphics $molid $color1 oldgids \
		      sphere $pos1 radius $radius \
		      resolution $resolution]
	set gid2 [moregraphics $molid $color2 oldgids \
		      sphere $pos2 radius $radius \
		      resolution $resolution]
	lappend newgids $gid1 $gid2
	return [list $gid1 $gid2]
    }

    # doublecone <options>
    #   generates two slightly shifted spheres
    #
    # Options:
    # molid <int> [top]
    # pos <vec> [{0 0 0}]
    # dir <vec> [{1 0 0}]
    # color1 <colorid> [red]
    # color2 <colorid> [blue]
    # replace <var> <var>
    # radius <float> [1.0]
    # length <float> [1.0]
    # res <int> [6]
    proc doublecone args {
	set none {}

	set molid "top"
	set pos {0 0 0}
	set dir {1 0 0}
	set color1 "red"
	set color2 "blue"
	set oldvar mg_oldgids
	set newvar mg_newgids
	set length 1.0
	set radius 1.0
	set shift 0.01
	set resolution 6

	# Parse options
	while {[llength $args] > 0} {
	    set arg [lshift args]
	    switch -- $arg {
		"molid"      { set molid [lshift args] }
		"pos"        { set pos [lshift args] }
		"dir"        { set dir [lshift args] }
		"color1"     { set color1 [lshift args] }
		"color2"     { set color2 [lshift args] }
		"replace"    { 
		    set oldvar [lshift args]
		    set newvar [lshift args] 
		}
		"radius"     { set radius [lshift args] }
		"length"     { set length [lshift args] }
		"resolution" { set resolution [lshift args] }
		default { error "error: doublesphere: unknown option: $arg" }
	    }
	}

	if { $molid == "top" } then { set molid [ molinfo top ] }

	set tipvec [vecscale $length [vecnorm $dir]]
	set tip1 [vecadd $pos $tipvec]
	set tip2 [vecadd $pos [vecinvert $tipvec]]
	
	upvar $oldvar oldgids
	upvar $newvar newgids
	
	set gid1 [moregraphics $molid $color1 oldgids \
		      cone $pos $tip1 radius $radius \
		      resolution $resolution]
	set gid2 [moregraphics $molid $color2 oldgids \
		      cone $pos $tip2 radius $radius \
		      resolution $resolution]
	lappend newgids $gid1 $gid2
	return [list $gid1 $gid2]
    }
    
    # arrow <options>
    #   generates an arrow
    #
    # Options:
    # molid <int> [top]
    # pos <vec> [{0 0 0}]
    # dir <vec> [{1 0 0}]
    # color1 <colorid> [red]
    # color2 <colorid> [blue]
    # replace <var> <var>
    # radius <float> [0.2]
    # coneradius <float> [2.0]
    # conelength <float> [0.2]
    # resolution <int> [6]
    proc arrow args {
	set none {}

	set molid "top"
	set pos {0 0 0}
	set dir {1 0 0}
	set color1 "red"
	set color2 "blue"
	set length 1.0
	set radius 0.2
	set coneradius 2.0
	set conelength 0.5
	set resolution 6
	set oldvar mg_oldgids
	set newvar mg_newgids

	# Parse options
	while {[llength $args] > 0} {
	    set arg [lshift args]
	    switch -- $arg {
		"molid"      { set molid [lshift args] }
		"pos"        { set pos [lshift args] }
		"dir"        { set dir [lshift args] }
		"color1"     { set color1 [lshift args] }
		"color2"     { set color2 [lshift args] }
		"replace"    { 
		    set oldvar [lshift args]
		    set newvar [lshift args] 
		}
		"radius"     { set radius [lshift args] }
		"coneradius"     { set coneradius [lshift args] }
		"conelength"     { set conelength [lshift args] }
		"length"     { set length [lshift args] }
		"resolution" { set resolution [lshift args] }
		default { error "error: arrow: unknown option: $arg" }
	    }
	}

	if { $molid == "top" } then { set molid [ molinfo top ] }

	set lenvec [vecscale $length [vecnorm $dir]]
	set base [vecadd $pos [vecscale -0.5 $lenvec]]
	set tip [vecadd $pos [vecscale 0.5 $lenvec]]
	set conebase [vecadd $base \
	    [vecscale [expr 1.0-$conelength] $lenvec]]
	
	upvar $oldvar oldgids
	upvar $newvar newgids
	
	set gid1 [moregraphics $molid $color1 oldgids \
		      cone $conebase $tip radius [expr $coneradius*$radius] \
		      resolution $resolution]
	set gid2 [moregraphics $molid $color2 oldgids \
		      cylinder $base $conebase radius $radius \
		      resolution $resolution filled yes]
	lappend newgids $gid1 $gid2
	return [list $gid1 $gid2]
    }


}
