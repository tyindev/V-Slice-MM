package vslice;

import flixel.FlxState;
import flixel.text.FlxText;
import flixel.FlxG;
import flixel.ui.FlxButton;
import sys.FileSystem;
import sys.io.File;
import haxe.io.Path;
import sys.io.FileInput;

class PlayState extends FlxState
{
    var maintxt:FlxText;
    var bg:FlxSprite;

    override public function create()
    {
        bg = new FlxSprite(-80).loadGraphic(Paths.image('menuDesat'));
        bg.scrollFactor.x = 0;
        bg.scrollFactor.y = 0.18;
        bg.setGraphicSize(Std.int(bg.width * 1.1));
        bg.updateHitbox();
        bg.screenCenter();
        bg.antialiasing = true;
        add(bg);

        maintxt = new FlxText(0, 0, FlxG.width, "Press enter to select your FNF V-Slice Mods Folder!", 32);
        maintxt.setFormat("VCR OSD Mono", 32, FlxColor.BLACK, CENTER);
        maintxt.screenCenter(Y);
        add(maintxt);

        super.create();
    }

    override public function update(elapsed:Float)
    {
        if (FlxG.keys.justPressed.ENTER)
        {
            var bi = BROWSEINFO.create();
            bi.lpszTitle = "Select your V-Slice mods folder";
            bi.ulFlags = BIF_RETURNONLYFSDIRS | BIF_NEWDIALOGSTYLE;
            var pidl = SHBrowseForFolder(RawPointer.addressOf(bi));
            if (pidl != null) {
                var charArray:Array<Char> = NativeArray.create(255);
                SHGetPathFromIDList(pidl, NativeArray.address(charArray, 0).raw);
                var path = "";
                for (c in charArray) {
                    if (c == 0) {
                        break;
                    }
                    path += String.fromCharCode(c);
                }
                maintxt.visible = false;
                trace("selected path: " + path);

                checkSubfoldersForMeta(path);

            } else {
                trace("cancelled");
            }
        }
        super.update(elapsed);
    }

    function checkSubfoldersForMeta(directory:String)
    {
        try {
            for (file in sys.FileSystem.readDirectory(directory)) {
                var filePath = haxe.io.Path.join([directory, file]);
                if (sys.FileSystem.isDirectory(filePath)) {
                    var metaFilePath = haxe.io.Path.join([filePath, "_polymod_meta.json"]);
                    if (sys.FileSystem.exists(metaFilePath)) {
                        trace("Found _polymod_meta.json in: " + filePath);
                        // Process the file as needed
                    }
                    // Recursively check subdirectories
                    checkSubfoldersForMeta(filePath);
                }
            }
        } catch (e:Dynamic) {
            trace("Error reading directory: " + e);
        }
    }
}
