package vslice;

import flixel.FlxState;
import flixel.text.FlxText;
import flixel.FlxG;
import flixel.ui.FlxButton;
import flixel.addons.ui.FlxUIGroup;
import flixel.util.FlxColor;
import flixel.FlxSprite;
import sys.FileSystem;
import haxe.Json;

class PlayState extends FlxState
{
    var maintxt:FlxText;
    var bg:FlxSprite;
    var descriptionText:FlxText;
    var buttonGroup:FlxUIGroup;
    var modActivated:Bool = false;
    var activationButton:FlxButton; 
    var currentModName:String;

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

        descriptionText = new FlxText(FlxG.width / 2, 0, FlxG.width / 2, "", 24);
        descriptionText.setFormat("VCR OSD Mono", 24, FlxColor.BLACK, LEFT);
        descriptionText.scrollFactor.x = 0;
        descriptionText.scrollFactor.y = 0.18;
        add(descriptionText);

        buttonGroup = new FlxUIGroup();
        add(buttonGroup);

        super.create();

        createActivationButton();
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

    function createActivationButton()
    {
        activationButton = new FlxButton(FlxG.width - buttonWidth - 10, FlxG.height - 60, "Activate/Deactivate Mod", toggleModActivation);
        activationButton.setGraphicSize(200, 40);
        activationButton.updateHitbox();
        buttonGroup.add(activationButton);
    }

    function toggleModActivation()
    {
        modActivated = !modActivated;
        activationButton.color = modActivated ? 0xFF00FF00 : 0xFFFF0000;
        if (modActivated) {
            if (currentModName != null) trace("Enabling mod: " + currentModName);
            renameMetaFile("_polymod_meta.json", "_polymod_meta_disabled.json");
        } else {
            if (currentModName != null) trace("Disabling mod: " + currentModName);
            renameMetaFile("_polymod_meta_disabled.json", "_polymod_meta.json");
        }
    }

    function renameMetaFile(currentName:String, newName:String)
    {
        var currentPath = sys.FileSystem.fullPath(currentName);
        var newPath = sys.FileSystem.fullPath(newName);
        if (sys.FileSystem.exists(currentPath)) {
            sys.FileSystem.rename(currentPath, newPath);
        }
    }

    function checkSubfoldersForMeta(directory:String)
    {
        try {
            for (file in sys.FileSystem.readDirectory(directory)) {
                var filePath = directory + '/' + file;
                if (sys.FileSystem.isDirectory(filePath)) {
                    var metaFilePath = filePath + "/_polymod_meta.json";
                    if (sys.FileSystem.exists(metaFilePath)) {
                        trace("Found _polymod_meta.json in: " + filePath);
                        var metaContent = sys.io.File.getContent(metaFilePath);
                        var metaData = Json.parse(metaContent);
                        currentModName = metaData.title;
                        createModButton(metaData.title, metaData.author, metaData.description, metaData.mod_version);
                    }
                    checkSubfoldersForMeta(filePath);
                }
            }
        } catch (e:Dynamic) {
            trace("Error reading directory: " + e);
        }
    }

    var buttonWidth:Int = 200;
    var buttonHeight:Int = 40;
    var verticalSpacing:Int = 10;

    function createModButton(title:String, author:String, description:String, version:String)
    {
        var button:FlxButton = new FlxButton(10, (buttonGroup.members.length * (buttonHeight + verticalSpacing)), title + " by " + author, function() {
            descriptionText.text = "Title: " + title + "\n" + "Author: " + author + "\n" + "Version: " + version + "\n\n" + description;
        });
        button.label.alignment = "center";
        button.setGraphicSize(buttonWidth, buttonHeight);
        button.updateHitbox();
        buttonGroup.add(button);
    }
}
