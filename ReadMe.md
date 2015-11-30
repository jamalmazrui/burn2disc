# burn2disc

Version 1.0  
November 29, 2015   
Copyright 2015 by Jamal Mazrui  
GNU Lesser General Public License (LGPL)


## Description
The burn2disc.exe utility is a stand-alone, Windows command-line program for burning files and directories onto optical media such as CDs and DVDs.  It does this via the ["Image Mastering API"](https://msdn.microsoft.com/en-us/library/windows/desktop/aa366450(v=vs.85).aspx) (IMAPI) that is built into Windows.  Any programming language can invoke another executable, and users familiar with the command line can easily invoke vurn2disc.exe.

## Operation
The command-line syntax is  
`burn2disc Command Argument Drive`

A value for the Command parameter is always needed, and other parameters are optional depending on the command.

Two commands let you burn data to a disc:

`burn2disc match FileSystemSpec`
which burns files and folders that match the file system specification, e.g.,  
`burn2disc match c:\temp\burn`  
or  
`burn2disc match c:\temp\burn\*.pdf`  

To burn a list of files instead, use the command  
`burn2disc list TextFileList`  

If the disc already contains data, these burn actions will add data or replace paths with the same names.

A few commands let you query information to aid your burn2disc decisions:  
`burn2disc devices`  
informs you about available optical devices,  
`burn2disc media`  
informs you about the current media in the default drive, and  
`burn2disc space`  
informs you about space available for burning onto the current media.

Another pair commands let you open or close the media tray:  
`burn2disc open`  
`burn2disc close`

## Development Notes
The file burn2disc.au3 contains the source code in the [AutIt](http://AutoItScript.com) programming language.  My code adapted portions of [examples by Microsoft]() and [Andreas Carlson]().
