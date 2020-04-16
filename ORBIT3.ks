//trying out some kOS.

//clear terminal TO look fancy
CLEARSCREEN.

//start countdown sequence and launch
PRINT "Counting down:".
WAIT 1.
FROM {local countdown is 10.} UNTIL countdown = -1
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
    DECLARE headingx TO 90.0. DECLARE headingy TO 90.0.

    IF SHIP:ALTITUDE > 12500 {
        SET headingy TO 45.
    } ELSE IF SHIP:ALTITUDE > 1500 {
        SET headingy TO 90.0 - (SHIP:ALTITUDE + 11000.0 - 12500) / 244.4.
    }

    LOCK STEERING TO HEADING(headingx, headingy, -90).
}

//determines whether TO stage
FUNCTION checkThrust {
    IF SHIP:MAXTHRUST = 0 {
        PRINT "Staging..." AT (0, 1).
        WAIT 0.5.
        STAGE.
    }
}

//update information in console
FUNCTION updateScreen {
    PRINT "HEADING: (" + SHIP:PROGRADE:VECTOR:X + ", " 
                       + SHIP:PROGRADE:VECTOR:Y + ", "
                       + SHIP:PROGRADE:VECTOR:Z + ")".

    CLEARSCREEN.
}

UNTIL SHIP:APOAPSIS > 85000 {
    updateHeading().
    checkThrust().
    updateScreen().
}

SAS ON.