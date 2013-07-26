unit uMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls,
  uMMFile,uConst,uPavkooHashString,uPavkooStringList;

type


  TPReadthread=class(TThread)
    protected
      procedure Execute; override;
  end;

  TPWriteThread=class(TThread)
    protected
      procedure Execute; override;
  end;


  TfrmMain = class(TForm)
    btnExecute: TButton;
    mmoInfo: TMemo;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnExecuteClick(Sender: TObject);
  private
    threadRead:TPReadthread;
    threadWrite:TPWriteThread;
  public
    { Public declarations }
    StartTime:Int64;
    EndTime:Int64;
  end;



var
  frmMain: TfrmMain;
  FOrignMMFile:TMMFile;
  FResultMMFile:TMMFile;  //删除以回写的方式来实现，暂时想不到其他好的方法
  FResultHash:TPStringHash;
  hEvent:THandle;
  tempList:TThreadStringList;


implementation



{$R *.dfm}

procedure TPReadthread.Execute;
var
  temp:String;
begin
  frmMain.StartTime := GetTickCount;
  try
    while not FOrignMMFile.Eof do
    begin
      temp := FOrignMMFile.ReadLine;
      if FResultHash.Add(temp) then
      begin
        tempList.Add(temp);
        SetEvent(hEvent);
      end;
    end;
  except
    on e:Exception do Application.MessageBox(PAnsiChar(e.Message),'异常');
  end;
end;


function GetTimeStamp:Int64;
asm
  RDTSC;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  FResultHash:= TPStringHash.Create(RECORDCOUNT);
  FOrignMMFile:=TMMFile.Create(BIGTEXTFILENAME,TMMRead,BIGMAPFILENAME);
  FResultMMFile:=TMMFile.Create(NEWBIGTEXTFILENAME,TMMWrite,RESULTMAPFILENAME);
  hEvent := CreateEvent(nil,True,False,EVENTFORWRITE);
  tempList:=TThreadStringList.Create;
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  FOrignMMFile.Free;
  FResultMMFile.Free;
  tempList.Free;
end;

procedure TfrmMain.btnExecuteClick(Sender: TObject);
begin
  FResultMMFile.FileSize:=FOrignMMFile.FileSize;
  frmMain.StartTime:=GetTickCount;
  threadRead := TPReadthread.Create(True);
  threadRead.Priority:=tpHighest;
  threadWrite := TPWriteThread.Create(True);
  threadWrite.Priority:=tpHighest;
  threadWrite.Resume;
  threadRead.Resume;
end;

{ TPWriteThread }

procedure TPWriteThread.Execute;
var
  temp:String;
begin
  while not FOrignMMFile.Eof do
  begin
    if WaitForSingleObject(hEvent,INFINITE)=WAIT_OBJECT_0	then
    begin
      if tempList.GetCount>0 then
      begin
        temp:=tempList.GetItem(0);
        FResultMMFile.WriteLine(temp);
        tempList.Remove(temp);
      end;
    end;
  end;
  frmMain.EndTime := GetTickCount;
  FResultMMFile.CutOffFile((FOrignMMFile.ReadedLineNumber - Cardinal(FResultHash.DuplicateList.Count))*WORDSLENTGH);
  with frmMain do
  begin
    mmoInfo.Lines.Add('总用时：'+FloatToStr((EndTime-StartTime) div 1000)+'秒');
    mmoInfo.Lines.Add('总记录数：'+IntToStr(FOrignMMFile.ReadedLineNumber));
    mmoInfo.Lines.Add('重复录数：'+intToStr(FResultHash.DuplicateList.Count));
    mmoInfo.Lines.SaveToFile('NewResult.txt');
    Application.ProcessMessages;
  end;
  FreeAndNil(FResultHash);
end;

end.
