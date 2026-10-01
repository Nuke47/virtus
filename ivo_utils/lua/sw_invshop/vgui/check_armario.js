var fso = new ActiveXObject("Scripting.FileSystemObject");
var f = fso.OpenTextFile("d:\\SteamLibrary\\steamapps\\common\\GarrysMod\\garrysmod\\addons\\ivo_utils\\lua\\sw_invshop\\vgui\\cl_3d_armario.lua", 1);
var content = f.ReadAll();
f.Close();

var lines = content.split("\n");
var depth = 2; // Assume we start at depth 2 at line 482

for (var i = 481; i <= 1008; i++) { // 482 to 1009
    var line = lines[i].replace(/^\s+|\s+$/g, "");
    if (line.substring(0, 2) === "--") continue;
    
    var cleanLine = line.replace(/".*?"/g, '""');
    
    var openMatch = cleanLine.match(/\b(if|for|while|function)\b/g);
    var closeMatch = cleanLine.match(/\bend\b/g);
    
    var oCount = openMatch ? openMatch.length : 0;
    var cCount = closeMatch ? closeMatch.length : 0;
    
    if (cleanLine.match(/\bif\b.*\bthen\b.*\bend\b/)) {
        oCount--;
        cCount--;
    }
    
    depth += oCount - cCount;
}
WScript.Echo("Depth at 1008 (before else): " + depth);
