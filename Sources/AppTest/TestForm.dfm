object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'Form1'
  ClientHeight = 576
  ClientWidth = 994
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCloseQuery = FormCloseQuery
  OnResize = FormResize
  PixelsPerInch = 96
  TextHeight = 13
  object InitializeBtn: TButton
    Left = 16
    Top = 16
    Width = 241
    Height = 49
    Caption = '1. Initialize'
    TabOrder = 0
    OnClick = InitializeBtnClick
  end
  object ShowBtn: TButton
    Left = 16
    Top = 72
    Width = 241
    Height = 49
    Caption = '2. Show browser'
    Enabled = False
    TabOrder = 1
    OnClick = ShowBtnClick
  end
  object FinalizeBtn: TButton
    Left = 16
    Top = 232
    Width = 241
    Height = 49
    Caption = '4. Finalize'
    Enabled = False
    TabOrder = 2
    OnClick = FinalizeBtnClick
  end
  object CloseBtn: TButton
    Left = 16
    Top = 288
    Width = 241
    Height = 49
    Caption = '5. Close this form'
    Enabled = False
    TabOrder = 3
    OnClick = CloseBtnClick
  end
  object Edit1: TEdit
    Left = 16
    Top = 130
    Width = 241
    Height = 21
    Enabled = False
    TabOrder = 4
    Text = 'www.netvcl.com'
  end
  object GoToButton: TButton
    Left = 16
    Top = 150
    Width = 241
    Height = 71
    Caption = '3. Go To Url'
    Enabled = False
    TabOrder = 5
    OnClick = GoToButtonClick
  end
end
