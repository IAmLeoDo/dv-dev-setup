// Windows Script Host JScript: locale-independent local build timestamp.
function pad(value) {
    return value < 10 ? "0" + value : String(value);
}
var now = new Date();
WScript.Echo(pad(now.getFullYear() % 100) + pad(now.getMonth() + 1) +
    pad(now.getDate()) + "_" + pad(now.getHours()) +
    pad(now.getMinutes()) + pad(now.getSeconds()));
