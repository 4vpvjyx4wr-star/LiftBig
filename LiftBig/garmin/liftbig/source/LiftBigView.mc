import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

class LiftBigView extends WatchUi.View {
    function initialize() {
        View.initialize();
    }

    function onUpdate(dc as Dc) as Void {
        var width = dc.getWidth();
        var height = dc.getHeight();
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

        var nameY = layout["nameY"] as Number;
        drawChevron(dc, layout["prevX"] as Number, nameY, -1, session.canMove(-1));
        drawChevron(dc, layout["nextX"] as Number, nameY, 1, session.canMove(1));

        var name = session.exerciseName();
        var nameFont = Graphics.FONT_TINY;
        var nameLimit = (layout["nextX"] as Number) - (layout["prevX"] as Number) - 52;
        if (dc.getTextWidthInPixels(name, nameFont) > nameLimit) {
            nameFont = Graphics.FONT_XTINY;
        }
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, nameY, nameFont, name, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        var slot = session.current();
        var done = slot != null && slot["done"] == true;
        if (done) {
            dc.setColor(0xFF6A1A, Graphics.COLOR_TRANSPARENT);
        } else {
            dc.setColor(0x9AA4B8, Graphics.COLOR_TRANSPARENT);
        }
        dc.drawText(cx, layout["setY"] as Number, Graphics.FONT_XTINY, session.setLabel(), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        var textMax = (layout["plusX"] as Number) - (layout["btnX"] as Number) - 56;
        drawAdjustRow(dc, layout, layout["weightY"] as Number, session.weightLabel(), textMax, false);
        drawAdjustRow(dc, layout, layout["repsY"] as Number, session.repsLabel(), textMax, false);
        drawAdjustRow(dc, layout, layout["restY"] as Number, session.restLabel(), textMax, session.restRemaining > 0);
        drawDone(dc, layout, done);
    }
}

class LiftBigDelegate extends WatchUi.BehaviorDelegate {
    var sawTap as Boolean = false;

    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onTap(evt as ClickEvent) as Boolean {
        sawTap = true;
        var coords = evt.getCoordinates();
        var x = coords[0] as Number;
        var y = coords[1] as Number;
        var settings = System.getDeviceSettings();
        var layout = screenLayout(settings.screenWidth, settings.screenHeight);
        var session = getApp().session;
        var top = hitTop(x, y, settings.screenWidth, settings.screenHeight, session.restRemaining > 0);
        if (top == 0) {
            session.requestHome();
            return true;
        }
        if (session.locked) {
            return true;
        }
        if (top == 1 && session.restRemaining > 0) {
            if (session.restPaused) {
                session.resumeRest();
            } else {
                session.pauseRest();
            }
            return true;
        }
        if (top == 2 && session.restRemaining > 0) {
            session.cancelRest();
            return true;
        }
        if (top == 1) {
            session.finishWorkout();
            return true;
        }
        var radius = layout["navR"] as Number;
        var nameY = layout["nameY"] as Number;
        if (inCircle(x, y, layout["prevX"] as Number, nameY, radius)) {
            session.move(-1);
            return true;
        }
        if (inCircle(x, y, layout["nextX"] as Number, nameY, radius)) {
            session.move(1);
            return true;
        }
        var buttonRadius = layout["btnR"] as Number;
        var minusX = layout["btnX"] as Number;
        var plusX = layout["plusX"] as Number;
        if (inCircle(x, y, minusX, layout["weightY"] as Number, buttonRadius)) {
            session.adjustWeight(-5);
            return true;
        }
        if (inCircle(x, y, plusX, layout["weightY"] as Number, buttonRadius)) {
            session.adjustWeight(5);
            return true;
        }
        if (inCircle(x, y, minusX, layout["repsY"] as Number, buttonRadius)) {
            session.adjustReps(-1);
            return true;
        }
        if (inCircle(x, y, plusX, layout["repsY"] as Number, buttonRadius)) {
            session.adjustReps(1);
            return true;
        }
        if (inCircle(x, y, minusX, layout["restY"] as Number, buttonRadius)) {
            session.adjustRest(-5);
            return true;
        }
        if (inCircle(x, y, plusX, layout["restY"] as Number, buttonRadius)) {
            session.adjustRest(5);
            return true;
        }
        if (inRect(x, y, layout["doneX"] as Number, layout["doneY"] as Number, layout["doneW"] as Number, layout["doneH"] as Number)) {
            session.toggleSet();
            return true;
        }
        return true;
    }

    function onSelect() as Boolean {
        if (sawTap) {
            sawTap = false;
            return true;
        }
        getApp().session.toggleSet();
        return true;
    }

    function onKey(evt as KeyEvent) as Boolean {
        var key = evt.getKey();
        if (key == WatchUi.KEY_ENTER || key == WatchUi.KEY_START) {
            getApp().session.toggleSet();
            return true;
        }
        if (key == WatchUi.KEY_ESC) {
            return true;
        }
        if (key == WatchUi.KEY_UP) {
            getApp().session.move(-1);
            return true;
        }
        if (key == WatchUi.KEY_DOWN) {
            getApp().session.move(1);
            return true;
        }
        return false;
    }

    function onSwipe(evt as SwipeEvent) as Boolean {
        var direction = evt.getDirection();
        if (direction == WatchUi.SWIPE_UP || direction == WatchUi.SWIPE_LEFT) {
            getApp().session.move(1);
            return true;
        }
        if (direction == WatchUi.SWIPE_DOWN) {
            getApp().session.move(-1);
            return true;
        }
        return false;
    }

    function onBack() as Boolean {
        return true;
    }
}

// 454x454 round Venu 3. Chevrons share the exercise-name row, inset
// so the 18px discs stay inside the circular mask. Rest controls sit
// in the top band and do not overlap that row.
function screenLayout(width as Number, height as Number) as Dictionary {
    var cx = width / 2;
    return {
        "cx" => cx,
        "prevX" => width * 15 / 100,
        "nextX" => width * 85 / 100,
        "navR" => 28,
        "nameY" => height * 28 / 100,
        "setY" => height * 38 / 100,
        "weightY" => height * 49 / 100,
        "repsY" => height * 60 / 100,
        "restY" => height * 71 / 100,
        "btnX" => width * 18 / 100,
        "plusX" => width * 82 / 100,
        "btnR" => 26,
        "doneX" => width * 20 / 100,
        "doneY" => height * 79 / 100,
        "doneW" => width * 60 / 100,
        "doneH" => 42,
        "timerY" => height * 8 / 100,
        "timerW" => 88,
        "timerH" => 36,
        "pauseX" => cx - 94,
        "cancelX" => cx + 6
    };
}

function drawChevron(dc as Graphics.Dc, x as Number, y as Number, direction as Number, enabled as Boolean) as Void {
    if (enabled) {
        dc.setColor(0x162033, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(x, y, 18);
        dc.setColor(0xFF6A1A, Graphics.COLOR_TRANSPARENT);
    } else {
        dc.setColor(0x121826, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(x, y, 18);
        dc.setColor(0x3A4458, Graphics.COLOR_TRANSPARENT);
    }
    dc.setPenWidth(3);
    dc.drawCircle(x, y, 18);
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
    var radius = 22;
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

function topRow(width as Number, height as Number, resting as Boolean) as Dictionary {
    var count = resting ? 3 : 2;
    var buttonW = resting ? 72 : 100;
    var gap = 8;
    var total = count * buttonW + (count - 1) * gap;
    var x = width / 2 - total / 2;
    return {
        "y" => height * 10 / 100,
        "h" => 32,
        "w" => buttonW,
        "x0" => x,
        "x1" => x + buttonW + gap,
        "x2" => x + (buttonW + gap) * 2
    };
}

function drawTopRow(dc as Graphics.Dc, width as Number, height as Number, session as Session) as Void {
    var resting = session.restRemaining > 0;
    var row = topRow(width, height, resting);
    var y = row["y"] as Number;
    var w = row["w"] as Number;
    var h = row["h"] as Number;
    drawPill(dc, row["x0"] as Number, y, w, h, "Home", session.exitAfterRest == false);
    if (resting) {
        var label = "Pause";
        var outline = false;
        if (session.restPaused) {
            label = "Resume";
            outline = true;
        }
        drawPill(dc, row["x1"] as Number, y, w, h, label, outline);
        drawPill(dc, row["x2"] as Number, y, w, h, "Cancel", true);
    } else if (session.locked == false && session.slots.size() > 0) {
        drawPill(dc, row["x1"] as Number, y, w, h, "Finish", false);
    }
}

function hitTop(x as Number, y as Number, width as Number, height as Number, resting as Boolean) as Number {
    var row = topRow(width, height, resting);
    var top = row["y"] as Number;
    var w = row["w"] as Number;
    var h = row["h"] as Number;
    if (inRect(x, y, row["x0"] as Number, top, w, h)) {
        return 0;
    }
    if (inRect(x, y, row["x1"] as Number, top, w, h)) {
        return 1;
    }
    if (resting && inRect(x, y, row["x2"] as Number, top, w, h)) {
        return 2;
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

function inCircle(x as Number, y as Number, cx as Number, cy as Number, radius as Number) as Boolean {
    var dx = x - cx;
    var dy = y - cy;
    return dx * dx + dy * dy <= radius * radius;
}

function inRect(x as Number, y as Number, left as Number, top as Number, width as Number, height as Number) as Boolean {
    return x >= left && x <= left + width && y >= top && y <= top + height;
}
