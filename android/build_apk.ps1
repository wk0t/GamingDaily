# ============================================================
#  Builds GamingDaily.apk without Gradle (aapt + javac + d8 + zipalign + apksigner)
# ============================================================
$ErrorActionPreference = 'Continue'   # Android tools write warnings to stderr; rely on exit codes, not stderr
$sdk      = "$env:LOCALAPPDATA\Android\Sdk"
$bt       = "$sdk\build-tools\34.0.0"
$platform = "$sdk\platforms\android-34\android.jar"
$jdk      = (Get-ChildItem "$env:ProgramFiles\Eclipse Adoptium" -Directory | Where-Object Name -like 'jdk-17*' | Select-Object -First 1).FullName
$proj     = $PSScriptRoot                                  # dossier android/
$out      = "$proj\build"
$apkFinal = Join-Path (Split-Path $proj -Parent) "GamingDaily.apk"  # racine du projet

New-Item -ItemType Directory -Force "$out\obj"  | Out-Null
New-Item -ItemType Directory -Force "$out\dex"  | Out-Null
New-Item -ItemType Directory -Force "$out\gen"  | Out-Null

Write-Output "[0/6] Generating R.java (resources)..."
& "$bt\aapt.exe" package -f -m -J "$out\gen" -M "$proj\AndroidManifest.xml" -S "$proj\res" -I $platform 2>&1
if ($LASTEXITCODE -ne 0) { throw "aapt (R.java) failed" }

Write-Output "[1/6] Compiling Java..."
$srcFiles = @()
$srcFiles += (Get-ChildItem "$proj\src" -Recurse -Filter *.java).FullName
$srcFiles += (Get-ChildItem "$out\gen" -Recurse -Filter *.java).FullName
& "$jdk\bin\javac.exe" --release 8 -classpath $platform -d "$out\obj" $srcFiles 2>&1
if ($LASTEXITCODE -ne 0) { throw "javac failed" }

Write-Output "[2/6] Converting to DEX (d8)..."
$classes = (Get-ChildItem "$out\obj" -Recurse -Filter *.class).FullName
& "$bt\d8.bat" --release --lib $platform --min-api 24 --output "$out\dex" $classes 2>&1
if ($LASTEXITCODE -ne 0) { throw "d8 failed" }

Write-Output "[3/6] Packaging APK (aapt)..."
if (Test-Path "$out\app.unsigned.apk") { del "$out\app.unsigned.apk" }
& "$bt\aapt.exe" package -f -M "$proj\AndroidManifest.xml" -S "$proj\res" -A "$proj\assets" -I $platform -F "$out\app.unsigned.apk" 2>&1
if ($LASTEXITCODE -ne 0) { throw "aapt package failed" }

Write-Output "[4/6] Adding classes.dex..."
Push-Location "$out\dex"
& "$bt\aapt.exe" add "$out\app.unsigned.apk" classes.dex 2>&1
Pop-Location
if ($LASTEXITCODE -ne 0) { throw "aapt add failed" }

Write-Output "[5/6] Aligning (zipalign)..."
if (Test-Path "$out\app.aligned.apk") { del "$out\app.aligned.apk" }
& "$bt\zipalign.exe" -f 4 "$out\app.unsigned.apk" "$out\app.aligned.apk" 2>&1

Write-Output "[6/6] Signing (apksigner)..."
# Local self-signed keystore (excluded from the repo via .gitignore). The default
# password is fine for a personal project; for real distribution, set
# $env:GMD_KEYSTORE_PASS instead. IMPORTANT: keep the same keystore from one version
# to the next, otherwise Android will refuse to install the update over the existing app.
$ks     = "$proj\gamingdaily.jks"
$ksPass = if ($env:GMD_KEYSTORE_PASS) { $env:GMD_KEYSTORE_PASS } else { 'gamingdaily123' }
if (-not (Test-Path $ks)) {
  & "$jdk\bin\keytool.exe" -genkeypair -keystore $ks -storepass $ksPass -keypass $ksPass -alias gmd -keyalg RSA -keysize 2048 -validity 10000 -dname "CN=Gaming Daily" 2>&1
}
& "$bt\apksigner.bat" sign --ks $ks --ks-pass "pass:$ksPass" --key-pass "pass:$ksPass" --out $apkFinal "$out\app.aligned.apk" 2>&1
if ($LASTEXITCODE -ne 0) { throw "apksigner failed" }

Write-Output ""
Write-Output "=== Verification ==="
& "$bt\apksigner.bat" verify --print-certs $apkFinal 2>&1 | Select-Object -First 4
& "$bt\aapt.exe" dump badging $apkFinal 2>&1 | Select-Object -First 6
Write-Output ""
Write-Output ("APK built: {0} ({1} KB)" -f $apkFinal, [math]::Round((Get-Item $apkFinal).Length/1KB))
