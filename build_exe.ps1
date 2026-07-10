# Recompile GamingDaily.exe avec le script embarque (base64).
# Le .exe n'est qu'un lanceur : il extrait le script PowerShell (encode en base64)
# vers le dossier temporaire, puis l'execute sans fenetre.
$root = $PSScriptRoot
$p    = Join-Path $root "GamingDaily.ps1"
$exe  = Join-Path $root "GamingDaily.exe"
$b64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($p))
$q = '\"'
$cs = @"
using System;
using System.Diagnostics;
using System.IO;
using System.Text;
class Program {
  static void Main() {
    string b64 = "$b64";
    string script = Encoding.UTF8.GetString(Convert.FromBase64String(b64));
    script = script.TrimStart('\uFEFF');
    string tmp = Path.Combine(Path.GetTempPath(), "GamingDaily_run.ps1");
    File.WriteAllText(tmp, script, new UTF8Encoding(true));
    var psi = new ProcessStartInfo();
    psi.FileName = "powershell.exe";
    psi.Arguments = "-ExecutionPolicy Bypass -WindowStyle Hidden -NoProfile -File $q" + tmp + "$q";
    psi.UseShellExecute = false;
    psi.CreateNoWindow = true;
    try { Process.Start(psi); } catch (Exception e) {
      System.Windows.Forms.MessageBox.Show("Erreur: " + e.Message);
    }
  }
}
"@
$csPath = Join-Path $env:TEMP "gmd_build.cs"
[IO.File]::WriteAllText($csPath, $cs, [Text.UTF8Encoding]::new($true))
$csc = "$env:WINDIR\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
& $csc /nologo /target:winexe /reference:System.Windows.Forms.dll /out:"$exe" $csPath 2>&1
Write-Output ("Exe recompile : {0} / {1} Ko" -f (Test-Path $exe), [math]::Round((Get-Item $exe).Length/1KB))
