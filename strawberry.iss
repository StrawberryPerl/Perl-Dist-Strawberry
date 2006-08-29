[Setup]
AppName=Strawberry Perl
AppVerName=Strawberry Perl 5.8.8 alpha 2
AppPublisher=Vanilla Perl Project
AppPublisherURL=http://vanillaperl.com/
AppId=strawberryperl

; name of startmenu folder
DefaultGroupName=Strawberry Perl
AllowNoIcons=yes

; hardcode where it's installed
DefaultDirName=C:\strawberry-perl
DisableDirPage=yes

; folder + filename of created setup exe
OutputDir=C:\
OutputBaseFilename=strawberry-perl-5.8.8-alpha-2

; location of source files
SourceDir=C:\strawberry-perl

; disallow win95 or above
; allow nt4 or above
MinVersion=4.0.950,4.0.1381

; use fast setting for testing
;Compression=lzma
Compression=lzma/fast

SolidCompression=yes
ChangesEnvironment=true

[Languages]
Name: eng; MessagesFile: compiler:Default.isl

[Files]
Source: dmake\*; DestDir: {app}\dmake; Flags: ignoreversion recursesubdirs createallsubdirs
Source: licenses\*; DestDir: {app}\licenses; Flags: ignoreversion recursesubdirs createallsubdirs
Source: links\*; DestDir: {app}\links; Flags: ignoreversion recursesubdirs createallsubdirs
Source: mingw\bin\*; DestDir: {app}\mingw\bin; Flags: ignoreversion recursesubdirs createallsubdirs
Source: mingw\include\*; DestDir: {app}\mingw\include; Flags: ignoreversion recursesubdirs createallsubdirs
Source: mingw\lib\*; DestDir: {app}\mingw\lib; Flags: ignoreversion recursesubdirs createallsubdirs
Source: mingw\libexec\*; DestDir: {app}\mingw\libexec; Flags: ignoreversion recursesubdirs createallsubdirs
Source: mingw\mingw32\*; DestDir: {app}\mingw\mingw32; Flags: ignoreversion recursesubdirs createallsubdirs
Source: perl\bin\*; DestDir: {app}\perl\bin; Flags: ignoreversion recursesubdirs createallsubdirs
Source: perl\html\*; DestDir: {app}\perl\html; Flags: ignoreversion recursesubdirs createallsubdirs
Source: perl\lib\*; DestDir: {app}\perl\lib; Flags: ignoreversion recursesubdirs createallsubdirs
Source: perl\site\lib\*; DestDir: {app}\perl\site\lib; Flags: ignoreversion recursesubdirs createallsubdirs confirmoverwrite
Source: README.txt; DestDir: {app}; Flags: ignoreversion isreadme
Source: LICENSE.txt; DestDir: {app}; Flags: ignoreversion
Source: Release-Notes.txt; DestDir: {app}; Flags: ignoreversion

[Icons]
Name: {group}\{cm:UninstallProgram,Strawberry Perl}; Filename: {uninstallexe}
Name: {group}\Internet Links\Strawberry Perl Homepage; Filename: {app}\links\Strawberry-Perl-Homepage.url
Name: {group}\Internet Links\Perlmonks Community Forum; Filename: {app}\links\Perlmonks-Community-Forum.url
Name: {group}\Internet Links\Mailing Lists; Filename: {app}\links\Perl-Mailing-Lists.url
Name: {group}\Internet Links\perldoc Documentation; Filename: {app}\links\Perl-Documentation.url
Name: {group}\Internet Links\Perl Homepage; Filename: {app}\links\Perl-Homepage.url
Name: {group}\Internet Links\Search CPAN Modules; Filename: {app}\links\Search-CPAN-Modules.url
Name: {group}\Perl Documentation; Filename: {app}\perl\html\pod\perltoc.html
Name: {group}\Install modules with CPAN.pm; Filename: {app}\perl\bin\cpan.bat; WorkingDir: {app}\perl
Name: {group}\README; Filename: {app}\README.txt

[Registry]
Root: HKLM; Subkey: SYSTEM\CurrentControlSet\Control\Session Manager\Environment; ValueType: expandsz; ValueName: PATH; ValueData: "{olddata};{app}\perl\bin;{app}\dmake\bin;{app}\mingw\bin"
Root: HKLM; Subkey: SYSTEM\CurrentControlSet\Control\Session Manager\Environment; ValueType: expandsz; ValueName: LIB; ValueData: "{olddata};{app}\mingw\lib;{app}\perl\bin"
Root: HKLM; Subkey: SYSTEM\CurrentControlSet\Control\Session Manager\Environment; ValueType: expandsz; ValueName: INCLUDE; ValueData: "{olddata};{app}\mingw\include;{app}\perl\lib\CORE;{app}\perl\lib\encode"
