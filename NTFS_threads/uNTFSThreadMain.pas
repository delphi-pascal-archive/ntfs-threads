////////////////////////////////////////////////////////////////////////////////
//
//  ****************************************************************************
//  * Project   : NTFSThread
//  * Unit Name : uNTFSThreadMain
//  * Purpose   : Демо чтения NTFS потоков + демонстрация чтения
//  *           : расширенных свойств файла, хранящихся в них.
//  * Author    : Александр (Rouse_) Багель
//  * Copyright : © Fangorn Wizards Lab 2001 - 2007 г.
//  * Version   : 1.00
//  * Home Page : http://rouse.drkb.ru
//  ****************************************************************************
//

unit uNTFSThreadMain;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls;

type
  TdlgNTFSThread = class(TForm)
    btnOpen: TButton;
    Panel1: TPanel;
    GroupBox1: TGroupBox;
    Splitter1: TSplitter;
    GroupBox2: TGroupBox;
    OpenDialog: TOpenDialog;
    lbStreams: TListBox;
    memStream: TMemo;
    procedure lbStreamsClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btnOpenClick(Sender: TObject);
  private
    FileName: String;
    FileHandle: THandle;
    StreamsSize: array of Int64;
    procedure CloseFileHandle;
    procedure QueryStreams;
    procedure LoadStream(StreamIndex: Integer);
    function LoadSummaryInformation(AFileName: String): String;
    function LoadDocSummaryInformation(AFileName: String): String;
  end;

var
  dlgNTFSThread: TdlgNTFSThread;

implementation

{$R *.dfm}

uses ActiveX, ComObj;

const
  FILE_STREAM_INFORMATION = 22;
  IID_IPropertySetStorage: TGUID = '{0000013A-0000-0000-C000-000000000046}';
  FMTID_SummaryInformation: TGUID = '{F29F85E0-4FF9-1068-AB91-08002B27B3D9}';
  FMTID_DocSummaryInformation:  TGUID =  '{D5CDD502-2E9C-101B-9397-08002B2CF9AE}';

const
  PIDDSI_CATEGORY     =  2;
  PIDDSI_PRESFORMAT   =  3;
  PIDDSI_BYTECOUNT    =  4;
  PIDDSI_LINECOUNT    =  5;
  PIDDSI_PARCOUNT     =  6;
  PIDDSI_SLIDECOUNT   =  7;
  PIDDSI_NOTECOUNT    =  8;
  PIDDSI_HIDDENCOUNT  =  9;
  PIDDSI_MMCLIPCOUNT  =  10;
  PIDDSI_SCALE        =  11;
  PIDDSI_HEADINGPAIR  =  12;
  PIDDSI_DOCPARTS     =  13;
  PIDDSI_MANAGER      =  14;
  PIDDSI_COMPANY      =  15;
  PIDDSI_LINKSDIRTY   =  16;

type
  STGFMT = (STGFMT_STORAGE = 0, STGFMT_FILE = 3,
    STGFMT_ANY = 4, STGFMT_DOCFILE = 5);

  NT_STATUS = Cardinal;

  PIO_STATUS_BLOCK = ^IO_STATUS_BLOCK;
  IO_STATUS_BLOCK = packed record
    Status: NT_STATUS;
    Information: DWORD;
  end;

  PFileStreamInformation = ^TFileStreamInformation;
  _FILE_STREAM_INFORMATION = packed record
    NextEntryOffset: ULONG;
    StreamNameLength: ULONG;
    StreamSize: Int64;
    StreamAllocationSize: Int64;
    StreamName: WCHAR;
  end;
  TFileStreamInformation = _FILE_STREAM_INFORMATION;

  function NtQueryInformationFile(FileHandle: THandle;
    var IoStatusBlock: IO_STATUS_BLOCK; FileInformation: Pointer;
    Length: DWORD; FileInformationClass: DWORD): NT_STATUS;
    stdcall; external 'ntdll.dll';

  function StgOpenStorageEx(pwcsName: POleStr; grfMode: Longint;
    stgfmt: STGFMT; grfAttrs: DWORD; pStgOptions: Pointer;
    reserved2: Pointer; riid : PGUID; out stgOpen: IStorage): HResult;
    stdcall; external 'ole32.dll';

procedure TdlgNTFSThread.CloseFileHandle;
begin
  if FileHandle <> INVALID_HANDLE_VALUE then
    CloseHandle(FileHandle);
  lbStreams.Clear;
  memStream.Text := '';
  SetLength(StreamsSize, 0);
  FileName := '';
end;

procedure TdlgNTFSThread.FormCreate(Sender: TObject);
begin
  FileHandle := INVALID_HANDLE_VALUE;
end;

procedure TdlgNTFSThread.FormDestroy(Sender: TObject);
begin
  CloseFileHandle;
end;

procedure TdlgNTFSThread.lbStreamsClick(Sender: TObject);
begin
  LoadStream(lbStreams.ItemIndex);
end;

function TdlgNTFSThread.LoadDocSummaryInformation(AFileName: String): String;
const
  NPID_DocSummaryInformation:
    array [PIDDSI_CATEGORY..PIDDSI_LINKSDIRTY] of String = (
      'Category', 'Presentation Target', 'Bytes', 'Lines', 'Paragraphs',
      'Slides', 'Notes', 'Hidden Slides', 'MM Clips', 'Scale',
      'Heading Pairs', 'Titles Of Parts', 'Manager', 'Company', 'Links Dirty');
var
  Storage: IStorage;
  PropStorage: IPropertyStorage;
  PropSpec: TPropSpec;
  PropVariant: TPropVariant;
  EnumSTATPROPSTG: IEnumSTATPROPSTG;
  StatPropStg: TStatPropStg;
  Fetched: ULONG;
begin
  Result := '';
  OleCheck(StgOpenStorageEx(StringToOleStr(AFileName),
    STGM_DIRECT or STGM_READ or STGM_SHARE_EXCLUSIVE, STGFMT_ANY, 0, nil, nil,
    @IID_IPropertySetStorage, Storage));
  OleCheck((Storage as IPropertySetStorage).Open(FMTID_DocSummaryInformation,
    STGM_DIRECT or STGM_READ or STGM_SHARE_EXCLUSIVE, PropStorage));

  Result := '';
  PropStorage.Enum(EnumSTATPROPSTG);
  PropSpec.ulKind := PRSPEC_PROPID;
  EnumSTATPROPSTG.Next(1, StatPropStg, @Fetched);
  repeat
    PropSpec.ulKind := PRSPEC_PROPID;
    PropSpec.propid := StatPropStg.propid;
    PropStorage.ReadMultiple(1, @PropSpec, @PropVariant);
    Result := Format('%s%s: %s'#13#10, [Result,
      NPID_DocSummaryInformation[StatPropStg.propid], PropVariant.pszVal]);
    EnumSTATPROPSTG.Next(1, StatPropStg, @Fetched);
  until Fetched = 0;
end;

procedure TdlgNTFSThread.LoadStream(StreamIndex: Integer);

  function ByteToHexStr(Data: Pointer; Len: Integer): String;
  var
    I, Octets, PartOctets: Integer;
    DumpData: String;
  begin
    if Len = 0 then Exit;
    I := 0;
    Octets := 0;
    PartOctets := 0;
    Result := '';
    while I < Len do
    begin
      case PartOctets of
        0: Result := Result + Format('%.4d: ', [Octets]);
        9:
        begin
          Inc(Octets, 10);
          PartOctets := -1;
          Result := Result + '    ' + DumpData + sLineBreak;
          DumpData := '';
        end;
      else
        begin
          Result := Result + Format('%s ', [IntToHex(TByteArray(Data^)[I], 2)]);
          if TByteArray(Data^)[I] in [$19..$FF] then
            DumpData := DumpData + Chr(TByteArray(Data^)[I])
          else
            DumpData := DumpData + '.';
          Inc(I);
        end;
      end;
      Inc(PartOctets);
    end;
    if PartOctets <> 0 then
    begin
      PartOctets := (8 - Length(DumpData)) * 3;
      Inc(PartOctets, 4);
      Result := Result + StringOfChar(' ', PartOctets) +
        DumpData
    end;
  end;

var
  hFile: THandle;
  lpNumberOfBytesRead: DWORD;
  Buff: array of Byte;
begin
  memStream.Text := '';
  if lbStreams.Items.Strings[StreamIndex] = ':'#5'SummaryInformation:$DATA' then
  begin
    memStream.Text := LoadSummaryInformation(FileName);
    memStream.Lines.Add('=================================================');
  end;
  if lbStreams.Items.Strings[StreamIndex] = ':'#5'DocumentSummaryInformation:$DATA' then
  begin
    memStream.Text := LoadDocSummaryInformation(FileName);
    memStream.Lines.Add('=================================================');
  end;
  hFile := CreateFile(PChar(FileName + lbStreams.Items.Strings[StreamIndex]),
    GENERIC_READ, FILE_SHARE_READ, nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
  if hFile <> INVALID_HANDLE_VALUE then
  try
    SetLength(Buff, StreamsSize[StreamIndex]);
    ReadFile(hFile, Buff[0], StreamsSize[StreamIndex], lpNumberOfBytesRead, nil);
    memStream.Text := memStream.Text +
      ByteToHexStr(@Buff[0], lpNumberOfBytesRead);
  finally
    CloseHandle(hFile);
  end;
end;

function TdlgNTFSThread.LoadSummaryInformation(AFileName: String): String;
const
  NPID_SummaryInformation: array [PIDSI_TITLE..PIDSI_DOC_SECURITY] of String = (
    'Title', 'Subject', 'Author', 'Keywords', 'Comments', 'Template',
    'Last Saved By', 'Revision Number', 'Total Editing Time', 'Last Printed',
    'Create Time/Date', 'Last Saved Time/Date', 'Number of Pages',
    'Number of Words', 'Number of Characters', 'Thumbnail',
    'Application Name', 'Security');
var
  Storage: IStorage;
  PropStorage: IPropertyStorage;
  PropSpec: TPropSpec;
  PropVariant: TPropVariant;
  EnumSTATPROPSTG: IEnumSTATPROPSTG;
  StatPropStg: TStatPropStg;
  Fetched: ULONG;
begin
  Result := '';
  OleCheck(StgOpenStorageEx(StringToOleStr(AFileName),
    STGM_DIRECT or STGM_READ or STGM_SHARE_EXCLUSIVE, STGFMT_ANY, 0, nil, nil,
    @IID_IPropertySetStorage, Storage));
  OleCheck((Storage as IPropertySetStorage).Open(FMTID_SummaryInformation,
    STGM_DIRECT or STGM_READ or STGM_SHARE_EXCLUSIVE, PropStorage));

  Result := '';
  PropStorage.Enum(EnumSTATPROPSTG);
  PropSpec.ulKind := PRSPEC_PROPID;
  EnumSTATPROPSTG.Next(1, StatPropStg, @Fetched);
  repeat
    PropSpec.ulKind := PRSPEC_PROPID;
    PropSpec.propid := StatPropStg.propid;
    PropStorage.ReadMultiple(1, @PropSpec, @PropVariant);
    Result := Format('%s%s: %s'#13#10, [Result,
      NPID_SummaryInformation[StatPropStg.propid], PropVariant.pszVal]);
    EnumSTATPROPSTG.Next(1, StatPropStg, @Fetched);
  until Fetched = 0;
end;

procedure TdlgNTFSThread.QueryStreams;
const
  STATUS_BUFFER_OVERFLOW = $80000005;
  STATUS_INFO_LENGTH_MISMATCH = $C0000004;
var
  IoStatusBlock: IO_STATUS_BLOCK;
  FileStreamInformation, FileStreamInformationReader: PFileStreamInformation;
  FileStreamInformationSize: DWORD;
  AResult: NT_STATUS;
begin
  if FileHandle = INVALID_HANDLE_VALUE then Exit;
  AResult := STATUS_BUFFER_OVERFLOW;
  FileStreamInformationSize := MAXSHORT;
  GetMem(FileStreamInformation, FileStreamInformationSize);
  repeat
    if AResult = STATUS_INFO_LENGTH_MISMATCH then
    begin
      FileStreamInformationSize := FileStreamInformationSize * 2;
      ReallocMem(FileStreamInformation, FileStreamInformationSize);
    end;
    AResult := NtQueryInformationFile(FileHandle, IoStatusBlock, FileStreamInformation,
      FileStreamInformationSize, FILE_STREAM_INFORMATION);
  until AResult <> STATUS_INFO_LENGTH_MISMATCH;
  try
    if (AResult = NO_ERROR) or (AResult = STATUS_BUFFER_OVERFLOW) then
    begin
      FileStreamInformationReader := FileStreamInformation;
      repeat
        SetLength(StreamsSize, Length(StreamsSize) + 1);
        StreamsSize[Length(StreamsSize) - 1] :=
          FileStreamInformationReader^.StreamSize;
        lbStreams.Items.Add(
          Copy(PWideChar(@FileStreamInformationReader^.StreamName),
          1, FileStreamInformationReader^.StreamNameLength div SizeOf(WideChar)));
        FileStreamInformationReader :=
          Pointer(DWORD(FileStreamInformationReader) +
          FileStreamInformationReader^.NextEntryOffset);
      until FileStreamInformationReader^.NextEntryOffset = 0; 
    end;
  finally
    FreeMem(FileStreamInformation);
  end;
  
end;

procedure TdlgNTFSThread.btnOpenClick(Sender: TObject);
begin
  OpenDialog.InitialDir := ExtractFilePath(ParamStr(0));
  if OpenDialog.Execute then
  begin
    CloseFileHandle;
    FileName := OpenDialog.FileName;
    FileHandle := CreateFile(PChar(FileName),
      GENERIC_READ, FILE_SHARE_READ, nil, OPEN_EXISTING,
      FILE_ATTRIBUTE_NORMAL, 0);
    QueryStreams;
  end;
end;

end.
