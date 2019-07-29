program client;

uses
  Forms,
  umain in 'umain.pas' {Form1},
  LibVHDI in 'libvhdi.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
