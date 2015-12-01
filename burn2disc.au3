; burn2disc
; Version 1.0
; November 30, 2015
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

; CD/DVD disc file system types
const $FsiFileSystemISO9660 = 1
const $FsiFileSystemJoliet  = 2
const $FsiFileSystemUDF102  = 4

; IFormat2Data Write Action Enumerations
const $IMAPI_FORMAT2_DATA_WRITE_ACTION_VALIDATING_MEDIA      = 0
const $IMAPI_FORMAT2_DATA_WRITE_ACTION_FORMATTING_MEDIA      = 1
const $IMAPI_FORMAT2_DATA_WRITE_ACTION_INITIALIZING_HARDWARE = 2
const $IMAPI_FORMAT2_DATA_WRITE_ACTION_CALIBRATING_POWER     = 3
const $IMAPI_FORMAT2_DATA_WRITE_ACTION_WRITING_DATA          = 4
const $IMAPI_FORMAT2_DATA_WRITE_ACTION_FINALIZATION          = 5
const $IMAPI_FORMAT2_DATA_WRITE_ACTION_COMPLETED             = 6
const $IMAPI_FORMAT2_DATA_WRITE_ACTION_VERIFYING             = 7

; IMAPI2 Media Types
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

func _getErrorMessage($iError)
static $bInitialized = false
local $s = ""

if not $bInitialized then
_setConstants()
$bInitialized = true
endIf

switch $iError
case $E_IMAPI_BURN_VERIFICATION_FAILED
$s = " The disc did not pass burn verification and may contain corrupt data or be unusable."
case $E_IMAPI_REQUEST_CANCELLED
$s = " The request was canceled."
case $E_IMAPI_RECORDER_REQUIRED
$s = " The request requires a current disc recorder to be selected."
case $S_IMAPI_WRITE_NOT_IN_PROGRESS
$s = " No write operation is currently in progress."
case $S_IMAPI_SPEEDADJUSTED
$s = " The requested write speed was not supported by the drive and the speed was adjusted."
case $S_IMAPI_ROTATIONADJUSTED
$s = " The requested rotation type was not supported by the drive and the rotation type was adjusted."
case $S_IMAPI_BOTHADJUSTED
$s = " The requested write speed and rotation type were not supported by the drive and they were both adjusted."
case $S_IMAPI_COMMAND_HAS_SENSE_DATA
$s = " The device accepted the command, but returned sense data, indicating an error."
case $E_IMAPI_RAW_IMAGE_IS_READ_ONLY
$s = " The image has become read-only due to a call to IRawCDImageCreator::CreateResultImage. As a result the object can no longer be modified."
case $E_IMAPI_RAW_IMAGE_TOO_MANY_TRACKS
$s = " No more tracks may be added. CD media is restricted to a range of 1-99 tracks."
case $E_IMAPI_RAW_IMAGE_NO_TRACKS
$s = " Tracks must be added to the image before using this function."
case $E_IMAPI_RAW_IMAGE_SECTOR_TYPE_NOT_SUPPORTED
$s = " The requested sector type is not supported."
case $E_IMAPI_RAW_IMAGE_TRACKS_ALREADY_ADDED
$s = " Tracks may not be added to the image prior to the use of this function."
case $E_IMAPI_RAW_IMAGE_INSUFFICIENT_SPACE
$s = " Adding this track would exceed the limitations of the start of the leadout."
case $E_IMAPI_RAW_IMAGE_TOO_MANY_TRACK_INDEXES
$s = " Adding this track would exceed the 99 index limit."
case $E_IMAPI_RAW_IMAGE_TRACK_INDEX_NOT_FOUND
$s = " The specified LBA offset is not in the list of track indexes."
case $S_IMAPI_RAW_IMAGE_TRACK_INDEX_ALREADY_EXISTS
$s = " The specified LBA offset is already in the list of track indexes."
case $E_IMAPI_RAW_IMAGE_TRACK_INDEX_OFFSET_ZERO_CANNOT_BE_CLEARED
$s = " Index 1 (LBA offset zero) cannot be cleared."
case $E_IMAPI_RAW_IMAGE_TRACK_INDEX_TOO_CLOSE_TO_OTHER_INDEX
$s = " Each index must have a minimum size of ten sectors."
case $E_IMAPI_RECORDER_NO_SUCH_MODE_PAGE
$s = " The device reported that the requested mode page (and type) is not present."
case $E_IMAPI_RECORDER_MEDIA_NO_MEDIA
$s = " There is no media in the device."
case $E_IMAPI_RECORDER_MEDIA_INCOMPATIBLE
$s = " The media is not compatible or of unknown physical format."
case $E_IMAPI_RECORDER_MEDIA_UPSIDE_DOWN
$s = " The media is inserted upside down."
case $E_IMAPI_RECORDER_MEDIA_BECOMING_READY
$s = " The drive reported that it is in the process of becoming ready. Please try the request again later."
case $E_IMAPI_RECORDER_MEDIA_FORMAT_IN_PROGRESS
$s = " The media is currently being formatted. Please wait for the format to complete before attempting to use the media."
case $E_IMAPI_RECORDER_MEDIA_BUSY
$s = " The drive reported that it is performing a long-running operation, such as finishing a write. The drive may be unusable for a long period of time."
case $E_IMAPI_RECORDER_INVALID_MODE_PARAMETERS
$s = " The drive reported that the combination of parameters provided in the mode page for a MODE SELECT command were not supported."
case $E_IMAPI_RECORDER_MEDIA_WRITE_PROTECTED
$s = " The drive reported that the media is write protected."
case $E_IMAPI_RECORDER_NO_SUCH_FEATURE
$s = " The feature page requested is not supported by the device."
case $E_IMAPI_RECORDER_FEATURE_IS_NOT_CURRENT
$s = " The feature page requested is supported, but is not marked as current."
case $E_IMAPI_RECORDER_GET_CONFIGURATION_NOT_SUPPORTED
$s = " The drive does not support the GET CONFIGURATION command."
case $E_IMAPI_RECORDER_COMMAND_TIMEOUT
$s = " The device failed to accept the command within the timeout period. This may be caused by the device having entered an inconsistent state, or the timeout value for the command may need to be increased."
case $E_IMAPI_RECORDER_DVD_STRUCTURE_NOT_PRESENT
$s = " The DVD structure is not present. This may be caused by incompatible drive/medium used."
case $E_IMAPI_RECORDER_MEDIA_SPEED_MISMATCH
$s = " The media's speed is incompatible with the device. This may be caused by using higher or lower speed media than the range of speeds supported by the device."
case $E_IMAPI_RECORDER_LOCKED
$s = " The device associated with this recorder during the last operation has been exclusively locked, causing this operation to fail."
case $E_IMAPI_RECORDER_CLIENT_NAME_IS_NOT_VALID
$s = " The client name is not valid."
case $E_IMAPI_RECORDER_INVALID_RESPONSE_FROM_DEVICE
$s = " The device reported unexpected or invalid data for a command."
case $E_IMAPI_LOSS_OF_STREAMING
$s = " The write failed because the drive did not receive data quickly enough to continue writing. Moving the source data to the local computer, reducing the write speed, or enabling a "buffer underrun free" setting may resolve this issue."
case $E_IMAPI_UNEXPECTED_RESPONSE_FROM_DEVICE
$s = " The write failed because the drive returned error information that could not be recovered from."
case $E_IMAPI_DF2DATA_WRITE_IN_PROGRESS
$s = " There is currently a write operation in progress."
case $E_IMAPI_DF2DATA_WRITE_NOT_IN_PROGRESS
$s = " There is no write operation currently in progress."
case $E_IMAPI_DF2DATA_INVALID_MEDIA_STATE
$s = " The requested operation is only valid with supported media."
case $E_IMAPI_DF2DATA_STREAM_NOT_SUPPORTED
$s = " The provided stream to write is not supported."
case $E_IMAPI_DF2DATA_STREAM_TOO_LARGE_FOR_CURRENT_MEDIA
$s = " The provided stream to write is too large for the currently inserted media."
case $E_IMAPI_DF2DATA_MEDIA_NOT_BLANK
$s = " Overwriting non-blank media is not allowed without the ForceOverwrite property set to VARIANT_TRUE."
case $E_IMAPI_DF2DATA_MEDIA_IS_NOT_SUPPORTED
$s = " The current media type is unsupported."
case $E_IMAPI_DF2DATA_RECORDER_NOT_SUPPORTED
$s = " This device does not support the operations required by this disc format."
case $E_IMAPI_DF2DATA_CLIENT_NAME_IS_NOT_VALID
$s = " The client name is not valid."
case $E_IMAPI_DF2TAO_WRITE_IN_PROGRESS
$s = " There is currently a write operation in progress."
case $E_IMAPI_DF2TAO_WRITE_NOT_IN_PROGRESS
$s = " There is no write operation currently in progress."
case $E_IMAPI_DF2TAO_MEDIA_IS_NOT_PREPARED
$s = " The requested operation is only valid when media has been "prepared"."
case $E_IMAPI_DF2TAO_MEDIA_IS_PREPARED
$s = " The requested operation is not valid when media has been "prepared" but not released."
case $E_IMAPI_DF2TAO_PROPERTY_FOR_BLANK_MEDIA_ONLY
$s = " The property cannot be changed once the media has been written to."
case $E_IMAPI_DF2TAO_TABLE_OF_CONTENTS_EMPTY_DISC
$s = " The table of contents cannot be retrieved from an empty disc."
case $E_IMAPI_DF2TAO_MEDIA_IS_NOT_BLANK
$s = " Only blank CD-R/RW media is supported."
case $E_IMAPI_DF2TAO_MEDIA_IS_NOT_SUPPORTED
$s = " Only blank CD-R/RW media is supported."
case $E_IMAPI_DF2TAO_TRACK_LIMIT_REACHED
$s = " CD-R and CD-RW media support a maximum of 99 audio tracks."
case $E_IMAPI_DF2TAO_NOT_ENOUGH_SPACE
$s = " There is not enough space left on the media to add the provided audio track."
case $E_IMAPI_DF2TAO_NO_RECORDER_SPECIFIED
$s = " You cannot prepare the media until you choose a recorder to use."
case $E_IMAPI_DF2TAO_INVALID_ISRC
$s = " The ISRC provided is not valid."
case $E_IMAPI_DF2TAO_INVALID_MCN
$s = " The Media Catalog Number provided is not valid."
case $E_IMAPI_DF2TAO_STREAM_NOT_SUPPORTED
$s = " The provided audio stream is not valid."
case $E_IMAPI_DF2TAO_RECORDER_NOT_SUPPORTED
$s = " This device does not support the operations required by this disc format."
case $E_IMAPI_DF2TAO_CLIENT_NAME_IS_NOT_VALID
$s = " The client name is not valid."
case $E_IMAPI_DF2RAW_WRITE_IN_PROGRESS
$s = " There is currently a write operation in progress."
case $E_IMAPI_DF2RAW_WRITE_NOT_IN_PROGRESS
$s = " There is no write operation currently in progress."
case $E_IMAPI_DF2RAW_MEDIA_IS_NOT_PREPARED
$s = " The requested operation is only valid when media has been "prepared"."
case $E_IMAPI_DF2RAW_MEDIA_IS_PREPARED
$s = " The requested operation is not valid when media has been "prepared" but not released."
case $E_IMAPI_DF2RAW_CLIENT_NAME_IS_NOT_VALID
$s = " The client name is not valid."
case $E_IMAPI_DF2RAW_MEDIA_IS_NOT_BLANK
$s = " Only blank CD-R/RW media is supported."
case $E_IMAPI_DF2RAW_MEDIA_IS_NOT_SUPPORTED
$s = " Only blank CD-R/RW media is supported."
case $E_IMAPI_DF2RAW_NOT_ENOUGH_SPACE
$s = " There is not enough space on the media to add the provided session."
case $E_IMAPI_DF2RAW_NO_RECORDER_SPECIFIED
$s = " You cannot prepare the media until you choose a recorder to use."
case $E_IMAPI_DF2RAW_STREAM_NOT_SUPPORTED
$s = " The provided audio stream is not valid."
case $E_IMAPI_DF2RAW_DATA_BLOCK_TYPE_NOT_SUPPORTED
$s = " The requested data block type is not supported by the current device."
case $E_IMAPI_DF2RAW_STREAM_LEADIN_TOO_SHORT
$s = " The stream does not contain a sufficient number of sectors in the leadin for the current media."
case $E_IMAPI_DF2RAW_RECORDER_NOT_SUPPORTED
$s = " This device does not support the operations required by this disc format."
case $E_IMAPI_ERASE_RECORDER_IN_USE
$s = " The format is currently using the disc recorder for an erase operation. Please wait for the erase to complete before attempting to set or clear the current disc recorder."
case $E_IMAPI_ERASE_ONLY_ONE_RECORDER_SUPPORTED
$s = " The erase format only supports one recorder. You must clear the current recorder before setting a new one."
case $E_IMAPI_ERASE_DISC_INFORMATION_TOO_SMALL
$s = " The drive did not report sufficient data for a READ DISC INFORMATION command. The drive may not be supported, or the media may not be correct."
case $E_IMAPI_ERASE_MODE_PAGE_2A_TOO_SMALL
$s = " The drive did not report sufficient data for a MODE SENSE (page 0x2A) command. The drive may not be supported, or the media may not be correct."
case $E_IMAPI_ERASE_MEDIA_IS_NOT_ERASABLE
$s = " The drive reported that the media is not erasable."
case $E_IMAPI_ERASE_DRIVE_FAILED_ERASE_COMMAND
$s = " The drive failed the erase command."
case $E_IMAPI_ERASE_TOOK_LONGER_THAN_ONE_HOUR
$s = " The drive did not complete the erase in one hour. The drive may require a power cycle, media removal, or other manual intervention to resume proper operation.  Note  Currently, this value will also be returned if an attempt to perform an erase on CD-RW or DVD-RW media via the IDiscFormat2Erase interface fails as a result of the media being bad."
case $E_IMAPI_ERASE_UNEXPECTED_DRIVE_RESPONSE_DURING_ERASE
$s = " The drive returned an unexpected error during the erase. The media may be unusable, the erase may be complete, or the drive may still be in the process of erasing the disc."
case $E_IMAPI_ERASE_DRIVE_FAILED_SPINUP_COMMAND
$s = " The drive returned an error for a START UNIT (spinup) command. Manual intervention may be required."
case $E_IMAPI_ERASE_MEDIA_IS_NOT_SUPPORTED
$s = " The current media type is unsupported."
case $E_IMAPI_ERASE_RECORDER_NOT_SUPPORTED
$s = " This device does not support the operations required by this disc format."
case $E_IMAPI_ERASE_CLIENT_NAME_IS_NOT_VALID
$s = " The client name is not valid."
case $IMAPI_E_FSI_INTERNAL_ERROR
$s = " Internal error occurred: %1!ls!."
case $IMAPI_E_INVALID_PARAM
$s = " The value specified for parameter '%1!ls!' is not valid."
case $IMAPI_E_READONLY
$s = " FileSystemImage object is in read only mode."
case $IMAPI_E_NO_OUTPUT
$s = " No output file system specified."
case $IMAPI_E_INVALID_VOLUME_NAME
$s = " The specified Volume Identifier is either too long or contains one or more invalid characters."
case $IMAPI_E_INVALID_DATE
$s = " Invalid file dates. %1!ls! time is earlier than %2!ls! time."
case $IMAPI_E_FILE_SYSTEM_NOT_EMPTY
$s = " The file system must be empty for this function."
case $IMAPI_E_FILE_SYSTEM_CHANGE_NOT_ALLOWED
$s = " You cannot change the file system specified for creation, because the file system from the imported session and the file system in the current session do not match."
case $IMAPI_E_NOT_FILE
$s = " Specified path '%1!ls!' does not identify a file."
case $IMAPI_E_NOT_DIR
$s = " Specified path '%1!ls!' does not identify a directory."
case $IMAPI_E_DIR_NOT_EMPTY
$s = " The directory '%1!s!' is not empty."
case $IMAPI_E_NOT_IN_FILE_SYSTEM
$s = " ls!' is not part of the file system. It must be added to complete this operation."
case $IMAPI_E_INVALID_PATH
$s = " Path '%1!s!' is badly formed or contains invalid characters."
case $IMAPI_E_RESTRICTED_NAME_VIOLATION
$s = " The name '%1!ls!' specified is not legal: Name of file or directory object created while the UseRestrictedCharacterSet property is set may only contain ANSI characters."
case $IMAPI_E_DUP_NAME
$s = " ls!' name already exists."
case $IMAPI_E_NO_UNIQUE_NAME
$s = " Attempt to add '%1!ls!' failed: cannot create a file-system-specific unique name for the %2!ls! file system."
case $IMAPI_E_ITEM_NOT_FOUND
$s = " Cannot find item '%1!ls!' in FileSystemImage hierarchy."
case $IMAPI_E_FILE_NOT_FOUND
$s = " The file '%1!s!' not found in FileSystemImage hierarchy."
case $IMAPI_E_DIR_NOT_FOUND
$s = " The directory '%1!s!' not found in FileSystemImage hierarchy."
case $IMAPI_E_IMAGE_SIZE_LIMIT
$s = " Adding '%1!ls!' would result in a result image having a size larger than the current configured limit."
case $IMAPI_E_IMAGE_TOO_BIG
$s = " Value specified for FreeMediaBlocks property is too small for estimated image size based on current data."
case $IMAPI_E_IMAGEMANAGER_IMAGE_NOT_ALIGNED
$s = " The image is not aligned on a 2kb sector boundary."
case $IMAPI_E_IMAGEMANAGER_NO_VALID_VD_FOUND
$s = " The image does not contain a valid volume descriptor."
case $IMAPI_E_IMAGEMANAGER_NO_IMAGE
$s = " The image has not been set using the IIsoImageManager::SetPath or IIsoImageManager::SetStream methods prior to calling the IIsoImageManager::Validate method."
case $IMAPI_E_IMAGEMANAGER_IMAGE_TOO_BIG
$s = " The provided image is too large to be validated as the size exceeds MAXLONG."
case $IMAPI_E_DATA_STREAM_INCONSISTENCY
$s = " Data stream supplied for file '%1!ls!' is inconsistent: expected %2!I64d! bytes, found %3!I64d!."
case $IMAPI_E_DATA_STREAM_READ_FAILURE
$s = " Cannot read data from stream supplied for file '%1!ls!'."
case $IMAPI_E_DATA_STREAM_CREATE_FAILURE
$s = " The following error was encountered when trying to create data stream for file '%1!ls!':"
case $IMAPI_E_DIRECTORY_READ_FAILURE
$s = " Failure enumerating files in the directory tree is inaccessible due to permissions."
case $IMAPI_E_TOO_MANY_DIRS
$s = " This file system image has too many directories for the %1!ls! file system."
case $IMAPI_E_ISO9660_LEVELS
$s = " ISO9660 is limited to 8 levels of directories."
case $IMAPI_E_DATA_TOO_BIG
$s = " Data file is too large for '%1!ls!' file system."
case $IMAPI_E_STASHFILE_OPEN_FAILURE
$s = " Cannot initialize %1!ls! stash file."
case $IMAPI_E_STASHFILE_SEEK_FAILURE
$s = " Error seeking in '%1!ls!' stash file."
case $IMAPI_E_STASHFILE_WRITE_FAILURE
$s = " Error encountered writing to '%1!ls!' stash file."
case $IMAPI_E_STASHFILE_READ_FAILURE
$s = " Error encountered reading from '%1!ls!' stash file."
case $IMAPI_E_INVALID_WORKING_DIRECTORY
$s = " The working directory '%1!ls!' is not valid."
case $IMAPI_E_WORKING_DIRECTORY_SPACE
$s = " Cannot set working directory to '%1!ls!'. Space available is %2!I64d! bytes, approximately %3!I64d! bytes required."
case $IMAPI_E_STASHFILE_MOVE
$s = " Attempt to move the data stash file to directory '%1!ls!' was not successful."
case $IMAPI_E_BOOT_IMAGE_DATA
$s = " The boot object could not be added to the image."
case $IMAPI_E_BOOT_OBJECT_CONFLICT
$s = " A boot object can only be included in an initial disc image."
case $IMAPI_E_BOOT_EMULATION_IMAGE_SIZE_MISMATCH
$s = " The emulation type requested does not match the boot image size."
case $IMAPI_E_EMPTY_DISC
$s = " Optical media is empty."
case $IMAPI_E_NO_SUPPORTED_FILE_SYSTEM
$s = " The specified disc does not contain one of the supported file systems."
case $IMAPI_E_FILE_SYSTEM_NOT_FOUND
$s = " The specified disc does not contain a '%1!ls!' file system."
case $IMAPI_E_FILE_SYSTEM_READ_CONSISTENCY_ERROR
$s = " Consistency error encountered while importing the '%1!ls!' file system."
case $IMAPI_E_FILE_SYSTEM_FEATURE_NOT_SUPPORTED
$s = " The '%1!ls!'file system on the selected disc contains a feature not supported for import: %2!ls!."
case $IMAPI_E_IMPORT_TYPE_COLLISION_FILE_EXISTS_AS_DIRECTORY
$s = " Could not import %2!ls! file system from disc. The file '%1!ls!' already exists within the image hierarchy as a directory."
case $IMAPI_E_IMPORT_SEEK_FAILURE
$s = " Cannot seek to block %1!I64d! on source disc."
case $IMAPI_E_IMPORT_READ_FAILURE
$s = " Import from previous session failed due to an error reading a block on the media (most likely block %1!u!)."
case $IMAPI_E_DISC_MISMATCH
$s = " Current disc is not the same one from which file system was imported."
case $IMAPI_E_IMPORT_MEDIA_NOT_ALLOWED
$s = " IMAPI does not allow multi-session with the current media type."
case $IMAPI_E_UDF_NOT_WRITE_COMPATIBLE
$s = " IMAPI cannot do multi-session with the current media because it does not support a compatible UDF revision for write."
case $IMAPI_E_INCOMPATIBLE_MULTISESSION_TYPE
$s = " IMAPI does not support the multisession type requested."
case $IMAPI_E_INCOMPATIBLE_PREVIOUS_SESSION
$s = " Operation failed due to an incompatible layout of the previous session imported from the medium."
case $IMAPI_E_NO_COMPATIBLE_MULTISESSION_TYPE
$s = " IMAPI supports none of the multisession type(s) provided on the current media.  Note  IFileSystemImage::ImportFileSystem method returns this error if there is no media in the recording device."
case $IMAPI_E_MULTISESSION_NOT_SET
$s = " MultisessionInterfaces property must be set prior calling this method."
case $IMAPI_E_IMPORT_TYPE_COLLISION_DIRECTORY_EXISTS_AS_FILE
$s = " Could not import %2!ls! file system from disc. The directory '%1!ls!' already exists within the image hierarchy as a file."
case $IMAPI_E_BAD_MULTISESSION_PARAMETER
$s = " One of multisession parameters cannot be retrieved or has a wrong value."
case $IMAPI_S_IMAGE_FEATURE_NOT_SUPPORTED
$s = " This feature is not supported for the current file system revision. The image will be created without this feature."
endSwitch
return $s
endFunc

func _setConstants()
; IMAPI Return Values
global const $E_IMAPI_BURN_VERIFICATION_FAILED = 0xC0AA0007 ; The disc did not pass burn verification and may contain corrupt data or be unusable.
global const $E_IMAPI_REQUEST_CANCELLED = 0xC0AA0002 ; The request was canceled.
global const $E_IMAPI_RECORDER_REQUIRED = 0xC0AA0003 ; The request requires a current disc recorder to be selected.
global const $S_IMAPI_WRITE_NOT_IN_PROGRESS = 0x00AA0302 ; No write operation is currently in progress.
global const $S_IMAPI_SPEEDADJUSTED = 0x00AA0004 ; The requested write speed was not supported by the drive and the speed was adjusted.
global const $S_IMAPI_ROTATIONADJUSTED = 0x00AA0005 ; The requested rotation type was not supported by the drive and the rotation type was adjusted.
global const $S_IMAPI_BOTHADJUSTED = 0x00AA0006 ; The requested write speed and rotation type were not supported by the drive and they were both adjusted.
global const $S_IMAPI_COMMAND_HAS_SENSE_DATA = 0x00AA0200 ; The device accepted the command, but returned sense data, indicating an error.
global const $E_IMAPI_RAW_IMAGE_IS_READ_ONLY = 0x80AA0A00 ; The image has become read-only due to a call to IRawCDImageCreator::CreateResultImage. As a result the object can no longer be modified.
global const $E_IMAPI_RAW_IMAGE_TOO_MANY_TRACKS = 0x80AA0A01 ; No more tracks may be added. CD media is restricted to a range of 1-99 tracks.
global const $E_IMAPI_RAW_IMAGE_NO_TRACKS = 0x80AA0A03 ; Tracks must be added to the image before using this function.
global const $E_IMAPI_RAW_IMAGE_SECTOR_TYPE_NOT_SUPPORTED = 0x80AA0A02 ; The requested sector type is not supported.
global const $E_IMAPI_RAW_IMAGE_TRACKS_ALREADY_ADDED = 0x80AA0A04 ; Tracks may not be added to the image prior to the use of this function.
global const $E_IMAPI_RAW_IMAGE_INSUFFICIENT_SPACE = 0x80AA0A05 ; Adding this track would exceed the limitations of the start of the leadout.
global const $E_IMAPI_RAW_IMAGE_TOO_MANY_TRACK_INDEXES = 0x80AA0A06 ; Adding this track would exceed the 99 index limit.
global const $E_IMAPI_RAW_IMAGE_TRACK_INDEX_NOT_FOUND = 0x80AA0A07 ; The specified LBA offset is not in the list of track indexes.
global const $S_IMAPI_RAW_IMAGE_TRACK_INDEX_ALREADY_EXISTS = 0x00AA0A08 ; The specified LBA offset is already in the list of track indexes.
global const $E_IMAPI_RAW_IMAGE_TRACK_INDEX_OFFSET_ZERO_CANNOT_BE_CLEARED = 0x80AA0A09 ; Index 1 (LBA offset zero) cannot be cleared.
global const $E_IMAPI_RAW_IMAGE_TRACK_INDEX_TOO_CLOSE_TO_OTHER_INDEX = 0x80AA0A0A ; Each index must have a minimum size of ten sectors.
global const $E_IMAPI_RECORDER_NO_SUCH_MODE_PAGE = 0xC0AA0201 ; The device reported that the requested mode page (and type) is not present.
global const $E_IMAPI_RECORDER_MEDIA_NO_MEDIA = 0xC0AA0202 ; There is no media in the device.
global const $E_IMAPI_RECORDER_MEDIA_INCOMPATIBLE = 0xC0AA0203 ; The media is not compatible or of unknown physical format.
global const $E_IMAPI_RECORDER_MEDIA_UPSIDE_DOWN = 0xC0AA0204 ; The media is inserted upside down.
global const $E_IMAPI_RECORDER_MEDIA_BECOMING_READY = 0xC0AA0205 ; The drive reported that it is in the process of becoming ready. Please try the request again later.
global const $E_IMAPI_RECORDER_MEDIA_FORMAT_IN_PROGRESS = 0xC0AA0206 ; The media is currently being formatted. Please wait for the format to complete before attempting to use the media.
global const $E_IMAPI_RECORDER_MEDIA_BUSY = 0xC0AA0207 ; The drive reported that it is performing a long-running operation, such as finishing a write. The drive may be unusable for a long period of time.
global const $E_IMAPI_RECORDER_INVALID_MODE_PARAMETERS = 0xC0AA0208 ; The drive reported that the combination of parameters provided in the mode page for a MODE SELECT command were not supported.
global const $E_IMAPI_RECORDER_MEDIA_WRITE_PROTECTED = 0xC0AA0209 ; The drive reported that the media is write protected.
global const $E_IMAPI_RECORDER_NO_SUCH_FEATURE = 0xC0AA020A ; The feature page requested is not supported by the device.
global const $E_IMAPI_RECORDER_FEATURE_IS_NOT_CURRENT = 0xC0AA020B ; The feature page requested is supported, but is not marked as current.
global const $E_IMAPI_RECORDER_GET_CONFIGURATION_NOT_SUPPORTED = 0xC0AA020C ; The drive does not support the GET CONFIGURATION command.
global const $E_IMAPI_RECORDER_COMMAND_TIMEOUT = 0xC0AA020D ; The device failed to accept the command within the timeout period. This may be caused by the device having entered an inconsistent state, or the timeout value for the command may need to be increased.
global const $E_IMAPI_RECORDER_DVD_STRUCTURE_NOT_PRESENT = 0xC0AA020E ; The DVD structure is not present. This may be caused by incompatible drive/medium used.
global const $E_IMAPI_RECORDER_MEDIA_SPEED_MISMATCH = 0xC0AA020F ; The media's speed is incompatible with the device. This may be caused by using higher or lower speed media than the range of speeds supported by the device.
global const $E_IMAPI_RECORDER_LOCKED = 0xC0AA0210 ; The device associated with this recorder during the last operation has been exclusively locked, causing this operation to fail.
global const $E_IMAPI_RECORDER_CLIENT_NAME_IS_NOT_VALID = 0xC0AA0211 ; The client name is not valid.
global const $E_IMAPI_RECORDER_INVALID_RESPONSE_FROM_DEVICE = 0xC0AA02FF ; The device reported unexpected or invalid data for a command.
global const $E_IMAPI_LOSS_OF_STREAMING = 0xC0AA0300 ; The write failed because the drive did not receive data quickly enough to continue writing. Moving the source data to the local computer, reducing the write speed, or enabling a "buffer underrun free" setting may resolve this issue.
global const $E_IMAPI_UNEXPECTED_RESPONSE_FROM_DEVICE = 0xC0AA0301 ; The write failed because the drive returned error information that could not be recovered from.
global const $E_IMAPI_DF2DATA_WRITE_IN_PROGRESS = 0xC0AA0400 ; There is currently a write operation in progress.
global const $E_IMAPI_DF2DATA_WRITE_NOT_IN_PROGRESS = 0xC0AA0401 ; There is no write operation currently in progress.
global const $E_IMAPI_DF2DATA_INVALID_MEDIA_STATE = 0xC0AA0402 ; The requested operation is only valid with supported media.
global const $E_IMAPI_DF2DATA_STREAM_NOT_SUPPORTED = 0xC0AA0403 ; The provided stream to write is not supported.
global const $E_IMAPI_DF2DATA_STREAM_TOO_LARGE_FOR_CURRENT_MEDIA = 0xC0AA0404 ; The provided stream to write is too large for the currently inserted media.
global const $E_IMAPI_DF2DATA_MEDIA_NOT_BLANK = 0xC0AA0405 ; Overwriting non-blank media is not allowed without the ForceOverwrite property set to VARIANT_TRUE.
global const $E_IMAPI_DF2DATA_MEDIA_IS_NOT_SUPPORTED = 0xC0AA0406 ; The current media type is unsupported.
global const $E_IMAPI_DF2DATA_RECORDER_NOT_SUPPORTED = 0xC0AA0407 ; This device does not support the operations required by this disc format.
global const $E_IMAPI_DF2DATA_CLIENT_NAME_IS_NOT_VALID = 0xC0AA0408 ; The client name is not valid.
global const $E_IMAPI_DF2TAO_WRITE_IN_PROGRESS = 0xC0AA0500 ; There is currently a write operation in progress.
global const $E_IMAPI_DF2TAO_WRITE_NOT_IN_PROGRESS = 0xC0AA0501 ; There is no write operation currently in progress.
global const $E_IMAPI_DF2TAO_MEDIA_IS_NOT_PREPARED = 0xC0AA0502 ; The requested operation is only valid when media has been "prepared".
global const $E_IMAPI_DF2TAO_MEDIA_IS_PREPARED = 0xC0AA0503 ; The requested operation is not valid when media has been "prepared" but not released.
global const $E_IMAPI_DF2TAO_PROPERTY_FOR_BLANK_MEDIA_ONLY = 0xC0AA0504 ; The property cannot be changed once the media has been written to.
global const $E_IMAPI_DF2TAO_TABLE_OF_CONTENTS_EMPTY_DISC = 0xC0AA0505 ; The table of contents cannot be retrieved from an empty disc.
global const $E_IMAPI_DF2TAO_MEDIA_IS_NOT_BLANK = 0xC0AA0506 ; Only blank CD-R/RW media is supported.
global const $E_IMAPI_DF2TAO_MEDIA_IS_NOT_SUPPORTED = 0xC0AA0507 ; Only blank CD-R/RW media is supported.
global const $E_IMAPI_DF2TAO_TRACK_LIMIT_REACHED = 0xC0AA0508 ; CD-R and CD-RW media support a maximum of 99 audio tracks.
global const $E_IMAPI_DF2TAO_NOT_ENOUGH_SPACE = 0xC0AA0509 ; There is not enough space left on the media to add the provided audio track.
global const $E_IMAPI_DF2TAO_NO_RECORDER_SPECIFIED = 0xC0AA050A ; You cannot prepare the media until you choose a recorder to use.
global const $E_IMAPI_DF2TAO_INVALID_ISRC = 0xC0AA050B ; The ISRC provided is not valid.
global const $E_IMAPI_DF2TAO_INVALID_MCN = 0xC0AA050C ; The Media Catalog Number provided is not valid.
global const $E_IMAPI_DF2TAO_STREAM_NOT_SUPPORTED = 0xC0AA050D ; The provided audio stream is not valid.
global const $E_IMAPI_DF2TAO_RECORDER_NOT_SUPPORTED = 0xC0AA050E ; This device does not support the operations required by this disc format.
global const $E_IMAPI_DF2TAO_CLIENT_NAME_IS_NOT_VALID = 0xC0AA050F ; The client name is not valid.
global const $E_IMAPI_DF2RAW_WRITE_IN_PROGRESS = 0xC0AA0600 ; There is currently a write operation in progress.
global const $E_IMAPI_DF2RAW_WRITE_NOT_IN_PROGRESS = 0xC0AA0601 ; There is no write operation currently in progress.
global const $E_IMAPI_DF2RAW_MEDIA_IS_NOT_PREPARED = 0xC0AA0602 ; The requested operation is only valid when media has been "prepared".
global const $E_IMAPI_DF2RAW_MEDIA_IS_PREPARED = 0xC0AA0603 ; The requested operation is not valid when media has been "prepared" but not released.
global const $E_IMAPI_DF2RAW_CLIENT_NAME_IS_NOT_VALID = 0xC0AA0604 ; The client name is not valid.
global const $E_IMAPI_DF2RAW_MEDIA_IS_NOT_BLANK = 0xC0AA0606 ; Only blank CD-R/RW media is supported.
global const $E_IMAPI_DF2RAW_MEDIA_IS_NOT_SUPPORTED = 0xC0AA0607 ; Only blank CD-R/RW media is supported.
global const $E_IMAPI_DF2RAW_NOT_ENOUGH_SPACE = 0xC0AA0609 ; There is not enough space on the media to add the provided session.
global const $E_IMAPI_DF2RAW_NO_RECORDER_SPECIFIED = 0xC0AA060A ; You cannot prepare the media until you choose a recorder to use.
global const $E_IMAPI_DF2RAW_STREAM_NOT_SUPPORTED = 0xC0AA060D ; The provided audio stream is not valid.
global const $E_IMAPI_DF2RAW_DATA_BLOCK_TYPE_NOT_SUPPORTED = 0xC0AA060E ; The requested data block type is not supported by the current device.
global const $E_IMAPI_DF2RAW_STREAM_LEADIN_TOO_SHORT = 0xC0AA060F ; The stream does not contain a sufficient number of sectors in the leadin for the current media.
global const $E_IMAPI_DF2RAW_RECORDER_NOT_SUPPORTED = 0xC0AA0610 ; This device does not support the operations required by this disc format.
global const $E_IMAPI_ERASE_RECORDER_IN_USE = 0x80AA0900 ; The format is currently using the disc recorder for an erase operation. Please wait for the erase to complete before attempting to set or clear the current disc recorder.
global const $E_IMAPI_ERASE_ONLY_ONE_RECORDER_SUPPORTED = 0x80AA0901 ; The erase format only supports one recorder. You must clear the current recorder before setting a new one.
global const $E_IMAPI_ERASE_DISC_INFORMATION_TOO_SMALL = 0x80AA0902 ; The drive did not report sufficient data for a READ DISC INFORMATION command. The drive may not be supported, or the media may not be correct.
global const $E_IMAPI_ERASE_MODE_PAGE_2A_TOO_SMALL = 0x80AA0903 ; The drive did not report sufficient data for a MODE SENSE (page 0x2A) command. The drive may not be supported, or the media may not be correct.
global const $E_IMAPI_ERASE_MEDIA_IS_NOT_ERASABLE = 0x80AA0904 ; The drive reported that the media is not erasable.
global const $E_IMAPI_ERASE_DRIVE_FAILED_ERASE_COMMAND = 0x80AA0905 ; The drive failed the erase command.
global const $E_IMAPI_ERASE_TOOK_LONGER_THAN_ONE_HOUR = 0x80AA0906 ; The drive did not complete the erase in one hour. The drive may require a power cycle, media removal, or other manual intervention to resume proper operation.
 ; Note  Currently, this value will also be returned if an attempt to perform an erase on CD-RW or DVD-RW media via the IDiscFormat2Erase interface fails as a result of the media being bad.
global const $E_IMAPI_ERASE_UNEXPECTED_DRIVE_RESPONSE_DURING_ERASE = 0x80AA0907 ; The drive returned an unexpected error during the erase. The media may be unusable, the erase may be complete, or the drive may still be in the process of erasing the disc.
global const $E_IMAPI_ERASE_DRIVE_FAILED_SPINUP_COMMAND = 0x80AA0908 ; The drive returned an error for a START UNIT (spinup) command. Manual intervention may be required.
global const $E_IMAPI_ERASE_MEDIA_IS_NOT_SUPPORTED = 0xC0AA0909 ; The current media type is unsupported.
global const $E_IMAPI_ERASE_RECORDER_NOT_SUPPORTED = 0xC0AA090A ; This device does not support the operations required by this disc format.
global const $E_IMAPI_ERASE_CLIENT_NAME_IS_NOT_VALID = 0xC0AA090B ; The client name is not valid.

global const $IMAPI_E_FSI_INTERNAL_ERROR = 0xC0AAB100 ; Internal error occurred: %1!ls!.
global const $IMAPI_E_INVALID_PARAM = 0xC0AAB101 ; The value specified for parameter '%1!ls!' is not valid.
global const $IMAPI_E_READONLY = 0xC0AAB102 ; FileSystemImage object is in read only mode.
global const $IMAPI_E_NO_OUTPUT = 0xC0AAB103 ; No output file system specified.
global const $IMAPI_E_INVALID_VOLUME_NAME = 0xC0AAB104 ; The specified Volume Identifier is either too long or contains one or more invalid characters.
global const $IMAPI_E_INVALID_DATE = 0xC0AAB105 ; Invalid file dates. %1!ls! time is earlier than %2!ls! time.
global const $IMAPI_E_FILE_SYSTEM_NOT_EMPTY = 0xC0AAB106 ; The file system must be empty for this function.
global const $IMAPI_E_FILE_SYSTEM_CHANGE_NOT_ALLOWED = 0xC0AAB163 ; You cannot change the file system specified for creation, because the file system from the imported session and the file system in the current session do not match.
global const $IMAPI_E_NOT_FILE = 0xC0AAB108 ; Specified path '%1!ls!' does not identify a file.
global const $IMAPI_E_NOT_DIR = 0xC0AAB109 ; Specified path '%1!ls!' does not identify a directory.
global const $IMAPI_E_DIR_NOT_EMPTY = 0xC0AAB10A ; The directory '%1!s!' is not empty.
global const $IMAPI_E_NOT_IN_FILE_SYSTEM = 0xC0AAB10B ; ls!' is not part of the file system. It must be added to complete this operation.
global const $IMAPI_E_INVALID_PATH = 0xC0AAB110 ; Path '%1!s!' is badly formed or contains invalid characters.
global const $IMAPI_E_RESTRICTED_NAME_VIOLATION = 0xC0AAB111 ; The name '%1!ls!' specified is not legal: Name of file or directory object created while the UseRestrictedCharacterSet property is set may only contain ANSI characters.
global const $IMAPI_E_DUP_NAME = 0xC0AAB112 ; ls!' name already exists.
global const $IMAPI_E_NO_UNIQUE_NAME = 0xC0AAB113 ; Attempt to add '%1!ls!' failed: cannot create a file-system-specific unique name for the %2!ls! file system.
global const $IMAPI_E_ITEM_NOT_FOUND = 0xC0AAB118 ; Cannot find item '%1!ls!' in FileSystemImage hierarchy.
global const $IMAPI_E_FILE_NOT_FOUND = 0xC0AAB119 ; The file '%1!s!' not found in FileSystemImage hierarchy.
global const $IMAPI_E_DIR_NOT_FOUND = 0xC0AAB11A ; The directory '%1!s!' not found in FileSystemImage hierarchy.
global const $IMAPI_E_IMAGE_SIZE_LIMIT = 0xC0AAB120 ; Adding '%1!ls!' would result in a result image having a size larger than the current configured limit.
global const $IMAPI_E_IMAGE_TOO_BIG = 0xC0AAB121 ; Value specified for FreeMediaBlocks property is too small for estimated image size based on current data.
global const $IMAPI_E_IMAGEMANAGER_IMAGE_NOT_ALIGNED = 0xC0AAB200 ; The image is not aligned on a 2kb sector boundary.
global const $IMAPI_E_IMAGEMANAGER_NO_VALID_VD_FOUND = 0xC0AAB201 ; The image does not contain a valid volume descriptor.
global const $IMAPI_E_IMAGEMANAGER_NO_IMAGE = 0xC0AAB202 ; The image has not been set using the IIsoImageManager::SetPath or IIsoImageManager::SetStream methods prior to calling the IIsoImageManager::Validate method.
global const $IMAPI_E_IMAGEMANAGER_IMAGE_TOO_BIG = 0xC0AAB203 ; The provided image is too large to be validated as the size exceeds MAXLONG.
global const $IMAPI_E_DATA_STREAM_INCONSISTENCY = 0xC0AAB128 ; Data stream supplied for file '%1!ls!' is inconsistent: expected %2!I64d! bytes, found %3!I64d!.
global const $IMAPI_E_DATA_STREAM_READ_FAILURE = 0xC0AAB129 ; Cannot read data from stream supplied for file '%1!ls!'.
global const $IMAPI_E_DATA_STREAM_CREATE_FAILURE = 0xC0AAB12A ; The following error was encountered when trying to create data stream for file '%1!ls!':
global const $IMAPI_E_DIRECTORY_READ_FAILURE = 0xC0AAB12B ; Failure enumerating files in the directory tree is inaccessible due to permissions.
global const $IMAPI_E_TOO_MANY_DIRS = 0xC0AAB130 ; This file system image has too many directories for the %1!ls! file system.
global const $IMAPI_E_ISO9660_LEVELS = 0xC0AAB131 ; ISO9660 is limited to 8 levels of directories.
global const $IMAPI_E_DATA_TOO_BIG = 0xC0AAB132 ; Data file is too large for '%1!ls!' file system.
global const $IMAPI_E_STASHFILE_OPEN_FAILURE = 0xC0AAB138 ; Cannot initialize %1!ls! stash file.
global const $IMAPI_E_STASHFILE_SEEK_FAILURE = 0xC0AAB139 ; Error seeking in '%1!ls!' stash file.
global const $IMAPI_E_STASHFILE_WRITE_FAILURE = 0xC0AAB13A ; Error encountered writing to '%1!ls!' stash file.
global const $IMAPI_E_STASHFILE_READ_FAILURE = 0xC0AAB13B ; Error encountered reading from '%1!ls!' stash file.
global const $IMAPI_E_INVALID_WORKING_DIRECTORY = 0xC0AAB140 ; The working directory '%1!ls!' is not valid.
global const $IMAPI_E_WORKING_DIRECTORY_SPACE = 0xC0AAB141 ; Cannot set working directory to '%1!ls!'. Space available is %2!I64d! bytes, approximately %3!I64d! bytes required.
global const $IMAPI_E_STASHFILE_MOVE = 0xC0AAB142 ; Attempt to move the data stash file to directory '%1!ls!' was not successful.
global const $IMAPI_E_BOOT_IMAGE_DATA = 0xC0AAB148 ; The boot object could not be added to the image.
global const $IMAPI_E_BOOT_OBJECT_CONFLICT = 0xC0AAB149 ; A boot object can only be included in an initial disc image.
global const $IMAPI_E_BOOT_EMULATION_IMAGE_SIZE_MISMATCH = 0xC0AAB14A ; The emulation type requested does not match the boot image size.
global const $IMAPI_E_EMPTY_DISC = 0xC0AAB150 ; Optical media is empty.
global const $IMAPI_E_NO_SUPPORTED_FILE_SYSTEM = 0xC0AAB151 ; The specified disc does not contain one of the supported file systems.
global const $IMAPI_E_FILE_SYSTEM_NOT_FOUND = 0xC0AAB152 ; The specified disc does not contain a '%1!ls!' file system.
global const $IMAPI_E_FILE_SYSTEM_READ_CONSISTENCY_ERROR = 0xC0AAB153 ; Consistency error encountered while importing the '%1!ls!' file system.
global const $IMAPI_E_FILE_SYSTEM_FEATURE_NOT_SUPPORTED = 0xC0AAB154 ; The '%1!ls!'file system on the selected disc contains a feature not supported for import: %2!ls!.
global const $IMAPI_E_IMPORT_TYPE_COLLISION_FILE_EXISTS_AS_DIRECTORY = 0xC0AAB155 ; Could not import %2!ls! file system from disc. The file '%1!ls!' already exists within the image hierarchy as a directory.
global const $IMAPI_E_IMPORT_SEEK_FAILURE = 0xC0AAB156 ; Cannot seek to block %1!I64d! on source disc.
global const $IMAPI_E_IMPORT_READ_FAILURE = 0xC0AAB157 ; Import from previous session failed due to an error reading a block on the media (most likely block %1!u!).
global const $IMAPI_E_DISC_MISMATCH = 0xC0AAB158 ; Current disc is not the same one from which file system was imported.
global const $IMAPI_E_IMPORT_MEDIA_NOT_ALLOWED = 0xC0AAB159 ; IMAPI does not allow multi-session with the current media type.
global const $IMAPI_E_UDF_NOT_WRITE_COMPATIBLE = 0xC0AAB15A ; IMAPI cannot do multi-session with the current media because it does not support a compatible UDF revision for write.
global const $IMAPI_E_INCOMPATIBLE_MULTISESSION_TYPE = 0xC0AAB15B ; IMAPI does not support the multisession type requested.
global const $IMAPI_E_INCOMPATIBLE_PREVIOUS_SESSION = 0xC0AAB133 ; Operation failed due to an incompatible layout of the previous session imported from the medium.
global const $IMAPI_E_NO_COMPATIBLE_MULTISESSION_TYPE = 0xC0AAB15C ; IMAPI supports none of the multisession type(s) provided on the current media.  Note  IFileSystemImage::ImportFileSystem method returns this error if there is no media in the recording device.
global const $IMAPI_E_MULTISESSION_NOT_SET = 0xC0AAB15D ; MultisessionInterfaces property must be set prior calling this method.
global const $IMAPI_E_IMPORT_TYPE_COLLISION_DIRECTORY_EXISTS_AS_FILE = 0xC0AAB15E ; Could not import %2!ls! file system from disc. The directory '%1!ls!' already exists within the image hierarchy as a file.
global const $IMAPI_E_BAD_MULTISESSION_PARAMETER = 0xC0AAB162 ; One of multisession parameters cannot be retrieved or has a wrong value.
global const $IMAPI_S_IMAGE_FEATURE_NOT_SUPPORTED = 0x00AAB15F ; This feature is not supported for the current file system revision. The image will be created without this feature.
endFunc

Func _burn2disc_COM_Error()
local $sError, $sText

$burn2disc_ErrorCode = 0
If IsObj($burn2disc_Error) Then
$burn2disc_ErrorCode = "0x" & Hex($burn2disc_Error.number)
$sText = "COM error number: " & $burn2disc_ErrorCode & @CrLf
$sText &= "WinDescription: " & $burn2disc_error.WinDescription & @CrLf
$sError = _getErrorMessage($burn2disc_ErrorCode)
if $sError then $sText &= "Message: " & $sError & @CrLf
$sText &= "SourceName: " & $burn2disc_error.SourceName & @CrLf
$sText &= "DescriptionSource: " & $burn2disc_error.DescriptionSource & @CrLf
$sText &= "HelpFileSource: " & $burn2disc_error.HelpFileSource & @CrLf
$sText &= "HelpContextSource: " & $burn2disc_error.HelpContextSource & @CrLf
$sText &= "LastDLLError: " & $burn2disc_error.LastDLLError & @CrLf
$sText &= "ScriptLine: " & $burn2disc_error.ScriptLine & @CrLf
$burn2disc_Error.clear
_output($sText)
EndIf
EndFunc

func _writer_update($oSource, $oProgress)
static $iProgress = 0
local $sTimeStatus = "Time: " & $oProgress.ElapsedTime & " / " & $oProgress.TotalTime
switch $oProgress.CurrentAction
case $IMAPI_FORMAT2_DATA_WRITE_ACTION_VALIDATING_MEDIA
_output("Validating media ")
case $IMAPI_FORMAT2_DATA_WRITE_ACTION_FORMATTING_MEDIA
_output("Formatting media ")
case $IMAPI_FORMAT2_DATA_WRITE_ACTION_INITIALIZING_HARDWARE
_output("Initializing Hardware ")
case $IMAPI_FORMAT2_DATA_WRITE_ACTION_CALIBRATING_POWER
_output("Calibrating Power")
case $IMAPI_FORMAT2_DATA_WRITE_ACTION_WRITING_DATA
if not $iProgress then _output("Burning")
$iProgress += 1

local $iTotalSectors, $iWrittenSectors, $nPercentDone

$iTotalSectors = $oProgress.SectorCount
$iWrittenSectors = $oProgress.LastWrittenLba - $oProgress.StartLba
$nPercentDone = ceiling(100 * $iWrittenSectors / $iTotalSectors)
_output($nPercentDone & "%")
case $IMAPI_FORMAT2_DATA_WRITE_ACTION_FINALIZATION
_output("Finishing burn")
case $IMAPI_FORMAT2_DATA_WRITE_ACTION_COMPLETED
_output("Done")
case $IMAPI_FORMAT2_DATA_WRITE_ACTION_VERIFYING
_output("Verifying data")
case else
_output("Unknown action: " & $oProgress.CurrentAction)
endSwitch
endFunc

Func old_writer_Update($oSource, $oProgress)
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
; if not isObj($oRecorder) then $oRecorder = _initRecorderFromDrive($sDrive)
$oRecorder = _initRecorderFromDrive($sDrive)
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

func _stringPlural($iCount, $sTerm)
local $sReturn = $iCount & " " & $sTerm
if $iCount <> 1 then $sReturn &= "s"
return $sReturn
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
_output("Found " & _stringPlural($aPaths[0], "path"))

$oRecorder = _initRecorderFromDrive($sDrive)
$oWriter = _initWriterFromDrive($sDrive)
_output("Creating file system image")
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
_output("Adding folder " & $sPath)
$oFSI.Root.AddTree($sPath, true)
elseIf FileExists($sPath) then
_output("Adding file " & $sPath)
$oFSI.Root.AddTree($sPath, false)
elseIf $iPath = 1 then
$sDiscName = $sPath
_output("Setting disc name to " & $sDiscName)
$oFSI.VolumeName = $sDiscname
endif
next

$oResult = $oFSI.CreateResultImage()
$oStream = $oResult.ImageStream

; Write stream to disc using recorder
_output("Writing data to disc")
ObjEvent($oWriter, "_writer_")
$oWriter.Write($oStream)
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
; _output("Is Supported Environment: " & $oDevices.IsSupportedEnvironment)

for $sUniqueID in $oDevices
$oRecorder = _createDiscRecorder()
$oRecorder.InitializeDiscRecorder( $sUniqueID )

For $sMountPoint in $oRecorder.volumePathNames
_output("Mount Point: " & $sMountPoint)
_output("")
Next

_output("ActiveRecorderId: " & $oRecorder.ActiveDiscRecorder)
_output("")
_output("Vendor Id: " & $oRecorder.VendorId)
_output("")
_output("Product Id: " & $oRecorder.ProductId)
_output("")
_output("Product Revision: " & $oRecorder.ProductRevision)
_output("")
_output("VolumeName: " & $oRecorder.VolumeName)
_output("")
_output("Can Load Media: " & $oRecorder.DeviceCanLoadMedia)
_output("")
_output("Legacy Device Number: " & $oRecorder.LegacyDeviceNumber)

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
local $iError
local $sError

_output("Erasing drive " & $sDrive)
$oErase = _initEraseFromDrive($sDrive)
; $oErase.FullErase = true
$iError = $oErase.EraseMedia()
if $iError then
$sError = _getErrorMessage($iError)
if $sError then _output("Error: " & $sError)
endIf

#CS
$oWriter = _initWriterFromDrive($sDrive)
$iResult = $oWriter.MediaPhysicallyBlank()
$iResult = $oWriter.MediaHeuristicallyBlank()
_output("Erase result: " & $iResult)
#CE
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

