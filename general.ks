//trying out some kOS.
//local tick for keeping track of time
DECLARE GLOBAL tick TO 0.

//clear terminal TO look fancy
CLEARSCREEN.



FUNCTION main {
    launchSequence().
}

// launches rocket until desired apoapsis is achieved
FUNCTION launchSequence {
    startupSequence().
    UNTIL SHIP:APOAPSIS > 90000 {
        updateHeading().
        doAutoStage().

        SET tick TO tick + 1.
        IF mod(tick, 10) = 0 {
            updateScreen().
        }
    }

    shutdownSequence().
}


//start countdown sequence and launch
FUNCTION startupSequence {
    PRINT "Counting down:".
    WAIT 1.
    FROM {local countdown is 3.} UNTIL countdown = 0
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


FUNCTION doSafeStage { // self explanatory
    WAIT UNTIL STAGE:READY.
    STAGE.
}



//determines the current heading of the rocket based on altitude
FUNCTION updateHeading {
    DECLARE headingx TO 90.0. DECLARE headingy TO 90.0.
    DECLARE finalheadingy TO 40.0. DECLARE initialalt TO 1500. DECLARE finalalt TO 14500.

    IF SHIP:ALTITUDE > finalalt {
        SET headingy TO finalheadingy.
    } ELSE IF SHIP:ALTITUDE > initialalt {
        SET headingy TO 90.0 - (SHIP:ALTITUDE - initialalt) * (90 - finalheadingy) / (finalalt - initialalt).
    }

    LOCK STEERING TO HEADING(headingx, headingy, 0.0).
}



//determines whether to stage
FUNCTION doAutoStage {
    LIST ENGINES IN myEngines.
    FOR eg in myEngines {
        IF eg:IGNITION AND eg:FLAMEOUT {
            WAIT 0.5.
            STAGE.
        }
    }
}



//update information in console
FUNCTION updateScreen {
    CLEARSCREEN.
    DECLARE shipDir TO SHIP:FACING.
    PRINT "HEADING: (" + shipDir:VECTOR:X + ", " 
                        + shipDir:VECTOR:Y + ", "
                        + shipDir:VECTOR:Z + ")" AT (0, 0).

    PRINT "PROGRADE: (" + SHIP:SRFPROGRADE:VECTOR:X + ", " 
                       + SHIP:SRFPROGRADE:VECTOR:Y + ", "
                       + SHIP:SRFPROGRADE:VECTOR:Z + ")" AT (0, 1).
        
    PRINT "AVAIL THRUST: " + SHIP:AVAILABLETHRUST AT (0, 2).
    PRINT "MAX THRUST: " + SHIP:MAXTHRUST AT (0, 3).
}



//loop functions until apoapsis is achieved
UNTIL SHIP:APOAPSIS > 90000 {
    updateHeading().
    doAutoStage().

    SET tick TO tick + 1.
    IF mod(tick, 10) = 0 {
        updateScreen().
    }
}


FUNCTION shutdownSequence { // also self explanatory
    SAS ON.
    LOCK SASMODE TO PROGRADE.
    WAIT 1.
}

// --- END OF LAUNCH SEQUENCE FUNCTIONS --- //

