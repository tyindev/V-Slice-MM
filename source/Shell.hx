package;
import cpp.Char;
import cpp.ConstCharStar;
import cpp.RawPointer;

@:include("shlobj.h")
@:native("BROWSEINFO")
@:structAccess
@:unreflective
extern class BROWSEINFO {
    public var lpszTitle:ConstCharStar;
    public var ulFlags:Int;
    
    public static inline function create():BROWSEINFO {
        return untyped __cpp__("{ 0 }");
    }
}

@:include("shlobj.h")
@:structAccess
@:unreflective
extern class BROWSEINFO_FLAGS {
    @:native("BIF_RETURNONLYFSDIRS") public static var BIF_RETURNONLYFSDIRS:Int;
    @:native("BIF_NEWDIALOGSTYLE") public static var BIF_NEWDIALOGSTYLE:Int;
}

@:include("shlobj.h")
@:structAccess
@:unreflective
extern class LPITEMIDLIST {
}


@:include("shlobj.h")
@:structAccess
@:unreflective
@:buildXml('
<target id="haxe" tool="linker" toolid="exe">
    <lib name="Shell32.lib" />
</target>
')
extern class ShellObject {
    @:native("SHBrowseForFolder") public static function SHBrowseForFolder(lpbi:RawPointer<BROWSEINFO>):LPITEMIDLIST;
    @:native("SHGetPathFromIDList") public static function SHGetPathFromIDList(pidl:LPITEMIDLIST, pszPath:RawPointer<Char>):Bool;
}