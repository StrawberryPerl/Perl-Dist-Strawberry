# Strawberry Perl Portable Shell - PowerShell Edition

# globals used by setup/teardown
$strawberry_perl_old_path = $env:Path
$strawberry_perl_old_env  = @{}
$strawberry_perl_env_keys = @(
    'TERM'
    'PERL_JSON_BACKEND'
    'PERL_YAML_BACKEND'
    'PERL5LIB'
    'PERL5OPT'
    'PERL_MM_OPT'
    'PERL_MB_OPT'
)

function strawberry_perl_setup_environment {
    foreach ($key in $global:strawberry_perl_env_keys) {
        if (Test-Path "env:$key") {
            $global:strawberry_perl_old_env[$key] = [Environment]::GetEnvironmentVariable($key)
        }
    }
    foreach ($key in $global:strawberry_perl_env_keys) {
        Set-Item -Path "env:$key" -Value ""
    }

    $path_pfx = $PSScriptRoot + "\perl\site\bin;" + $PSScriptRoot + "\perl\bin;" + $PSScriptRoot + "\c\bin;"
    $env:Path = $path_pfx + $env:Path
}

function strawberry_perl_teardown_environment {
    $env:Path = $global:strawberry_perl_old_path
    foreach ($key in $global:strawberry_perl_env_keys) {
        if ($global:strawberry_perl_old_env.ContainsKey($key)) {
            [Environment]::SetEnvironmentVariable($key, $global:strawberry_perl_old_env[$key])
        } else {
            [Environment]::SetEnvironmentVariable($key, $null)  # actually unsets it
        }
    }
}

# only set the env
if ($args[0] -eq "--setenv") {
    strawberry_perl_setup_environment
    Write-Host "Strawberry-Perl environment vars set for the session"
    return
}

# When creating an interactive session,
#  the newly spawned Powershell sources portableshell.ps1
#  to set up the environment.
# This is the recursion guard portion
if ($MyInvocation.InvocationName -eq '.') {
    strawberry_perl_setup_environment

    Write-Host "----------------------------------------------"
    Write-Host "Welcome to Strawberry Perl Portable Edition!"
    Write-Host "* URL - http://www.strawberryperl.com/"
    Write-Host "* see README.TXT for more info"
    Write-Host "----------------------------------------------"

    perl -MConfig -e 'printf(qq{Perl executable: %s\nPerl version   : %vd / $Config{archname}\n\n}, $^X, $^V)'

    if ($LASTEXITCODE -ne 0) {
        Write-Host "FATAL ERROR: 'perl' does not work; check if your strawberry pack is complete!"
        exit
    }

    return
}

if ($args.Count -gt 0) { # pass to perl
    try {
        strawberry_perl_setup_environment

        perl $args
        if ($LASTEXITCODE -ne 0) {
            Write-Host "FATAL ERROR: perl exited with code $LASTEXITCODE"
        }
    } finally {
        strawberry_perl_teardown_environment
    }
    return
} else { # interactive run
    # The user could be running either powershell.exe (PS v5) or pwsh.exe (PS v7).
    # He would expect to keep his shell version.
    $exe = (Get-Process -Id $PID).Path
    & $exe -NoExit -Command ". '$PSCommandPath'"
}
