object dlgNTFSThread: TdlgNTFSThread
  Left = 221
  Top = 131
  Width = 830
  Height = 675
  Caption = #1054#1073#1086#1079#1088#1077#1074#1072#1090#1077#1083#1100' NTFS '#1087#1086#1090#1086#1082#1086#1074
  Color = clBtnFace
  Font.Charset = RUSSIAN_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 120
  TextHeight = 16
  object btnOpen: TButton
    Left = 8
    Top = 8
    Width = 169
    Height = 25
    Caption = #1054#1090#1082#1088#1099#1090#1100' '#1092#1072#1081#1083
    TabOrder = 0
    OnClick = btnOpenClick
  end
  object Panel1: TPanel
    Left = 0
    Top = 40
    Width = 822
    Height = 607
    Align = alBottom
    Anchors = [akLeft, akTop, akRight, akBottom]
    BevelOuter = bvNone
    TabOrder = 1
    object Splitter1: TSplitter
      Left = 242
      Top = 0
      Width = 4
      Height = 607
    end
    object GroupBox1: TGroupBox
      Left = 0
      Top = 0
      Width = 242
      Height = 607
      Align = alLeft
      Caption = ' '#1057#1087#1080#1089#1086#1082' '#1087#1086#1090#1086#1082#1086#1074' '
      TabOrder = 0
      object lbStreams: TListBox
        Left = 2
        Top = 18
        Width = 238
        Height = 587
        Align = alClient
        ItemHeight = 16
        TabOrder = 0
        OnClick = lbStreamsClick
      end
    end
    object GroupBox2: TGroupBox
      Left = 246
      Top = 0
      Width = 576
      Height = 607
      Align = alClient
      Caption = ' '#1044#1072#1085#1085#1099#1077' '#1087#1086' '#1087#1086#1090#1086#1082#1091' '
      TabOrder = 1
      object memStream: TMemo
        Left = 2
        Top = 18
        Width = 572
        Height = 587
        Align = alClient
        Font.Charset = RUSSIAN_CHARSET
        Font.Color = clWindowText
        Font.Height = -17
        Font.Name = 'Courier'
        Font.Style = []
        ParentFont = False
        ScrollBars = ssVertical
        TabOrder = 0
      end
    end
  end
  object OpenDialog: TOpenDialog
    Left = 184
    Top = 8
  end
end
