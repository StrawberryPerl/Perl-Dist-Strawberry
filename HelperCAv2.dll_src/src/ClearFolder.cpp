// ClearFolder.cpp : Defines the Clear Folder custom action.
//
// Copyright (c) Curtis Jewell 2009.
//
// This code is free software; you can redistribute it and/or modify it
// under the same terms as Perl itself.

// ##### EXPORTED FUCTIONS: ClearFolderFast ClearFolderSlow ClearSiteFolder

#include "stdafx.h"
#include "ErrorMsg.h"

// Default DllMain, since nothing special is happening here.
BOOL APIENTRY DllMain(HMODULE hModule, DWORD ul_reason_for_call, LPVOID lpReserved)
{
    return TRUE;
}

// Gets GUID for Directory columns. Return value needs to be free()'d.
LPTSTR CreateDirectoryGUID()
{
    GUID guid;
    ::CoCreateGuid(&guid);

    LPTSTR sGUID = (LPTSTR)malloc(40 * sizeof(TCHAR)); 

    // Formatting GUID correctly.
    _stprintf_s(sGUID, 40, 
        TEXT("DX_%.08X_%.04X_%.04X_%.02X%.02X_%.02X%.02X%.02X%.02X%.02X%.02X"),
        guid.Data1, guid.Data2, guid.Data3, 
        guid.Data4[0], guid.Data4[1], guid.Data4[2], guid.Data4[3], 
        guid.Data4[4], guid.Data4[5], guid.Data4[6], guid.Data4[7]);

    return sGUID;
}

// Gets GUID for FileKey column. Return value needs to be free()'d.
LPTSTR CreateFileGUID()
{
    GUID guid;
    ::CoCreateGuid(&guid);

    LPTSTR sGUID = (LPTSTR)malloc(40 * sizeof(TCHAR)); 

    // Formatting GUID correctly.
    _stprintf_s(sGUID, 40, 
        TEXT("FX_%.08X_%.04X_%.04X_%.02X%.02X_%.02X%.02X%.02X%.02X%.02X%.02X"),
        guid.Data1, guid.Data2, guid.Data3, 
        guid.Data4[0], guid.Data4[1], guid.Data4[2], guid.Data4[3], 
        guid.Data4[4], guid.Data4[5], guid.Data4[6], guid.Data4[7]);

    return sGUID;
}

// Finds directory ID for directory named in sDirectory.
UINT GetDirectoryID(
    MSIHANDLE hModule,    // Handle of MSI being installed. [in]
    LPCTSTR sParentDirID, // ID of parent directory (to search in). [in]
    LPCTSTR sDirectory,   // Directory to find the ID for. [in]
    LPTSTR &sDirectoryID) // ID of directory. Can be NULL. Must be free()'d if not. [out]
{
#ifdef _DEBUG
    SimpleLogString4(hModule, _T("DEBUG: GetDirectoryID sParentDirID="), sParentDirID, _T(" sDirectory="), sDirectory);
#endif

    LPCTSTR sSQL = _T("SELECT `Directory`,`DefaultDir` FROM `Directory` WHERE `Directory_Parent`= ?");

    UINT uiAnswer = ERROR_SUCCESS;
    PMSIHANDLE phView;

    // Get database handle
    PMSIHANDLE phDB = ::MsiGetActiveDatabase(hModule);
    RETURN_IF_NULL(phDB, hModule, _T("ERROR: GetDirectoryID - MsiGetActiveDatabase FAILED"));

    // Open the view.
    uiAnswer = ::MsiDatabaseOpenView(phDB, sSQL, &phView);
    LOG_DEBUG_DETAILS_ON_ERROR(uiAnswer, hModule);
    RETURN_ON_ERROR(uiAnswer, hModule, _T("ERROR: GetDirectoryID - MsiDatabaseOpenView FAILED"));

    // Create and fill the record.
    PMSIHANDLE phRecordSelect = ::MsiCreateRecord(1);
    RETURN_IF_NULL(phRecordSelect, hModule, _T("ERROR: GetDirectoryID - MsiCreateRecord FAILED"));

    uiAnswer = ::MsiRecordSetString(phRecordSelect, 1, sParentDirID);
    RETURN_ON_ERROR(uiAnswer, hModule, _T("ERROR: GetDirectoryID - MsiRecordSetString FAILED"));

    // Execute the SQL statement.
    uiAnswer = ::MsiViewExecute(phView, phRecordSelect);
    RETURN_ON_ERROR(uiAnswer, hModule, _T("ERROR: GetDirectoryID - MsiViewExecute FAILED"));

    PMSIHANDLE phRecord = MsiCreateRecord(2);
    TCHAR sDir[MAX_PATH + 1];
    TCHAR* sPipeLocation = NULL;
    DWORD dwLengthID = 0;
    
    // Fetch the first row from the view.
    sDirectoryID = NULL;
    uiAnswer = ::MsiViewFetch(phView, &phRecord);

    while (uiAnswer == ERROR_SUCCESS) {

        // Get the directory.
        DWORD dwLengthDir = MAX_PATH;
        uiAnswer = ::MsiRecordGetString(phRecord, 2, sDir, &dwLengthDir);

#ifdef _DEBUG
    SimpleLogString4(hModule, _T("DEBUG: GetDirectoryID looping sDir="), sDir, _T(" sDirectory="), sDirectory);
#endif
        // We found our directory.
        if (_tcscmp(sDirectory, sDir) == 0) {
            dwLengthID = 0;
            uiAnswer = ::MsiRecordGetString(phRecord, 1, _T(""), &dwLengthID);
            if (uiAnswer == ERROR_MORE_DATA) {
                dwLengthID++;
                sDirectoryID = (TCHAR *)malloc(dwLengthID * sizeof(TCHAR));
                uiAnswer = ::MsiRecordGetString(phRecord, 1,sDirectoryID, &dwLengthID);
            }

            // We're done! Hurray!
            uiAnswer = ::MsiViewClose(phView);
            RETURN_ON_ERROR_FREE(uiAnswer, (TCHAR *)sDirectoryID, hModule, _T("ERROR: GetDirectoryID - MsiViewClose.1 FAILED"));

            return uiAnswer;
        }

        sPipeLocation = _tcschr(sDir, _T('|'));
        if (sPipeLocation != NULL) {
            // Adjust the position past the pipe character.
            sPipeLocation = _tcsninc(sPipeLocation, 1); 

            // NOW compare the filename!
            if (_tcscmp(sDirectory, sPipeLocation) == 0) {
                dwLengthID = 0;
                uiAnswer = ::MsiRecordGetString(phRecord, 1, _T(""), &dwLengthID);
                if (uiAnswer == ERROR_MORE_DATA) {
                    dwLengthID++;
                    sDirectoryID = (TCHAR *)malloc(dwLengthID * sizeof(TCHAR));
                    uiAnswer = ::MsiRecordGetString(phRecord, 1,sDirectoryID, &dwLengthID);
                }
                
                // We're done! Hurray!
                uiAnswer = ::MsiViewClose(phView);
                RETURN_ON_ERROR_FREE(uiAnswer, (TCHAR *)sDirectoryID, hModule, _T("ERROR: GetDirectoryID - MsiViewClose.2 FAILED"));

                return uiAnswer;
            }
        }

        // Fetch the next row.
        uiAnswer = ::MsiViewFetch(phView, &phRecord);
    }

    // No more items is not an error.
    if (uiAnswer == ERROR_NO_MORE_ITEMS) {
        uiAnswer = ERROR_SUCCESS;
    }

    return uiAnswer;
}

// Is the file in sFileName in the directory referred to by sDirectoryID installed by this MSI? Returned in bInstalled.
UINT IsFileInstalled(
    MSIHANDLE hModule,    // Handle of MSI being installed. [in]
    LPCTSTR sDirectoryID, // ID of directory being checked. [in]
    LPCTSTR sFileName,    // Filename to check. [in]
    bool& bInstalled)     // Whether file was installed by MSI or not. [out]
{
#ifdef _DEBUG
    SimpleLogString4(hModule, _T("DEBUG: IsFileInstalled sDirectoryID="), sDirectoryID, _T(" sFileName="), sFileName);
#endif

    LPCTSTR sSQL = _T("SELECT `File`.`FileName` FROM `Component`,`File` WHERE `Component`.`Component`=`File`.`Component_` AND `Component`.`Directory_` = ?");
    PMSIHANDLE phView;
    bInstalled = false;

    UINT uiAnswer = ERROR_SUCCESS;

    // Get database handle
    PMSIHANDLE phDB = ::MsiGetActiveDatabase(hModule);
    RETURN_IF_NULL(phDB, hModule, _T("ERROR: IsFileInstalled - MsiGetActiveDatabase FAILED"));

    // Open the view.
    uiAnswer = ::MsiDatabaseOpenView(phDB, sSQL, &phView);
    LOG_DEBUG_DETAILS_ON_ERROR(uiAnswer, hModule);
    RETURN_ON_ERROR(uiAnswer, hModule, _T("ERROR: IsFileInstalled - MsiDatabaseOpenView FAILED"));

    // Create and fill the record.
    PMSIHANDLE phRecord = MsiCreateRecord(1);
    RETURN_IF_NULL(phRecord, hModule, _T("ERROR: IsFileInstalled - MsiCreateRecord FAILED"));

    uiAnswer = ::MsiRecordSetString(phRecord, 1, sDirectoryID);
    RETURN_ON_ERROR(uiAnswer, hModule, _T("ERROR: IsFileInstalled - MsiRecordSetString FAILED"));

    // Execute the view.
    uiAnswer = ::MsiViewExecute(phView, phRecord);
    RETURN_ON_ERROR(uiAnswer, hModule, _T("ERROR: IsFileInstalled - MsiViewExecute FAILED"));

    TCHAR sFile[MAX_PATH + 1];
    TCHAR* sPipeLocation = NULL;
    
#ifdef _DEBUG
    SimpleLogString1(hModule, _T("DEBUG: IsFileInstalled - gonna loop"));
#endif

    // Fetch the first row.
    uiAnswer = ::MsiViewFetch(phView, &phRecord);

    while (uiAnswer == ERROR_SUCCESS) {

        // Get the filename.
        DWORD dwLengthFile = MAX_PATH + 1;
        uiAnswer = ::MsiRecordGetString(phRecord, 1, sFile, &dwLengthFile);

        // Compare the filename.
        if (_tcscmp(sFileName, sFile) == 0) {
#ifdef _DEBUG
            SimpleLogString1(hModule, _T("DEBUG: IsFileInstalled - true.1"));
#endif
            bInstalled = true;
            uiAnswer = ::MsiViewClose(phView);
            return uiAnswer;
        }

        sPipeLocation = _tcschr(sFile, _T('|'));
        if (sPipeLocation != NULL) {
            // Adjust the position past the pipe character.
            sPipeLocation = _tcsninc(sPipeLocation, 1); 

            // NOW compare the filename!
            if (_tcscmp(sFileName, sPipeLocation) == 0) {
#ifdef _DEBUG
                SimpleLogString1(hModule, _T("DEBUG: IsFileInstalled - true.2"));
#endif
                bInstalled = true;
                uiAnswer = ::MsiViewClose(phView);
                return uiAnswer;
            }
        }

        // Fetch the next row.
        uiAnswer = ::MsiViewFetch(phView, &phRecord);
    }

    // It's not an error if we had no more rows to search for.
    if (uiAnswer == ERROR_NO_MORE_ITEMS) {
#ifdef _DEBUG
        SimpleLogString1(hModule, _T("DEBUG: IsFileInstalled - no more items"));
#endif
        uiAnswer = ERROR_SUCCESS;
    } else {
        return uiAnswer;
    }

    // Close out and get out of here.
    uiAnswer = ::MsiViewClose(phView);
    return uiAnswer;
}

// Adds a record to remove a file in the directory referred to by sDirectoryID. (The filename can be *.* to remove all files.)
UINT AddRemoveFileRecord(
    MSIHANDLE hModule,    // Handle of MSI being installed. [in]
    LPCTSTR sDirectoryID, // ID of directory to remove files from. [in]
    LPCTSTR sFileName,    // Filename to remove. [in]
    LPCTSTR sRemovalComponent)
{
#ifdef _DEBUG
    SimpleLogString4(hModule, _T("DEBUG: AddRemoveFileRecord sDirectoryID="), sDirectoryID, _T(" sFileName="), sFileName);
    SimpleLogString2(hModule, _T("DEBUG: AddRemoveFileRecord sRemovalComponent="), sRemovalComponent);
#endif

    PMSIHANDLE phView;
    UINT uiAnswer = ERROR_SUCCESS;

    // Get database handle
    PMSIHANDLE phDB = ::MsiGetActiveDatabase(hModule);
    RETURN_IF_NULL(phDB, hModule, _T("ERROR: AddRemoveFileRecord - MsiGetActiveDatabase FAILED"));

    // Open the view.
    // NOTE: all the parameterized values (?) must precede all nonparameterized values
    LPCTSTR sSQL = _T("INSERT INTO `RemoveFile` (`FileKey`, `Component_`, `DirProperty`, `FileName`, `InstallMode`) VALUES (?, ?, ?, ?, 2) TEMPORARY");    
    uiAnswer = ::MsiDatabaseOpenView(phDB, sSQL, &phView);
    LOG_DEBUG_DETAILS_ON_ERROR(uiAnswer, hModule);
    RETURN_ON_ERROR(uiAnswer, hModule, _T("ERROR: AddRemoveFileRecord - MsiDatabaseOpenView FAILED"));

    // Create a record storing the values to add.
    PMSIHANDLE phRecord = MsiCreateRecord(4);
    RETURN_IF_NULL(phRecord, hModule, _T("ERROR: AddRemoveFileRecord - MsiCreateRecord FAILED"));

    // Fill the record.
    LPTSTR sFileID = CreateFileGUID();

    uiAnswer = ::MsiRecordSetString(phRecord, 1, sFileID);
    RETURN_ON_ERROR_FREE(uiAnswer, (LPTSTR)sFileID, hModule, _T("ERROR: AddRemoveFileRecord - MsiRecordSetString.1 FAILED"));

    uiAnswer = ::MsiRecordSetString(phRecord, 2, sRemovalComponent);
    RETURN_ON_ERROR_FREE(uiAnswer, (LPTSTR)sFileID, hModule, _T("ERROR: AddRemoveFileRecord - MsiRecordSetString.2 FAILED"));

    uiAnswer = ::MsiRecordSetString(phRecord, 3, sDirectoryID);
    RETURN_ON_ERROR_FREE(uiAnswer, (LPTSTR)sFileID, hModule, _T("ERROR: AddRemoveFileRecord - MsiRecordSetString.3 FAILED"));

    uiAnswer = ::MsiRecordSetString(phRecord, 4, sFileName);
    RETURN_ON_ERROR_FREE(uiAnswer, (LPTSTR)sFileID, hModule, _T("ERROR: AddRemoveFileRecord - MsiRecordSetString.4 FAILED"));

    // Execute the SQL statement and close the view.
    uiAnswer = ::MsiViewExecute(phView, phRecord);
    LOG_DEBUG_DETAILS_ON_ERROR(uiAnswer, hModule);
    RETURN_ON_ERROR_FREE(uiAnswer, (LPTSTR)sFileID, hModule, _T("ERROR: AddRemoveFileRecord - MsiViewExecute FAILED"));

    uiAnswer = ::MsiViewClose(phView);
    free((LPTSTR)sFileID);
    return uiAnswer;    
}

// Adds a record to remove the directory referred to by sDirectoryID.
UINT AddRemoveDirectoryRecord(
    MSIHANDLE hModule,    // Handle of MSI being installed. [in]
    LPCTSTR sDirectoryID, // ID of directory to remove. [in]
    LPCTSTR sRemovalComponent)
{
#ifdef _DEBUG
    SimpleLogString2(hModule, _T("DEBUG: AddRemoveDirectoryRecord sDirectoryID="), sDirectoryID);
    SimpleLogString2(hModule, _T("DEBUG: AddRemoveDirectoryRecord sRemovalComponent="), sRemovalComponent);
#endif

    LPCTSTR sSQL = _T("INSERT INTO `RemoveFile` (`FileKey`, `Component_`, `DirProperty`, `FileName`, `InstallMode`) VALUES (?, ?, ?, ?, 2) TEMPORARY");

    PMSIHANDLE phView;
    UINT uiAnswer = ERROR_SUCCESS;

    // Get database handle
    PMSIHANDLE phDB = ::MsiGetActiveDatabase(hModule);
    RETURN_IF_NULL(phDB, hModule, _T("ERROR: AddRemoveDirectoryRecord - MsiGetActiveDatabase FAILED"));

    // Open the view.
    uiAnswer = ::MsiDatabaseOpenView(phDB, sSQL, &phView);
    LOG_DEBUG_DETAILS_ON_ERROR(uiAnswer, hModule);
    RETURN_ON_ERROR(uiAnswer, hModule, _T("ERROR: AddRemoveDirectoryRecord - MsiDatabaseOpenView FAILED"));

    // Create a record storing the values to add.
    PMSIHANDLE phRecord = MsiCreateRecord(4);
    RETURN_IF_NULL(phRecord, hModule, _T("ERROR: AddRemoveDirectoryRecord - MsiCreateRecord FAILED"));

    // Fill the record.
    LPTSTR sFileID = CreateFileGUID();

    uiAnswer = ::MsiRecordSetString(phRecord, 1, sFileID);
    RETURN_ON_ERROR_FREE(uiAnswer, (LPTSTR)sFileID, hModule, _T("ERROR: AddRemoveDirectoryRecord - MsiRecordSetString.1 FAILED"));

    uiAnswer = ::MsiRecordSetString(phRecord, 2, sRemovalComponent);
    RETURN_ON_ERROR_FREE(uiAnswer, (LPTSTR)sFileID, hModule, _T("ERROR: AddRemoveDirectoryRecord - MsiRecordSetString.2 FAILED"));

    uiAnswer = ::MsiRecordSetString(phRecord, 3, sDirectoryID);
    RETURN_ON_ERROR_FREE(uiAnswer, (LPTSTR)sFileID, hModule, _T("ERROR: AddRemoveDirectoryRecord - MsiRecordSetString.3 FAILED"));

    uiAnswer = ::MsiRecordSetString(phRecord, 4, NULL); // NULL Filename means remove directory
    RETURN_ON_ERROR_FREE(uiAnswer, (LPTSTR)sFileID, hModule, _T("ERROR: AddRemoveDirectoryRecord - MsiRecordSetString.4 FAILED"));

    // Execute the SQL statement and close the view.
    uiAnswer = ::MsiViewExecute(phView, phRecord);
    LOG_DEBUG_DETAILS_ON_ERROR(uiAnswer, hModule);
    RETURN_ON_ERROR_FREE(uiAnswer, (LPTSTR)sFileID, hModule, _T("ERROR: AddRemoveDirectoryRecord - MsiViewExecute FAILED"));

    uiAnswer = ::MsiViewClose(phView);
    free((LPTSTR)sFileID);
    return uiAnswer;    
}


// Adds a record to reference the directory referred to by sParentDirID and sName
// in sDirectoryID. sDirectoryID will need free()'d when done.
UINT AddDirectoryRecord(
    MSIHANDLE hModule,     // Handle of MSI being installed. [in]
    LPCTSTR sParentDirID,  // ID of parent directory. [in]
    LPCTSTR sName,         // Name of directory being added to MSI. [in]
    LPTSTR &sDirectoryID)  // ID to use when adding directory. [out]
{
#ifdef _DEBUG
    SimpleLogString4(hModule, _T("DEBUG: AddDirectoryRecord sParentDirID="), sParentDirID, _T(" sName="), sName);
#endif

    LPCTSTR sSQL = _T("INSERT INTO `Directory` (`Directory`, `Directory_Parent`, `DefaultDir`) VALUES (?, ?, ?) TEMPORARY");

    PMSIHANDLE phView;
    UINT uiAnswer = ERROR_SUCCESS;

    // Get database handle
    PMSIHANDLE phDB = ::MsiGetActiveDatabase(hModule);
    RETURN_IF_NULL(phDB, hModule, _T("ERROR: AddDirectoryRecord - MsiGetActiveDatabase FAILED"));

    // Open the view.
    uiAnswer = ::MsiDatabaseOpenView(phDB, sSQL, &phView);
    LOG_DEBUG_DETAILS_ON_ERROR(uiAnswer, hModule);
    RETURN_ON_ERROR(uiAnswer, hModule, _T("ERROR: AddDirectoryRecord - MsiDatabaseOpenView FAILED"));

    // Create a record storing the values to add.
    PMSIHANDLE phRecord = MsiCreateRecord(3);
    RETURN_IF_NULL(phRecord, hModule, _T("ERROR: AddDirectoryRecord - MsiCreateRecord FAILED"));

    // Get the ID to add.
    sDirectoryID = CreateDirectoryGUID();

    // Fill the record.
    uiAnswer = ::MsiRecordSetString(phRecord, 1, sDirectoryID);
    RETURN_ON_ERROR(uiAnswer, hModule, _T("ERROR: AddDirectoryRecord - MsiRecordSetString.1 FAILED"));

    uiAnswer = ::MsiRecordSetString(phRecord, 2, sParentDirID);
    RETURN_ON_ERROR(uiAnswer, hModule, _T("ERROR: AddDirectoryRecord - MsiRecordSetString.2 FAILED"));

    uiAnswer = ::MsiRecordSetString(phRecord, 3, sName);
    RETURN_ON_ERROR(uiAnswer, hModule, _T("ERROR: AddDirectoryRecord - MsiRecordSetString.3 FAILED"));

    // Execute the SQL statement and close the view.
    uiAnswer = ::MsiViewExecute(phView, phRecord);
    RETURN_ON_ERROR(uiAnswer, hModule, _T("ERROR: AddDirectoryRecord - MsiViewExecute FAILED"));

    uiAnswer = ::MsiViewClose(phView);
    return uiAnswer;    
}

// The main routine used for new directories.
UINT AddDirectoryQuick(
    MSIHANDLE hModule,         // Handle of MSI being installed. [in]
    LPCTSTR sCurrentDir,       // Directory being searched. [in]
    LPCTSTR sCurrentDirID,     // ID of directory being searched. [in]
    LPCTSTR sRemovalComponent)
{
#ifdef _DEBUG
    SimpleLogString4(hModule, _T("DEBUG: AddDirectoryQuick sCurrentDir="), sCurrentDir, _T(" sCurrentDirID="), sCurrentDirID);
#endif

    // Set up the wildcard for the files to find.
    TCHAR sFind[MAX_PATH + 1];
    _tcscpy_s(sFind, MAX_PATH, sCurrentDir);
    _tcscat_s(sFind, MAX_PATH, TEXT("\\*"));

    // Set up other variables.
    TCHAR sSubDir[MAX_PATH + 1];
    WIN32_FIND_DATA found;

    HANDLE hFindHandle;

    BOOL bFileFound = FALSE;
    UINT uiAnswer = ERROR_SUCCESS;
    UINT uiCounter = 0;
    LPCTSTR sID = NULL;

    // Start finding files and directories.
    hFindHandle = ::FindFirstFile(sFind, &found);

    if (hFindHandle != INVALID_HANDLE_VALUE) {
        bFileFound = TRUE;
    }

    while (bFileFound & (uiAnswer == ERROR_SUCCESS)) {
        if ((found.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) == FILE_ATTRIBUTE_DIRECTORY) {

            // Handle . and ..
            if (0 == _tcscmp(found.cFileName, TEXT("."))) {
                bFileFound = ::FindNextFile(hFindHandle, &found);
                continue;
            }

            if (0 == _tcscmp(found.cFileName, TEXT(".."))) {
                bFileFound = ::FindNextFile(hFindHandle, &found);
                continue;
            }

            // Create a new directory spec to recurse into.
            _tcscpy_s(sSubDir, MAX_PATH, sCurrentDir);
            _tcscat_s(sSubDir, MAX_PATH, found.cFileName);
            _tcscat_s(sSubDir, MAX_PATH, TEXT("\\"));

            // We need to get a directory ID, add the property, then go down 
            // into this directory.
            sID = CreateDirectoryGUID(); 
            uiAnswer = ::MsiSetProperty(hModule, sID, sSubDir); 
            RETURN_ON_ERROR_FREE(uiAnswer, (LPTSTR)sID, hModule, _T("ERROR: AddDirectoryQuick - MsiSetProperty FAILED"));

            SimpleLogString4(hModule, _T("MSPQ: Added directory property with ID string: "), sID, _T(" and name: "), sSubDir);
            
            uiAnswer = AddDirectoryQuick(hModule, sSubDir, sID, sRemovalComponent);
            RETURN_ON_ERROR_FREE(uiAnswer, (LPTSTR)sID, hModule, _T("ERROR: AddDirectoryQuick FAILED"));

            free((LPTSTR)sID);    
        }
    
        // Check and see if there is another file to process.
        bFileFound = ::FindNextFile(hFindHandle, &found);
    }
    
    // Close the find handle.
    ::FindClose(hFindHandle);
    
    // add an entry to delete ourselves.
    uiAnswer = AddRemoveDirectoryRecord(hModule, sCurrentDirID, sRemovalComponent);
    RETURN_ON_ERROR(uiAnswer, hModule, _T("ERROR: AddDirectoryQuick - AddRemoveDirectoryRecord FAILED"));

    SimpleLogString4(hModule, _T("ARDR: Added remove directory entry with ID string: "), sCurrentDirID, _T(" and name: "), sCurrentDir);

    uiAnswer = AddRemoveFileRecord(hModule, sCurrentDirID, _T("*.*"), sRemovalComponent);
    RETURN_ON_ERROR(uiAnswer, hModule, _T("ERROR: AddDirectoryQuick - AddRemoveFileRecord FAILED"));

    SimpleLogString3(hModule, _T("ARFR3: Added remove file record entry with ID string: "), sCurrentDirID, _T(" for all files."));
    
    return uiAnswer;
}

// The main routine used for previously existing directories.
UINT AddDirectory(
    MSIHANDLE hModule,         // Handle of MSI being installed. [in]
    LPCTSTR sCurrentDir,       // Directory being searched. [in]
    LPCTSTR sCurrentDirID,     // ID of directory being searched. [in]
    bool bUninstallSite,       // Do we uninstall the site directory? [in]
    bool& bDeleteEntryCreated, // Was a delete-directory entry created by this call? [out]
    LPCTSTR sRemovalComponent)
{
#ifdef _DEBUG
    SimpleLogString4(hModule, _T("DEBUG: AddDirectory sCurrentDir="), sCurrentDir, _T(" sCurrentDirID="), sCurrentDirID);
    SimpleLogString2(hModule, _T("DEBUG: AddDirectory bUninstallSite="), bUninstallSite ? _T("yes") : _T("no"));
#endif

    // Set up the wildcard for the files to find.
    TCHAR sFind[MAX_PATH + 1];
    _tcscpy_s(sFind, MAX_PATH, sCurrentDir);
    _tcscat_s(sFind, MAX_PATH, TEXT("\\*"));

    // Set up other variables.
    TCHAR sSubDir[MAX_PATH + 1];
    TCHAR sCurrentIDCheck[7];
    WIN32_FIND_DATA found;
    TCHAR* sSubDirID = NULL;
    bool bDeleteEntryCreatedBelow = false;

    HANDLE hFindHandle;

    BOOL bFileFound = FALSE;
    UINT uiAnswer = ERROR_SUCCESS;
    bool bDirectoryFound = false;
    bool bInstalled = false;

    LPTSTR sID = CreateDirectoryGUID();

    // We need to copy the first part of sCurrentDirID so
    // we can make the "Do we uninstall site?" check.
    _tcsncpy_s(sCurrentIDCheck, 6, sCurrentDirID, _TRUNCATE);

    // Start finding files and directories.
    hFindHandle = ::FindFirstFile(sFind, &found);
    if (hFindHandle != INVALID_HANDLE_VALUE) {
        bFileFound = TRUE;
    }

    while (bFileFound & (uiAnswer == ERROR_SUCCESS)) {
        if ((found.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) == FILE_ATTRIBUTE_DIRECTORY) {

            // Handle . and ..
            if (0 == _tcscmp(found.cFileName, TEXT("."))) {
                bFileFound = ::FindNextFile(hFindHandle, &found);
                continue;
            }

            if (0 == _tcscmp(found.cFileName, TEXT(".."))) {
                bFileFound = ::FindNextFile(hFindHandle, &found);
                continue;
            }

            // If we're not supposed to uninstall the site directory, skip it.
            if ((!bUninstallSite) &&
                (0 == _tcscmp(found.cFileName, TEXT("site"))) &&
                (0 == _tcscmp(sCurrentIDCheck, TEXT("d_perl")))) {
                bFileFound = ::FindNextFile(hFindHandle, &found);
                continue;
            }

            // Create a new directory spec to recurse into.
            _tcscpy_s(sSubDir, MAX_PATH, sCurrentDir);
            _tcscat_s(sSubDir, MAX_PATH, found.cFileName);
            _tcscat_s(sSubDir, MAX_PATH, TEXT("\\"));

            // Try and get the ID that already exists.
            uiAnswer = GetDirectoryID(hModule, sCurrentDirID, found.cFileName, sSubDirID);
            RETURN_ON_ERROR_FREE(uiAnswer, LPTSTR(sID), hModule, _T("ERROR: AddDirectory - GetDirectoryID FAILED"));

            if (sSubDirID != NULL) {
                // We have an existing directory ID.
                uiAnswer = AddDirectory(
                    hModule, sSubDir, sSubDirID, bUninstallSite, bDeleteEntryCreatedBelow, sRemovalComponent);
                RETURN_ON_ERROR_FREE2(uiAnswer, (LPTSTR)sID, (TCHAR*)sSubDirID, hModule, _T("ERROR: AddDirectory - AddDirectory FAILED"));
                free(sSubDirID);
            } else {
                // We need to get a directory ID, add the property, then go down 
                // into this directory.
                sID = CreateDirectoryGUID(); 
                uiAnswer = ::MsiSetProperty(hModule, sID, sSubDir); 
                RETURN_ON_ERROR_FREE(uiAnswer, (LPTSTR)sID, hModule, _T("ERROR: AddDirectory - MsiSetProperty FAILED"));

                SimpleLogString4(hModule, _T("MSP: Added directory property with ID string: "), sID, _T(" and name: "), sSubDir);
                
                uiAnswer = AddDirectoryQuick(hModule, sSubDir, sID, sRemovalComponent);
                bDeleteEntryCreatedBelow = true;
                RETURN_ON_ERROR_FREE(uiAnswer, (LPTSTR)sID, hModule, _T("ERROR: AddDirectory - AddDirectoryQuick FAILED"));
            }
        } else {
            // Verify that the file wasn't installed by this MSI.
            bInstalled = false;

            uiAnswer = IsFileInstalled(hModule, sCurrentDirID, found.cFileName, bInstalled);
            RETURN_ON_ERROR_FREE(uiAnswer, (LPTSTR)sID, hModule, _T("ERROR: AddDirectory - IsFileInstalled FAILED"));

            if (!bInstalled) {
                uiAnswer = AddRemoveFileRecord(hModule, sCurrentDirID, found.cFileName, sRemovalComponent);
                RETURN_ON_ERROR_FREE(uiAnswer, (LPTSTR)sID, hModule, _T("ERROR: AddDirectory - AddRemoveFileRecord FAILED"));
                SimpleLogString4(hModule, _T("ARFR1: Added remove file record entry with ID string: "), sCurrentDirID, _T(" and name: "), found.cFileName);
            }
        }
    
        // Check and see if there is another file to process.
        bFileFound = ::FindNextFile(hFindHandle, &found);
    }
    
    // Close the find handle.
    ::FindClose(hFindHandle);
    
    // If we are an extra directory, add an entry to delete ourselves.
    if (bDeleteEntryCreatedBelow){
        uiAnswer = AddRemoveDirectoryRecord(hModule, sCurrentDirID, sRemovalComponent);
        bDeleteEntryCreated = true;
        RETURN_ON_ERROR_FREE(uiAnswer, (LPTSTR)sID, hModule, _T("ERROR: AddDirectory - AddRemoveDirectoryRecord FAILED"));
        SimpleLogString4(hModule, _T("ARDR: Added remove directory entry with ID string: "), sCurrentDirID, _T(" and name: "), sCurrentDir);
    } 

    // Clean up after ourselves.
    free((LPTSTR)sID);    
#ifdef _DEBUG
    SimpleLogString1(hModule, _T("DEBUG: AddDirectory end"));
#endif
    return uiAnswer;
}

// Quick way to handle 
UINT AddTopDirectoryQuick(
    MSIHANDLE hModule,         // Handle of MSI being installed. [in]
    LPCTSTR sCurrentDir,       // Directory being searched. [in]
    LPCTSTR sCurrentDirID,     // ID of directory being searched. [in]
    bool& bDeleteEntryCreated, // Was a delete-directory entry created by this call? [out]
    LPCTSTR sRemovalComponent)
{
#ifdef _DEBUG
    SimpleLogString4(hModule, _T("DEBUG: AddTopDirectoryQuick sCurrentDir="), sCurrentDir, _T(" sCurrentDirID="), sCurrentDirID);
#endif

    // Set up the wildcard for the files to find.
    TCHAR sFind[MAX_PATH + 1];
    _tcscpy_s(sFind, MAX_PATH, sCurrentDir);
    _tcscat_s(sFind, MAX_PATH, TEXT("\\*"));

    // Set up other variables.
    TCHAR sSubDir[MAX_PATH + 1];
    WIN32_FIND_DATA found;
    TCHAR* sSubDirID = NULL;
    bool bDeleteEntryCreatedBelow = false;

    HANDLE hFindHandle;

    BOOL bFileFound = FALSE;
    UINT uiAnswer = ERROR_SUCCESS;
    bool bDirectoryFound = false;
    bool bInstalled = false;

    LPTSTR sID = CreateDirectoryGUID();

    // Start finding files and directories.
    hFindHandle = ::FindFirstFile(sFind, &found);
    if (hFindHandle != INVALID_HANDLE_VALUE) {
        bFileFound = TRUE;
    }

    while (bFileFound & (uiAnswer == ERROR_SUCCESS)) {
        if ((found.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) == FILE_ATTRIBUTE_DIRECTORY) {

            // Handle . and ..
            if (0 == _tcscmp(found.cFileName, TEXT("."))) {
                bFileFound = ::FindNextFile(hFindHandle, &found);
                continue;
            }
            if (0 == _tcscmp(found.cFileName, TEXT(".."))) {
                bFileFound = ::FindNextFile(hFindHandle, &found);
                continue;
            }

            bool bQuickUninstallCheck;
            bQuickUninstallCheck =  (0 == _tcscmp(found.cFileName, TEXT("cpan"))) || 
                                    (0 == _tcscmp(found.cFileName, TEXT("cpanplus"))) || 
                                    (0 == _tcscmp(found.cFileName, TEXT("cpanminus"))) || 
                                    (0 == _tcscmp(found.cFileName, TEXT("ppm")));


#ifdef _DEBUG
            SimpleLogString4(hModule, _T("DEBUG: AddTopDirectoryQuick name="), found.cFileName, _T(" bQuickUninstallCheck="), bQuickUninstallCheck ? _T("yes") : _T("no"));
#endif
            if (!bQuickUninstallCheck) {
                bFileFound = ::FindNextFile(hFindHandle, &found);
                continue;
            }

            // Create a new directory spec to recurse into.
            _tcscpy_s(sSubDir, MAX_PATH, sCurrentDir);
            _tcscat_s(sSubDir, MAX_PATH, found.cFileName);
            _tcscat_s(sSubDir, MAX_PATH, TEXT("\\"));

            // Try and get the ID that already exists.
            uiAnswer = GetDirectoryID(hModule, sCurrentDirID, found.cFileName, sSubDirID);
            RETURN_ON_ERROR_FREE(uiAnswer, LPTSTR(sID), hModule, _T("ERROR: AddTopDirectoryQuick - GetDirectoryID FAILED"));

            if (sSubDirID != NULL) {
                // We have an existing directory ID.
                uiAnswer = AddDirectory(hModule, sSubDir, sSubDirID, false, bDeleteEntryCreatedBelow, sRemovalComponent);
                RETURN_ON_ERROR_FREE2(uiAnswer, (LPTSTR)sID, (TCHAR*)sSubDirID, hModule, _T("ERROR: AddTopDirectoryQuick - AddDirectory FAILED"));
                free(sSubDirID);
            } else {
                // We need to get a directory ID, add the property, then go down 
                // into this directory.
                uiAnswer = ERROR_INSTALL_FAILURE; 
                RETURN_ON_ERROR_FREE(uiAnswer, (LPTSTR)sID, hModule, _T("ERROR: AddTopDirectoryQuick FAILED"));
            }
        } else {
            // Verify that the file wasn't installed by this MSI.
            bInstalled = false;

            uiAnswer = IsFileInstalled(hModule, sCurrentDirID, 
                found.cFileName, bInstalled);
            RETURN_ON_ERROR_FREE(uiAnswer, (LPTSTR)sID, hModule, _T("ERROR: AddTopDirectoryQuick - IsFileInstalled FAILED"));

            if (!bInstalled) {
                uiAnswer = AddRemoveFileRecord(hModule, sCurrentDirID, found.cFileName, sRemovalComponent);
                RETURN_ON_ERROR_FREE(uiAnswer, (LPTSTR)sID, hModule, _T("ERROR: AddTopDirectoryQuick - AddRemoveFileRecord FAILED"));
                SimpleLogString4(hModule, _T("ARFR1: Added remove file record entry with ID string: "), sCurrentDirID, _T(" and name: "), found.cFileName);
            }
        }
    
        // Check and see if there is another file to process.
        bFileFound = ::FindNextFile(hFindHandle, &found);
    }
    
    // Close the find handle.
    ::FindClose(hFindHandle);

    // Clean up after ourselves.
    free((LPTSTR)sID);    
    return uiAnswer;
}

// returns ID of component that will be used for adding extra RemoveFile items for deleted files/dirs
// currently we take the component where perl.exe file is included - this will for sure exist
// TODO: maybe create some special component dedicated for this purpose
UINT GetRemovalComponent(
    MSIHANDLE hModule,           // Database Handle of MSI being installed. [in]
    LPCTSTR sMergeModuleID,      // ID of merge module being uninstalled. [in]
    LPTSTR sRemovalComponent,    // ID of removal component [out] - preallocated!
    DWORD uiRemovalComponentLen)  // size of sRemovalComponent buffer
{
#ifdef _DEBUG
    SimpleLogString2(hModule, _T("DEBUG: GetRemovalComponent sMergeModuleID="), sMergeModuleID);
#endif

    LPCTSTR sSQL = _T("SELECT `Directory` FROM `Directory` WHERE `Directory_Parent`= ? AND `DefaultDir` = ?");

    // Get database handle
    PMSIHANDLE phDB = ::MsiGetActiveDatabase(hModule);
    RETURN_IF_NULL(phDB, hModule, _T("ERROR: GetRemovalComponent - MsiGetActiveDatabase FAILED"));

    PMSIHANDLE phView;
    UINT uiAnswer = ERROR_SUCCESS;

    uiAnswer = ::MsiDatabaseOpenView(phDB, sSQL, &phView);
    LOG_DEBUG_DETAILS_ON_ERROR(uiAnswer, hModule);
    RETURN_ON_ERROR(uiAnswer, hModule, _T("ERROR: GetRemovalComponent - MsiDatabaseOpenView.1 FAILED"));

    PMSIHANDLE phRecord = ::MsiCreateRecord(2);
    RETURN_IF_NULL(phRecord, hModule, _T("ERROR: GetRemovalComponent - MsiCreateRecord.2 FAILED"));

    TCHAR sPerlID[100];
    _tcscpy_s(sPerlID, 99, TEXT("d_perl"));
    if (_tcscmp(sMergeModuleID, TEXT("")) != 0) {
        _tcscat_s(sPerlID, 99, TEXT("."));
        _tcscat_s(sPerlID, 99, sMergeModuleID);
    }

#ifdef _DEBUG
    SimpleLogString2(hModule, _T("DEBUG: GetRemovalComponent sPerlID="), sPerlID);
#endif
    uiAnswer = ::MsiRecordSetString(phRecord, 1, sPerlID);
    RETURN_ON_ERROR(uiAnswer, hModule, _T("ERROR: GetRemovalComponent - MsiRecordSetString.sPerlID FAILED"));

    uiAnswer = ::MsiRecordSetString(phRecord, 2, TEXT("bin"));
    RETURN_ON_ERROR(uiAnswer, hModule, _T("ERROR: GetRemovalComponent - MsiRecordSetString.bin FAILED"));

    uiAnswer = ::MsiViewExecute(phView, phRecord);
    RETURN_ON_ERROR(uiAnswer, hModule, _T("ERROR: GetRemovalComponent - MsiViewExecute.1 FAILED"));
    
    PMSIHANDLE phAnswerRecord = ::MsiCreateRecord(1);
    RETURN_IF_NULL(phAnswerRecord, hModule, _T("ERROR: GetRemovalComponent - MsiCreateRecord.1 FAILED"));

    uiAnswer = ::MsiViewFetch(phView, &phAnswerRecord);
    RETURN_ON_ERROR(uiAnswer, hModule, _T("ERROR: GetRemovalComponent - MsiViewFetch.1 FAILED"));
    
    // Get the ID.
    TCHAR sID[100];
    DWORD dwLengthID = 99;
    uiAnswer = ::MsiRecordGetString(phAnswerRecord, 1, sID, &dwLengthID);
    RETURN_ON_ERROR(uiAnswer, hModule, _T("ERROR: GetRemovalComponent - MsiRecordGetString.1 FAILED"));
#ifdef _DEBUG
    SimpleLogString2(hModule, _T("DEBUG: GetRemovalComponent sID="), sID);
#endif
        
    uiAnswer = ::MsiViewClose(phView);
    RETURN_ON_ERROR(uiAnswer, hModule, _T("ERROR: GetRemovalComponent - MsiViewClose.1 FAILED"));

    LPCTSTR sSQLFile = _T("SELECT `Component`.`Component` FROM `Component`,`File` WHERE `Component`.`Directory_` = ? AND `File`.`FileName`= ? AND `File`.`Component_` = `Component`.`Component`");

    uiAnswer = ::MsiDatabaseOpenView(phDB, sSQLFile, &phView);
    LOG_DEBUG_DETAILS_ON_ERROR(uiAnswer, hModule);
    RETURN_ON_ERROR(uiAnswer, hModule, _T("ERROR: GetRemovalComponent - MsiDatabaseOpenView.2 FAILED"));

    uiAnswer = ::MsiRecordSetString(phRecord, 1, sID);
    RETURN_ON_ERROR(uiAnswer, hModule, _T("ERROR: GetRemovalComponent - MsiRecordSetString.sID FAILED"));

    uiAnswer = ::MsiRecordSetString(phRecord, 2, TEXT("perl.exe"));
    RETURN_ON_ERROR(uiAnswer, hModule, _T("ERROR: GetRemovalComponent - MsiRecordSetString.perl.exe FAILED"));

    uiAnswer = ::MsiViewExecute(phView, phRecord);
    RETURN_ON_ERROR(uiAnswer, hModule, _T("ERROR: GetRemovalComponent - MsiViewExecute.2 FAILED"));

    uiAnswer = ::MsiViewFetch(phView, &phAnswerRecord);
    RETURN_ON_ERROR(uiAnswer, hModule, _T("ERROR: GetRemovalComponent - MsiViewFetch.2 FAILED"));
    
    // Get the ID.
    dwLengthID = uiRemovalComponentLen-1;
    uiAnswer = ::MsiRecordGetString(phAnswerRecord, 1, sRemovalComponent, &dwLengthID);
    RETURN_ON_ERROR(uiAnswer, hModule, _T("ERROR: GetRemovalComponent - MsiRecordGetString.2 FAILED"));
    
    uiAnswer = ::MsiViewClose(phView);
    RETURN_ON_ERROR(uiAnswer, hModule, _T("ERROR: GetRemovalComponent - MsiViewClose.2 FAILED"));

#ifdef _DEBUG
    SimpleLogString2(hModule, _T("DEBUG: GetRemovalComponent sRemovalComponent="), sRemovalComponent);
#endif

    return uiAnswer; 
}

UINT ClearFolderMain_Internal(
    MSIHANDLE hModule,   // Handle of MSI being installed. [in]
    bool bUninstallFast) // Whether to just uninstall cpan, cpanplus, and ppm. 
{
    TCHAR sInstallDirectory[MAX_PATH + 1];
    TCHAR sMergeModuleID[100];
    TCHAR sQuick[6];
    UINT uiAnswer;
    DWORD dwPropLength;
    bool bUninstallSite = false;
    TCHAR sRemovalComponent[100];

#ifdef _DEBUG
    SimpleLogString1(hModule, _T("DEBUG: ClearFolderMain_Internal started"));
#endif

    // Get directory to search.
    dwPropLength = 5; 
    uiAnswer = ::MsiGetProperty(hModule, TEXT("UNINSTALL_QUICK"), sQuick, &dwPropLength); 
    if (ERROR_MORE_DATA == uiAnswer) {
        uiAnswer = ERROR_SUCCESS;
    }
    RETURN_ON_ERROR(uiAnswer, hModule, _T("ERROR: ClearFolderMain - MsiGetProperty[UNINSTALL_QUICK] FAILED"));
#ifdef _DEBUG
    SimpleLogString2(hModule, _T("DEBUG: ClearFolderMain sQuick.1="), sQuick);
#endif
    if (0 != _tcscmp(sQuick, _T(""))) return ERROR_SUCCESS;

    dwPropLength = 5; 
    uiAnswer = ::MsiGetProperty(hModule, TEXT("UNINSTALL_SITE"), sQuick, &dwPropLength); 
    if (ERROR_MORE_DATA == uiAnswer) {
        uiAnswer = ERROR_SUCCESS;
    }
#ifdef _DEBUG
    SimpleLogString2(hModule, _T("DEBUG: ClearFolderMain sQuick.2="), sQuick);
#endif
    RETURN_ON_ERROR(uiAnswer, hModule, _T("ERROR: ClearFolderMain - MsiGetProperty[UNINSTALL_SITE] FAILED"));
    if (0 != _tcscmp(sQuick, _T(""))) bUninstallSite = true;

    // Get directory to search.
    dwPropLength = MAX_PATH; 
    uiAnswer = ::MsiGetProperty(hModule, TEXT("INSTALLDIR"), sInstallDirectory, &dwPropLength);
    RETURN_ON_ERROR(uiAnswer, hModule, _T("ERROR: ClearFolderMain - MsiGetProperty[INSTALLDIR] FAILED"));
    SimpleLogString2(hModule, _T("ClearFolderMain - sInstallDirectory="), sInstallDirectory);

    dwPropLength = 99; 
    uiAnswer = ::MsiGetProperty(hModule, TEXT("MergeModuleID"), sMergeModuleID, &dwPropLength); 
    RETURN_ON_ERROR(uiAnswer, hModule, _T("ERROR: ClearFolderMain - MsiGetProperty[PerlModuleID] FAILED"));
    SimpleLogString2(hModule, _T("ClearFolderMain - sMergeModuleID="), sMergeModuleID);

    // Get component to use for adding RemoveFile items for deleted files
    uiAnswer = GetRemovalComponent(hModule, sMergeModuleID, sRemovalComponent, sizeof(sRemovalComponent));
    RETURN_ON_ERROR(uiAnswer, hModule, _T("ERROR: ClearSiteFolder - GetComponent FAILED"));

    TCHAR sInstallDirID[100];
    _tcscpy_s(sInstallDirID, 99, TEXT("INSTALLDIR"));
    if (_tcscmp(sMergeModuleID, TEXT("")) != 0) {
        _tcscat_s(sInstallDirID, 99, TEXT("."));
        _tcscat_s(sInstallDirID, 99, sMergeModuleID);
    }

    // Start getting files to delete (recursive)
    SimpleLogString4(hModule, _T("ClearFolderMain sInstallDirectory="), sInstallDirectory, _T(" sInstallDirID="), sInstallDirID);
    SimpleLogString2(hModule, _T("ClearFolderMain bUninstallFast="), bUninstallFast ? _T("yes") : _T("no"));
    SimpleLogString2(hModule, _T("ClearFolderMain bUninstallSite="), bUninstallSite ? _T("yes") : _T("no"));
    bool bDeleteEntryCreated = false;
    if (bUninstallFast) {
#ifdef _DEBUG
        SimpleLogString1(hModule, _T("DEBUG: ClearFolderMain gonna call AddTopDirectoryQuick"));
#endif
        uiAnswer = AddTopDirectoryQuick(hModule, sInstallDirectory, sInstallDirID, bDeleteEntryCreated, sRemovalComponent);
        RETURN_ON_ERROR(uiAnswer, hModule, _T("ERROR: ClearFolderMain - AddTopDirectoryQuick FAILED"));
    } else {
#ifdef _DEBUG
        SimpleLogString1(hModule, _T("DEBUG: ClearFolderMain gonna call AddDirectory"));
#endif
        uiAnswer = AddDirectory(hModule, sInstallDirectory, sInstallDirID, bUninstallSite, bDeleteEntryCreated, sRemovalComponent);
        RETURN_ON_ERROR(uiAnswer, hModule, _T("ERROR: ClearFolderMain - AddDirectory FAILED"));
    }

    return uiAnswer;
}

UINT ClearSiteFolder_Internal(
    MSIHANDLE hModule) // Handle of MSI being installed. [in]
{
    TCHAR sInstallDirectory[MAX_PATH + 1];
    TCHAR sSiteDirectory[MAX_PATH + 1];
    TCHAR sMergeModuleID[100];
    TCHAR sQuick[6];
    UINT uiAnswer;
    DWORD dwPropLength;
    TCHAR sRemovalComponent[100];

#ifdef _DEBUG
    SimpleLogString1(hModule, _T("DEBUG: ClearSiteFolder_Internal started"));
#endif

    // Get directory to search.
    dwPropLength = 5; 
    uiAnswer = ::MsiGetProperty(hModule, TEXT("UNINSTALL_QUICK"), sQuick, &dwPropLength); 
    if (ERROR_MORE_DATA == uiAnswer) {
#ifdef _DEBUG
        SimpleLogString1(hModule, _T("DEBUG: ClearSiteFolder_Internal - UNINSTALL_QUICK/ERROR_MORE_DATA"));
#endif
        uiAnswer = ERROR_SUCCESS;
    }
    RETURN_ON_ERROR(uiAnswer, hModule, _T("ERROR: ClearSiteFolder - MsiGetProperty[UNINSTALL_QUICK] FAILED"));

    if (0 != _tcscmp(sQuick, _T(""))) {
#ifdef _DEBUG
        SimpleLogString1(hModule, _T("DEBUG: ClearSiteFolder_Internal - UNINSTALL_QUICK not set"));
#endif
        return ERROR_SUCCESS;
    }

    dwPropLength = 99; 
    uiAnswer = ::MsiGetProperty(hModule, TEXT("MergeModuleID"), sMergeModuleID, &dwPropLength); 
    RETURN_ON_ERROR(uiAnswer, hModule, _T("ERROR: ClearSiteFolder - MsiGetProperty[PerlModuleID] FAILED"));
    SimpleLogString2(hModule, _T("ClearSiteFolder_Internal - sMergeModuleID="), sMergeModuleID);

    // Get component to use for adding RemoveFile items for deleted files
    uiAnswer = GetRemovalComponent(hModule, sMergeModuleID, sRemovalComponent, sizeof(sRemovalComponent));
    RETURN_ON_ERROR(uiAnswer, hModule, _T("ERROR: ClearSiteFolder - GetComponent FAILED"));

    // Get directory to search.
    dwPropLength = MAX_PATH; 
    uiAnswer = ::MsiGetProperty(hModule, TEXT("INSTALLDIR"), sInstallDirectory, &dwPropLength); 
    RETURN_ON_ERROR(uiAnswer, hModule, _T("ERROR: ClearSiteFolder - MsiGetProperty[INSTALLDIR] FAILED"));
    SimpleLogString2(hModule, _T("ClearSiteFolder_Internal - sInstallDirectory="), sInstallDirectory);

    _tcscpy_s(sSiteDirectory, MAX_PATH, sInstallDirectory);
    _tcscat_s(sSiteDirectory, MAX_PATH, TEXT("perl\\site\\"));
    SimpleLogString2(hModule, _T("ClearSiteFolder_Internal - sSiteDirectory="), sSiteDirectory);
    
    TCHAR sSiteDirID[100];
    _tcscpy_s(sSiteDirID, 99, TEXT("d_perl_site"));
    if (_tcscmp(sMergeModuleID, TEXT("")) != 0) {
        _tcscat_s(sSiteDirID, 99, TEXT("."));
        _tcscat_s(sSiteDirID, 99, sMergeModuleID);
    }
    SimpleLogString2(hModule, _T("ClearSiteFolder_Internal - sSiteDirID="), sSiteDirID);

    // Start getting files to delete (recursive)
    bool bDeleteEntryCreated = false;
    uiAnswer = AddDirectory(hModule, sSiteDirectory, sSiteDirID, true, bDeleteEntryCreated, sRemovalComponent);
    RETURN_ON_ERROR(uiAnswer, hModule, _T("ERROR: ClearSiteFolder - AddDirectory FAILED"));

    return uiAnswer;
}

UINT __stdcall ClearFoldersSlow(
       MSIHANDLE hModule) // Handle of MSI being installed. [in]
{
    UINT uiResult;
    uiResult = ClearFolderMain_Internal(hModule, false);
    if (uiResult != ERROR_SUCCESS) SimpleLogString1(hModule, _T("WARNING: ClearFolderSlow FAILED; however we are gonna continue"));
    return ERROR_SUCCESS;
}

UINT __stdcall ClearFoldersFast(
       MSIHANDLE hModule) // Handle of MSI being installed. [in]
{
    UINT uiResult;
    uiResult = ClearFolderMain_Internal(hModule, true);
    if (uiResult != ERROR_SUCCESS) SimpleLogString1(hModule, _T("WARNING: ClearFolderFast FAILED; however we are gonna continue"));
    return ERROR_SUCCESS;
}

UINT __stdcall ClearSiteFolder(
    MSIHANDLE hModule) // Handle of MSI being installed. [in]
{
    UINT uiResult;
    uiResult = ClearSiteFolder_Internal(hModule);
    if (uiResult != ERROR_SUCCESS) SimpleLogString1(hModule, _T("WARNING: ClearSiteFolder FAILED; however we are gonna continue"));
    return ERROR_SUCCESS;
}                               
