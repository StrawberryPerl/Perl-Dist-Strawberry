// Relocate.cpp : Defines the Relocate custom action.
//
// Copyright (c) Curtis Jewell 2009, 2010
//
// This code is free software; you can redistribute it and/or modify it
// under the same terms as Perl itself.

// ##### EXPORTED FUCTIONS: RelocateMSI

#include "stdafx.h"
#include "ErrorMsg.h"

UINT Blip(
    MSIHANDLE hModule) // Handle of MSI being installed. [in]
{
    // Set up variables.
    PMSIHANDLE hRecord = ::MsiCreateRecord(4);
    RETURN_IF_NULL(hRecord, hModule, _T("ERROR: Blip - MsiCreateRecord FAILED"));

    UINT uiAnswer = ::MsiRecordSetInteger(hRecord, 1, 2);
    RETURN_ON_ERROR(uiAnswer, hModule, _T("ERROR: Blip - MsiRecordSetInteger.1 FAILED"));
    
    uiAnswer = ::MsiRecordSetInteger(hRecord, 2, 0);
    RETURN_ON_ERROR(uiAnswer, hModule, _T("ERROR: Blip - MsiRecordSetInteger.2 FAILED"));

    uiAnswer = ::MsiRecordSetInteger(hRecord, 3, 0);
    RETURN_ON_ERROR(uiAnswer, hModule, _T("ERROR: Blip - MsiRecordSetInteger.3 FAILED"));

    uiAnswer = ::MsiRecordSetInteger(hRecord, 4, 0);
    RETURN_ON_ERROR(uiAnswer, hModule, _T("ERROR: Blip - MsiRecordSetInteger.4 FAILED"));

    // Send the message
    uiAnswer = ::MsiProcessMessage(hModule, INSTALLMESSAGE(INSTALLMESSAGE_PROGRESS), hRecord);

    // Corrects return value for use with MSI_OK.
    switch (uiAnswer) {
    case IDOK:
    case 0: // Means no action was taken...
        return ERROR_SUCCESS;
    case IDCANCEL:
        return ERROR_INSTALL_USEREXIT;
    default:
        return ERROR_INSTALL_FAILURE;
    }
}

UINT _stdcall Relocate_MoveFile(
    MSIHANDLE hModule,
    const TCHAR *sFileTo,   // Original name of the file 
    const TCHAR *sFileFrom) // File to rename into its place.
{
    // Create "to-the-side" location for original file.
    TCHAR sFileSpec[_MAX_PATH];
    _tcscpy_s(sFileSpec, _MAX_PATH, sFileTo);
    _tcscat_s(sFileSpec, _MAX_PATH, _T(".old"));

    BOOL bAnswer = TRUE;

    // Move original file out of the way.
    bAnswer = ::MoveFileEx(sFileTo, sFileSpec, MOVEFILE_WRITE_THROUGH);
    if (bAnswer == FALSE) {
        SimpleLogString4(hModule, _T("ERROR: Relocate_MoveFile - failed to move.1 "), sFileTo, _T(" to "), sFileSpec);
        return ERROR_INSTALL_FAILURE;
    }

    // Move new file into the old file's place.
    bAnswer = ::MoveFileEx(sFileFrom, sFileTo, MOVEFILE_WRITE_THROUGH);
    if (bAnswer == FALSE) {
        SimpleLogString4(hModule, _T("ERROR: Relocate_MoveFile - failed to move.2 "), sFileFrom, _T(" to "), sFileTo);
        return ERROR_INSTALL_FAILURE;
    }

    // Remove the old file.
    bAnswer = ::DeleteFile(sFileSpec);
    if (bAnswer == FALSE) {
        SimpleLogString2(hModule, _T("ERROR: Relocate_MoveFile - failed to delete "), sFileSpec);
        return ERROR_INSTALL_FAILURE;
    }
    
    return ERROR_SUCCESS;
}


void _stdcall Relocate_GetSearchString(
    MSIHANDLE hModule,
          TCHAR *sString,   // String to search for [out] 
    const TCHAR *sDir,      // Directory to search for.
    const TCHAR *sType)     // Type of search to do.
{
    if (0 == _tcscmp(sType, _T("backslash"))) {
        _tcscpy_s(sString, _MAX_PATH, sDir);
        return;
    }

    TCHAR *sWorkP = NULL;
    if (0 == _tcscmp(sType, _T("slash"))) {
        _tcscpy_s(sString, _MAX_PATH, sDir);

        // Change each backslash to a slash.
        sWorkP = _tcschr(sString, _T('\\'));
        while(sWorkP) {
            *sWorkP = _T('/');
            sWorkP = _tcschr(sString, _T('\\'));
        }

        return;
    }

    if (0 == _tcscmp(sType, _T("doublebackslash"))) {
        TCHAR *sWork1 = (TCHAR *)malloc((_MAX_PATH + 1) * sizeof(TCHAR));
        TCHAR *sWork2 = (TCHAR *)malloc((_MAX_PATH + 1) * sizeof(TCHAR));

        _tcscpy_s(sString, _MAX_PATH, sDir);

        // Change to slashes first.
        sWorkP = _tcschr(sString, _T('\\'));
        while(sWorkP) {
            *sWorkP = _T('/');
            sWorkP = _tcschr(sString, _T('\\'));
        }

        _tcscpy_s(sWork1, _MAX_PATH, sString);
        sWorkP = _tcschr(sWork1, _T('/'));
        while (sWorkP) {
            // Fix to make sure that we don't attempt to buffer-overrun.
            if (1 == _tcslen(sWorkP)) {
                // Add the second slash.
                _tcscat_s(sWork1, _MAX_PATH, _T("\\"));

                // Set the first one.
                *sWorkP = _T('\\');

                // We're done.
                break;
            }

            // Block it to copying before the slash.
            *sWorkP = _T('\0');
            _tcscpy_s(sWork2, _MAX_PATH, sWork1);

            // Append the backslashes, and then the rest of the string.
            _tcscat_s(sWork2, _MAX_PATH, _T("\\\\"));
            _tcscat_s(sWork2, _MAX_PATH, ++sWorkP);

            // Copy back out of our work area, so that they match.
            _tcscpy_s(sWork1,  _MAX_PATH, sWork2);

            // Try another search.
            sWorkP = _tcschr(sWork1, _T('/'));
        }

        // Copy our answer out.
        _tcscpy_s(sString, _MAX_PATH, sWork1);
        free((void*)sWork1);
        free((void*)sWork2);
        return;
    }

    if (0 == _tcscmp(sType, _T("url"))) {
        TCHAR sWork3[_MAX_PATH + 1];
        _tcscpy_s(sWork3, _MAX_PATH, sDir);

        // Change each backslash to a slash.
        sWorkP = _tcschr(sWork3, _T('\\'));
        while(sWorkP) {
            *sWorkP = _T('/');
            sWorkP = _tcschr(sWork3, _T('\\'));
        }

        _tcscpy_s(sString, _MAX_PATH, _T("file:///"));
        _tcscat_s(sString, _MAX_PATH, sWork3);
        return;
    }

    // Error: Return an empty string.
    _tcscpy_s(sString, _MAX_PATH, _T(""));
    return;

}


UINT _stdcall Relocate_File(
    MSIHANDLE hModule,
    const TCHAR *sDirectoryFrom, // Directory to relocate from
    const TCHAR *sDirectoryTo,   // Directory to relocate to
    const TCHAR *sFile,          // File to relocate
    const TCHAR *sType)          // Type of relocation to do.
{
    UINT uiAnswer = ERROR_SUCCESS;
    TCHAR sFileIn[_MAX_PATH];
    TCHAR sFileOut[_MAX_PATH];
    _tcscpy_s(sFileIn, _MAX_PATH, sDirectoryTo);
    _tcscat_s(sFileIn, _MAX_PATH, sFile);
    _tcscpy_s(sFileOut, _MAX_PATH, sFileIn);
    _tcscat_s(sFileOut, _MAX_PATH, _T(".new"));

    TCHAR sStringIn[_MAX_PATH];
    TCHAR sStringOut[_MAX_PATH];

    // Log the fact that we're relocating a file.
    SimpleLogString4(hModule, _T("Relocate_File file="), sFile, _T(" type="), sType);

    // Get the strings to look for.
    Relocate_GetSearchString(hModule, sStringIn,  sDirectoryFrom, sType);
    Relocate_GetSearchString(hModule, sStringOut, sDirectoryTo,   sType);

    if (0 == _tcscmp(sStringIn, _T(""))) {
        SimpleLogString1(hModule, _T("ERROR: Relocate_File - empty In"));
        return ERROR_INSTALL_FAILURE;
    }

    if (0 == _tcscmp(sStringOut, _T(""))) {
        SimpleLogString1(hModule, _T("ERROR: Relocate_File - empty Out"));
        return ERROR_INSTALL_FAILURE;
    }

    // Open our files.
    FILE *fFileIn;
    FILE *fFileOut;
    errno_t eAnswer = 0;
    eAnswer = _tfopen_s(&fFileIn, sFileIn, _T("rtS"));
    if (eAnswer != 0) {
        SimpleLogString3(hModule, _T("WARNING: Relocate_File - probably non-existing file "), sFileIn, _T(" - gonna continue, just skipping this one"));
        return ERROR_SUCCESS;
    }
    eAnswer = _tfopen_s(&fFileOut, sFileOut, _T("wt"));
    if (eAnswer != 0) {
        SimpleLogString2(hModule, _T("ERROR: Relocate_File - open.1 'wt' failed for "), sFileOut);
        fclose(fFileIn);
        return ERROR_INSTALL_FAILURE;
    }

    // Set up our variables for the relocation.
    TCHAR  sLine[32767];
    TCHAR  sWork1[32767];
    TCHAR  sWork2[32767];
    TCHAR *sLoc   = NULL;
    size_t iStringInLength = _tcslen(sStringIn);
    size_t iStringOutLength = _tcslen(sStringOut);
    int iErrorFlag = 0;
    long lLine = 0;
    // Do the relocation.
    while (!feof(fFileIn)) {

        // Deal with errors. 
        if( _fgetts( sLine, 32766, fFileIn ) == NULL) {
            if (iErrorFlag) {
                fclose(fFileIn);
                fclose(fFileOut);
                ::DeleteFile(sFileOut);
                uiAnswer = ERROR_INSTALL_FAILURE;
                break;
            }
            iErrorFlag++;
            continue;
        }
        _tcscpy_s(sWork1, 32766, sLine);
        sLoc = _tcsstr(sWork1, sStringIn);
        while (sLoc) {
            // "Cap" the initial string and copy it to sWork2, then append sStringOut to it.
            *sLoc = _T('\0');
            _tcscpy_s(sWork2, 32766, sWork1);
            _tcscat_s(sWork2, 32766, sStringOut);

            // Append the rest of the line.
            sLoc += iStringInLength;
            _tcscat_s(sWork2, 32766, sLoc);

            // Copy back out of our work area, so that they match.
            _tcscpy_s(sWork1, 32766, sWork2);

            // Advance along the string.
            sLoc -= iStringInLength;
            sLoc += iStringInLength;

            // Try another search.
            sLoc = _tcsstr(sLoc, sStringIn);

            // If we're done, copy to sLine so it can be written out.
            if (!sLoc) {
                _tcscpy_s(sLine, 32766, sWork1);
            }
        }
        
        // Write the line out.
        _fputts(sLine, fFileOut);

        // Check every so often for cancel button.
        lLine++;
        if (0 == (lLine % 100)) {
            uiAnswer = Blip(hModule);
            if (ERROR_SUCCESS != uiAnswer) {
                fclose(fFileIn);
                fclose(fFileOut);
                ::DeleteFile(sFileOut);
                return uiAnswer;
            }
        }

    }

    fflush(fFileOut);
    fclose(fFileIn);
    fclose(fFileOut);

    RETURN_ON_ERROR(uiAnswer, hModule, _T("ERROR: Relocate_File.1 FAILED"));

    BOOL bAnswer = TRUE;
    // Check for readonly status on the file.
    DWORD dwAttributes = ::GetFileAttributes(sFileIn);
    if (dwAttributes && FILE_ATTRIBUTE_READONLY) {
        bAnswer = ::SetFileAttributes(sFileIn, dwAttributes && !FILE_ATTRIBUTE_READONLY);
        if (bAnswer == FALSE) { 
            ::DeleteFile(sFileOut);
            SimpleLogString2(hModule, _T("ERROR: Relocate_File - failed to unset ReadOnly on "), sFileIn);
            uiAnswer = ERROR_INSTALL_FAILURE; 
        }
        RETURN_ON_ERROR(uiAnswer, hModule, _T("ERROR: Relocate_File.2 FAILED"));
    }

    uiAnswer = Relocate_MoveFile(hModule, sFileIn, sFileOut);
    RETURN_ON_ERROR(uiAnswer, hModule, _T("ERROR: Relocate_File.3 FAILED"));

    // Set readonly status back.
    if (dwAttributes && FILE_ATTRIBUTE_READONLY) {
        ::SetFileAttributes(sFileIn, dwAttributes);
    }

    return uiAnswer;
}


UINT Relocate_Worker(
    MSIHANDLE hModule,                // Handle of MSI being installed. [in]
                                    // Passed to most other routines.
    const TCHAR *sInstallDirectory,    // Directory being installed into.
    const TCHAR *sRelocationFile)    // File to use to relocate.
{
    UINT uiAnswer;
    FILE *fRelocationFileIn;
    FILE *fRelocationFileOut;
    TCHAR sLine[_MAX_PATH + 12];
    TCHAR sFileFrom[_MAX_PATH + 1];
    TCHAR sFileTo[_MAX_PATH + 1];
    TCHAR sDirectoryFrom[_MAX_PATH + 1];
    TCHAR sDirectoryTo[_MAX_PATH + 1];

    // Log what we're doing.
    SimpleLogString4(hModule, _T("Relocate_Worker dir="), sInstallDirectory, _T(" file="), sRelocationFile);

    // Get filename to open
    _tcscpy_s(sFileFrom, _MAX_PATH, sRelocationFile);
	_tcscpy_s(sFileTo, _MAX_PATH, sRelocationFile);
    _tcscat_s(sFileTo, _MAX_PATH, _T(".new"));

    // Open our files.
    errno_t eAnswer = 0;
    eAnswer = _tfopen_s(&fRelocationFileIn, sFileFrom, _T("rtS"));
    if (eAnswer != 0) {
        SimpleLogString3(hModule, _T("WARNING: Relocate_Worker - probably non-existing file "), sFileFrom, _T(" - gonna continue, just skipping this one"));
        return ERROR_SUCCESS;
    }

    // First line of relocation file has where to relocate from.
    if( _fgetts( sDirectoryFrom, _MAX_PATH + 1, fRelocationFileIn ) == NULL) {
        fclose(fRelocationFileIn);
        SimpleLogString1(hModule, _T("ERROR: Relocate_Worker - invalid first line"));
        return ERROR_INSTALL_FAILURE;
    }

    // Take off the line ending.
    *(sDirectoryFrom + _tcslen(sDirectoryFrom) - 1) = _T('\0');
    SimpleLogString2(hModule, _T("Relocate_Worker sDirectoryFrom="), sDirectoryFrom);

    // Second parameter is where to relocate to.
    //_tcscpy_s(sDirectoryTo, _MAX_PATH, sInstallDirectory);
	GetShortPathName(sInstallDirectory, sDirectoryTo, _MAX_PATH);
	SimpleLogString2(hModule, _T("Relocate_Worker sDirectoryTo="),  sDirectoryTo);

    // Make sire it ends in a slash.
    if (*(sDirectoryTo + _tcslen(sDirectoryTo) - 1) != _T('\\')) {
        _tcscat_s(sDirectoryTo, _MAX_PATH, _T("\\"));
    }

    // We don't need to relocate if the directories are identical, right? right.
    // It's not an error, however.
    if (0 == _tcscmp(sDirectoryFrom, sDirectoryTo)) {
        fclose(fRelocationFileIn);
        SimpleLogString2(hModule, _T("WARNING: Relocate_Worker, from/to dirs are the same - "),  sDirectoryTo);
        return ERROR_SUCCESS;
    }

    // Open up the file to write relocating to.
    eAnswer = _tfopen_s(&fRelocationFileOut, sFileTo, _T("wt"));
    if (eAnswer != 0) {
        fclose(fRelocationFileIn);
        SimpleLogString2(hModule, _T("ERROR: open.2 'wt' failed for "), sFileTo);
        return ERROR_INSTALL_FAILURE;
    }

    // Log what we're doing.
    SimpleLogString2(hModule, _T("Relocating from "), sDirectoryFrom);

    // Put where to relocate to in the file.
    _fputts(sDirectoryTo, fRelocationFileOut);
    _fputts(_T("\n"), fRelocationFileOut);

    int iErrorFlag = 0;
    // Go into the relocation loop.
    while (!feof(fRelocationFileIn)) {

        // Deal with errors. 
        if( _fgetts( sLine, _MAX_PATH + 11, fRelocationFileIn ) == NULL) {
            if (iErrorFlag) {
                SimpleLogString1(hModule, _T("ERROR: cannot fgetts line"));
                uiAnswer = ERROR_INSTALL_FAILURE;
                break;
            }
            iErrorFlag++;
            continue;
        }

        // Deal with comments.
        if ('#' == *sLine) {
            _fputts(sLine, fRelocationFileOut);
            continue;
        }

        // Deal with lines that contain only whitespace.
        if (_tcslen(sLine) <= _tcsspn(sLine, _T(" \t\n")))
            continue;

        // Check for the colon.
        if (NULL == _tcschr(sLine, _T(':')))
            continue;

        // We have a good line. So put it back out before we tokenize it.
        _fputts(sLine, fRelocationFileOut);

        // Take off the line ending for tokenizing purposes.
        *(sLine + _tcslen(sLine) - 1) = _T('\0');

        // Tokenize the line.
        TCHAR  sFileToRelocate[_MAX_PATH + 1];
        TCHAR  sRelocationType[17];
        TCHAR *sTokenContext = NULL;
        TCHAR *sToken = NULL;

        sToken = _tcstok_s(sLine, _T(":"), &sTokenContext);
        _tcscpy_s(sFileToRelocate, _MAX_PATH, sToken);
        sToken = _tcstok_s(NULL, _T("\n"), &sTokenContext);
        _tcscpy_s(sRelocationType, 16, sToken);

        // Actually relocate the file.
        uiAnswer = Relocate_File(hModule, sDirectoryFrom, sDirectoryTo, sFileToRelocate, sRelocationType);
        if (uiAnswer != ERROR_SUCCESS) {
            SimpleLogString1(hModule, _T("ERROR: Relocate_File failure"));
            break;
        }
    }

    fflush(fRelocationFileOut);
    fclose(fRelocationFileIn);
    fclose(fRelocationFileOut);

    RETURN_ON_ERROR(uiAnswer, hModule, _T("ERROR: Relocate_Worker.1 FAILED"));

    uiAnswer = Relocate_MoveFile(hModule, sFileFrom, sFileTo);    
    RETURN_ON_ERROR(uiAnswer, hModule, _T("ERROR: Relocate_Worker.2 FAILED"));

    SimpleLogString1(hModule, _T("Relocate_Worker end"));
    return uiAnswer;
}

UINT __stdcall RelocateMSI(
    MSIHANDLE hModule) // Handle of MSI being installed. [in]
                       // Passed to most other routines.
{
    TCHAR sInstallDirectory[MAX_PATH + 1];
    TCHAR sRelocationFile[MAX_PATH + 1];
    TCHAR sCAData[MAX_PATH * 2 + 7];
    UINT uiAnswer;
    DWORD dwPropLength;

    // Get directory to relocate to.
    dwPropLength = MAX_PATH * 2 + 6; 
    uiAnswer = ::MsiGetProperty(hModule, TEXT("CustomActionData"), sCAData, &dwPropLength); 
    RETURN_ON_ERROR(uiAnswer, hModule, _T("ERROR: RelocateMSI MsiGetProperty[CustomActionData] FAILED"));

    TCHAR *sTokenContext = NULL;
    TCHAR *sToken = NULL;

    SimpleLogString2(hModule, _T("RelocateMSI CustomActionData="), sCAData);    

    sToken = _tcstok_s(sCAData, _T(";"), &sTokenContext);
    if (!sToken || 0 != _tcscmp(sToken, _T("MSI"))) {
        SimpleLogString1(hModule, _T("ERROR: RelocateMSI CustomActionData - invalid token1"));
        return ERROR_INSTALL_FAILURE;
    }

    sToken = _tcstok_s(NULL, _T(";"), &sTokenContext);
    if (!sToken) {
        SimpleLogString1(hModule, _T("ERROR: RelocateMSI CustomActionData - invalid token2"));
        return ERROR_INSTALL_FAILURE;
    }
    _tcscpy_s(sInstallDirectory, _MAX_PATH, sToken);

    sToken = _tcstok_s(NULL, _T(";"), &sTokenContext);
    if (!sToken) {
        SimpleLogString1(hModule, _T("ERROR: RelocateMSI CustomActionData - invalid token3"));
        return ERROR_INSTALL_FAILURE;
    }
    _tcscpy_s(sRelocationFile, _MAX_PATH, sToken);

    uiAnswer = Relocate_Worker(hModule, sInstallDirectory, sRelocationFile);
    SimpleLogString1(hModule, _T("RelocateMSI end"));
    return uiAnswer;
}



