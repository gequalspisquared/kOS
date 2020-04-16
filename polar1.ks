//trying out some kOS.
//local tick for keeping track of time
DECLARE GLOBAL tick TO 0.

//clear terminal TO look fancy
CLEARSCREEN.

//start countdown sequence and launch
PRINT "Counting down:".
WAIT 1.
FROM {local countdown is 3.} UNTIL countdown = -1
    STEP {SET countdown TO countdown - 1.} DO {
        PRINT "..." + countdown.
        WAIT 1.
    }
LOCK THROTTLE TO 1.
STAGE.
PRINT "LIFTOFF.".
WAIT 1.
CLEARSCREEN.



//determines the current heading of the rocket based on altitude
FUNCTION updateHeading {
    DECLARE headingx TO 350.0. DECLARE headingy TO 90.0.
    DECLARE finalheadingy TO 45.0. DECLARE initialalt TO 1500. DECLARE finalalt TO 12500.

    IF SHIP:ALTITUDE > finalalt {
        SET headingy TO finalheadingy.
    } ELSE IF SHIP:ALTITUDE > initialalt {
        SET headingy TO 90.0 - (SHIP:ALTITUDE - initialalt) * (90 - finalheadingy) / (finalalt - initialalt).
    }

    LOCK STEERING TO HEADING(headingx, headingy, -90).
}



//determines whether TO stage
FUNCTION checkThrust {
    LIST ENGINES IN myEngines.
    FOR eg in myEngines {
        // IF SHIP:MAXTHRUST < (SHIP:AVAILABLETHRUST - 1) {
        //     PRINT "Staging..." AT (0, 10).
        //     WAIT 0.5.
        //     STAGE.
        // }
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
UNTIL SHIP:APOAPSIS > 85000 {
    updateHeading().
    checkThrust().
    SET tick TO tick + 1.
    IF mod(tick, 10) = 0 {
        updateScreen().
    }
}

SAS ON.
LOCK SASMODE TO PROGRADE.
WAIT 1.