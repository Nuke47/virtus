const fs = require('fs');
const lines = fs.readFileSync('d:\\SteamLibrary\\steamapps\\common\\GarrysMod\\garrysmod\\addons\\ivo_utils\\lua\\sw_invshop\\vgui\\cl_3d_shop.lua', 'utf8').split('\n');
let depth = 0;
for (let i = 561; i < 856; i++) {
    const line = lines[i];
    // Very dumb lua block counter
    let openCount = (line.match(/\b(if|for|while)\b/g) || []).length;
    openCount += (line.match(/\bfunction\b/g) || []).length;
    let closeCount = (line.match(/\bend\b/g) || []).length;
    
    // ignore one-liners like `if X then Y end`
    const oneliners = (line.match(/\bif\b.*\bthen\b.*\bend\b/g) || []).length;
    openCount -= oneliners;
    closeCount -= oneliners;
    
    // adjust for elseif/else (they don't change depth)
    
    depth += openCount - closeCount;
    if (depth < 2) { // Print when depth drops
        console.log(`${i+1} [${depth}]: ${line.trim()}`);
    }
}
console.log("Final depth at 856:", depth);
