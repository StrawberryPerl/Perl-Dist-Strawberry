// This code is free software; you can redistribute it and/or modify it
// under the same terms as Perl itself.

// This code is free software; you can redistribute it and/or modify it
// under the same terms as Perl itself.

// ##### MSI logging related functions, no exported functions

#include "stdafx.h"

void Log(MSIHANDLE hModule, LPCTSTR sString) // Handle of MSI being installed. [in]
{
	// Set up variables.
	PMSIHANDLE hRecord = ::MsiCreateRecord(2);
    if (hRecord == NULL) return;

	UINT uiAnswer = ::MsiRecordSetString(hRecord, 0, sString);
	if (uiAnswer != ERROR_SUCCESS) return;
	
	// Send the message
	::MsiProcessMessage(hModule, INSTALLMESSAGE(INSTALLMESSAGE_INFO), hRecord);
}

void SimpleLogString1(MSIHANDLE hModule, LPCTSTR s)
{
	static TCHAR str[513];
	_tcscpy_s(str, 512, s ? s : _T("<null>"));
	Log(hModule, str);
}

void SimpleLogString2(MSIHANDLE hModule, LPCTSTR s, LPCTSTR t)
{
	static TCHAR str[513];
	_tcscpy_s(str, 512, s ? s : _T("<null>"));
	_tcscat_s(str, 512, t ? t : _T("<null>"));
	Log(hModule, str);
}

void SimpleLogString3(MSIHANDLE hModule, LPCTSTR s, LPCTSTR t, LPCTSTR u)
{
	static TCHAR str[513];
	_tcscpy_s(str, 512, s ? s : _T("<null>"));
	_tcscat_s(str, 512, t ? t : _T("<null>"));
	_tcscat_s(str, 512, u ? u : _T("<null>"));
	Log(hModule, str);
}

void SimpleLogString4(MSIHANDLE hModule, LPCTSTR s, LPCTSTR t, LPCTSTR u, LPCTSTR v)
{
	static TCHAR str[513];
	_tcscpy_s(str, 512, s ? s : _T("<null>"));
	_tcscat_s(str, 512, t ? t : _T("<null>"));
	_tcscat_s(str, 512, u ? u : _T("<null>"));
	_tcscat_s(str, 512, v ? v : _T("<null>"));
	Log(hModule, str);
}

UINT RETURN_ON_ERROR(UINT retval, MSIHANDLE hModule, LPCTSTR s)
{
	if (ERROR_SUCCESS != retval) {
		SimpleLogString1(hModule, s);
		return 1;
	}
	return 0;
}

void PrintUINT(MSIHANDLE hModule, UINT i) 
{
	static TCHAR sNumber[100];
	_stprintf_s(sNumber, 99, _T("%d"), i);
	SimpleLogString2(hModule, _T("DEBUG: UINT="), sNumber);
}

void PrintLastErrorDetails(MSIHANDLE hModule)
{
	PMSIHANDLE hLastErrorRec = MsiGetLastErrorRecord();
    TCHAR* szExtendedError = NULL;
	DWORD cchExtendedError = 0;
    if (hLastErrorRec) {
		// Since we are not currently calling MsiFormatRecord during an
		// install session, hInstall is NULL. If MsiFormatRecord was called
        // via a DLL custom action, the hInstall handle provided to the DLL
        // custom action entry point could be used to further resolve 
        // properties that might be contained within the error record.
            
		// To determine the size of the buffer required for the text,
        // szResultBuf must be provided as an empty string with
        // *pcchResultBuf set to 0.

        UINT uiStatus = MsiFormatRecord(NULL, hLastErrorRec, TEXT(""), &cchExtendedError);

		if (ERROR_MORE_DATA == uiStatus) {
			// returned size does not include null terminator.
            cchExtendedError++;

            szExtendedError = new TCHAR[cchExtendedError];
            if (szExtendedError) {
				uiStatus = MsiFormatRecord(NULL, hLastErrorRec, szExtendedError, &cchExtendedError);
				if (ERROR_SUCCESS == uiStatus) {
					// We now have an extended error message to report.
					SimpleLogString2(hModule, _T("DEBUG: ExtendedError="), szExtendedError);
					SimpleLogString1(hModule, _T("DEBUG: check message code(1:) at http://msdn.microsoft.com/en-us/library/aa372835.aspx"));
                }
                delete [] szExtendedError;
                szExtendedError = NULL;
            }
        }
	}
}
