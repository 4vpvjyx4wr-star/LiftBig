import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Timer;
import Toybox.WatchUi;

// Hit tests use the size onUpdate just drew with. Device settings can
// disagree with the drawable on a round screen, and then every tap misses.
var drawnWidth as Number = 454;
var drawnHeight as Number = 454;

class LiftBigView extends WatchUi.View {
    function initialize() {
        View.initialize();
    }

    function onUpdate(dc as Dc) as Void {
        var width = dc.getWidth();
        var height = dc.getHeight();
        drawnWidth = width;
        drawnHeight = height;
        var session = getApp().session;
        session.syncRestClock(true);
        var layout = screenLayout(width, height);
        var cx = layout["cx"] as Number;

        dc.setColor(0x0A0F1E, 0x0A0F1E);
        dc.clear();
        drawRestArc(dc, session, cx, height / 2, width);
        drawTopRow(dc, width, height, session);

        if (session.locked || session.slots.size() == 0) {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, height / 2, Graphics.FONT_XTINY, "Open a workout\non your iPhone.", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            return;
        }

        var slot = session.current();
        var done = slot != null && slot["done"] == true;
        if (done) {
            dc.setColor(0xFF6A1A, Graphics.COLOR_TRANSPARENT);
        } else {
            dc.setColor(0x9AA4B8, Graphics.COLOR_TRANSPARENT);
        }
        dc.drawText(cx, layout["setY"] as Number, Graphics.FONT_XTINY, session.setLabel(), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        var nameY = layout["nameY"] as Number;
        var navR = layout["navR"] as Number;
        var prevX = layout["prevX"] as Number;
        var nextX = layout["nextX"] as Number;
        drawChevron(dc, prevX, nameY, -1, session.canMoveExercise(-1), navR);
        drawChevron(dc, nextX, nameY, 1, session.canMoveExercise(1), navR);

        var nameFont = Graphics.FONT_TINY;
        var nameLimit = nextX - prevX - (navR * 2) - 8;
        if (nameLimit < 40) {
            nameLimit = 40;
        }
        var fullName = session.exerciseName();
        if (dc.getTextWidthInPixels(fullName, nameFont) > nameLimit) {
            nameFont = Graphics.FONT_XTINY;
        }
        var name = fitExerciseName(dc, fullName, nameFont, nameLimit);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, nameY, nameFont, name, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        var textMax = (layout["plusX"] as Number) - (layout["btnX"] as Number) - 56;
        drawAdjustRow(dc, layout, layout["weightY"] as Number, session.weightLabel(), textMax, false);
        drawAdjustRow(dc, layout, layout["repsY"] as Number, session.repsLabel(), textMax, false);
        drawAdjustRow(dc, layout, layout["restY"] as Number, session.restLabel(), textMax, session.restRemaining > 0);
        drawDone(dc, layout, done);
    }
}

class LiftBigDelegate extends WatchUi.BehaviorDelegate {
    var lastBackMs as Number = -1000;
    var lastTapMs as Number = -10000;
    var physicalSelect as Boolean = false;
    var selectTimer as Timer.Timer = new Timer.Timer();

    function initialize() {
        BehaviorDelegate.initialize();
    }

    function stepBack() as Void {
        var now = System.getTimer();
        if (now - lastBackMs < 400) {
            return;
        }
        lastBackMs = now;
        var session = getApp().session;
        if (session.canMoveExercise(-1)) {
            session.moveExercise(-1);
            return;
        }
        // leaveNow() clears the timer. Stay up until the buzz instead.
        if (session.restRemaining > 0 && session.restPaused == false) {
            session.requestHome();
            return;
        }
        session.leaveNow();
    }

    function onTap(evt as ClickEvent) as Boolean {
        lastTapMs = System.getTimer();
        physicalSelect = false;
        selectTimer.stop();
        var coords = evt.getCoordinates();
        var x = coords[0] as Number;
        var y = coords[1] as Number;
        var width = drawnWidth;
        var height = drawnHeight;
        if (width < 100 || height < 100) {
            var settings = System.getDeviceSettings();
            width = settings.screenWidth;
            height = settings.screenHeight;
        }
        var layout = screenLayout(width, height);
        var session = getApp().session;
        if (session.locked) {
            return true;
        }
        var resting = session.restRemaining > 0;
        var top = hitTop(x, y, width, height, resting, !resting && session.allSetsDone());
        if (top == 1 && resting) {
            if (session.restPaused) {
                session.resumeRest();
            } else {
                session.pauseRest();
            }
            return true;
        }
        if (top == 2 && resting) {
            session.cancelRest();
            return true;
        }
        if (top == 1) {
            session.finishWorkout();
            return true;
        }

        // Hit the drawn circles, not coarse left/right bands. A tap that
        // misses every control still returns true so it does not toggle the set.
        var nameY = layout["nameY"] as Number;
        var navR = layout["navR"] as Number;
        if (inCircle(x, y, layout["prevX"] as Number, nameY, navR)) {
            session.moveExercise(-1);
            return true;
        }
        if (inCircle(x, y, layout["nextX"] as Number, nameY, navR)) {
            session.moveExercise(1);
            return true;
        }
        var btnX = layout["btnX"] as Number;
        var plusX = layout["plusX"] as Number;
        var btnR = layout["btnR"] as Number;
        var weightY = layout["weightY"] as Number;
        if (inCircle(x, y, btnX, weightY, btnR)) {
            session.adjustWeight(-5);
            return true;
        }
        if (inCircle(x, y, plusX, weightY, btnR)) {
            session.adjustWeight(5);
            return true;
        }
        var repsY = layout["repsY"] as Number;
        if (inCircle(x, y, btnX, repsY, btnR)) {
            session.adjustReps(-1);
            return true;
        }
        if (inCircle(x, y, plusX, repsY, btnR)) {
            session.adjustReps(1);
            return true;
        }
        var restY = layout["restY"] as Number;
        if (inCircle(x, y, btnX, restY, btnR)) {
            session.adjustRest(-5);
            return true;
        }
        if (inCircle(x, y, plusX, restY, btnR)) {
            session.adjustRest(5);
            return true;
        }
        if (inRect(x, y, layout["doneX"] as Number, layout["doneY"] as Number, layout["doneW"] as Number, layout["doneH"] as Number)) {
            session.toggleSet();
            return true;
        }
        return true;
    }

    // A screen touch is also Select. That path must not complete the set.
    // The drawn Set done control, and the physical Start button, do that.
    function onSelect() as Boolean {
        return true;
    }

    // Start can arrive just before the tap coordinates. Wait long enough to
    // see the tap, then do nothing if the touch already handled itself.
    function armPhysicalSelect() as Void {
        var now = System.getTimer();
        if (now - lastTapMs < 400) {
            return;
        }
        physicalSelect = true;
        selectTimer.stop();
        selectTimer.start(method(:commitPhysicalSelect), 300, false);
    }

    function commitPhysicalSelect() as Void {
        if (physicalSelect == false) {
            return;
        }
        physicalSelect = false;
        if (System.getTimer() - lastTapMs < 400) {
            return;
        }
        getApp().session.toggleSet();
    }

    function onKey(evt as KeyEvent) as Boolean {
        var key = evt.getKey();
        if (key == WatchUi.KEY_ENTER || key == WatchUi.KEY_START) {
            armPhysicalSelect();
            return true;
        }
        if (key == WatchUi.KEY_ESC) {
            stepBack();
            return true;
        }
        // Venu 3 has no up or down button. These are swipe and page events.
        if (key == WatchUi.KEY_UP || key == WatchUi.KEY_DOWN) {
            return true;
        }
        return false;
    }

    function onNextPage() as Boolean {
        return true;
    }

    function onPreviousPage() as Boolean {
        return true;
    }

    function onSwipe(evt as SwipeEvent) as Boolean {
        return true;
    }

    function onBack() as Boolean {
        stepBack();
        return true;
    }
}

// 454x454 round Venu 3. Hit radius matches the drawn disc so neighboring
// circles do not overlap. Row pitch is wider than the diameter, and the
// centers stay inside the round bezel. Previous and next sit clear of
// the weight row. Pause and cancel use the top band.
function screenLayout(width as Number, height as Number) as Dictionary {
    var cx = width / 2;
    var navSpan = width * 28 / 100;
    return {
        "cx" => cx,
        "prevX" => cx - navSpan,
        "nextX" => cx + navSpan,
        "navR" => 22,
        "setY" => height * 28 / 100,
        "nameY" => height * 36 / 100,
        "weightY" => height * 49 / 100,
        "repsY" => height * 61 / 100,
        "restY" => height * 73 / 100,
        "btnX" => width * 18 / 100,
        "plusX" => width * 82 / 100,
        "btnR" => 22,
        "doneX" => width * 20 / 100,
        "doneY" => height * 80 / 100,
        "doneW" => width * 60 / 100,
        "doneH" => 40,
        "timerY" => height * 8 / 100,
        "timerW" => 88,
        "timerH" => 36,
        "pauseX" => cx - 94,
        "cancelX" => cx + 6
    };
}

function drawChevron(dc as Graphics.Dc, x as Number, y as Number, direction as Number, enabled as Boolean, radius as Number) as Void {
    if (enabled) {
        dc.setColor(0x162033, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(x, y, radius);
        dc.setColor(0xFF6A1A, Graphics.COLOR_TRANSPARENT);
    } else {
        dc.setColor(0x121826, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(x, y, radius);
        dc.setColor(0x3A4458, Graphics.COLOR_TRANSPARENT);
    }
    dc.setPenWidth(3);
    dc.drawCircle(x, y, radius);
    dc.setPenWidth(4);
    if (direction < 0) {
        dc.drawLine(x + 6, y - 8, x - 5, y);
        dc.drawLine(x - 5, y, x + 6, y + 8);
    } else {
        dc.drawLine(x - 6, y - 8, x + 5, y);
        dc.drawLine(x + 5, y, x - 6, y + 8);
    }
}

function drawAdjustRow(dc as Graphics.Dc, layout as Dictionary, y as Number, label as String, textMax as Number, active as Boolean) as Void {
    var minusX = layout["btnX"] as Number;
    var plusX = layout["plusX"] as Number;
    var radius = layout["btnR"] as Number;
    drawRoundButton(dc, minusX, y, radius, false);
    drawRoundButton(dc, plusX, y, radius, true);
    var font = Graphics.FONT_TINY;
    if (dc.getTextWidthInPixels(label, font) > textMax) {
        font = Graphics.FONT_XTINY;
    }
    if (active) {
        dc.setColor(0xFF6A1A, Graphics.COLOR_TRANSPARENT);
    } else {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
    }
    dc.drawText(layout["cx"] as Number, y, font, label, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
}

function drawRoundButton(dc as Graphics.Dc, x as Number, y as Number, radius as Number, plus as Boolean) as Void {
    dc.setColor(0x162033, Graphics.COLOR_TRANSPARENT);
    dc.fillCircle(x, y, radius);
    dc.setColor(0xFF6A1A, Graphics.COLOR_TRANSPARENT);
    dc.setPenWidth(3);
    dc.drawCircle(x, y, radius);
    dc.setPenWidth(4);
    dc.drawLine(x - 9, y, x + 9, y);
    if (plus) {
        dc.drawLine(x, y - 9, x, y + 9);
    }
}

function drawDone(dc as Graphics.Dc, layout as Dictionary, done as Boolean) as Void {
    var x = layout["doneX"] as Number;
    var y = layout["doneY"] as Number;
    var w = layout["doneW"] as Number;
    var h = layout["doneH"] as Number;
    if (done) {
        fillPill(dc, x, y, w, h, 0xFF6A1A);
        fillPill(dc, x + 3, y + 3, w - 6, h - 6, 0x162033);
        dc.setColor(0xFF6A1A, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x + w / 2, y + h / 2, Graphics.FONT_XTINY, "Undo", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    } else {
        fillPill(dc, x, y, w, h, 0xFF6A1A);
        dc.setColor(0x0A0F1E, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x + w / 2, y + h / 2, Graphics.FONT_XTINY, "Set done", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}

// Two pills, centered. On a 454 circle the top of this row is ~40px
// inside the bezel, and the bottom stays clear of the set line.
function topRow(width as Number, height as Number) as Dictionary {
    var buttonW = width * 21 / 100;
    var gap = 16;
    var total = buttonW * 2 + gap;
    var x = width / 2 - total / 2;
    return {
        "y" => height * 15 / 100,
        "h" => 36,
        "w" => buttonW,
        "x0" => x,
        "x1" => x + buttonW + gap
    };
}

function drawTopRow(dc as Graphics.Dc, width as Number, height as Number, session as Session) as Void {
    var resting = session.restRemaining > 0;
    var row = topRow(width, height);
    var y = row["y"] as Number;
    var w = row["w"] as Number;
    var h = row["h"] as Number;
    if (resting) {
        var label = "Pause";
        var outline = false;
        if (session.restPaused) {
            label = "Resume";
            outline = true;
        }
        drawPill(dc, row["x0"] as Number, y, w, h, label, outline);
        drawPill(dc, row["x1"] as Number, y, w, h, "Cancel", true);
        return;
    }
    if (session.allSetsDone()) {
        drawPill(dc, width / 2 - w / 2, y, w, h, "Finish", false);
    }
}

function hitTop(x as Number, y as Number, width as Number, height as Number, resting as Boolean, showFinish as Boolean) as Number {
    var row = topRow(width, height);
    var top = row["y"] as Number;
    var w = row["w"] as Number;
    var h = row["h"] as Number;
    if (resting) {
        if (inRect(x, y, row["x0"] as Number, top, w, h)) {
            return 1;
        }
        if (inRect(x, y, row["x1"] as Number, top, w, h)) {
            return 2;
        }
        return -1;
    }
    if (showFinish && inRect(x, y, width / 2 - w / 2, top, w, h)) {
        return 1;
    }
    return -1;
}

function drawPill(dc as Graphics.Dc, x as Number, y as Number, w as Number, h as Number, label as String, outline as Boolean) as Void {
    if (outline) {
        fillPill(dc, x, y, w, h, 0xFF6A1A);
        fillPill(dc, x + 2, y + 2, w - 4, h - 4, 0x162033);
        dc.setColor(0xFF6A1A, Graphics.COLOR_TRANSPARENT);
    } else {
        fillPill(dc, x, y, w, h, 0xFF6A1A);
        dc.setColor(0x0A0F1E, Graphics.COLOR_TRANSPARENT);
    }
    dc.drawText(x + w / 2, y + h / 2, Graphics.FONT_XTINY, label, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
}

function fillPill(dc as Graphics.Dc, x as Number, y as Number, w as Number, h as Number, color as Number) as Void {
    dc.setColor(color, Graphics.COLOR_TRANSPARENT);
    dc.fillRoundedRectangle(x, y, w, h, h / 2);
}

function drawRestArc(dc as Graphics.Dc, session as Session, cx as Number, cy as Number, width as Number) as Void {
    if (session.restRemaining <= 0 || session.restPreset <= 0) {
        return;
    }
    var radius = width / 2 - 8;
    dc.setColor(0x243044, Graphics.COLOR_TRANSPARENT);
    dc.setPenWidth(6);
    dc.drawArc(cx, cy, radius, Graphics.ARC_CLOCKWISE, 90, 90);
    var sweep = (session.restRemaining.toFloat() * 360.0 / session.restPreset.toFloat()).toNumber();
    if (sweep > 360) {
        sweep = 360;
    }
    if (sweep <= 0) {
        return;
    }
    var end = 90 - sweep;
    if (end < 0) {
        end = end + 360;
    }
    if (session.restPaused) {
        dc.setColor(0x9AA4B8, Graphics.COLOR_TRANSPARENT);
    } else {
        dc.setColor(0xFF6A1A, Graphics.COLOR_TRANSPARENT);
    }
    dc.drawArc(cx, cy, radius, Graphics.ARC_CLOCKWISE, 90, end);
}

// The title sits between the arrows. Cut it instead of drawing through them.
function fitExerciseName(dc as Graphics.Dc, name as String, font as Graphics.FontType, limit as Number) as String {
    if (limit < 1) {
        return "";
    }
    if (dc.getTextWidthInPixels(name, font) <= limit) {
        return name;
    }
    var ellipsis = "...";
    if (dc.getTextWidthInPixels(ellipsis, font) > limit) {
        return "";
    }
    var trimmed = name;
    while (trimmed.length() > 1) {
        trimmed = trimmed.substring(0, trimmed.length() - 1);
        var candidate = trimmed + ellipsis;
        if (dc.getTextWidthInPixels(candidate, font) <= limit) {
            return candidate;
        }
    }
    return ellipsis;
}

function nearChevron(x as Number, y as Number, cx as Number, cy as Number) as Boolean {
    return inCircle(x, y, cx, cy, 40);
}

function inCircle(x as Number, y as Number, cx as Number, cy as Number, radius as Number) as Boolean {
    var dx = x - cx;
    var dy = y - cy;
    return dx * dx + dy * dy <= radius * radius;
}

function inRect(x as Number, y as Number, left as Number, top as Number, width as Number, height as Number) as Boolean {
    return x >= left && x <= left + width && y >= top && y <= top + height;
}
