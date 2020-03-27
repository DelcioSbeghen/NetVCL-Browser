program TestApp;

uses
  Vcl.Forms,
  TestForm in 'TestForm.pas' {Form1},
  TestLoad in 'TestLoad.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
