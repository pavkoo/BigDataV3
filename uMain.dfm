object frmMain: TfrmMain
  Left = 867
  Top = 241
  Width = 392
  Height = 324
  Caption = #21435#37325#22797
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object btnExecute: TButton
    Left = 32
    Top = 24
    Width = 305
    Height = 65
    Caption = #25191#34892#20998#26512#21644#21024#38500
    TabOrder = 0
    OnClick = btnExecuteClick
  end
  object mmoInfo: TMemo
    Left = 32
    Top = 96
    Width = 305
    Height = 177
    ImeName = #20013#25991'('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
    ScrollBars = ssVertical
    TabOrder = 1
  end
end
