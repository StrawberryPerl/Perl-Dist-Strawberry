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
   return ::MsiSetProperty(hModule, TEXT("WIXUI_INSTALLDIR_VALID"), TEXT("1"));
}
