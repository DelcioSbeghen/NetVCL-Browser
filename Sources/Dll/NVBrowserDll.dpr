library NVBrowserDll;

{ Important note about DLL memory management: ShareMem must be the
  first unit in your library's USES clause AND your project's (select
  Project-View Source) USES clause if your DLL exports any procedures or
  functions that pass strings as parameters or function results. This
  applies to all strings passed to and from your DLL--even those that
  are nested in records and classes. ShareMem is the interface unit to
  the BORLNDMM.DLL shared memory manager, which must be deployed along
  with your DLL. To avoid using BORLNDMM.DLL, pass string information
  using PChar or ShortString parameters. }

{$I cef.inc}

uses
  SysUtils, Classes,
  uCEFApplication,
  NV.DesignPanel in 'NV.DesignPanel.pas', Windows, Vcl.Controls, Dialogs, vcl.Forms;

{$R *.res}
// This is the simplest way to create a DLL with all that it's necessary to show a
// Chromium based browser using CEF4Delphi

// To test this demo you need to build the CEF4DelphiLoader, DLLBrowser and SubProcess projects found in this directory.

// CEF3 needs to be initialized and finalized outside the DLL's initialization and
// finalization sections. For this reason, you need to call InitializeCEF4Delphi
// after you load this DLL and you also need to call FinalizeCEF4Delphi before
// unloading this DLL.

// CEF3 can only be initialized once per process and this means that :
// 1. You can only call InitializeCEF4Delphi and FinalizeCEF4Delphi once.
// 2. If you use a DLL like this as a plugin and there's another loaded plugin using
// CEF you will have problems.

// When you use CEF in a DLL you must use a different EXE for the subprocesses and that EXE
// must configure GlobalCEFApp with the same properties.

// ***************************
// This demo is incomplete!!!!
// ***************************
// As all other demos, you need to close all web browsers before calling FinalizeCEF4Delphi.
// All the browsers must be closed following the destruction sequence described in uWebBrowser.pas.

procedure Initialize_CEF4Delphi; stdcall;
begin
  GlobalCEFApp := TCefApplication.Create;

  // In case you want to use custom directories for the CEF3 binaries, cache, cookies and user data.
  // If you don't set a cache directory the browser will use in-memory cache.
  // The cache, cookies and user data directories must be writable.
  {
    GlobalCEFApp.FrameworkDirPath     := 'cef';
    GlobalCEFApp.ResourcesDirPath     := 'cef';
    GlobalCEFApp.LocalesDirPath       := 'cef\locales';
    GlobalCEFApp.cache                := 'cef\cache';
    GlobalCEFApp.cookies              := 'cef\cookies';
    GlobalCEFApp.UserDataPath         := 'cef\User Data';
  }

  GlobalCEFApp.CheckCEFFiles    := False; // iniciar mesmo faltando arquivos CEF
  GlobalCEFApp.Locale           := 'pt-BR';
  GlobalCEFApp.FrameworkDirPath := 'lib';
  GlobalCEFApp.ResourcesDirPath := 'lib';
  GlobalCEFApp.LocalesDirPath   := 'lib';

  // GlobalCEFApp.CheckCEFFiles         := False;
  // GlobalCEFApp.SetCurrentDir         := True;

  GlobalCEFApp.BrowserSubprocessPath := 'NVCoreBrowser.exe';

  // This demo uses a different EXE for the subprocesses.
  // With this configuration it's not necessary to have the
  // GlobalCEFApp.StartMainProcess call in a if..then clause.

  GlobalCEFApp.WindowlessRenderingEnabled := True;

  GlobalCEFApp.StartMainProcess;
end;

var
  Panel: TNvDesignPanel;

procedure Finalize_CEF4Delphi; stdcall;
begin
  DestroyGlobalCEFApp;
end;

procedure Show_Browser(Handle: HWND); stdcall;
begin
  // WebBrowserFrm := TWebBrowserFrm.Create(nil);
  // WebBrowserFrm.Show;


  if Panel = nil then

  Panel              := TNvDesignPanel.Create(nil);

 // showmessage(IntToStr(Handle));
  //windows.SetParent(Panel.Handle, Handle);
 // Panel.ParentWindow := Handle;
 Panel.ParentWindow:= Handle;

  //Panel.Align        := alClient;

end;

procedure Resize_Browser(Height: Integer; Width: Integer); stdcall;
begin
  Panel.Height := Height;
  Panel.Width  := Width;
end;

procedure Load_Url(Url: PChar); stdcall;
begin
  Panel.LoadUrl(Url);
end;

procedure Show_DevTools(MousePoint:TPoint);  stdcall;
begin
  Panel.ShowDevTools(MousePoint);
end;


procedure Close_Browser; stdcall;
begin
  FreeAndNil(Panel);
end;

exports
  Initialize_CEF4Delphi,
  Finalize_CEF4Delphi,
  Show_Browser,
  Resize_Browser,
  Load_Url,
  Show_DevTools,
  Close_Browser;

//var
//  SaveDllProc: TDLLProc;
//
//procedure LibExit(Reason: Integer);
//begin
//  if Reason = DLL_PROCESS_DETACH then
//    begin
//       Finalization Code
//
//    end;
//
//  if Assigned(SaveDllProc) then
//    SaveDllProc(Reason); // call saved entry point procedure
//end;

begin
//  // Initialization Code
//
//
//
//  SaveDllProc := DllProc;  // save exit procedure chain
//  DllProc     := @LibExit; // install LibExit exit procedure

end.
