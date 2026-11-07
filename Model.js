// Shared by QML and the dependency-free Node checks.
function valid(interval, button, limit, delay) {
    return Number.isInteger(interval) && interval >= 10 && interval <= 3600000
        && ["left", "right", "middle"].indexOf(button) !== -1
        && Number.isInteger(limit) && limit >= 0 && limit <= 1000000
        && Number.isInteger(delay) && delay >= 1 && delay <= 10;
}
function command(button) {
    var code = {left: "0xC0", right: "0xC1", middle: "0xC2"}[button];
    if (!code) throw new Error("Invalid mouse button");
    // A complete down/up pair, without ydotool's default 50 ms delay.
    return ["ydotool", "click", "--next-delay", "0", code];
}
