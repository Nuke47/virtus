var fso = new ActiveXObject("Scripting.FileSystemObject");
var f = fso.OpenTextFile("d:\\SteamLibrary\\steamapps\\common\\GarrysMod\\garrysmod\\addons\\ivo_utils\\lua\\sw_invshop\\vgui\\cl_3d_shop.lua", 1);
var content = f.ReadAll();
f.Close();

var lines = content.split("\n");
var depth = 0;

for (var i = 561; i <= 855; i++) {
    var line = lines[i].replace(/^\s+|\s+$/g, "");
    if (line.substring(0, 2) === "--") continue;
    
    // Naive heuristic: remove strings
    var cleanLine = line.replace(/".*?"/g, '""');
    
    var openMatch = cleanLine.match(/\b(if|for|while|function)\b/g);
    var closeMatch = cleanLine.match(/\bend\b/g);
    
    var oCount = openMatch ? openMatch.length : 0;
    var cCount = closeMatch ? closeMatch.length : 0;
    
    // adjust for one-liners
    if (cleanLine.match(/\bif\b.*\bthen\b.*\bend\b/)) {
        oCount--;
        cCount--;
    }
    
    depth += oCount - cCount;
    if (oCount !== cCount) {
        WScript.Echo((i+1) + " [" + depth + "]: " + line);
    }
}
