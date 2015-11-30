; burn2disc
; Version 1.0
; November 29, 2015
; Copyright 2015 by Jamal Mazrui
; GNU Lesser General Public License (LGPL)

Opt("MustDeclareVars", 1)
	
#include <WinAPI.au3>
#include <WinAPIShPath.au3>
#Include <File.au3>

Global $burn2disc_Error , $burn2disc_ErrorCode

global $oDevices ; DiscMaster2 object to connect to CD/DVD drives
global $oErase
global $oFSI ; File System Image
global $oRecorder ; DiscRecorder object
global $oResult ; result of creating file system image
global $oStream ; Data stream for burning device
global $oWriter

global $sSayLineExe = @scriptDir & "\" & "SayLine.exe"

; IMAPI2 Constants

; *** IMAPI2 Media Types
Const $IMAPI_MEDIA_TYPE_UNKNOWN            = 0 ; Media not present OR is unrecognized
Const $IMAPI_MEDIA_TYPE_CDROM              = 1 ; CD-ROM
Const $IMAPI_MEDIA_TYPE_CDR                = 2 ; CD-R
Const $IMAPI_MEDIA_TYPE_CDRW               = 3 ; CD-RW
Const $IMAPI_MEDIA_TYPE_DVDROM             = 4 ; DVD-ROM
Const $IMAPI_MEDIA_TYPE_DVDRAM             = 5 ; DVD-RAM
Const $IMAPI_MEDIA_TYPE_DVDPLUSR           = 6 ; DVD+R
Const $IMAPI_MEDIA_TYPE_DVDPLUSRW          = 7 ; DVD+RW
Const $IMAPI_MEDIA_TYPE_DVDPLUSR_DUALLAYER = 8 ; DVD+R dual layer
Const $IMAPI_MEDIA_TYPE_DVDDASHR           = 9 ; DVD-R
Const $IMAPI_MEDIA_TYPE_DVDDASHRW          = 10 ; DVD-RW
Const $IMAPI_MEDIA_TYPE_DVDDASHR_DUALLAYER = 11 ; DVD-R dual layer
Const $IMAPI_MEDIA_TYPE_DISK               = 12 ; Randomly writable

; IMAPI2 Data Media States
Const $IMAPI_FORMAT2_DATA_MEDIA_STATE_UNKNOWN            = 0
Const $IMAPI_FORMAT2_DATA_MEDIA_STATE_INFORMATIONAL_MASK = 15
Const $IMAPI_FORMAT2_DATA_MEDIA_STATE_UNSUPPORTED_MASK   = 61532 ;0xfc00
Const $IMAPI_FORMAT2_DATA_MEDIA_STATE_OVERWRITE_ONLY     = 1
Const $IMAPI_FORMAT2_DATA_MEDIA_STATE_BLANK              = 2
Const $IMAPI_FORMAT2_DATA_MEDIA_STATE_APPENDABLE         = 4
Const $IMAPI_FORMAT2_DATA_MEDIA_STATE_FINAL_SESSION      = 8
Const $IMAPI_FORMAT2_DATA_MEDIA_STATE_DAMAGED            = 1024 ;0x400
Const $IMAPI_FORMAT2_DATA_MEDIA_STATE_ERASE_REQUIRED     = 2048 ;0x800
Const $IMAPI_FORMAT2_DATA_MEDIA_STATE_NON_EMPTY_SESSION  = 4096 ;0x1000
Const $IMAPI_FORMAT2_DATA_MEDIA_STATE_WRITE_PROTECTED    = 8192 ;0x2000
Const $IMAPI_FORMAT2_DATA_MEDIA_STATE_FINALIZED          = 16384 ;0x4000
Const $IMAPI_FORMAT2_DATA_MEDIA_STATE_UNSUPPORTED_MEDIA  = 32768 ;0x8000

; *** CD/DVD disc file system types
Const $FileSystemISO9660 = 1
Const $FileSystemJoliet  = 2
Const $FileSystemUDF102  = 4

const $IMAPI_SECTOR_SIZE = 2048
const $IMAPI_SECTORS_PER_SECOND_AT_1X_CD = 75
const $IMAPI_SECTORS_PER_SECOND_AT_1X_DVD = 680

const $IMAPI_FEATURE_PAGE_TYPE_DVD_DASH_WRITE = 47

#cs
const $IMAPI_MEDIA_TYPE_UNKNOWN = 0x00
const $IMAPI_MEDIA_TYPE_CDROM = 0x01
const $IMAPI_MEDIA_TYPE_CDR = 0x02
const $IMAPI_MEDIA_TYPE_CDRW = 0x03
const $IMAPI_MEDIA_TYPE_DVDROM = 0x04
const $IMAPI_MEDIA_TYPE_DVDRAM = 0x05
const $IMAPI_MEDIA_TYPE_DVDPLUSR = 0x06
const $IMAPI_MEDIA_TYPE_DVDPLUSRW = 0x07
const $IMAPI_MEDIA_TYPE_DVDPLUSR_DUALLAYER = 0x08
const $IMAPI_MEDIA_TYPE_DVDDASHR = 0x09
const $IMAPI_MEDIA_TYPE_DVDDASHRW = 0x0A
const $IMAPI_MEDIA_TYPE_DVDDASHR_DUALLAYER = 0x0B
const $IMAPI_MEDIA_TYPE_DISK = 0x0C
const $IMAPI_MEDIA_TYPE_DVDPLUSRW_DUALLAYER = 0x0D
const $IMAPI_MEDIA_TYPE_HDDVDROM = 0x0E
const $IMAPI_MEDIA_TYPE_HDDVDR = 0x0F
const $IMAPI_MEDIA_TYPE_HDDVDRAM = 0x10
const $IMAPI_MEDIA_TYPE_BDROM = 0x11
const $IMAPI_MEDIA_TYPE_BDR = 0x12
const $IMAPI_MEDIA_TYPE_BDRE = 0x13
const $IMAPI_MEDIA_TYPE_MAX = 0x13
#ce

Func _burn2disc_COM_Error()
local $sText

$burn2disc_ErrorCode = 0
If IsObj($burn2disc_Error) Then
$burn2disc_ErrorCode = Hex($burn2disc_Error.number)
$sText = "COM error number: " & $burn2disc_error.number) & @CrLf
$sText &= "WinDescription: " & $burn2disc_error.WinDescription) & @CrLf
$sText &= "SourceName: " & $burn2disc_error.SourceName) & @CrLf
$sText &= "DescriptionSource: " & $burn2disc_error.DescriptionSource) & @CrLf
$sText &= "HelpFileSource: " & $burn2disc_error.HelpFileSource) & @CrLf
$sText &= "HelpContextSource: " & $burn2disc_error.HelpContextSource) & @CrLf
$sText &= "LastDLLError: " & $burn2disc_error.LastDLLError) & @CrLf
$sText &= "ScriptLine: " & $burn2disc_error.ScriptLine) & @CrLf
$burn2disc_Error.clear
_output($sText)
EndIf
EndFunc

Func _writer_Update($oSource, $oProgress)
_Output($oProgress.CurrentAction)
_output(int(100 * $oProgress.ElapsedTime / $oProgress.TotalTime) & "%")
$oSource = 0
$oProgress = 0
EndFunc

Func _Progress($array)
	_printLine("Current action: "&$array[0]&@CRLF)
	_printLine("Remaing time: "&$array[1]&@CRLF)
	_printLine("Elapsed time: "&$array[2]&@CRLF)
	_printLine("Total time: "&$array[3]&@CRLF)
EndFunc

func _destroyObjects()
$oDevices = 0
$oErase = 0
$oFSI = 0
$oRecorder = 0
$oStream = 0
$oWriter = 0
endFunc

func _getFirstOpticDrive()
$oDevices = _createDiscDevices()
if not $oDevices.Count then return ""

local $sUniqueID = $oDevices.Item(0)

$oRecorder = _createDiscRecorder()
$oRecorder.InitializeDiscRecorder($sUniqueID)

local $sPath = $oRecorder.VolumePathNames[0]
local $sDrive = StringLeft($sPath, 1)
return $sDrive
endFunc

func _initRecorderFromDrive($sDrive)
local $sPath, $sUniqueID

$oDevices = _createDiscDevices()
for $sUniqueID in $oDevices
$oRecorder = _createDiscRecorder()
$oRecorder.InitializeDiscRecorder($sUniqueID)

For $sPath in $oRecorder.VolumePathNames
if $sDrive = StringLeft($sPath, 1) Then exitLoop

$oRecorder = 0
next
next
$oDevices = 0
return $oRecorder
endFunc

func _createDiscErase()
return ObjCreate("IMAPI2.MsftDiscFormat2Erase")
endFunc

func _initEraseFromDrive($sDrive)
local $oReturn = _createDiscErase()
$oReturn.ClientName = "burn2disc"
if not isObj($oRecorder) then $oRecorder = _initRecorderFromDrive($sDrive)
$oReturn.recorder = $oRecorder
return $oReturn
EndFunc

func _createFileSystemImage()
return ObjCreate("IMAPI2FS.MsftFileSystemImage")
endFunc

func _createDataWriter()
return ObjCreate ("IMAPI2.MsftDiscFormat2Data")
endFunc

func _initWriterFromDrive($sDrive)
local $oReturn = _createDataWriter()
$oReturn.ClientName = "burn2disc"
if not isObj($oRecorder) then $oRecorder = _initRecorderFromDrive($sDrive)
$oReturn.recorder = $oRecorder
return $oReturn
endFunc

func _createDiscRecorder()
return ObjCreate("IMAPI2.MsftDiscRecorder2")
endFunc

func _createDiscDevices()
return ObjCreate("IMAPI2.MsftDiscMaster2")
endFunc

func _stringQuote($sText)
return '"' & $sText & '"'
endFunc

func _output($sText)
if $sText and FileExists($sSayLineExe) then
_Say($sText)
else
_printLine($sText)
endIf
endFunc

func _say($sText)
RunWait(_stringQuote($sSayLineExe) & " " & $sText)
endFunc

Func _printLine($sLine)
Return ConsoleWrite($sLine & @CrLf)
EndFunc

func _dirExists($sPath)
return StringInStr(FileGetAttrib($sPath), "D")
endFunc

Func _FileRead($sFile)
local $iReadMode = 0 + 16384
local $f = FileOpen($sFile, $iReadMode)
local $sBody = FileRead($f)
FileClose($f)
Return $sBody
EndFunc

Func _exit($sText)
_output($sText)
_destroyObjects()
Exit
EndFunc

Func _IMAPI2_DrivesGetID()
Local $iCount
$oDevices = _createDiscDevices()
If Not IsObj($oDevices) Then Return -1
$iCount = $oDevices.Count()
Local $aVersions[$iCount + 1]
$aVersions[0] = $iCount
For $i = 1 To $iCount
$aVersions[$i] = $oDevices.Item($i - 1)
Next
$oDevices = 0
Return $aVersions
EndFunc ;==>_IMAPI2_DrivesGetID

Func _IMAPI2_DriveGetObj($sUniqueID)
$oRecorder = _createDiscRecorder()
$oRecorder.InitializeDiscRecorder($sUniqueID)
Return $oRecorder
EndFunc ;==>_IMAPI2_DriveGetObj

Func _IMAPI2_DriveGetMedia(ByRef $oRecorder)
Local $iCode
$IMAPI2_ErrorCode = 0
$oWriter = _createDataWriter()
$iCode = Hex($oWriter.CurrentPhysicalMediaType())
$oWriter = 0
If $IMAPI2_ErrorCode <> 0 Then Return -1
Return $iCode
EndFunc ;==>_IMAPI2_DriveGetMedia

Func _IMAPI2_DriveGetSpeeds(ByRef $oRecorder)
Local $aSpeeds
Local $oWriter = _createDataWriter()
$oWriter.recorder = $oRecorder
$aSpeeds = $oWriter.SupportedWriteSpeeds()
$oWriter = ""
Return $aSpeeds
EndFunc ;==>_IMAPI2_DriveGetSpeeds

Func _IMAPI2_DriveGetSupportedMedia(ByRef $oRecorder)
local aTypes
local $i

$oWriter = _createDataWriter()
$oWriter.recorder = $oRecorder
$aTypes = $oWriter.SupportedMediaTypes()
For $i = 0 To UBound($aTypes) - 1
$aTypes[$i] = Hex($aTypes[$i], 2)
Next
$oWriter = ""
Return $aTypes
EndFunc ;==>_IMAPI2_DriveGetSupportedMedia

Func _IMAPI2_DriveMediaIsBlank(ByRef $oRecorder)
local $iResult

$oWriter = _createDataWriter()
$oWriter.recorder = $oRecorder
$iResult = $oWriter.MediaPhysicallyBlank()
$oWriter = ""
Return $iResult
EndFunc ;==>_IMAPI2_DriveMediaIsBlank

Func _IMAPI2_DriveMediaFreeSpace(ByRef $oRecorder)
local $iFreeSpace

$oWriter = _createDataWriter()
$oWriter.recorder = $oRecorder
$iFreeSpace = $oWriter.FreeSectorsOnMedia() * $IMAPI_SECTOR_SIZE
Return $iFreeSpace
EndFunc ;==>_IMAPI2_DriveMediaFreeSpace

Func _IMAPI2_DriveMediaTotalSpace(ByRef $oRecorder)
Local $iFreeSpace
$oWriter = _createDataWriter()
$oWriter.recorder = $oRecorder
$iFreeSpace = $oWriter.TotalSectorsOnMedia() * $IMAPI_SECTOR_SIZE
Return $iFreeSpace
EndFunc ;==>_IMAPI2_DriveMediaTotalSpace

Func _IMAPI2_DriveGetLetter(ByRef $oRecorder)
Local $aNames

$aNames = $oRecorder.VolumePathNames
Return StringLeft($aNames[0], 1)
EndFunc ;==>_IMAPI2_DriveGetLetter

Func _IMAPI2_DriveEject(ByRef $oRecorder)
$oRecorder.EjectMedia()
EndFunc ;==>_IMAPI2_DriveEject

Func _IMAPI2_DriveClose(ByRef $oRecorder)
$oRecorder.CloseTray()
EndFunc ;==>_IMAPI2_DriveClose

Func _IMAPI2_CreateDirectoryInFS($oFSI,$sDirName)
Local $oRootDir=$oFSI.Root
$oRootDir.AddDirectory($sDirName)
EndFunc

Func _IMAPI2_CreateFSForDrive(ByRef $oRecorder, $sDiscname)
$oFSI = _createFileSystemImage()
$oFSI.ChooseImageDefaults($oRecorder)
$oFSI.VolumeName = $sDiscname
Return $oFSI
EndFunc ;==>_IMAPI2_CreateFSForDrive

Func _IMAPI2_CreateFSForMedia($iMediaType, $sDiscname)
$oFSI = _createFileSystemImage()
$oFSI.ChooseImageDefaultsForMediaType($iMediaType)
$oFSI.VolumeName = $sDiscname
Return $oFSI
EndFunc ;==>_IMAPI2_CreateFSForMedia

Func _IMAPI2_FSCountFiles($oFSI)
Return $oFSI.FileCount()
EndFunc ;==>_IMAPI2_FSCountFiles

Func _IMAPI2_FSCountDirectories(ByRef $oFSI)
Return $oFSI.DirectoryCount()
EndFunc ;==>_IMAPI2_FSCountDirectories

Func _IMAPI2_FSItemExists(ByRef $oFSI, $sItemName)
Return $oFSI.Exists($sItemName)
EndFunc ;==>_IMAPI2_FSItemExists

Func _IMAPI2_AddFolderToFS(ByRef $oFSI, $sPath)
Local $oRootDir
$oRootDir = $oFSI.Root
$oRootDir.AddTree($sPath, False)
EndFunc ;==>_IMAPI2_AddFolderToFS

Func _IMAPI2_AddFileToFS(ByRef $oFSI, $sFileName, $sDestinationDir)
Local $oRootDir

$oRootDir = $oFSI.Root
$oStream = ObjCreate("ADODB.Stream")
$oStream.Open
$oStream.Type = 1
$oStream.LoadFromFile($sFileName)
$oRootDir.AddFile($sDestinationDir, $oStream)
EndFunc ;==>_IMAPI2_AddFileToFS

Func _IMAPI2_RemoveFolderFromFS(ByRef $oFSI, $sPath)
Local $oRootDir
$oRootDir = $oFSI.Root
$oRootDir.RemoveTree($sPath, False)
EndFunc ;==>_IMAPI2_RemoveFolderFromFS

Func _IMAPI2_RemoveFileFromFS(ByRef $oFSI, $sPath)
Local $oRootDir
$oRootDir = $oFSI.Root
$oRootDir.Remove($sPath, False)
EndFunc ;==>_IMAPI2_RemoveFolderFromFS

Func _IMAPI2_BurnFSToDrive(ByRef $oFSI, ByRef $oRecorder, $sFunction = "")

local $vStream, $iTemp
$oWriter = _createDataWriter()
$oWriter.recorder = $oRecorder
$oResult = $oFSI.CreateResultImage()
$vStream = $oResult.ImageStream
$IMAPI2_UserCallback = $sFunction
ObjEvent($oWriter, "_IMAPI2_")
$oWriter.write($vStream)
If $IMAPI2_ErrorCode Then
$iTemp = $IMAPI2_ErrorCode
$IMAPI2_ErrorCode = 0
Return $iTemp
EndIf
$oWriter = ""
EndFunc ;==>_IMAPI2_BurnFSToDrive

Func _IMAPI2_BurnImageToDrive(ByRef $oRecorder, $sImage, $sFunction = "")
local $iTemp
Local $oWriter = _createDataWriter()
$oWriter.recorder = $oRecorder
$oStream = ObjCreate("ADODB.Stream")
$oStream.Open
$oStream.Type = 1
$oStream.LoadFromFile($sImage)
$IMAPI2_UserCallback = $sFunction
ObjEvent($oWriter, "_IMAPI2_")
$oWriter.write($oStream)
If $IMAPI2_ErrorCode Then
$iTemp = $IMAPI2_ErrorCode
$IMAPI2_ErrorCode = 0
Return $iTemp
EndIf
$oWriter = ""
EndFunc ;==>_IMAPI2_BurnImageToDrive

Func _IMAPI2_DriveEraseDisc(ByRef $oRecorder)
$oErase = _createDiscErase()
$oErase.EraseMedia()
$oErase = 0
EndFunc ;==>_IMAPI2_DriveEraseDisc

Func _IMAPI2_DriveGetVendorId(ByRef $oRecorder)
Local $sTemp = $oRecorder.VendorId
Return ($sTemp)
EndFunc ;==>_IMAPI2_DriveGetVendorId

Func _IMAPI2_DriveGetProductId(ByRef $oRecorder)
Local $sTemp = $oRecorder.ProductId
Return ($sTemp)
EndFunc ;==>_IMAPI2_DriveGetProductId

Func _IMAPI2_Update($oObjThatFired, $oProgress)
Local $vArray[4]
$vArray[0] = $oProgress.CurrentAction
$vArray[1] = $oProgress.RemainingTime
$vArray[2] = $oProgress.ElapsedTime
$vArray[3] = $oProgress.TotalTime
If $IMAPI2_UserCallback Then
Call($IMAPI2_UserCallback, $vArray)
EndIf
$oObjThatFired = 0
EndFunc ;==>_IMAPI2_Update

Func _IMAPI2_COM_Error()
$IMAPI2_ErrorCode = 0
If IsObj($IMAPI2_Error) Then
$IMAPI2_ErrorCode = Hex($IMAPI2_Error.number)
$IMAPI2_Error.clear
EndIf
EndFunc ;==>_IMAPI2_COM_Error

func _burn($aPaths, $sDrive, $sDiscName = "")
; Adds data paths, files or directories, to disc (new session is added if disc already contains data)

local $iPath
local $sPath

if not IsArray($aPaths) or not $aPaths[0] then _exit("Path not found")
_output("Path count: " & $aPaths[0])

$oRecorder = _initRecorderFromDrive($sDrive)
$oWriter = _initWriterFromDrive($sDrive)
$oFSI = _createFileSystemImage()

; Import last session if disc is not empty or initialize file system if disc is empty
If Not $oWriter.MediaHeuristicallyBlank Then
$oFSI.MultisessionInterfaces = $oWriter.MultisessionInterfaces
If @error then
_output("Multisession is not supported for this disc")
exit
EndIf

_output("Importing data from previous session")
$oFSI.ImportFileSystem()
Else
$oFSI.ChooseImageDefaults($oRecorder)
EndIf

; Add data paths to file system
For $iPath = 1 to $aPaths[0] 
$sPath = $aPaths[$iPath]
if _DirExists($sPath) then
_output("Adding directory " & $sPath)
$oFSI.Root.AddTree($sPath, true)
elseIf FileExists($sPath) then
_output("Adding file " & $sPath)
$oFSI.Root.AddTree($sPath, false)
elseIf $iPath = 1 then
$sDiscName = $sPath
$oFSI.VolumeName = $sDiscname
endif
next

$oResult = $oFSI.CreateResultImage()
$oStream = $oResult.ImageStream

; Write stream to disc using recorder
_output("Writing data to disc")
; $IMAPI2_UserCallback = "_progress"
; ObjEvent($oWriter, "_IMAPI2_")
ObjEvent($oWriter, "_writer_")
$oWriter.Write($oStream)

_output("Done")
EndFunc

func _close($sDrive)
$oRecorder = _initRecorderFromDrive($sDrive)
$oRecorder.CloseTray()
EndFunc

Func _devices()
local $i, $iIndex ; Index to recording drive
local $oCurrentFeature, $oCurrentProfile, $oSupportedFeature, $oSupportedModePage, $oSupportedProfile
local $sMountPoint, $sPath, $sUniqueID


$oDevices = _createDiscDevices()
_output("Is Supported Environment: " & $oDevices.IsSupportedEnvironment)

for $sUniqueID in $oDevices
$oRecorder = _createDiscRecorder()
$oRecorder.InitializeDiscRecorder( $sUniqueID )

_output("ActiveRecorderId: " & $oRecorder.ActiveDiscRecorder)
_output("Vendor Id: " & $oRecorder.VendorId)
_output("Product Id: " & $oRecorder.ProductId)
_output("Product Revision: " & $oRecorder.ProductRevision)
_output("VolumeName: " & $oRecorder.VolumeName)
_output("Can Load Media: " & $oRecorder.DeviceCanLoadMedia)
_output("Legacy Device Number: " & $oRecorder.LegacyDeviceNumber)

_output("")
For $sMountPoint in $oRecorder.volumePathNames
_output("Mount Point: " & $sMountPoint)
Next

; not useful output without more translations from numbers to words
#CS
_output("")
_output("Supported Features") ;in _IMAPI_FEATURE_PAGE_TYPE
For $oSupportedFeature in $oRecorder.supportedFeaturePages
if $oSupportedFeature = $IMAPI_FEATURE_PAGE_TYPE_DVD_DASH_WRITE then
_output("Feature: " & $oSupportedFeature & "  Drive supports DVD-RW")
else
_output("Feature: " & $oSupportedFeature)
endif
Next

_output("")
_output("Current Features") ;in _IMAPI_FEATURE_PAGE_TYPE
For $oCurrentFeature in $oRecorder.CurrentFeaturePages
_output("Feature: " & $oCurrentFeature)
Next

_output("")
_output("Supported Profiles") ;in _IMAPI_PROFILE_TYPE
For $oSupportedProfile in $oRecorder.SupportedProfiles
_output("Profile: " & $oSupportedProfile)
Next

_output("")
_output("Current Profiles") ;in _IMAPI_PROFILE_TYPE
For $oCurrentProfile in $oRecorder.CurrentProfiles
_output("Profile: " & $oCurrentProfile)
Next

_output("")
_output("Supported Mode Pages") ;in  _IMAPI_MODE_PAGE_TYPE
For $oSupportedModePage in $oRecorder.SupportedModePages
_output("Mode Page: " & $oSupportedModePage)
next
#CE
Next
EndFunc

func _erase($sDrive)
local $iResult

_output("Erasing drive " & $sDrive)
$oErase = _initEraseFromDrive($sDrive)
$oErase.FullErase = true
$iResult = $oErase.EraseMedia()
$oWriter = _initWriterFromDrive($sDrive)
; $iResult = $oWriter.MediaPhysicallyBlank()
$iResult = $oWriter.MediaHeuristicallyBlank()
_output("Erase result: " & $iResult)
EndFunc

Func _media($sDrive)
; Examines characteristics of media loaded in disc device, checking media type, media state, recorder and media compatibility

local $bResult

_output("Drive " & $sDrive)
$oRecorder = _initRecorderFromDrive($sDrive)
$oWriter = _initWriterFromDrive($sDrive)

$bResult = $oWriter.IsRecorderSupported($oRecorder)
If $bResult then
_output("Current recorder IS supported")
else
_output("Current recorder IS NOT supported")
Endif

$bResult = $oWriter.IsCurrentMediaSupported($oRecorder)
If $bResult then
_output("Current media IS supported")
else
_output("Current media IS NOT supported")
Endif

_output("ClientName = " & $oWriter.ClientName)

; Check a few CurrentMediaStatus possibilities
; Each status is associated with a bit and some combinations are legal

local $iCurMediaStatus
$iCurMediaStatus = $oWriter.CurrentMediaStatus
_output("Checking Current Media Status")

if BitAnd($IMAPI_FORMAT2_DATA_MEDIA_STATE_UNKNOWN, $iCurMediaStatus) then
_output("Media state is unknown")
Endif

if BitAnd($IMAPI_FORMAT2_DATA_MEDIA_STATE_OVERWRITE_ONLY, $iCurMediaStatus) then
_output("Currently, only overwriting is supported")
Endif

if BitAnd($IMAPI_FORMAT2_DATA_MEDIA_STATE_APPENDABLE, $iCurMediaStatus) then
_output("Media is currently appendable")
Endif

if BitAnd($IMAPI_FORMAT2_DATA_MEDIA_STATE_FINAL_SESSION, $iCurMediaStatus) then
_output("Media is in final writing session")
Endif

if BitAnd($IMAPI_FORMAT2_DATA_MEDIA_STATE_DAMAGED, $iCurMediaStatus) then
_output("Media is damaged")
Endif

local $iMediaType
$iMediaType = $oWriter.CurrentPhysicalMediaType
_output("Current Media Type")
DisplayMediaType($iMediaType)

EndFunc

Func DisplayMediaType($iMediaType)
Switch $iMediaType
Case $IMAPI_MEDIA_TYPE_UNKNOWN
_output("Empty device or an unknown disc type")

Case $IMAPI_MEDIA_TYPE_CDROM
_output("CD-ROM")

Case $IMAPI_MEDIA_TYPE_CDR
_output("CD-R")

Case $IMAPI_MEDIA_TYPE_CDRW
_output("CD-RW")

Case $IMAPI_MEDIA_TYPE_DVDROM
_output("Read-only DVD drive and/or disc")

Case $IMAPI_MEDIA_TYPE_DVDRAM
_output("DVD-RAM")

Case $IMAPI_MEDIA_TYPE_DVDPLUSR
_output("DVD+R")

Case $IMAPI_MEDIA_TYPE_DVDPLUSRW
_output("DVD+RW")

Case $IMAPI_MEDIA_TYPE_DVDPLUSR_DUALLAYER
_output("DVD+R Dual Layer media")

Case $IMAPI_MEDIA_TYPE_DVDDASHR
_output("DVD-R")

Case $IMAPI_MEDIA_TYPE_DVDDASHRW
_output("DVD-RW")

Case $IMAPI_MEDIA_TYPE_DVDDASHR_DUALLAYER
_output("DVD-R Dual Layer media")

Case $IMAPI_MEDIA_TYPE_DISK
_output("Randomly-writable, hardware-defect " + "managed media type ")
_output("that reports the ""Disc"" profile " + "as current")
EndSwitch
EndFunc

func _space($sDrive)
local $iFreeSpace, $iTotalSpace

_output("Checking space on drive " & $sDrive)
$oWriter = _initWriterFromDrive($sDrive)
$iFreeSpace = $oWriter.FreeSectorsOnMedia() * $IMAPI_SECTOR_SIZE
$iTotalSpace = $oWriter.TotalSectorsOnMedia() * $IMAPI_SECTOR_SIZE
_output(Int(100 * $iFreeSpace / $iTotalSpace) &"% free (" & $iFreeSpace & " out of " &$iTotalSpace & " bytes)")
endFunc

func _open($sDrive)
$oRecorder = _initRecorderFromDrive($sDrive)
$oRecorder.EjectMedia()
EndFunc

; Main program
local $aPaths
local $iPath, $iParamCount
local $sDir, $sDrive, $sSpec, $sTask

$burn2disc_Error = ObjEvent("AutoIt.Error", "_burn2disc_COM_Error")

$iParamCount = $CMDLine[0]
If not $iParamCount Then _exit("Syntax:" & @CrLf & "burn2disc Command Argument Drive")

$sTask = $CmdLine[1]

if $sTask = "match" or $sTask = "list" then
if $iParamCount < 2 then _exit("provide a file specification as a second parameter to this task")

$sSpec = $CMDLine[2]
If $iParamCount > 2 then $sDrive = $CMDLine[3]

elseIf $iParamCount > 1 then
$sDrive = $CMDLine[2]
endIf

if not $sDrive then $sDrive = _getFirstOpticDrive()

switch $sTask
case "match"
; _output("sPec: " & $sSpec)
if false then
; if _dirExists($sSpec) then
$sDir = $sSpec
$sSpec = "*.*"
else
$sDir = _WinAPI_PathRemoveFileSpec($sSpec)
if not $sDir then $sDir = @workingDir
$sSpec = _WinAPI_PathFindFileName($sSpec)
if not $sSpec then $sSpec = "*.*"
endIf
; _output("sDir: " & $sDir)
; _output("sPec: " & $sSpec)
; $sSpec = _WinAPI_PathStrip($sSpec)
; $aPaths = _FileListToArray($sDir, $sSpec)
$aPaths = _FileListToArray($sDir, $sSpec, $FLTA_FILESFOLDERS, true)
if @Error then _exit("error " & @error)

#CS
for $sPath in $aPaths
_output($sPath)
next

for $iPath = 1 to $aPaths[0]
$sPath = $sDir & "\" & $aPaths[$iPath]
$aPaths[$iPath] = $sPath
next
#CE
_burn($aPaths, $sDrive)
case "close"
_close($sDrive)
case "devices"
_devices()
case "erase"
_erase($sDrive)
case "help"
_help()
case "list"
_FileReadToArray($sSpec, $aPaths)
_burn($aPaths, $sDrive)
case "media"
_media($sDrive)
case "open"
_open($sDrive)
case "replace"
_replace($aPaths, $sDrive)
case "space"
_space($sDrive)
case else
_exit("Invalid command")
EndSwitch
_destroyObjects()

