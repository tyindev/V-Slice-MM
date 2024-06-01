package vslice;

import flixel.FlxState;
import flixel.text.FlxText;
import flixel.FlxG;
import flixel.ui.FlxButton;
import flixel.group.FlxGroup;
import flixel.util.FlxColor;
import flixel.FlxSprite;
import sys.FileSystem;
import sys.io.File;
import haxe.Json;
import flixel.FlxObject;

class PlayState extends FlxState
{
    var maintxt:FlxText;
    var bg:FlxSprite;
    var descriptionText:FlxText;
    var buttonGroup:FlxGroup;
    var modActivated:Bool = false;
    var activationButton:FlxButton;
    var currentModName:String;
    var currentModPath:String;
    var savePath:String = "mod_folder_path.txt";
    var scrollContainer:FlxGroup;
    var scrollSpeed:Int = 5;
    var icon:FlxSprite;
    var launchButton:FlxButton;

    override public function create()
    {
        FlxG.sound.playMusic(Paths.music('gay'));
        bg = new FlxSprite(-80).loadGraphic(Paths.image('menuDesat'));
        bg.scrollFactor.x = 0;
        bg.scrollFactor.y = 0.18;
        bg.setGraphicSize(Std.int(bg.width * 1.1));
        bg.updateHitbox();
        bg.screenCenter();
        bg.antialiasing = true;
        add(bg);

        maintxt = new FlxText(0, 0, FlxG.width, "Press enter to select your FNF V-Slice Mods Folder!", 32);
        maintxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.BLACK);
        maintxt.screenCenter(Y);
        add(maintxt);

        descriptionText = new FlxText(FlxG.width / 2, 0, FlxG.width / 2, "", 24);
        descriptionText.scrollFactor.x = 0;
        descriptionText.scrollFactor.y = 0.18;
        descriptionText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.BLACK);
        add(descriptionText);

        scrollContainer = new FlxGroup();
        add(scrollContainer);

        super.create();

        createActivationButton();
        createLaunchButton();
        loadModFolderPath();
    }

    function createLaunchButton()
    {
        launchButton = new FlxButton(FlxG.width - buttonWidth - 10, FlxG.height - 110, "Launch Funkin'", launchFunkin);
        launchButton.setGraphicSize(200, 40);
        launchButton.updateHitbox();
        add(launchButton);
    }

    function launchFunkin()
    {
        var modFolderPath = "";
        try {
            if (FileSystem.exists(savePath)) {
                modFolderPath = File.getContent(savePath);
            } else {
                trace("No saved mod folder path found.");
                return;
            }
        } catch (e:Dynamic) {
            trace("Failed to load mod folder path: " + e);
            return;
        }

        trace("Mod folder path: " + modFolderPath);

        var lastSlashIndex = modFolderPath.lastIndexOf("/");
        if (lastSlashIndex == -1) {
            lastSlashIndex = modFolderPath.lastIndexOf("\\");
            if (lastSlashIndex == -1) {
                trace("Invalid mod folder path: " + modFolderPath);
                return;
            }
        }
        var parentDirectory = modFolderPath.substring(0, lastSlashIndex);
        var executablePath = parentDirectory + "/Funkin.exe";
        trace("Launching Funkin.exe from path: " + executablePath);

        try {
            Sys.command(executablePath);
        } catch (e:Dynamic) {
            trace("Failed to launch Funkin.exe: " + e);
        }
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

                currentModName = null;
                currentModPath = null;

                saveModFolderPath(path);
                checkSubfoldersForMeta(path);

            } else {
                trace("cancelled");
            }
        }

        if (FlxG.keys.pressed.UP)
        {
            for (modButton in scrollContainer.members)
            {
                (cast modButton:FlxObject).y += scrollSpeed;
            }
        }
        if (FlxG.keys.pressed.DOWN)
        {
            for (modButton in scrollContainer.members)
            {
                (cast modButton:FlxObject).y -= scrollSpeed;
            }
        }

        super.update(elapsed);
    }

    function createActivationButton()
    {
        activationButton = new FlxButton(FlxG.width - buttonWidth - 10, FlxG.height - 60, "Activate/Deactivate Mod", toggleModActivation);
        activationButton.setGraphicSize(200, 40);
        activationButton.updateHitbox();
        add(activationButton);
    }

    function toggleModActivation()
    {
        modActivated = !modActivated;
        activationButton.color = modActivated ? 0xFF00FF00 : 0xFFFF0000;
        if (currentModPath != null) 
        {
            if (modActivated) {
                if (currentModName != null) trace("Enabling mod: " + currentModName);
                renameMetaFile(currentModPath + "/_polymod_meta_disabled.json", currentModPath + "/_polymod_meta.json");
            } else {
                if (currentModName != null) trace("Disabling mod: " + currentModName);
                renameMetaFile(currentModPath + "/_polymod_meta.json", currentModPath + "/_polymod_meta_disabled.json");
            }
            updateDescriptionText(modActivated);
        } else {
            trace("No mod selected.");
        }
    }

    function updateDescriptionText(modActivated:Bool)
    {
        var activationStatus = modActivated ? "Yes" : "No";
        var description = descriptionText.text;
        var existingDescription = description.substring(0, description.lastIndexOf("Mod Activated:") + "Mod Activated:".length);
        descriptionText.text = existingDescription + " " + activationStatus;
    }

    function renameMetaFile(currentPath:String, newPath:String)
    {
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
                    var metaFilePathEnabled = filePath + "/_polymod_meta.json";
                    var metaFilePathDisabled = filePath + "/_polymod_meta_disabled.json";
                    if (sys.FileSystem.exists(metaFilePathEnabled)) {
                        trace("Found _polymod_meta.json in: " + filePath);
                        var metaContent = sys.io.File.getContent(metaFilePathEnabled);
                        var metaData = Json.parse(metaContent);
                        createModButton(metaData.title, metaData.author, metaData.description, metaData.mod_version, false, filePath);
                    } else if (sys.FileSystem.exists(metaFilePathDisabled)) {
                        trace("Found _polymod_meta_disabled.json in: " + filePath);
                        var metaContent = sys.io.File.getContent(metaFilePathDisabled);
                        var metaData = Json.parse(metaContent);
                        createModButton(metaData.title, metaData.author, metaData.description, metaData.mod_version, false, filePath);
                    }
                }
            }
        } catch (e:Dynamic) {
            trace("Error reading directory: " + e);
        }
    }

    function loadModIcon(path:String):FlxSprite
    {
        var iconPath:String = path + "/_polymod_icon.png";
        trace("Checking for mod icon at path: " + iconPath);

        if (!sys.FileSystem.exists(iconPath)) {
            iconPath = "assets/images/default_icon.png";
            trace("Mod icon not found. Loading default icon at path: " + iconPath);
        } else {
            trace("Mod icon found at path: " + iconPath);
        }

        var icon:FlxSprite = new FlxSprite(0, 0).loadGraphic(iconPath);
        icon.setGraphicSize(128, 128);
        icon.updateHitbox();
        return icon;
    }

    var buttonWidth:Int = 200;
    var buttonHeight:Int = 40;
    var verticalSpacing:Int = 10;

    function createModButton(title:String, author:String, description:String, version:String, disabled:Bool = false, path:String)
    {
        var buttonText = disabled ? title + " (Disabled)" : title;
        var button:FlxButton = new FlxButton(10, (scrollContainer.length * (buttonHeight + verticalSpacing)), buttonText, function() {
            descriptionText.text = "Title: " + title + "\n" + "Author: " + author + "\n" + "Version: " + version + "\n\n" + description + "\n\nMod Activated: " + (disabled ? "No" : "Yes");
            currentModName = title;
            currentModPath = path;

            if (icon != null) {
                remove(icon);
            }

            icon = loadModIcon(path);
            icon.x = descriptionText.x;
            icon.y = descriptionText.y + descriptionText.height + 10;
            icon.visible = true;
            add(icon);
            trace("Icon position: (" + icon.x + ", " + icon.y + ")");
        });

        var buttonLabel:FlxText = new FlxText(0, 0, buttonText);
        buttonLabel.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.BLACK);
        button.label = buttonLabel;

        button.setGraphicSize(buttonWidth, buttonHeight);
        button.updateHitbox();
        scrollContainer.add(button);
    }


    function saveModFolderPath(path:String)
    {
        try {
            File.saveContent(savePath, path);
            trace("Saved mod folder path: " + path);
        } catch (e:Dynamic) {
            trace("Failed to save mod folder path: " + e);
        }
    }

    function loadModFolderPath()
    {
        try {
            if (FileSystem.exists(savePath)) {
                var path = File.getContent(savePath);
                trace("Loaded mod folder path: " + path);
                maintxt.visible = false;
                checkSubfoldersForMeta(path);
            } else {
                trace("No saved mod folder path found.");
            }
        } catch (e:Dynamic) {
            trace("Failed to load mod folder path: " + e);
        }
    }
}
