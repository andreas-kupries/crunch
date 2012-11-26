## -*- tcl -*-
# # ## ### ##### ######## ############# ##################### ##################################

namespace eval crunch {
    namespace export {[a-z]*}
    namespace ensemble create
}

# # ## ### ##### ######## ############# ##################### ##################################

proc ::crunch::complete {} {
    catch { R close }
    catch { S close }
    return
}

# # ## ### ##### ######## ############# ##################### ##################################

proc ::crunch::repository {r} {
    variable rfile [file normalize $r]
    sqlite3 R $r
    return
}

# # ## ### ##### ######## ############# ##################### ##################################

proc ::crunch::state {s} {
    set has [file exists $s]
    sqlite3 S $s
    if {$has} return
    # Generate structures to hold the processing state.
    S eval {
	-- Table of revisions we have fully processed.
	CREATE TABLE done ( uuid TEXT PRIMARY KEY );
    }
    return
}

proc ::crunch::filter {revisions} {
    puts {exclude already done}

    S eval {
	SELECT uuid FROM done
    } v {
	set done($v(uuid)) .
    }

    set result {}
    foreach uuid $revisions {
	if {[info exists done($uuid)]} continue
	lappend result $uuid
    }
    return $result
}

proc ::crunch::mark {uuid} {
    S transaction {
	S eval {
	    INSERT INTO done VALUES ( $uuid )
	}
    }
    return
}

# # ## ### ##### ######## ############# ##################### ##################################

proc ::crunch::setup {} {
    variable rfile
    puts {setup}

    file delete -force src
    file mkdir         src

    cd src
    exec >& ../log.setup fossil open $rfile
    cd ..
    return
}

proc ::crunch::goto {uuid} {
    puts "goto $uuid"

    cd src
    exec >& ../log.goto fossil update $uuid
    cd ..
    return
}

# # ## ### ##### ######## ############# ##################### ##################################

namespace eval crunch::revisions {
    namespace export {[a-z]*}
    namespace ensemble create
}

proc ::crunch::revisions::all {} {
    puts {revisions: take all}

    return [R eval {
	SELECT   B.uuid
	FROM     event E, blob B
	WHERE    E.objid = B.rid
	ORDER BY E.mtime
	DESC
    }]
}

proc ::crunch::revisions::path {from to} {
    puts {revisions: path $from ... $to}
    R close

    set res {}
    foreach line [split [exec fossil test-shortest-path $from $to] \n] {
	lappend res [lindex $line 2]
    }
    return $res
}

# # ## ### ##### ######## ############# ##################### ##################################
return
