unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ComCtrls,
  IdHashMessageDigest,IdGlobal,IdHash,
  uPavkooHashString,IniFiles,uConst;



type
  
  TForm1 = class(TForm)
    btn1: TButton;
    lbltIP: TLabel;
    btn2: TButton;
    btn3: TButton;
    btn4: TButton;
    btn5: TButton;
    Button1: TButton;
    btn6: TButton;
    btn7: TButton;
    btn8: TButton;
    btn10: TButton;
    btn11: TButton;
    procedure btn1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btn2Click(Sender: TObject);
    procedure btn3Click(Sender: TObject);
    procedure btn4Click(Sender: TObject);
    procedure btn5Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure btn7Click(Sender: TObject);
    procedure btn6Click(Sender: TObject);
    procedure btn8Click(Sender: TObject);
    procedure FormDestroy(Sender: TObject);

  private
    { Private declarations }
    FPathStr :string;
    FNewPathStr:String;
    fileSizeLow:Cardinal;
    fileSizeHigh:Cardinal;
    ms:TMemoryStatus;
    FileMapedPos: Cardinal;
    FSizeToMap: Cardinal;
    startTime,endtime:integer;
    FindstartTime,Findendtime:integer;
    MapFinished:Boolean;
    hash:TPStringHash;
    lastStrLeft:string;
    FStop:Boolean;
    LineNumber:Integer;
    procedure OpenFileMap;
    procedure CloseFileMap;
    function getMapOnetimeRecord:Integer;
//    function md5(const orl:String):String;
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  hFile,hFileMapping:THandle;
  pfile:Pointer;
  FReapeatCount:Cardinal = 0;
  
implementation

{$R *.dfm}


procedure TForm1.btn1Click(Sender: TObject);
var
  TF:TextFile;
  lineString:string;
  i,j:integer;
begin
  startTime:= GetTickCount;
  AssignFile(Tf,FPathStr);
  ReWrite(Tf);
  Randomize;
  SetLength(lineString,WORDSLENTGH-2 );
  for i := 1 to RECORDCOUNT do
  begin
    for j := 1 to WORDSLENTGH-2  do
    begin
      lineString[j] :=  Char(65 +Random(2));
    end;
    WriteLn(Tf,lineString);
//    Self.Canvas.TextOut(Self.ClientWidth div 2,Self.ClientHeight div 2,inttostr(I));
  end;
  CloseFile(Tf);
  endtime:= GetTickCount;
  lbltIP.Caption := 'Time uesed : ' +floattostr((endtime-startTime)/1000)+ ' S';
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  FPathStr :=ExtractFilePath(Application.ExeName)+BIGTEXTFILENAME;
  FNewPathStr := ExtractFilePath(Application.ExeName)+NEWBIGTEXTFILENAME;
  if fileExists(FPathStr) then
  begin
//    btn1.enabled:=False;
    btn1.Caption :=btn1.Caption + '     【文件已经存在】';
  end;  
  FileMapedPos:=0;
  FSizeToMap := MAPFILESIZE;
  MapFinished:=False;
  hash:=TPStringHash.Create(RECORDCOUNT);
end;

procedure TForm1.OpenFileMap;
var
  error:String;
begin
  hFile := CreateFile(PAnsiChar(FPathStr),GENERIC_READ or GENERIC_WRITE,FILE_SHARE_READ	or FILE_SHARE_WRITE	,nil,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,0);
  error:=sysutils.SysErrorMessage(getlasterror);

  fileSizeLow:=GetFileSize(hFile,@fileSizeHigh);
  error:=sysutils.SysErrorMessage(getlasterror);
//  hFileMapping := CreateFileMapping(hFile,nil,PAGE_READWRITE,0,0,MAPFILE);
  error:=sysutils.SysErrorMessage(getlasterror);
end;

procedure TForm1.CloseFileMap;
begin
  UnmapViewOfFile(pfile);
  CloseHandle(hFileMapping);
  CloseHandle(hFile);
end;

procedure TForm1.btn2Click(Sender: TObject);
var
  str:String;
begin
  SetString(str,Pchar(pfile),WORDSLENTGH);
  lbltIP.Caption := str;
end;

procedure TForm1.btn3Click(Sender: TObject);
begin
  OpenFileMap;
end;

procedure TForm1.btn4Click(Sender: TObject);
begin
  ms.dwLength := sizeof(ms);
  GlobalMemoryStatus(ms);
  lbltip.Caption := '可用虚拟内存空间：'+inttostr(ms.dwAvailVirtual div 1024 div 1024) + 'MB';
end;

procedure TForm1.btn5Click(Sender: TObject);
var
  errorinfo:String;
begin
  hFile := CreateFile('C:\MMTEXT.DAT',GENERIC_READ or GENERIC_WRITE,FILE_SHARE_READ or FILE_SHARE_WRITE	,nil,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL,0);
  hFileMapping := CreateFileMapping(hFile,nil,PAGE_READWRITE,0,200*1024,nil);
  pfile := MapViewOfFile(hFileMapping,FILE_MAP_ALL_ACCESS,0,0,200*1024);
  UnmapViewOfFile(pfile);
  closeHandle(hFileMapping);
  SetFilePointer(hFile,190*1024,nil,FILE_BEGIN);  //文件剪短
  errorinfo := SysErrorMessage(GetLastError);
  SetEndOfFile(hFile);
  errorinfo := SysErrorMessage(GetLastError);  
  closeHandle(hFile);
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  CloseFileMap;
end;


procedure TForm1.btn7Click(Sender: TObject);
var
  str:String;
  i,recordCount:integer;
  charMaped : Cardinal;
begin
  btn7.Enabled := False;
  btn3.Click;
  lastStrLeft:='';
  startTime:= GetTickCount;
  FindstartTime:= GetTickCount;
  LineNumber:=0;
  while ((not MapFinished) and (not FStop)) do
  begin
    btn8.Click;
    charMaped:=0;
    recordCount := getMapOnetimeRecord;
    //承接头一块的末尾数据
    if Length(lastStrLeft)<>0 then
    begin
      SetString(str,Pchar(pfile),WORDSLENTGH-Length(lastStrLeft)-2);
      charMaped:= charMaped+ Cardinal(Length(str)+2);
      pfile := Pointer(Integer(pfile)+Length(str) + 2);
      str:= str + lastStrLeft ;
      lastStrLeft :='';
      Inc(LineNumber);
//      hash.Add(str,LineNumber);
    end;
    for i := 0 to recordCount-1 do
    begin
      SetString(str,Pchar(pfile),WORDSLENTGH-2);
      Inc(LineNumber);
//      hash.Add(str,LineNumber);
      pfile := Pointer(Integer(pfile)+WORDSLENTGH);
      charMaped:= charMaped+ WORDSLENTGH;
    end;
    //最后一条数据可能不够长，因为文件被分块了
    SetString(lastStrLeft,Pchar(pfile),FSizeToMap-charMaped);
  end;
  btn10.Click;
  endtime:= GetTickCount;
  lbltIP.Caption := lbltIP.Caption+#13+#10+'Time uesed : ' +floattostr((endtime-startTime))+ ' Ms';
  hash.Free;
  btn7.Enabled := True;
  Button1.Click;
end;

procedure TForm1.btn6Click(Sender: TObject);
begin
  // T_T 怎么删除一行啊。。。。。。。。。。。。
end;


procedure TForm1.btn8Click(Sender: TObject);
var
  error:String;
begin
  UnmapViewOfFile(pfile);
  if FileMapedPos + MAPFILESIZE > fileSizeLow then
  begin
    FSizeToMap := fileSizeLow - FileMapedPos;
    MapFinished:=True;
  end;
  pfile := MapViewOfFile(hFileMapping,FILE_MAP_ALL_ACCESS,0,FileMapedPos,FSizeToMap);
  error:=sysutils.SysErrorMessage(getlasterror);
  if MapFinished then btn8.Enabled := False;
  FileMapedPos := FileMapedPos +FSizeToMap;
  Findendtime := GetTickCount;
  lbltIP.Caption := '已经查找了 '+inttostr(FileMapedPos div 1024 div 1024) +' MB,其中重复记录条数为：'+inttostr(FReapeatCount)+#13+#10+
                    '耗时：' +IntToStr((Findendtime-FindStartTime)) +'Ms';
  Application.ProcessMessages;
end;

function TForm1.getMapOnetimeRecord: Integer;
begin 
  if Length(lastStrLeft)>0 then
  begin
    Result := (FSizeToMap-WORDSLENTGH+Cardinal(length(lastStrLeft))) div WORDSLENTGH;
  end
  else
  begin
    Result := FSizeToMap div WORDSLENTGH;
  end;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  hash.Free;
end;





end.
