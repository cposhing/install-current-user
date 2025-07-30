<# : batch portion
@REM ------------------------------------------
@set __POWER_SHELL_ERROR__=
@FOR /F "usebackq tokens=1* delims==" %%A IN (`powershell.exe -noprofile "& {$scriptDir='%~dp0'; $script='%~nx0'; icm -ScriptBlock ([Scriptblock]::Create((Get-Content -Raw '%~f0'))) -NoNewScope}"`) DO @(
  IF "%%A"=="PSHELL_MESSAGE" (set __POWER_SHELL_ERROR__=%%B) ELSE IF "%%B"=="" (echo %%A) ELSE (echo %%A=%%B)
)
@IF NOT "%__POWER_SHELL_ERROR__%"=="" @(
	echo [[31mERROR[0m] %__POWER_SHELL_ERROR__%
    echo [[31mERROR[0m] An error occurred. Please fix the indicated issue before continuing. >&2 && exit /b 1
)
@echo [[94mINFO[0m] idea64.exe.vmoptions replaced.
@GOTO :EOF
: end batch / begin powershell #>

#jetbra path
$jetbraPath = Split-Path -Path "$scriptDir" -Parent

#calculate ja-netfilter.jar path
$jaNetfilterJarPath = Join-Path -Path $jetbraPath -ChildPath "ja-netfilter.jar"
if (!(Test-Path -Path "$jaNetfilterJarPath" -PathType Leaf)) {
    Write-Output "PSHELL_MESSAGE='$script' parent folder not exists ja-netfilter.jar"
    exit $?
}

#calculate idea vmoptions path
$ideaVmoptionsPath = Join-Path -Path $(Split-Path -Path "$jetbraPath" -Parent) -ChildPath "bin\idea64.exe.vmoptions"
if (!(Test-Path -Path "$ideaVmoptionsPath" -PathType Leaf)) {
    Write-Output "PSHELL_MESSAGE='$script' parent folder not in idea home folder"
    exit $?
}

# read vmoptions content
$ideaVmoptionsContent = Get-Content -Raw -Path "$ideaVmoptionsPath"
if (!$ideaVmoptionsContent) {
    Write-Output "PSHELL_MESSAGE='$ideaVmoptionsPath' content is empty."
    exit $?
}

#backup original vmoptions file
Rename-Item -Path "$ideaVmoptionsPath" -NewName "idea64.exe.vmoptions.original" -Force -ErrorAction SilentlyContinue | Out-Null
if (Test-Path -Path "$ideaVmoptionsPath" -PathType Leaf) {
    Write-Output "PSHELL_MESSAGE='$ideaVmoptionsPath' back up error."
    exit $?
}

# add content
# add `add-opens` line
$ideaVmoptionsContent += "`r`n"
$ideaVmoptionsContent += "--add-opens=java.base/jdk.internal.org.objectweb.asm=ALL-UNNAMED" + "`r`n"
$ideaVmoptionsContent += "--add-opens=java.base/jdk.internal.org.objectweb.asm.tree=ALL-UNNAMED" + "`r`n"

# add `ja-netfilter.jar` line
$ideaVmoptionsContent += "`r`n"
$ideaVmoptionsContent += "-javaagent:$jaNetfilterJarPath=jetbrains" + "`r`n"

#out new vmoptions file utf8 no bom
Invoke-Command -ScriptBlock {
    [System.IO.File]::WriteAllText("$ideaVmoptionsPath", $ideaVmoptionsContent, $(New-Object System.Text.UTF8Encoding $False))
} -ErrorAction SilentlyContinue
if (!(Test-Path -Path "$ideaVmoptionsPath" -PathType Leaf)) {
    Write-Output "PSHELL_MESSAGE='$ideaVmoptionsPath' replace error."
    exit $?
}
