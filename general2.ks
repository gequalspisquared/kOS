// trying out some kOS.
// TO DO: add info readouts to the terminal
// TO DO: let executeNextNode take in a node ???

// local tick for keeping track of time
DECLARE GLOBAL tick TO 0.

// clear terminal to look fancy
CLEARSCREEN.

// main function
FUNCTION main {
    SET STEERINGMANAGER:MAXSTOPPINGTIME TO 6. // depends on craft, more = longer turns
    DECLARE LOCAL desiredApoapsis TO 100000.

    launchSequence(desiredApoapsis).
    addNodeToCircularize(desiredApoapsis).
    executeNextNode().

    SAS ON.
    WAIT 0.1.
    SET SASMODE TO "PROGRADE".
    
    WAIT UNTIL FALSE.
}

// --- BEGINNING OF LAUNCH SEQUENCE --- //

// launches rocket until desired apoapsis is achieved
FUNCTION launchSequence {
    PARAMETER targetApoapsis.

    startupSequence().
    UNTIL SHIP:APOAPSIS > targetApoapsis {
        updateHeading(). // steepness factor?
        checkFairing().
        doAutoStage().

        SET tick TO tick + 1.
        // IF mod(tick, 10) = 0 {
        //     updateScreen().
        // }
    }
    shutdownSequence().
}

// start countdown sequence and launch
FUNCTION startupSequence {
    PRINT "Counting down:".
    WAIT 1.
    FROM {LOCAL countdown IS 3.} UNTIL countdown = 0
        STEP {SET countdown TO countdown - 1.} DO {
            PRINT "..." + countdown.
            WAIT 1.
        }
    LOCK THROTTLE TO 1.
    STAGE.
    PRINT "LIFTOFF.".
    WAIT 1.
    CLEARSCREEN.
}

// determines the current heading of the rocket based on altitude (flight profile)
FUNCTION updateHeading {
    DECLARE headingx TO 90.0. DECLARE headingy TO 90.0.
    DECLARE finalheadingy TO 20.0. DECLARE initialalt TO 500. DECLARE finalalt TO 35000.

    IF SHIP:ALTITUDE > finalalt {
        SET headingy TO finalheadingy.
    } ELSE IF SHIP:ALTITUDE > initialalt {
        SET headingy TO 90.0 - (SHIP:ALTITUDE - initialalt) * (90 - finalheadingy) / (finalalt - initialalt).
    }

    LOCK STEERING TO HEADING(headingx, headingy, 0.0).
}

FUNCTION checkFairing {
    IF SHIP:ALTITUDE > 60000 {
        AG10 ON.
    }
}

// update information in console
FUNCTION updateScreen { 
    CLEARSCREEN.
    DECLARE shipDir TO SHIP:FACING.
    PRINT "HEADING: (" + shipDir:VECTOR:X + ", " 
                       + shipDir:VECTOR:Y + ", "
                       + shipDir:VECTOR:Z + ")" AT (0, 0).

    PRINT "PROGRADE: (" + SHIP:SRFPROGRADE:VECTOR:X + ", " 
                        + SHIP:SRFPROGRADE:VECTOR:Y + ", "
                        + SHIP:SRFPROGRADE:VECTOR:Z + ")" AT (0, 1).
        
    PRINT "AVL THRUST: " + SHIP:AVAILABLETHRUST AT (0, 2).
    PRINT "MAX THRUST: " + SHIP:MAXTHRUST AT (0, 3).
}

// unlocks controls and deploys panels once apoapsis is achieved
FUNCTION shutdownSequence { 
    TOGGLE PANELS.
    UNLOCK STEERING.
    UNLOCK THROTTLE.
    WAIT 1.
}

// --- END OF LAUNCH SEQUENCE FUNCTIONS --- //
// --------------------------------------- //
// --- BEGINNING OF MANEUVER FUNCTIONS --- //

// executes the next available maneuver node or given node
FUNCTION executeNextNode {
    DECLARE LOCAL originalmnv TO NODE(TIME:SECONDS, 0, 0, 0).
    IF HASNODE = true {
        SET originalmnv TO NEXTNODE.
        LOCK currentmnv TO NEXTNODE.
    } ELSE {
        RETURN "NO NODE GIVEN".
    }
    
    DECLARE startTime TO calculateManeuverStartTime(originalmnv).
    lockSteeringToManeuverTarget(currentmnv).
    WAIT UNTIL startTime.
    WHEN vang(originalmnv:BURNVECTOR, SHIP:FACING:VECTOR) < 0.5 AND TIME:SECONDS > startTime -0.1 THEN {
        LOCK THROTTLE TO 1.   
    }

    UNTIL isManeuverComplete(originalmnv, currentmnv) {
        doAutoStage().
        adjustManeuverThrottle(currentmnv).
    }

    LOCK THROTTLE TO 0.
    REMOVE currentmnv.

    UNLOCK THROTTLE.
    UNLOCK STEERING.
}

// calculates the start time of a maneuver node in utime
FUNCTION calculateManeuverStartTime {
    PARAMETER mnv.
    RETURN TIME:SECONDS + mnv:ETA - calculateManeuverBurnTime(mnv) / 2.
}

// calculates burn time of a maneuver node
FUNCTION calculateManeuverBurnTime {
    PARAMETER mnv.
    DECLARE LOCAL dV TO mnv:DELTAV:MAG.
    DECLARE LOCAL g0 TO 9.8055.
    DECLARE LOCAL isp TO 0.

    LIST ENGINES IN myEngines.
    FOR eng IN myEngines {
        IF eng:IGNITION AND NOT eng:FLAMEOUT {
            SET isp TO isp + (eng:ISP * (eng:AVAILABLETHRUST / SHIP:AVAILABLETHRUST)).
        }
    }

    DECLARE LOCAL mf TO SHIP:MASS / constant():e^(dV / (isp * g0)).
    DECLARE LOCAL fuelFlow TO SHIP:AVAILABLETHRUST / (isp * g0).
    DECLARE LOCAL dt TO (SHIP:MASS - mf) / fuelFlow.

    RETURN dt.
}

// points ship at manuever node
FUNCTION lockSteeringToManeuverTarget {
    PARAMETER mnv.
    LOCK STEERING TO mnv:BURNVECTOR.
}

// determines whether or not a maneuver node is complete
FUNCTION isManeuverComplete {
    PARAMETER originalmnv, currentmnv.
    IF vang(originalmnv:BURNVECTOR, currentmnv:BURNVECTOR) > 90 OR currentmnv:DELTAV:MAG < 0.2 {
        RETURN true.
    } ELSE {
        RETURN false.
    }
}

// adjusts throttle during maneuver burn
FUNCTION adjustManeuverThrottle {
    PARAMETER mnv.
    IF mnv:DELTAV:MAG < 10 {
        LOCK THROTTLE TO mnv:DELTAV:MAG / 10.
    }
}

// creates maneuver to circularize orbit (for launch)
FUNCTION addNodeToCircularize {
    PARAMETER desiredApoapsis.
    DECLARE LOCAL dV TO sqrt(KERBIN:MU / (desiredApoapsis + KERBIN:RADIUS)) -
                        sqrt(SHIP:VELOCITY:ORBIT:SQRMAGNITUDE + 2 * KERBIN:MU * 
                            (1 / (desiredApoapsis + KERBIN:RADIUS) - 1 / (SHIP:ALTITUDE + KERBIN:RADIUS))).

    ADD NODE(TIME:SECONDS + ETA:APOAPSIS, 0, 0, dV).
}

// --- END OF MANEUVER FUNCTIONS --- //
// ------------------------------------ //
// --- BEGINNING OF GENERAL FUNCTIONS --- //

// self explanatory
FUNCTION doSafeStage {
    WAIT UNTIL STAGE:READY.
    STAGE.
    WAIT 1.
}

// determines whether to stage
FUNCTION doAutoStage { 
    LIST ENGINES IN myEngines.
    FOR eg in myEngines {
        IF eg:IGNITION AND eg:FLAMEOUT {
            PRINT "FLAMEOUT".
            doSafeStage().
            BREAK.
        } 
    }
    IF SHIP:AVAILABLETHRUST < 0.1 {
        doSafeStage().
        PRINT "NO THRUST".
    }
}

// found this online, reduces over-correction on steering
// takes a DIRECTION, not a vector
// FUNCTION smoothRotate {
//     PARAMETER dir.
//     LOCAL spd IS max(SHIP:ANGULARMOMENTUM:MAG/10,4).
//     LOCAL curF IS SHIP:FACING:FOREVECTOR.
//     LOCAL curR IS SHIP:FACING:TOPVECTOR.
//     LOCAL rotR IS R(0,0,0).
//     IF VANG(dir:FOREVECTOR,curF) < 90{SET rotR TO ANGLEAXIS(min(0.5,VANG(dir:TOPVECTOR,curR)/spd),VCRS(curR,dir:TOPVECTOR)).}
//     RETURN LOOKDIRUP(ANGLEAXIS(min(2,VANG(dir:FOREVECTOR,curF)/spd),VCRS(curF,dir:FOREVECTOR))*curF,rotR*curR).
// }

// run the program
main().
