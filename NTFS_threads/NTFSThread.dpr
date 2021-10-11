program NTFSThread;

uses
  Forms,
  uNTFSThreadMain in 'uNTFSThreadMain.pas' {dlgNTFSThread};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TdlgNTFSThread, dlgNTFSThread);
  Application.Run;
end.
