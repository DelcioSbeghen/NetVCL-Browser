unit TestLoad;


interface

uses
  Controls;

procedure ShowBrowser(aParent: TWinControl);
procedure ResizeBrowser(Height: Integer; Width: Integer);
procedure CloseBrowser;
procedure LoadUrl(url:string);


implementation

uses
  Windows, SysUtils;

type
  TShow_BrowserProc   = procedure(Handle: HWND); stdcall ;
  TResize_BrowserProc = procedure(Height: Integer; Width: Integer); stdcall ;
  TLoad_UrlProc       = procedure(Url: PChar); stdcall ;
  TClose_BrowserProc  = procedure;  stdcall ;

var
  hDll          : THandle = 0;
  Show_Browser  : TShow_BrowserProc;
  Resize_Browser: TResize_BrowserProc;
  Load_Url      : TLoad_UrlProc;
  Close_Browser : TClose_BrowserProc;
  Initialize_CEF4Delphi:TClose_BrowserProc;
  Finalize_CEF4Delphi:TClose_BrowserProc;

procedure LoadDll;
begin


  hDll := LoadLibrary(PWideChar(ExtractFilePath(ParamStr(0)) +  'NVBrowserDll.dll'));

  if hDll < 32 then
    raise Exception.Create('Error on Load NVBrowserDll.dll');

  Show_Browser   := GetProcAddress(hDll, PChar('Show_Browser'));
  @Resize_Browser := GetProcAddress(hDll, PChar('Resize_Browser'));
  @Load_Url       := GetProcAddress(hDll, PChar('Load_Url'));
  @Close_Browser  := GetProcAddress(hDll, PChar('Close_Browser'));
  @Initialize_CEF4Delphi:=  GetProcAddress(hDll, PChar('Initialize_CEF4Delphi'));
  @Finalize_CEF4Delphi:=  GetProcAddress(hDll, PChar('Finalize_CEF4Delphi'));

end;

procedure UnLoadDll;
begin
  Finalize_CEF4Delphi;
  FreeLibrary(hDll);
end;

procedure ShowBrowser(aParent: TWinControl);
begin
  if hDll < 32 then
    LoadDll;
    Initialize_CEF4Delphi;
  Show_Browser(aParent.Handle);
  Resize_Browser(aParent.Height, aParent.Width);
end;

procedure ResizeBrowser(Height: Integer; Width: Integer);
begin
  Resize_Browser(Height, Width);
end;

procedure CloseBrowser;
begin
  Close_Browser;
end;

procedure LoadUrl(url:string);
begin
  Load_Url(PChar(url));
end;


initialization

finalization

if hDll > 32 then
  UnLoadDll;

end.
