// CheckDirName.cpp : Defines the CheckDirName custom action.
//
// Copyright (c) Curtis Jewell 2009, 2010
//
// This code is free software; you can redistribute it and/or modify it
// under the same terms as Perl itself.

// ##### EXPORTED FUCTIONS: CheckDirName

#include "stdafx.h"
#include "ErrorMsg.h"

UINT __stdcall CheckDirName(MSIHANDLE hModule)
{
	TCHAR sInstallDir[MAX_PATH + 1];
	TCHAR sNum[11];
	DWORD dwPropLength;
	UINT uiAnswer;

	// Get directory to search.
	dwPropLength = 10; 
	uiAnswer = ::MsiGetProperty(hModule, TEXT("WIXUI_INSTALLDIR_VALID"), sNum, &dwPropLength); 
	if (ERROR_MORE_DATA == uiAnswer) {
		uiAnswer = ERROR_SUCCESS;
	}
	RETURN_ON_ERROR(uiAnswer, hModule, _T("ERROR: CheckDirName - MsiGetProperty[WIXUI_INSTALLDIR_VALID] FAILED"));

	if (0 != _tcscmp(sNum, _T("1"))) {
		return ERROR_SUCCESS;
	}

	// Get directory to check.
	dwPropLength = MAX_PATH; 
	uiAnswer = ::MsiGetProperty(hModule, TEXT("INSTALLDIR"), sInstallDir, &dwPropLength); 
	RETURN_ON_ERROR(uiAnswer, hModule, _T("ERROR: CheckDirName - MsiGetProperty[INSTALLDIR] FAILED"));

	if (NULL != _tcsspnp(sInstallDir, 
        _T("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz@!_:+-.[]\\"))) {
		return ::MsiSetProperty(hModule, TEXT("WIXUI_INSTALLDIR_VALID"), TEXT("-2"));
	}

	// Check the "long name" of that directory.
	TCHAR sInstallDirWork[MAX_PATH + 1];
	TCHAR sInstallDirLong[MAX_PATH + 1];
	_tcscpy_s(sInstallDirWork, MAX_PATH, sInstallDir);
	DWORD dwAnswer = ::GetLongPathName(sInstallDirWork, sInstallDirLong, MAX_PATH);

	TCHAR* pcSlash;
	DWORD dwError;
	while (0 == dwAnswer) {

		dwError = ::GetLastError();
		if ((ERROR_FILE_NOT_FOUND != dwError) && (ERROR_PATH_NOT_FOUND != dwError))
			break;

		// Keep working backwards until we get it right, or until there are no more backslashes.
		pcSlash = _tcsrchr(sInstallDirWork, _T('\\'));
		if (NULL == pcSlash) 
			break;

		*pcSlash = _T('\0');
		dwAnswer = ::GetLongPathName(sInstallDirWork, sInstallDirLong, MAX_PATH);
	}

	if (NULL != _tcsspnp(sInstallDirLong, 
		_T("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz@!_:+-.[]\\"))) {
		return ::MsiSetProperty(hModule, TEXT("WIXUI_INSTALLDIR_VALID"), TEXT("-2"));
	}

	return ::MsiSetProperty(hModule, TEXT("WIXUI_INSTALLDIR_VALID"), TEXT("1"));
}
