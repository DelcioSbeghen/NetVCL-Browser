unit NV.DesignPanel;

interface

uses
  Classes, Messages, SysUtils, Controls, ExtCtrls, Windows, Forms,
  uCEFChromium, Vcl.Consts, uCEFBufferPanel, uCEFInterfaces, uCEFTypes, SyncObjs,
  uCEFConstants, Vcl.StdCtrls;

type
  TNvDesignPanel = class(TBufferPanel)
  strict private
    FDsWeb        : TChromium;
    FTimerDs      : TTimer;
    FResizeCS     : TCriticalSection;
    FResizing     : boolean;
    FPendingResize: boolean;
    FIMECS        : TCriticalSection;
    FDeviceBounds : TCefRectDynArray;
    FSelectedRange: TCefRange;
    FCanClose     : boolean;
  private
    // FAjax   : TNvAjax;
    FLoading: boolean;
    procedure CMShowingChanged(var Message: TMessage); message CM_SHOWINGCHANGED;
    procedure WMClose(var Msg: TMessage); message WM_CLOSE;
    // procedure CMDesignHitTest(var Message: TCMDesignHitTest); message CM_DESIGNHITTEST;
    procedure DoResize;
  protected
    // FContainer: TNvModuleContainer;
    procedure InitDesignBrowser(Sender: TObject);
    procedure DoDesignPaint(Sender: TObject; const browser: ICefBrowser; kind: TCefPaintElementType;
      dirtyRectsCount: NativeUInt; const dirtyRects: PCefRectArray; const buffer: Pointer;
      width, height: Integer);
    procedure DoIMECancelComposition(Sender: TObject);
    procedure DoIMECommitText(Sender: TObject; const aText: ustring;
      const replacement_range: PCefRange; relative_cursor_pos: Integer);
    procedure DoIMESetComposition(Sender: TObject; const aText: ustring;
      const underlines: TCefCompositionUnderlineDynArray;
      const replacement_range, selection_range: TCefRange);
    procedure DoGetViewRect(Sender: TObject; const browser: ICefBrowser; var rect: TCefRect);
    procedure DoGetScreenPoint(Sender: TObject; const browser: ICefBrowser; viewX, viewY: Integer;
      var screenX, screenY: Integer; out Result: boolean);
    procedure DoGetScreenInfo(Sender: TObject; const browser: ICefBrowser;
      var screenInfo: TCefScreenInfo; out Result: boolean);
    procedure DoIMECompositionRangeChanged(Sender: TObject; const browser: ICefBrowser;
      const selected_range: PCefRange; character_boundsCount: NativeUInt;
      const character_bounds: PCefRect);
    procedure DoBrowserClose(Sender: TObject; const browser: ICefBrowser;
      var aAction: TCefCloseBrowserAction);
    procedure DoBrowserBeforeClose(Sender: TObject; const browser: ICefBrowser);
    procedure Resize; override;
    procedure PendingResizeMsg(var aMessage: TMessage); message CEF_PENDINGRESIZE;
    procedure RangeChangedMsg(var aMessage: TMessage); message CEF_IMERANGECHANGED;
    procedure Invalidate; override;
    procedure Paint; override;
    procedure CreateParams(var Params: TCreateParams); override;
  public
    constructor Create(AOwner: TComponent);
    destructor Destroy; override;
    procedure LoadUrl(url: ustring);
    // procedure FreeInstance; override;
    // procedure BeforeDestruction; override;
    // function Render: string;
    procedure UpdateDesign;
    procedure ShowDevTools(MousePos: TPoint);
    property Top;
    property Left;
    property width;
    property height;
  end;

var
  RootPath: string = '';

implementation

uses
  uCEFApplication, System.Math, uCEFMiscFunctions, Vcl.Graphics,
  uCEFWindowParent, Threading;

// Hack
type
  TCustomForm = class(Forms.TCustomForm);

  TForm = class(Forms.TForm);

const
  Html =                          //
    '<!doctype html>'             //
    + '<html lang="en">'          //
    + ' <head>'                   //
    + '   <meta charset="utf-8">' //
    + '   <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">' //
    + '   <title>Teste!</title>'                              //
    + '   <script>'                                           //
    + '     function DoLoad() {'                              //
    + '     App = new window.TApplication("");'               //
    + '     }'                                                //
    + '   </script>'                                          //
    + ' </head>'                                              //
    + ' <body onload="DoLoad()" }>'                           //
    + '   <script src="./jquery-3.3.1.slim.min.js"></script>' //
  // + '   <script src="https://cdnjs.cloudflare.com/ajax/libs/popper.js/1.14.7/umd/popper.min.js" integrity="sha384-UO2eT0CpHqdSJQ6hJty5KVphtPhzWj9WO1clHTMGa3JDZwrnQq4sF86dIHNDz0W1" crossorigin="anonymous"></script>'//
    + '   <script src="./bootstrap.min.js"></script>'             //
    + '   <script Type="module" src="./nv.bs.forms.js"></script>' //
    + ' </body>'                                                  //
    + '</html>';

  { TDWForm }

  // procedure TDWForm.CMDesignHitTest(var Message: TCMDesignHitTest);
  // begin
  // if Message.Msg = CM_MOUSEWHEEL then
  // begin
  //
  // end;
  //
  // inherited;
  // end;

  // procedure TNvDesignPanel.BeforeDestruction;
  // begin
  // inherited;
  //
  //
  // end;

procedure TNvDesignPanel.CMShowingChanged(var Message: TMessage);
begin
  // if not(csDesigning in ComponentState) { and (fsShowing in FFormState) } then
  // raise EInvalidOperation.Create(SVisibleChanged);

  if Showing { and (csDesigning in ComponentState) } then
    begin
      if FDsWeb.Initialized then
        begin
          FDsWeb.WasHidden(False);
          // FDsWeb.SendFocusEvent(True);
        end
      else
        begin
          // opaque white background color
          FDsWeb.Options.BackgroundColor := CefColorSetARGB($FF, $FF, $FF, $FF);

          // The IME handler needs to be created when Panel1 has a valid handle
          // and before the browser creation.
          // You can skip this if the user doesn't need an "Input Method Editor".

          CreateIMEHandler;

          if FDsWeb.CreateBrowser(nil, '') then
            Invalidate
            // FDsWeb.InitializeDragAndDrop(self)

          else
            FTimerDs.Enabled := True;
        end;

    end;

  // and (csDesigning in ComponentState) and not (FDsWeb.CreateBrowser(nil, '')) then
  // FTimerDs.Enabled := True;
  inherited;
end;

constructor TNvDesignPanel.Create(AOwner: TComponent);
begin
  FLoading := True;
  inherited Create(AOwner);
  SetDesigning(True);

  // FPopUpBitmap    := nil;
  // FPopUpRect      := rect(0, 0, 0, 0);
  // FShowPopUp      := False;
  FResizing      := False;
  FPendingResize := False;
  FCanClose      := False;
  // FClosing        := False;
  FDeviceBounds := nil;
  //
  FSelectedRange.from := 0;
  FSelectedRange.to_  := 0;

  FResizeCS := TCriticalSection.Create;
  FIMECS    := TCriticalSection.Create;
  //
  // InitializeLastClick;

  OnIMECancelComposition := DoIMECancelComposition;
  OnIMECommitText        := DoIMECommitText;
  OnIMESetComposition    := DoIMESetComposition;

  FTimerDs                 := TTimer.Create(nil);
  FTimerDs.Enabled         := False;
  FTimerDs.OnTimer         := InitDesignBrowser;
  FDsWeb                   := TChromium.Create(nil);
  FDsWeb.CustomHeaderName  := 'Cache-Control';
  FDsWeb.CustomHeaderValue := 'no-cache';

  FDsWeb.OnClose       := DoBrowserClose;
  FDsWeb.OnBeforeClose := DoBrowserBeforeClose;
  FDsWeb.DefaultUrl    := 'http://www.google.com'; // 'http://127.0.0.1:' + FDesignServer.Port;
  // 'data:text/html,' + Html;
  FDsWeb.OnPaint                      := DoDesignPaint;
  FDsWeb.OnGetScreenInfo              := DoGetScreenInfo;
  FDsWeb.OnGetScreenPoint             := DoGetScreenPoint;
  FDsWeb.OnGetViewRect                := DoGetViewRect;
  FDsWeb.OnIMECompositionRangeChanged := DoIMECompositionRangeChanged;

  // FCanClose := False;
  // FDsWeb.CreateBrowser(Self);
  // FDsWeb.LoadString(Render, 'about:blank');

  // else
  // FCanClose := True;
  FLoading := False;
  UpdateDesign;

end;

procedure TNvDesignPanel.CreateParams(var Params: TCreateParams);
var
  LRect      : TRect;
  LParent    : TCustomForm;
  CreateStyle: TFormBorderStyle;
  LPopupMode : TPopupMode;
begin
  inherited CreateParams(Params);

  if (Parent = nil) and (ParentWindow = 0) then
    Params.WndParent := Application.Handle;

  // test
  // with Params do
  // begin
  // if (Parent = nil) and (ParentWindow = 0) then
  // begin
  // LParent := nil;
  // if csDesigning in ComponentState then
  // LPopupMode := pmExplicit
  // // else if (fsModal in FormState) and (FPopupMode = pmNone) then
  // // LPopupMode := pmAuto
  // // else if FormStyle = fsNormal then
  // // LPopupMode := FPopupMode
  // else
  // LPopupMode := pmNone;
  // case LPopupMode of
  // pmNone:
  // begin
  // if Application.MainFormOnTaskBar then
  // begin
  // // FCreatingMainForm is True when the MainForm is
  // // being created, Self = Application.MainForm during CM_RECREATEWND.
  // // if FCreatingMainForm or (Self = Application.MainForm) then
  // // WndParent := 0
  // // else
  // if Assigned(Application.MainForm) and Application.MainForm.HandleAllocated then
  // begin
  // WndParent := Application.MainFormHandle;
  // if WndParent = Application.MainForm.Handle then
  // begin
  // if TCustomForm(Application.MainForm).PopupChildren.IndexOf(Self) < 0
  // then
  // TCustomForm(Application.MainForm).PopupChildren.Add(Self);
  // FreeNotification(Application.MainForm);
  // end;
  // end
  // else
  // WndParent := Application.Handle;
  // end
  // else
  // begin
  // WndParent := Application.Handle;
  // SetWindowLong(WndParent, GWL_EXSTYLE, GetWindowLong(WndParent, GWL_EXSTYLE) and
  // not WS_EX_TOOLWINDOW);
  // end;
  // end;
  // // pmAuto:
  // // begin
  // // if FCreatingMainForm then
  // // WndParent := 0 // A main form can't be parented to another form
  // // else
  // // WndParent := Application.ActiveFormHandle;
  // // if (WndParent <> 0) and (IsIconic(WndParent) or not IsWindowVisible(WndParent) or
  // // not IsWindowEnabled(WndParent)) then
  // // WndParent := 0;
  // // if (WndParent <> 0) and
  // // (GetWindowLong(WndParent, GWL_EXSTYLE) and WS_EX_TOOLWINDOW = WS_EX_TOOLWINDOW) then
  // // WndParent := GetNonToolWindowPopupParent(WndParent);
  // // if (WndParent <> 0) and (Screen.ActiveForm <> nil) and
  // // (Screen.ActiveForm.WindowHandle = WndParent) then
  // // LParent := Screen.ActiveForm
  // // else if WndParent = 0 then
  // // if Application.MainFormOnTaskBar then
  // // begin
  // // // FCreatingMainForm is True when the MainForm is
  // // // being created, Self = Application.MainForm during CM_RECREATEWND.
  // // if FCreatingMainForm or (Self = Application.MainForm) then
  // // WndParent := 0
  // // else
  // // if Assigned(Application.MainForm) and Application.MainForm.HandleAllocated then
  // // begin
  // // WndParent := Application.MainFormHandle;
  // // if WndParent = Application.MainForm.Handle then
  // // begin
  // // if Application.MainForm.PopupChildren.IndexOf(Self) < 0 then
  // // Application.MainForm.PopupChildren.Add(Self);
  // // FreeNotification(Application.MainForm);
  // // end;
  // // end
  // // else
  // // WndParent := Application.Handle;
  // // end
  // // else
  // // begin
  // // WndParent := Application.Handle;
  // // SetWindowLong(WndParent, GWL_EXSTYLE, GetWindowLong(WndParent, GWL_EXSTYLE) and not WS_EX_TOOLWINDOW);
  // // end;
  // // end;
  // pmExplicit:
  // begin
  // // if Assigned(FPopupParent) and not (csDesigning in ComponentState) then
  // // begin
  // // WndParent := FPopupParent.Handle;
  // // LParent := FPopupParent;
  // // end
  // // else
  // WndParent := Application.MainFormHandle;
  // if (WndParent <> 0) and (Application.MainForm <> nil) and
  // (TForm(Application.MainForm).WindowHandle = WndParent) then
  // LParent := TCustomForm(Application.MainForm)
  // else if WndParent = 0 then
  // begin
  // WndParent := Application.Handle;
  // if not Application.MainFormOnTaskBar then
  // SetWindowLong(WndParent, GWL_EXSTYLE, GetWindowLong(WndParent, GWL_EXSTYLE)
  // and not WS_EX_TOOLWINDOW);
  // end;
  // end;
  // end;
  //
  // if Assigned(LParent) then
  // begin
  //
  // if LParent.PopupChildren.IndexOf(Self) < 0 then
  // LParent.PopupChildren.Add(Self);
  // FreeNotification(LParent);
  // // FInternalPopupParent := LParent;
  // end;
  // // else if WndParent <> Application.Handle then
  // // FInternalPopupParentWnd := WndParent;
  // Style := Style and not(WS_CHILD or WS_GROUP or WS_TABSTOP);
  // end;
  // WindowClass.Style := CS_DBLCLKS;
  // if (csDesigning in ComponentState) and (Parent = nil) then
  // Style := Style or (WS_CAPTION or WS_THICKFRAME or WS_MINIMIZEBOX or WS_MAXIMIZEBOX or
  // WS_SYSMENU)
  // else
  // begin
  // // if (not(csDesigning in ComponentState) or (Parent = nil)) and (FPosition in [poDefault, poDefaultPosOnly, poScreenCenter]) then
  // // begin
  // // X := Integer(CW_USEDEFAULT);
  // // Y := Integer(CW_USEDEFAULT);
  // // end;
  //
  // // GetBorderStyles(Style, ExStyle, WindowClass.Style);
  // // CreateStyle := FBorderStyle;
  // // if (FormStyle = fsMDIChild) and (CreateStyle in [bsNone, bsDialog]) then
  // // CreateStyle := bsSizeable;
  // // if (CreateStyle in [bsSizeable, bsSizeToolWin]) and
  // // (not(csDesigning in ComponentState) or (Parent = nil)) and
  // // (FPosition in [poDefault, poDefaultSizeOnly]) then
  // // begin
  // // Width := Integer(CW_USEDEFAULT);
  // // Height := Integer(CW_USEDEFAULT);
  // // end;
  // // if CreateStyle in [bsSingle, bsSizeable, bsNone] then
  // // begin
  // // if not (csDesigning in ComponentState) then
  // // if FWindowState = wsMinimized then
  // // begin
  // // if Application.MainFormOnTaskBar and FCreatingMainForm then
  // // // Delay minimizing the mainform until TApplication.Run
  // // Application.FInitialMainFormState := wsMinimized
  // // else
  // // Style := Style or WS_MINIMIZE;
  // // end else
  // // if FWindowState = wsMaximized then Style := Style or WS_MAXIMIZE;
  // // end
  // // else
  // // FWindowState := wsNormal;
  // if csInline in ComponentState then
  // Style := Style and not WS_CAPTION;
  // // if FormStyle = fsMDIChild then
  // // {$IF DEFINED(CLR)}
  // // WndProc := @DefMDIChildProc;
  // // {$ELSE}
  // // WindowClass.lpfnWndProc := @DefMDIChildProc;
  // // {$ENDIF}
  // // GetBorderIconStyles(Style, ExStyle);
  // // if Application.MainFormOnTaskBar and (FCreatingMainForm or
  // // (((csDesigning in ComponentState) or (csRecreating in ControlState)) and
  // // (FormStyle <> fsMDIChild) and (Self = Application.MainForm))) then
  // // ExStyle := ExStyle or WS_EX_APPWINDOW;
  //
  // // if IsClientSizeStored and (FWindowState = wsMaximized) then
  // // begin
  // // // Ensure correct size when form is restored from maximized state
  // // LRect := Rect(0, 0, FClientWidth, FClientHeight);
  // // if AdjustWindowRectEx(LRect, Style, FMenu <> nil, ExStyle) then
  // // begin
  // // Width := LRect.Right - LRect.Left;
  // // Height := LRect.Bottom - LRect.Top;
  // // end;
  // // end;
  // end;
  // end;

end;

destructor TNvDesignPanel.Destroy;
begin
  if Assigned(FDsWeb) and (not FCanClose) then
    begin
      FCanClose := True;
      Visible   := False;
      FDsWeb.CloseBrowser(True);
      // Exit;
    end;

  while FDsWeb.Initialized do
    begin
      Application.ProcessMessages;
      Sleep(10);
    end;


  // Sleep(10000);

  // while not FCanClose do
  // begin
  // Application.ProcessMessages;
  // Sleep(10);
  // end;

  if Assigned(FTimerDs) then
    FTimerDs.Free;

  if Assigned(FDsWeb) then
    begin
      // FDsWeb.ShutdownDragAndDrop;

      // if (FPopUpBitmap <> nil) then
      // FreeAndNil(FPopUpBitmap);
      if (FResizeCS <> nil) then
        FResizeCS.Free;
      if (FIMECS <> nil) then
        FIMECS.Free;

      if (FDeviceBounds <> nil) then
        begin
          Finalize(FDeviceBounds);
          FDeviceBounds := nil;
        end;

      FDsWeb.Free;
    end;
  // if Assigned(FDesignServer) then
  // FDesignServer.Free;

  // FreeAndNil(FAjax);

  inherited;
end;

procedure TNvDesignPanel.DoBrowserBeforeClose(Sender: TObject; const browser: ICefBrowser);
begin
  FCanClose := True;
  PostMessage(Self.Handle, WM_CLOSE, 0, 0);
end;

procedure TNvDesignPanel.DoBrowserClose(Sender: TObject; const browser: ICefBrowser;
  var aAction: TCefCloseBrowserAction);
begin
  aAction := cbaDelay;
end;

procedure TNvDesignPanel.DoDesignPaint(Sender: TObject; const browser: ICefBrowser;
  kind: TCefPaintElementType; dirtyRectsCount: NativeUInt; const dirtyRects: PCefRectArray;
  const buffer: Pointer; width, height: Integer);
var
  src, dst                                                              : PByte;
  i, J, TempLineSize, TempSrcOffset, TempDstOffset, SrcStride, DstStride: Integer;
  n                                                                     : NativeUInt;
  TempWidth, TempHeight, TempScanlineSize                               : Integer;
  TempBufferBits                                                        : Pointer;
  TempForcedResize                                                      : boolean;
begin

  if FCanClose then
    Exit;

  try
    FResizeCS.Acquire;
    TempForcedResize := False;

    if BeginBufferDraw then
      begin
        if (kind = PET_POPUP) then
          begin
            // if (FPopUpBitmap = nil) or
            // (width  <> FPopUpBitmap.Width) or
            // (height <> FPopUpBitmap.Height) then
            // begin
            // if (FPopUpBitmap <> nil) then FPopUpBitmap.Free;
            //
            // FPopUpBitmap             := TBitmap.Create;
            // FPopUpBitmap.PixelFormat := pf32bit;
            // FPopUpBitmap.HandleType  := bmDIB;
            // FPopUpBitmap.Width       := width;
            // FPopUpBitmap.Height      := height;
            // end;
            //
            // TempWidth        := FPopUpBitmap.Width;
            // TempHeight       := FPopUpBitmap.Height;
            // TempScanlineSize := FPopUpBitmap.Width * SizeOf(TRGBQuad);
            // TempBufferBits   := FPopUpBitmap.Scanline[pred(FPopUpBitmap.Height)];
          end
        else
          begin
            TempForcedResize := UpdateBufferDimensions(width, height) or
              not(BufferIsResized(False));
            TempWidth        := BufferWidth;
            TempHeight       := BufferHeight;
            TempScanlineSize := ScanlineSize;
            TempBufferBits   := BufferBits;
          end;

        if (TempBufferBits <> nil) then
          begin
            SrcStride := width * SizeOf(TRGBQuad);
            DstStride := -TempScanlineSize;

            n := 0;

            while (n < dirtyRectsCount) do
              begin
                if (dirtyRects[n].x >= 0) and (dirtyRects[n].y >= 0) then
                  begin
                    TempLineSize := min(dirtyRects[n].width, TempWidth - dirtyRects[n].x) *
                      SizeOf(TRGBQuad);

                    if (TempLineSize > 0) then
                      begin
                        TempSrcOffset := ((dirtyRects[n].y * width) + dirtyRects[n].x) *
                          SizeOf(TRGBQuad);
                        TempDstOffset :=
                          ((TempScanlineSize * pred(TempHeight)) -
                          (dirtyRects[n].y * TempScanlineSize)) +
                          (dirtyRects[n].x * SizeOf(TRGBQuad));

                        src := @PByte(buffer)[TempSrcOffset];
                        dst := @PByte(TempBufferBits)[TempDstOffset];

                        i := 0;
                        J := min(dirtyRects[n].height, TempHeight - dirtyRects[n].y);

                        while (i < J) do
                          begin
                            Move(src^, dst^, TempLineSize);

                            Inc(dst, DstStride);
                            Inc(src, SrcStride);
                            Inc(i);
                          end;
                      end;
                  end;

                Inc(n);
              end;

            // if FShowPopup and (FPopUpBitmap <> nil) then
            // Panel1.BufferDraw(FPopUpRect.Left, FPopUpRect.Top, FPopUpBitmap);
          end;

        EndBufferDraw;
        InvalidatePanel;

        if (kind = PET_VIEW) then
          begin
            if (TempForcedResize or FPendingResize) and (WindowHandle <> 0) then
              PostMessage(Handle, CEF_PENDINGRESIZE, 0, 0);

            FResizing      := False;
            FPendingResize := False;
          end;
      end;
  finally
    FResizeCS.Release;
  end;

end;

procedure TNvDesignPanel.DoGetScreenInfo(Sender: TObject; const browser: ICefBrowser;
  var screenInfo: TCefScreenInfo; out Result: boolean);
var
  TempRect: TCefRect;
begin
  if (GlobalCEFApp <> nil) then
    begin
      TempRect.x      := 0;
      TempRect.y      := 0;
      TempRect.width  := DeviceToLogical(width, GlobalCEFApp.DeviceScaleFactor);
      TempRect.height := DeviceToLogical(height, GlobalCEFApp.DeviceScaleFactor);

      screenInfo.device_scale_factor := GlobalCEFApp.DeviceScaleFactor;
      screenInfo.depth               := 0;
      screenInfo.depth_per_component := 0;
      screenInfo.is_monochrome       := Ord(False);
      screenInfo.rect                := TempRect;
      screenInfo.available_rect      := TempRect;

      Result := True;
    end
  else
    Result := False;
end;

procedure TNvDesignPanel.DoGetScreenPoint(Sender: TObject; const browser: ICefBrowser;
  viewX, viewY: Integer; var screenX, screenY: Integer; out Result: boolean);
var
  TempScreenPt, TempViewPt: TPoint;
begin
  if (GlobalCEFApp <> nil) then
    begin
      TempViewPt.x := LogicalToDevice(viewX, GlobalCEFApp.DeviceScaleFactor);
      TempViewPt.y := LogicalToDevice(viewY, GlobalCEFApp.DeviceScaleFactor);
      TempScreenPt := ClientToScreen(TempViewPt);
      screenX      := TempScreenPt.x;
      screenY      := TempScreenPt.y;
      Result       := True;
    end
  else
    Result := False;

end;

procedure TNvDesignPanel.DoGetViewRect(Sender: TObject; const browser: ICefBrowser;
  var rect: TCefRect);
begin
  if (GlobalCEFApp <> nil) then
    begin
      rect.x      := 0;
      rect.y      := 0;
      rect.width  := DeviceToLogical(width, GlobalCEFApp.DeviceScaleFactor);
      rect.height := DeviceToLogical(height, GlobalCEFApp.DeviceScaleFactor);
    end;
end;

procedure TNvDesignPanel.DoIMECancelComposition(Sender: TObject);
begin
  FDsWeb.IMECancelComposition;
end;

procedure TNvDesignPanel.DoIMECommitText(Sender: TObject; const aText: ustring;
  const replacement_range: PCefRange; relative_cursor_pos: Integer);
begin
  FDsWeb.IMECommitText(aText, replacement_range, relative_cursor_pos);
end;

procedure TNvDesignPanel.DoIMECompositionRangeChanged(Sender: TObject; const browser: ICefBrowser;
  const selected_range: PCefRange; character_boundsCount: NativeUInt;
  const character_bounds: PCefRect);
var
  TempPRect: PCefRect;
  i        : NativeUInt;
begin
  try
    FIMECS.Acquire;

    // TChromium.OnIMECompositionRangeChanged is triggered in a different thread
    // and all functions using a IMM context need to be executed in the same
    // thread, in this case the main thread. We need to save the parameters and
    // send a message to the form to execute Panel1.ChangeCompositionRange in
    // the main thread.

    if (FDeviceBounds <> nil) then
      begin
        Finalize(FDeviceBounds);
        FDeviceBounds := nil;
      end;

    FSelectedRange := selected_range^;

    if (character_boundsCount > 0) then
      begin
        SetLength(FDeviceBounds, character_boundsCount);

        i         := 0;
        TempPRect := character_bounds;

        while (i < character_boundsCount) do
          begin
            FDeviceBounds[i] := TempPRect^;
            LogicalToDevice(FDeviceBounds[i], GlobalCEFApp.DeviceScaleFactor);

            Inc(TempPRect);
            Inc(i);
          end;
      end;

    PostMessage(Handle, CEF_IMERANGECHANGED, 0, 0);
  finally
    FIMECS.Release;
  end;

end;

procedure TNvDesignPanel.DoIMESetComposition(Sender: TObject; const aText: ustring;
  const underlines: TCefCompositionUnderlineDynArray;
  const replacement_range, selection_range: TCefRange);
begin
  FDsWeb.IMESetComposition(aText, underlines, @replacement_range, @selection_range);
end;

procedure TNvDesignPanel.DoResize;
begin
  if WindowHandle <> 0 { csDesigning in ComponentState } then
    begin
      try
        FResizeCS.Acquire;

        if FResizing then
          FPendingResize := True
        else if BufferIsResized then
          FDsWeb.Invalidate(PET_VIEW)

        else
          begin
            FResizing := True;
            FDsWeb.WasResized;
          end;
      finally
        FResizeCS.Release;
      end;
    end;
end;

// procedure TNvDesignPanel.FreeInstance;
// begin
// if not FCanClose then
// Exit;
//
// inherited;
// end;

procedure TNvDesignPanel.InitDesignBrowser(Sender: TObject);
begin
  FTimerDs.Enabled := False;
  if not(FDsWeb.CreateBrowser(nil, '')) and not(FDsWeb.Initialized) then
    FTimerDs.Enabled := True
  else
    begin
      FDsWeb.LoadUrl('http://www.google.com.br');
      // 'http://localhost:' + FDesignServer.Port + '/');
      Invalidate;
      UpdateDesign;
    end;
end;

procedure TNvDesignPanel.Invalidate;
begin
  if csDestroying in ComponentState then
    Exit;

  inherited;
  if not(csLoading in ComponentState) and not FLoading then
    UpdateDesign;
end;

procedure TNvDesignPanel.LoadUrl(url: ustring);
begin
  TTask.Run(
    procedure
    begin
      while not(FDsWeb.Initialized) do
        Sleep(10);

      FDsWeb.LoadUrl(url);

    end);
end;

procedure TNvDesignPanel.Paint;
begin
  if (FDsWeb <> nil) { and (csDesigning in ComponentState) } then
    begin
      if not(CopyBuffer) then
        begin
          Canvas.Brush.Color := Color;
          Canvas.Brush.Style := bsSolid;
          Canvas.FillRect(rect(0, 0, width, height));
        end;
    end
  else
    inherited;

end;

procedure TNvDesignPanel.PendingResizeMsg(var aMessage: TMessage);
begin
  DoResize;
end;

// procedure TNvDesignPanel.ProcessRequest(J: TJsonObject);
// procedure UpdateChildControlProps(aControl: TControl);
// var
// C         : Integer;
// ParamIndex: Integer;
// O         : TJsonObject;
// begin
// if J.Count = 0 then
// Exit;
//
// if control is an container
// if aControl is TNvWinControl then
// begin
// O := J.ExtractObject(aControl.Name);
// if O <> nil then
// TNvWinControl(aControl).ProcessRequest(O);
//
// update Child controls values
// for C := 0 to TNvWinControl(aControl).ControlCount - 1 do
// begin
// UpdateChildControlProps(TNvWinControl(aControl).Controls[C]);
// end;
// end
// else if control is an control
// else if aControl is TNvControl then
// begin
// O := J.ExtractObject(aControl.Name);
// if O <> nil then
// TNvControl(aControl).ProcessRequest(O);
// end;
// end;
//
// var
// i: Integer;
// begin
// for i := 0 to ControlCount - 1 do
// begin
// UpdateChildControlProps(Controls[i]);
// end;
// end;

procedure TNvDesignPanel.RangeChangedMsg(var aMessage: TMessage);
begin
  try
    FIMECS.Acquire;
    ChangeCompositionRange(FSelectedRange, FDeviceBounds);
  finally
    FIMECS.Release;
  end;
end;

// function TNvDesignPanel.Render: string;
// var
// // J: TJsonObject;
// // Comps: TJsonArray;
// i     : Integer;
// Script: string;
// begin
//
// // J := TJsonObject.Create;
// // try
// // with J.A['Reqs'].AddObject do
// // begin
// // S['Name'] := 'nv.report.js';
// // S['Url'] := '/nv.report.js';
// // S['Type'] := 'jsm';
// // end;
// // with J.A['Reqs'].AddObject do
// // begin
// // S['Name'] := 'nv.report.css';
// // S['Url'] := '/nv.report.css';
// // S['Type'] := 'css';
// // end;
//
// // Comps := J.A['Comps'];
//
// for i := 0 to ControlCount - 1 do
// begin
// if Controls[i] is TNvControl then
// TNvControl(Controls[i]).Render(Ajax)
// else if Controls[i] is TNvWinControl then
// TNvWinControl(Controls[i]).Render(Ajax)
// end;
// // if Assigned(FDsWeb) and Assigned(FDsWeb.Browser) then
// /// /      FDsWeb.Browser.MainFrame.ExecuteJavaScript(//
// /// /        'alert("teste");'
// /// /        , 'about:blank', 0);
// // FDsWeb.Browser.MainFrame.ExecuteJavaScript(//
// // 'window.App.FDesign = true;' + //
// // 'window.App.ParseJson(' + J.ToJSON + ');', 'about:blank', 0);
// /// /  finally
// /// /    J.Free;
// /// /  end;
//
// end;

procedure TNvDesignPanel.Resize;
begin
  inherited;
  DoResize;
end;

procedure TNvDesignPanel.ShowDevTools(MousePos: TPoint);
var
  Frm     : Forms.TForm;
  DevTools: TCEFWindowParent;
begin
  Frm             := Forms.TForm.Create(nil);
  Frm.WindowState := wsNormal;
  Frm.height      := 600;
  Frm.width       := 600;
  Frm.FormStyle   := fsStayOnTop;
  DevTools        := TCEFWindowParent.Create(Frm);
  DevTools.Parent := Frm;
  DevTools.Align  := alClient;
  Frm.Show;

  FDsWeb.ShowDevTools(MousePos, DevTools);
end;

procedure TNvDesignPanel.UpdateDesign;
begin
  if Assigned(FResizeCS) then
    begin
      FResizeCS.Acquire;
      FResizing      := False;
      FPendingResize := False;
      FResizeCS.Release;
    end;

  // if Assigned(FDsWeb) and FDsWeb.Initialized then
  // begin
  // if FLoading then
  // Exit;
  //
  // if (FRoot <> nil) and (FRoot.Ajax.Json.Count > 0) then
  // begin
  // //
  // // FContainer.Render(nil);
  // // FDsWeb.browser.MainFrame.ExecuteJavaScript( //
  // // 'window.App.FDesign = true;' +            //
  // // 'window.App.ParseJson(' + FRoot.Ajax.Json.ToJSON + ');', 'about:blank', 0);
  // // if FContainer.Ajax <> nil then
  // // FRoot.Ajax.Json.Clear;
  // end;
  // end; //
end;

procedure TNvDesignPanel.WMClose(var Msg: TMessage);
begin
  Hide;
  Free;
end;

end.
