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
   Begin VB.CommandButton Command2 
      Caption         =   "Windowed"
      Height          =   375
      Left            =   120
      TabIndex        =   1
      Top             =   600
      Visible         =   0   'False
      Width           =   1095
   End
   Begin VB.Timer Timer1 
      Interval        =   50
      Left            =   3480
      Top             =   1440
   End
   Begin VB.CommandButton Command1 
      Caption         =   "Exit"
      Height          =   375
      Left            =   120
      TabIndex        =   0
      Top             =   120
      Visible         =   0   'False
      Width           =   1095
   End
End
Attribute VB_Name = "frmMain"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit

Private objTest As D3DXMesh
Private objDrawTest As New clsSimplex, objRenderTest As New clsRenderPipeline

Private objTexture As Direct3DTexture9

Private Sub Command1_Click()
Unload Me
End Sub

Private Sub Command2_Click()
On Error Resume Next
d3dpp.Windowed = 1
'd3dpp.BackBufferWidth = 800
'd3dpp.BackBufferHeight = 600 'then change the window's size manually
d3dd9.Reset d3dpp
Me.Refresh
End Sub

Private Sub Form_KeyDown(KeyCode As Integer, Shift As Integer)
If KeyCode = vbKeyS And Shift = vbCtrlMask Then
   '///test
   SaveRenderTargetToFile objTexture, CStr(App.Path) + "\test.bmp", D3DXIFF_BMP
   '///
End If
End Sub

Private Sub Form_Load()
On Error Resume Next
Set d3d9 = Direct3DCreate9(D3D_SDK_VERSION)
If d3d9 Is Nothing Then
 MsgBox "Can't create D3D9!!!", vbExclamation, "Fatal Error"
 Form_Unload 0
 End
End If
With d3dpp
 .hDeviceWindow = Me.hWnd
 .SwapEffect = D3DSWAPEFFECT_DISCARD
 .BackBufferCount = 1
 .BackBufferFormat = D3DFMT_X8R8G8B8
 .BackBufferWidth = 640
 .BackBufferHeight = 480
 .Windowed = 1
 .hDeviceWindow = Me.hWnd
 .EnableAutoDepthStencil = 1
 .AutoDepthStencilFormat = D3DFMT_D24S8
 '.PresentationInterval = D3DPRESENT_INTERVAL_IMMEDIATE
 '.MultiSampleType = D3DMULTISAMPLE_4_SAMPLES
End With
'create device
Set d3dd9 = d3d9.CreateDevice(0, D3DDEVTYPE_HAL, Me.hWnd, D3DCREATE_HARDWARE_VERTEXPROCESSING, d3dpp)
If d3dd9 Is Nothing Then
 MsgBox "Can't create device!!!", vbExclamation, "Fatal Error"
 Form_Unload 0
 End
End If
pSetRenderState
End Sub

Private Sub pSetRenderState()
'test only
Dim mat As D3DMATRIX
Dim v0 As D3DVECTOR, v1 As D3DVECTOR, v2 As D3DVECTOR
With d3dd9
 .SetRenderState D3DRS_LIGHTING, 0
 .SetSamplerState 0, D3DSAMP_MIPFILTER, D3DTEXF_LINEAR
 .SetSamplerState 0, D3DSAMP_MINFILTER, D3DTEXF_LINEAR
 .SetSamplerState 0, D3DSAMP_MAGFILTER, D3DTEXF_LINEAR
 D3DXMatrixPerspectiveFovLH mat, Atn(1), Me.ScaleWidth / Me.ScaleHeight, 0.1, 100
 .SetTransform D3DTS_PROJECTION, mat
 v0.x = 0 '2
 v0.y = 6
 v0.z = 3
 v2.z = 10
 D3DXMatrixLookAtLH mat, v0, v1, v2
 .SetTransform D3DTS_VIEW, mat
 '///
 .SetTextureStageState 0, D3DTSS_COLOROP, D3DTOP_SELECTARG1
 .SetTextureStageState 0, D3DTSS_COLORARG1, D3DTA_TEXTURE
 .SetSamplerState 0, D3DSAMP_ADDRESSU, D3DTADDRESS_CLAMP
 .SetSamplerState 0, D3DSAMP_ADDRESSV, D3DTADDRESS_CLAMP
 '///
 .SetRenderState D3DRS_CULLMODE, D3DCULL_CCW
 '.SetRenderState D3DRS_NORMALIZENORMALS, 1
End With
'//////test
'D3DXCreateBox d3dd9, 2, 2, 4, objTest, Nothing 'no texcoord
'D3DXCreateTeapot d3dd9, objTest, Nothing 'no texcoord
objDrawTest.Create
Set objTest = pTest
D3DXCreateTexture d3dd9, 1024, 512, 1, D3DUSAGE_RENDERTARGET, D3DFMT_A8R8G8B8, 0, objTexture
'///
objRenderTest.Create
'objRenderTest.SetLightDirectionByVal 0, 1, 1, True
objRenderTest.SetLightPositionByVal 0, 2, 1.5
objRenderTest.SetLightType D3DLIGHT_POINT
'///
End Sub

Private Sub Form_Unload(Cancel As Integer)
Set objDrawTest = Nothing
Set objTest = Nothing
Set objTexture = Nothing
Set d3dd9 = Nothing
Set d3d9 = Nothing
End Sub

Private Function pTest() As D3DXMesh
Dim obj As D3DXMesh
'bug in x file loader: you must write "1.000" instead of "1" or it'll buggy :-3
D3DXLoadMeshFromXW CStr(App.Path) + "\media\cube1_1.x", 0, d3dd9, Nothing, Nothing, Nothing, 0, obj
'D3DXLoadMeshFromXW CStr(App.Path) + "\media\poly20.x", 0, d3dd9, Nothing, Nothing, Nothing, 0, obj
'Set obj = obj.CloneMeshFVF(0, m_nDefaultFVF, d3dd9)
'///recalculate normal
D3DXComputeNormals obj, ByVal 0
'///
Set pTest = obj
End Function

Private Sub Timer1_Timer()
On Error Resume Next
Dim i As Long
Dim mat As D3DMATRIX, mat1 As D3DMATRIX
Static j As Long
With d3dd9
 i = .TestCooperativeLevel
 If i = D3DERR_DEVICENOTRESET Then
  .Reset d3dpp
'  j = 0
  i = .TestCooperativeLevel
  Debug.Print "Reset"
 End If
 If i = 0 Then
  If j = 0 Then
   'render texture
   objDrawTest.BeginRenderToTexture objTexture
   .Clear 0, ByVal 0, D3DCLEAR_TARGET, 0, 1, 0
   .BeginScene
   objTest.DrawSubset 0
   objTest.DrawSubset 1 '???? draw seal
   .EndScene
   objDrawTest.EndRenderToTexture
   j = 1
  End If
   D3DXMatrixRotationZ mat1, 0.03
   .GetTransform D3DTS_WORLD, mat
   D3DXMatrixMultiply mat, mat1, mat
   .SetTransform D3DTS_WORLD, mat
   '///
   objRenderTest.SetTexture objTexture
   objRenderTest.BeginRender
   .Clear 0, ByVal 0, D3DCLEAR_TARGET Or D3DCLEAR_ZBUFFER, 0, 1, 0
   .BeginScene
'   .SetTexture 0, objTexture
   objTest.DrawSubset 0
   .EndScene
   objRenderTest.EndRender
'   j = 1
'  End If
  .Present ByVal 0, ByVal 0, 0, ByVal 0
 End If
End With
'Command1.Refresh
'Command2.Refresh
End Sub
