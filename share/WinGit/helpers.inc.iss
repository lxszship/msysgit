[Code]

// Copies a NULL-terminated array of characters to a string.
function ArrayToString(Chars:array of Char):String;
var
    Len,i:Longint;
begin
    Len:=GetArrayLength(Chars);
    SetLength(Result,Len);

    i:=0;
    while (i<Len) and (Chars[i]<>#0) do begin
        Result[i+1]:=Chars[i];
        Inc(i);
    end;

    SetLength(Result,i);
end;

// Copies a string to a NULL-terminated array of characters.
function StringToArray(Str:String):array of Char;
var
    Len,i:Longint;
begin
    Len:=Length(Str);
    SetArrayLength(Result,Len+1);

    i:=0;
    while i<Len do begin
        Result[i]:=Str[i+1];
        Inc(i);
    end;

    Result[i]:=#0;
end;

// Returns the path to the common or user shell folder as specified in "Param".
function GetShellFolder(Param:string):string;
begin
    if IsAdminLoggedOn then begin
        Param:='{common'+Param+'}';
    end else begin
        Param:='{user'+Param+'}';
    end;
    Result:=ExpandConstant(Param);
end;

// As IsComponentSelected() is not supported during uninstall, this work-around
// simply checks the Registry. This is unreliable if the user runs the installer
// twice, the first time selecting the component, the second deselecting it.
function IsComponentInstalled(Component:String):Boolean;
var
    UninstallKey,UninstallValue:String;
    Value:String;
begin
    Result:=False;

    UninstallKey:='SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{#APP_NAME}_is1';
    UninstallValue:='Inno Setup: Selected Components';

    if RegQueryStringValue(HKEY_LOCAL_MACHINE,UninstallKey,UninstallValue,Value) then begin
        Result:=(Pos(Component,Value)>0);
    end;
end;

// Checks whether the specified directory can be created and written to
// by creating all intermediate directories and a temporary file.
function IsDirWritable(DirName:String):Boolean;
var
    AbsoluteDir,FirstExistingDir,FirstCreatedDir,FileName:String;
begin
    Result:=True;

    AbsoluteDir:=ExpandFileName(DirName);

    FirstExistingDir:=AbsoluteDir;
    while not DirExists(FirstExistingDir) do begin
        FirstCreatedDir:=FirstExistingDir;
        FirstExistingDir:=ExtractFileDir(FirstExistingDir);
    end;
    Log('Line {#__LINE__}: First directory in hierarchy that already exists is "' + FirstExistingDir + '".')

    if Length(FirstCreatedDir)>0 then begin
        Log('Line {#__LINE__}: First directory in hierarchy needs to be created is "' + FirstCreatedDir + '".')

        if ForceDirectories(DirName) then begin
            FileName:=GenerateUniqueName(DirName,'.txt');
            Log('Line {#__LINE__}: Trying to write to temporary file "' + Filename + '".')

            if SaveStringToFile(FileName,'This file is writable.',False) then begin
                if not DeleteFile(FileName) then begin
                    Result:=False;
                end;
            end else begin
                Result:=False;
            end;
        end else begin
            Result:=False;
        end;

        if not DelTree(FirstCreatedDir,True,False,True) then begin
            Result:=False;
        end;
    end;
end;
