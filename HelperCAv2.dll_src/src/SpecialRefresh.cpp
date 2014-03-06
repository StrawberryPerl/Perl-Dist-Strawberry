// SpecialRefresh.cpp : broadcast a WM_SETTINGCHANGE message to all windows in the system
// see http://support.microsoft.com/kb/104011
//
// This code is free software; you can redistribute it and/or modify it
// under the same terms as Perl itself.

// ##### EXPORTED FUCTIONS: SpecialRefresh

#include "stdafx.h"
#include "ErrorMsg.h"

UINT __stdcall SpecialRefresh(MSIHANDLE hModule) {    
    DWORD_PTR dwResult;
    SendMessageTimeout( HWND_BROADCAST, WM_SETTINGCHANGE, 0,
                        (LPARAM) _T("Environment"), SMTO_ABORTIFHUNG,
                        5000, &dwResult );

    return ERROR_SUCCESS;
}
