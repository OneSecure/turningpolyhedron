VERSION 5.00
Begin VB.Form frmMain 
   BorderStyle     =   1  'Fixed Single
   Caption         =   "Form1"
   ClientHeight    =   7200
   ClientLeft      =   45
   ClientTop       =   435
   ClientWidth     =   9600
   BeginProperty Font 
      Name            =   "Tahoma"
      Size            =   8.25
      Charset         =   0
      Weight          =   400
      Underline       =   0   'False
      Italic          =   0   'False
      Strikethrough   =   0   'False
   EndProperty
   KeyPreview      =   -1  'True
   LinkTopic       =   "Form1"
   MaxButton       =   0   'False
   ScaleHeight     =   480
   ScaleMode       =   3  'Pixel
   ScaleWidth      =   640
   StartUpPosition =   3  '����ȱʡ
End
Attribute VB_Name = "frmMain"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit

Private Declare Sub CopyMemory Lib "kernel32.dll" Alias "RtlMoveMemory" (ByRef Destination As Any, ByRef Source As Any, ByVal Length As Long)

Private Declare Function GetCursorPos Lib "user32.dll" (ByRef lpPoint As POINTAPI) As Long
Private Declare Function GetAsyncKeyState Lib "user32.dll" (ByVal vKey As Long) As Integer
Private Declare Function ScreenToClient Lib "user32.dll" (ByVal hwnd As Long, ByRef lpPoint As POINTAPI) As Long
Private Type POINTAPI
    x As Long
    y As Long
End Type

Implements IFakeDXUIEvent

Private Const WM_INPUTLANGCHANGE As Long = &H51
Private Const WM_IME_COMPOSITION As Long = &H10F
Private Const WM_IME_STARTCOMPOSITION As Long = &H10D
Private Const WM_IME_ENDCOMPOSITION As Long = &H10E
Private Const WM_IME_NOTIFY As Long = &H282
Private Const WM_MOUSEWHEEL As Long = &H20A

'TODO:mouseleave event

Private cSub As New cSubclass

Implements iSubclass

Private Sub Form_DblClick()
Dim p As POINTAPI
GetCursorPos p
ScreenToClient Me.hwnd, p
Call FakeDXUIOnMouseEvent(1, 0, p.x, p.y, 4)
End Sub

Private Sub Form_KeyDown(KeyCode As Integer, Shift As Integer)
'///TEST ONLY
Dim v1 As D3DVECTOR, v2 As D3DVECTOR, v3 As D3DVECTOR
Dim i As Long
'///
If FakeDXUIOnKeyEvent(KeyCode, Shift, 1) Then Exit Sub
'///
If KeyCode = vbKeyS And Shift = vbCtrlMask Then
   '///test
   D3DXSaveTextureToFileW CStr(App.Path) + "\test.bmp", D3DXIFF_BMP, objTexture, ByVal 0
   D3DXSaveTextureToFileW CStr(App.Path) + "\testnormal.bmp", D3DXIFF_BMP, objNormalTexture, ByVal 0
   '///
End If
'///TEST ONLY
If bTestOnly Then
 i = -1
 Select Case KeyCode
 Case vbKeyUp
  i = 0
 Case vbKeyLeft
  i = 1
 Case vbKeyDown
  i = 2
 Case vbKeyRight
  i = 3
 Case vbKeySpace
  'TODO:when a polyhedron is falling then can't change polyhedron index
  i = objGameMgr.CurrentPolyhedron + 1
  If i > objGameMgr.PolyhedronCount Then i = 1
  objGameMgr.CurrentPolyhedron = i
  Exit Sub
 Case vbKeyR
  objGameMgr.ResetOnNextUpdate = True
  Exit Sub
 End Select
 If i >= 0 Then
  If Not objGameMgr.CurrentPolyhedronObject Is Nothing Then
   '///
   objCamera.GetRealCamera v1, v2, v3
   v1.x = v1.x - v2.x
   v1.y = v1.y - v2.y
   v2.x = v1.x - v1.y
   v2.y = v1.x + v1.y
   If v2.x > 0 Then
    If v2.y > 0 Then i = i + 1 _
    Else i = i + 2
   Else
    If v2.y < 0 Then i = i - 1
   End If
   i = i And 3&
   '///
   If Not objGameMgr.IsCurrentPolyhedronMoving Then
    If objGameMgr.MoveCurrentPolyhedron(i) = 1 Then
     'nothing need to do
    End If
   End If
  End If
 End If
End If
End Sub

Private Sub Form_KeyPress(KeyAscii As Integer)
'///
If FakeDXUIOnKeyEvent(KeyAscii, 0, 0) Then Exit Sub
'///
End Sub

Private Sub Form_KeyUp(KeyCode As Integer, Shift As Integer)
'///
If FakeDXUIOnKeyEvent(KeyCode, Shift, 2) Then Exit Sub
'///
End Sub

Private Sub Form_Load()
FakeDXAppInit Me, cSub, Me, Me
'///
FakeDXAppMainLoop
'///
FakeDXAppDestroy
'///
End Sub

Private Sub Form_MouseDown(Button As Integer, Shift As Integer, x As Single, y As Single)
'///
If FakeDXUIOnMouseEvent(Button, Shift, x, y, 1) Then Exit Sub
'///
Select Case Button
Case 1, 2
 objCamera.LockCamera = Button = 2
 objCamera.BeginDrag x, y
 FakeDXUISetCapture = -1
End Select
End Sub

Private Sub Form_MouseMove(Button As Integer, Shift As Integer, x As Single, y As Single)
'///
If FakeDXUIOnMouseEvent(Button, Shift, x, y, 0) Then Exit Sub
'///
Select Case Button
Case 1, 2
 objCamera.Drag x, y, 0.01
End Select
End Sub

Private Sub Form_MouseUp(Button As Integer, Shift As Integer, x As Single, y As Single)
'///
If FakeDXUIOnMouseEvent(Button, Shift, x, y, 2) Then Exit Sub
'///
FakeDXUISetCapture = 0
End Sub

Private Sub Form_QueryUnload(Cancel As Integer, UnloadMode As Integer)
cSub.UnSubclass
FakeDXAppRequestUnload = True
Cancel = &H1& And Not FakeDXAppCanUnload
End Sub

Private Function IFakeDXUIEvent_OnEvent(ByVal obj As clsFakeDXUI, ByVal nType As Long, ByVal nParam1 As Long, ByVal nParam2 As Long, ByVal nParam3 As Long) As Long
Dim i As Long, bErr As Boolean
Dim obj1 As clsTreeStorageNode, v1 As D3DVECTOR
Dim s As String
'///
Select Case nType
Case FakeCtl_Event_Click
 Select Case obj.Name
 Case "cmdClose"
  i = FakeDXUIFindControl("frmTopmost")
  If i Then FakeDXUIControls(i).Unload
 Case "cmdExit"
 ' With New clsFakeDXUIMsgBox
 '  If .MsgBox(objText.GetText("Are you sure?"), vbYesNo Or vbQuestion, objText.GetText("Exit game")) = vbYes Then Unload Me
 ' End With
  Unload Me
 Case "cmdDanger"
  With New clsFakeCommonDialog
   If .VBGetOpenFileName(s, , , , , "XML Level file|*.xml", , App.Path + "\data\") Then
    i = objFileMgr.LoadFile(s)
    If i > 0 Then
     Set obj1 = New clsTreeStorageNode
     With New clsXMLSerializer
      If .ReadNode(objFileMgr.FilePointer(i), objFileMgr.FileSize(i), obj1) Then
       objGameMgr.ClearLevelData
       If objGameMgr.AddLevelDataFromNode(obj1) Then
        objGameMgr.CreateLevelRuntimeData
        '///
        bTestOnly = True 'change mode
        '///
       Else
        bErr = True
       End If
      Else
       bErr = True
      End If
     End With
     objFileMgr.CloseFile i
    Else
     bErr = True
    End If
   End If
  End With
  If bErr Then
   With New clsFakeDXUIMsgBox
    .MsgBox "Error when loading level file:" + vbCrLf + s, vbExclamation, "Error"
   End With
  End If
 Case "Check1"
  i = FakeDXUIFindControl("Check2")
  If i Then FakeDXUIControls(i).Enabled = obj.Value
 Case "Check2"
  bTestOnly = obj.Value
 Case "cmdOptions"
  frmSettings.Show
 End Select
Case FakeCtl_Event_Change
 Select Case obj.Name
 Case "Slider1"
  i = FakeDXUIFindControl("Progress1")
  If i Then
   With FakeDXUIControls(i)
    .Caption = Format(obj.Value / 100, "0%")
    .Value = obj.Value
    objRenderTest.OrenNayarRoughness = obj.Value / 100
   End With
  End If
 End Select
 'i = FakeDXUIFindControl("Label1")
 'If i Then FakeDXUIControls(i).Caption = CStr(obj.Value) + "," + CStr(obj.Value(1))
End Select
End Function

Private Sub iSubclass_After(lReturn As Long, ByVal hwnd As Long, ByVal uMsg As Long, ByVal wParam As Long, ByVal lParam As Long)
Dim i As Long
Dim p As POINTAPI
Select Case uMsg
Case WM_IME_NOTIFY
 FakeDXUI_IME.OnIMENotify wParam, lParam
Case WM_IME_COMPOSITION, WM_IME_STARTCOMPOSITION, WM_IME_ENDCOMPOSITION
 FakeDXUI_IME.OnIMEComposition wParam, lParam
Case WM_INPUTLANGCHANGE
 FakeDXUI_IME.OnInputLanguageChange
Case WM_MOUSEWHEEL
 i = (wParam And &HFFFF0000) \ &H10000
' p.x = (lParam And &H7FFF&) Or (&HFFFF8000 And ((lParam And &H8000&) <> 0))
' p.y = (lParam And &HFFFF0000) \ &H10000
 GetCursorPos p
 ScreenToClient Me.hwnd, p
 OnMouseWheel (wParam And 3&) Or (vbMiddleButton And ((wParam And &H10&) <> 0)), _
 ((wParam And &HC&) \ 4&) Or (vbAltMask And ((GetAsyncKeyState(vbKeyMenu) And &H8000&) <> 0)), p.x, p.y, i \ 120&
End Select
End Sub

Private Sub iSubclass_Before(bHandled As Boolean, lReturn As Long, hwnd As Long, uMsg As Long, wParam As Long, lParam As Long)
'
End Sub

Friend Sub OnMouseWheel(ByVal Button As MouseButtonConstants, ByVal Shift As ShiftConstants, ByVal x As Long, ByVal y As Long, ByVal nDelta As Long)
If FakeDXUIOnMouseWheel(nDelta, Shift) Then Exit Sub
'etc.
If nDelta > 0 Then
 objCamera.Zoom 0.8
Else
 objCamera.Zoom 1.25
End If
End Sub

