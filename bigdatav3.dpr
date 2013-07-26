program bigdatav3;

uses
  Forms,
  uPavkooHashString in 'uPavkooHashString.pas',
  uMMFile in 'uMMFile.pas',
  uMain in 'uMain.pas' {frmMain},
  uConst in 'uConst.pas',
  Unit1 in 'Unit1.pas' {Form1},
  uPavkooStringList in 'uPavkooStringList.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmMain, frmMain);
  //  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
