object frmMain: TfrmMain
  Left = 199
  Top = 113
  Width = 473
  Height = 460
  Caption = 'h c'
  Color = clBtnFace
  Font.Charset = SHIFTJIS_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'MS P????'
  Font.Style = []
  OldCreateOrder = False
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  OnResize = FormResize
  PixelsPerInch = 96
  TextHeight = 16
  object lbl00: TLabel
    Left = 229
    Top = 11
    Width = 40
    Height = 16
    Alignment = taRightJustify
    AutoSize = False
    Caption = '('#180'-`)'
  end
  object lbl01: TLabel
    Left = 400
    Top = 11
    Width = 44
    Height = 16
    Caption = 'Priority:'
  end
  object cmdStart: TButton
    Left = 5
    Top = 5
    Width = 107
    Height = 27
    Caption = 'Start Server'
    Enabled = False
    TabOrder = 0
    OnClick = cmdStartClick
  end
  object cmdStop: TButton
    Left = 117
    Top = 5
    Width = 107
    Height = 27
    Caption = 'Stop Server'
    Enabled = False
    TabOrder = 1
    OnClick = cmdStopClick
  end
  object txtDebug: TMemo
    Left = 0
    Top = 32
    Width = 597
    Height = 534
    Align = alBottom
    Anchors = [akLeft, akTop, akRight, akBottom]
    ReadOnly = True
    ScrollBars = ssVertical
    TabOrder = 2
  end
  object cbxPriority: TComboBox
    Left = 464
    Top = 5
    Width = 133
    Height = 24
    Style = csDropDownList
    ItemHeight = 16
    ItemIndex = 3
    TabOrder = 3
    Text = 'Normal'
    OnClick = cbxPriorityClick
    Items.Strings = (
      'RealTime'
      'High'
      'AboveNormal'
      'Normal'
      'BelowNormal'
      'Idle')
  end
  object sv1: TServerSocket
    Active = False
    Port = 6900
    ServerType = stNonBlocking
    OnClientConnect = sv1ClientConnect
    OnClientDisconnect = sv1ClientDisconnect
    OnClientRead = sv1ClientRead
    OnClientError = sv1ClientError
    Left = 204
  end
  object sv2: TServerSocket
    Active = False
    Port = 5964
    ServerType = stNonBlocking
    OnClientConnect = sv2ClientConnect
    OnClientDisconnect = sv2ClientDisconnect
    OnClientRead = sv2ClientRead
    OnClientError = sv2ClientError
    Left = 212
  end
  object sv3: TServerSocket
    Active = False
    Port = 5967
    ServerType = stNonBlocking
    OnClientConnect = sv3ClientConnect
    OnClientDisconnect = sv3ClientDisconnect
    OnClientRead = sv3ClientRead
    OnClientError = sv3ClientError
    Left = 220
  end
  object DBsaveTimer: TTimer
    Enabled = False
    Interval = 900000
    OnTimer = DBsaveTimerTimer
    Left = 8
    Top = 32
  end
end
