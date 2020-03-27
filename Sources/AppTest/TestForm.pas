unit TestForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls;

type
  TForm1 = class(TForm)
    InitializeBtn: TButton;
    ShowBtn: TButton;
    FinalizeBtn: TButton;
    CloseBtn: TButton;
    Edit1: TEdit;
    GoToButton: TButton;
    procedure InitializeBtnClick(Sender: TObject);
    procedure ShowBtnClick(Sender: TObject);
    procedure FinalizeBtnClick(Sender: TObject);
    procedure CloseBtnClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure GoToButtonClick(Sender: TObject);
    procedure FormResize(Sender: TObject);
  private
    FInitialized: Boolean;
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

uses
  TestLoad;

procedure TForm1.GoToButtonClick(Sender: TObject);
begin
  LoadUrl(Edit1.Text);
end;

procedure TForm1.CloseBtnClick(Sender: TObject);
begin
  close;
end;

procedure TForm1.FinalizeBtnClick(Sender: TObject);
begin
  // FinalizeCEF4Delphi;
  CloseBrowser;
  ShowBtn.Enabled     := False;
  Edit1.Enabled       := False;
  GoToButton.Enabled  := False;
  FinalizeBtn.Enabled := False;
  CloseBtn.Enabled    := True;
end;

procedure TForm1.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if FInitialized then
    // FinalizeCEF4Delphi;

    CanClose := True;
end;

procedure TForm1.FormResize(Sender: TObject);
begin
  if not ShowBtn.Enabled and FinalizeBtn.Enabled then
    ResizeBrowser(Height, Width);
end;

procedure TForm1.InitializeBtnClick(Sender: TObject);
begin
  // InitializeCEF4Delphi;

  FInitialized := True;

  InitializeBtn.Enabled := False;
  ShowBtn.Enabled       := True;
  FinalizeBtn.Enabled   := True;
end;

procedure TForm1.ShowBtnClick(Sender: TObject);
begin
  ShowBrowser(Self);
  ResizeBrowser(Height, Width);
  ShowBtn.Enabled    := False;
  Edit1.Enabled      := True;
  GoToButton.Enabled := True;
end;

end.
