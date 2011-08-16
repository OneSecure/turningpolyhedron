VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "clsMainMenu"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Implements IFakeDXUIEvent
Implements IFakeDXAppEvent
Implements IRenderableObject

Private m_idxForm As Long

Friend Sub Create()
If m_idxForm Then Exit Sub
'///
With FakeDXUIControls(1)
 '///main menu test
 With .AddNewChildren(FakeCtl_None, 0, 0, 0, 0, , , False, , , , , , , 1, 1)
  m_idxForm = .Index
  Set .EventObject = Me
  '///some buttons, including settings
  .AddNewChildren FakeCtl_Button, 8, -32, 80, -8, , , , , objText.GetText("Exit"), , "cmdExit", , 1, , 1, , , objText.GetText("Exit the game and return to desktop.")
  .AddNewChildren FakeCtl_Button, 208, -32, 280, -8, , , , , objText.GetText("Options"), , "cmdOptions", , 1, , 1, , , objText.GetText("Change the game settings.")
  '///following items are TEST ONLY
  .AddNewChildren(FakeCtl_Button, 108, -32, 180, -8, , , , , "Danger!!!", , "cmdDanger", , 1, , 1).ForeColor = &HFF0000
 End With
End With
End Sub

Friend Sub Show()
Create
FakeDXAppChangeRootObject &H7&, Me, Me
FakeDXUIControls(m_idxForm).Show
objCamera.MoveTargetTo Vec3
End Sub

Friend Sub Hide()
If m_idxForm Then FakeDXUIControls(m_idxForm).Hide
End Sub

Private Function IFakeDXAppEvent_OnEvent(ByVal nType As Long, ByVal nParam1 As Long, ByVal nParam2 As Long, ByVal nParam3 As Long) As Long
Dim Button As Long
'///
Select Case nType
Case FakeDXAppEvent_KeyDown 'TEST ONLY
 Select Case nParam1 'TEST ONLY
 Case vbKeyF2 'TEST ONLY
  objGame.ShowLevelFileSelection 'TEST ONLY
 Case vbKeyF3 'test only
  Dim s() As String
  Dim i As Long, m As Long
  m = objFileMgr.EnumerateFile("levels", s)
  'm = objFileMgr.EnumerateFile("texture.tar.lzma", s)
  For i = 1 To m
   Debug.Print s(i)
  Next i
 End Select 'TEST ONLY
Case FakeDXAppEvent_MouseDown
 Button = nParam3 And &HFFFF&
 Select Case Button
 Case 1, 2
  objCamera.LockCamera = Button = 2
  objCamera.BeginDrag nParam1, nParam2
 End Select
Case FakeDXAppEvent_MouseMove
 Button = nParam3 And &HFFFF&
 Select Case Button
 Case 1, 2
  objCamera.Drag nParam1, nParam2, 0.01
 End Select
Case FakeDXAppEvent_MouseWheel
 If nParam1 > 0 Then
  objCamera.Zoom 0.8
 Else
  objCamera.Zoom 1.25
 End If
End Select
End Function

Private Function IFakeDXUIEvent_OnEvent(ByVal obj As clsFakeDXUI, ByVal nType As Long, ByVal nParam1 As Long, ByVal nParam2 As Long, ByVal nParam3 As Long) As Long
Dim i As Long, bErr As Boolean
Dim obj1 As clsTreeStorageNode, v1 As D3DVECTOR
Dim s As String
'///
Select Case nType
Case FakeCtl_Event_Click
 Select Case obj.Name
 Case "cmdExit"
 ' With New clsFakeDXUIMsgBox
 '  If .MsgBox(objText.GetText("Are you sure?"), vbYesNo Or vbQuestion, objText.GetText("Exit game")) = vbYes Then Unload Me
 ' End With
  FakeDXAppRequestUnload = True '???
 Case "cmdOptions"
  frmSettings.Show
 '///TEST ONLY
 Case "cmdDanger"
  With New clsFakeCommonDialog
   If .VBGetOpenFileName(s, , , , , "XML Level file|*.xml;*.xml.lzma", , App.Path + "\data\") Then
    i = objFileMgr.LoadFile(s)
    If i > 0 Then
     Set obj1 = New clsTreeStorageNode
     With New clsXMLSerializer
      If .ReadNode(objFileMgr.FilePointer(i), objFileMgr.FileSize(i), obj1) Then
       objGameMgr.ClearLevelData
       If objGameMgr.AddLevelDataFromNode(obj1) Then
        objGameMgr.CreateLevelRuntimeData
        '///change mode TODO:
        objGame.ShowGame
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
   Show
   With New clsFakeDXUIMsgBox
    .MsgBox "Error when loading level file:" + vbCrLf + s, vbExclamation, "Error"
   End With
  End If
 End Select
End Select
End Function

Private Sub IRenderableObject_Hide()
Hide
End Sub

Private Sub IRenderableObject_Render(ByVal nType As enumRenderPassType, ByVal objRender As clsRenderPipeline, ByVal objCamera As clsCamera, ByVal IsEffectBegin As Boolean, ByVal IsSceneBegin As Boolean)
Select Case nType
Case RenderPass_Main
 If Not IsEffectBegin Then
  objRenderTest.SetTexture objTexture
  objRenderTest.SetNormalTexture objNormalTexture
  If Not objRender.BeginRender(nType) Then Exit Sub
 End If
 If Not IsSceneBegin Then d3dd9.BeginScene
 '///draw cube with effects
 objTest.DrawSubset 0
 objRenderTest.EndEffect
 '////////draw landscape test (new and buggy) without advanced shading effects
 d3dd9.SetTexture 0, objLandTexture
 objLand.Render objRender, objCamera
 '////////
 '///
 If Not IsSceneBegin Then d3dd9.EndScene
 If Not IsEffectBegin Then objRender.EndRender
Case RenderPass_FogVolume
 'TODO:
Case RenderPass_Overlay
' If Not IsSceneBegin Then d3dd9.BeginScene
' FakeDXGDIDrawText FakeDXUIDefaultFont, objText.GetText("Turning Polyhedron"), _
' 0, 16, d3dpp.BackBufferWidth, 32, , DT_CENTER Or DT_SINGLELINE Or DT_NOCLIP, , , , , , , , True
' If Not IsSceneBegin Then d3dd9.EndScene
End Select
End Sub