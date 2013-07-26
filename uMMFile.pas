unit uMMFile;

interface
   uses
     Windows,SysUtils,uConst,Forms;

   type
     TMMFileOPenMode=(TMMRead,TMMWrite);
     
     TMMFile=class(TObject)
     private
       FhFile:THandle;
       FhFileMapping:THandle;
       FLock: TRTLCriticalSection;
       FPBaseFile:Pointer;
       FPath:String;
       FOpenType:TMMFileOPenMode;
       FFileMaped:Cardinal;
       FSizeToMap:Cardinal;
       FCharRead:Cardinal;
       FCharWrite:Cardinal;
       FCharReadPerMap:Cardinal;
       FCharWritePerMap:Cardinal;
       FFileSize:Cardinal; //文件大小
       errorinfo:string;
       function GetEOF:Boolean;
       procedure MapFile;
       procedure SetFileSize(const Value:Cardinal);
       procedure ShowAvaliable;
     public
       FPFile:Pointer;
       ReadedLineNumber:Cardinal; //记录当前映像文件所读取过的记录行数
       constructor Create(const filePath: String;OpenFileType:TMMFileOPenMode; mapfileName:string);
       function ReadLine:String;
       procedure WriteLine(const Value:String);
       procedure CutOffFile(NewFileSize:Cardinal);
       destructor Destroy;override;
       procedure ReSetPosition;
       property Eof:Boolean read GetEOF;
       property FileSize:Cardinal read FFileSize write SetFileSize;
     end;

implementation

{ TMMFile }

constructor TMMFile.Create(const filePath: String;OpenFileType:TMMFileOPenMode; mapfileName:string);
var
  CreationDistribution:Cardinal;
begin
  InitializeCriticalSection(FLock);
  FPath:=filePath;
  FPBaseFile := nil;
  FOpenType:= OpenFileType;
  if FOpenType=TMMRead then
  begin
    if not FileExists(filePath) then
      raise Exception.Create('文件不存在，不能打开！');
    CreationDistribution:=OPEN_EXISTING;
  end
  else
  begin
    if FileExists(filePath) then DeleteFile(FPath);
    CreationDistribution:=CREATE_NEW;
  end;
  FhFile := CreateFile(PAnsiChar(FPath),GENERIC_READ or GENERIC_WRITE,FILE_SHARE_READ	or FILE_SHARE_WRITE	,nil,CreationDistribution,FILE_ATTRIBUTE_NORMAL,0);
  errorinfo := SysErrorMessage(getlasterror);
  if FOpenType=TMMRead then
  begin
    FFileSize:=GetFileSize(FhFile,nil);
    FhFileMapping := CreateFileMapping(FhFile,nil,PAGE_READWRITE,0,0,PAnsiChar(mapfileName));
    errorinfo := SysErrorMessage(getlasterror);
    FPFile:=nil;
    MapFile;
    ReadedLineNumber:=0;
  end;
end;


procedure TMMFile.CutOffFile(NewFileSize: Cardinal);
var
  lowInt:LongInt;
  highInt:Longint;
  tempInt:Int64;
begin
  lowInt:=0;
  highInt:=0;
  tempInt:= NewFileSize;
  if FOpenType=TMMRead then Exit;
  if not UnmapViewOfFile(FPBaseFile) then
    Application.MessageBox(PAnsiChar(SysErrorMessage(getlasterror)),PAnsiChar('错误'));
  if not CloseHandle(FhFileMapping) then
    Application.MessageBox(PAnsiChar(SysErrorMessage(getlasterror)),PAnsiChar('错误'));
  if NewFileSize>Cardinal(MaxInt) then
  begin
    lowInt:= tempInt and $00000000ffffffff;
    highInt:= tempInt and $ffffffff00000000;
  end
  else
  begin
    lowInt:=Integer(NewFileSize);
  end;
  if SetFilePointer(FhFile,lowInt,@highInt,File_Begin)=$FFFFFFFF then
    Application.MessageBox(PAnsiChar(SysErrorMessage(getlasterror)),PAnsiChar('错误'));
  if not SetEndOfFile(FhFile) then
    Application.MessageBox(PAnsiChar(SysErrorMessage(getlasterror)),PAnsiChar('错误'));
end;

destructor TMMFile.Destroy;
begin
  UnmapViewOfFile(FPBaseFile);
  CloseHandle(FhFileMapping);
  CloseHandle(FhFile);
  DeleteCriticalSection(FLock);
  inherited;
end;

function TMMFile.GetEOF: Boolean;
begin
  if FOpenType=TMMRead then
    Result:=(FCharRead=FFileSize)
  else
    Result:=False;
end;

procedure TMMFile.MapFile;
begin
  if FOpenType = TMMWrite then FlushViewOfFile(FPBaseFile,FSizeToMap);
  if FPBaseFile <> nil then
  begin
    if not UnmapViewOfFile(FPBaseFile) then
      Application.MessageBox(PAnsiChar(SysErrorMessage(getlasterror)),PAnsiChar('错误'));
    FPBaseFile := nil;
  end;
  if (FFileMaped+MAPFILESIZE>FFileSize) then
    FSizeToMap := FFileSize-FFileMaped
  else
    FSizeToMap:=MAPFILESIZE;
  FPFile:= MapViewOfFile(FhFileMapping,FILE_MAP_ALL_ACCESS,0,FFileMaped,FSizeToMap);
  FPBaseFile := FPFile;
  if FPFile=nil then
  begin
    Application.MessageBox(PAnsiChar(SysErrorMessage(getlasterror)),PAnsiChar('错误'));
    ShowAvaliable;
  end;
  FFileMaped:=FSizeToMap+FFileMaped;
  FCharReadPerMap:=0;  //一次映射后，读取的字符个数
  FCharWritePerMap:=0;
end;

function TMMFile.ReadLine: String;
var
  LastString,tempString:String;
begin
  //如果一次映射完了，就再映射
  if FCharReadPerMap=FSizeToMap then
  begin
    MapFile;
  end;
  //块末尾不能读取一个字符串的时候，需要拼接
  if FCharReadPerMap+WORDSLENTGH>FSizeToMap then
  begin
    SetString(LastString,Pchar(Fpfile),FSizeToMap-FCharReadPerMap);
    FCharRead:=FCharRead+Cardinal(Length(LastString));
    MapFile;                                                                                                                         
    SetString(tempString,Pchar(Fpfile),WORDSLENTGH-Length(LastString));
    FCharRead:= FCharRead+ Cardinal(Length(tempString));
    FCharReadPerMap :=  FCharReadPerMap+Cardinal(Length(tempString));
    FPFile := Pointer(Cardinal(FPFile)+Cardinal(Length(tempString)));
    tempString:= LastString+tempString;
    Result := tempString;
    Inc(ReadedLineNumber);
    Exit;
  end;
  SetString(tempString,Pchar(FPFile),WORDSLENTGH);
  FPFile := Pointer(Cardinal(FPFile)+WORDSLENTGH);
  FCharRead := FCharRead+WORDSLENTGH;
  FCharReadPerMap:=FCharReadPerMap+WORDSLENTGH;
  Result:= tempString;
  Inc(ReadedLineNumber);
end;

procedure TMMFile.ReSetPosition;
begin
  if FOpenType=TMMWrite then
    Exception.Create('TMMWrite时，暂时不支持ReSetPosition');
  FFileMaped:=0;
  FCharRead:=0;
  FCharReadPerMap:=0;
  ReadedLineNumber:=0;
  MapFile;
end;

procedure TMMFile.SetFileSize(const Value: Cardinal);
var
  errorinfo:string;
begin
  if  (FFileSize=0) and (FOpenType=TMMWrite) then
  begin
    FFileSize:=Value;
    FhFileMapping := CreateFileMapping(FhFile,nil,PAGE_READWRITE,0,FFileSize,nil);//PAnsiChar(mapfileName)
    errorinfo := SysErrorMessage(getlasterror);
    FPFile:=nil;
    MapFile;
  end;
end;

procedure TMMFile.ShowAvaliable;
var
  ms:TMemoryStatus;
begin
  ms.dwLength := sizeof(ms);
  GlobalMemoryStatus(ms);
  Application.MessageBox(PAnsiChar('可用虚拟内存空间：'+inttostr(ms.dwAvailVirtual div 1024 div 1024) + 'MB'),'');
end;


procedure TMMFile.WriteLine(const Value: String);
var
  LastString,tempString:String;
  space:Cardinal;
begin

  if FCharWritePerMap=FSizeToMap then
  begin
    MapFile;
  end;
  if FCharWritePerMap+Cardinal(Length(Value))>FSizeToMap then
  begin
    space :=FSizeToMap-FCharWritePerMap;//剩下的可以写的字符个数
    tempString:=Copy(Value,1,space);
    LastString := Copy(Value,space+1,Length(Value)-Integer(space));
    CopyMemory(Pointer(FPFile),PAnsiChar(tempString),Length(tempString));
    FPFile:=Pointer(Cardinal(FPFile)+space);
    FCharWrite:=FCharWrite+Cardinal(space);
    MapFile;
    CopyMemory(Pointer(FPFile),PAnsiChar(LastString),Length(LastString));
    FPFile:=Pointer(Cardinal(FPFile)+Cardinal(length(LastString)));
    FCharWrite:=FCharWrite+Cardinal(length(LastString));
    FCharWritePerMap:=FCharWritePerMap+Cardinal(length(LastString));
    Exit;
  end;
  CopyMemory(PChar(FPFile),PAnsiChar(Value),Length(Value));
  FPFile:=Pointer(Cardinal(FPFile)+Cardinal(length(Value)));
  FCharWrite:=FCharWrite+Cardinal(length(Value));
  FCharWritePerMap:=FCharWritePerMap+Cardinal(length(Value));
end;

end.
