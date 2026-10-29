# Publica una version nueva de Shinobi Empires para descargar desde la pagina web.
# Comprime el build de Windows y lo sube como Release de GitHub; el boton "Descargar"
# de la pagina siempre baja la ultima.
#
# Uso:  doble clic en publicar_juego.bat
#       o: powershell -ExecutionPolicy Bypass -File publicar_juego.ps1 [-Notas "que cambio"] [-Prueba]
#   -Prueba : solo arma el ZIP (no sube nada) para revisar que todo anda.
#   -Build  : carpeta del build, si el juego no esta clonado al lado de esta carpeta.
#
# Funciona en cualquier PC: clonar este repo al lado de "shinobi-empires" (misma carpeta padre)
# y tener gh con sesion iniciada (gh auth login).

param(
    [string]$Notas = "",
    [switch]$Prueba,
    [string]$Build = ""
)

$ErrorActionPreference = "Stop"
$repo  = "Freshkz/shinobi-empires-web"
if ($Build) { $build = $Build } else { $build = Join-Path $PSScriptRoot "..\shinobi-empires\Builds\Windows" }
$build = [System.IO.Path]::GetFullPath($build)

function Salir($msg) { Write-Host ""; Write-Host $msg -ForegroundColor Red; exit 1 }

if (-not (Test-Path (Join-Path $build "ShinobiEmpires.exe"))) {
    Salir "No encontre el juego compilado en $build. Primero genera el build de Windows."
}
if (-not $Prueba) {
    gh auth status *> $null
    if ($LASTEXITCODE -ne 0) { Salir "GitHub no tiene sesion iniciada. Corre: gh auth login" }
}

# Version = fecha y hora del build (asi dos builds distintos nunca chocan).
$exe     = Get-Item (Join-Path $build "ShinobiEmpires.exe")
$datos   = Get-ChildItem (Join-Path $build "ShinobiEmpires_Data") -Recurse -File | Sort-Object LastWriteTime -Descending | Select-Object -First 1
$fecha   = @($exe.LastWriteTime, $datos.LastWriteTime) | Sort-Object -Descending | Select-Object -First 1
$version = "v" + $fecha.ToString("yyyy.MM.dd-HHmm")
Write-Host "Version a publicar: $version (build del $($fecha.ToString('dd/MM/yyyy HH:mm')))" -ForegroundColor Yellow

if (-not $Prueba) {
    gh release view $version --repo $repo *> $null
    if ($LASTEXITCODE -eq 0) { Salir "La version $version ya esta publicada. Genera un build nuevo antes de volver a publicar." }
}

# Copia temporal sin las carpetas de depuracion (no se reparten) y ZIP con tar (rapido, sin limite de 2 GB).
$tmp = Join-Path $env:TEMP ("shinobi_publicar_" + [guid]::NewGuid().ToString("N").Substring(0, 8))
$carpeta = Join-Path $tmp "ShinobiEmpires"
$zip = Join-Path $tmp "ShinobiEmpires.zip"
try {
    Write-Host "Copiando el juego..."
    New-Item -ItemType Directory -Force $carpeta | Out-Null
    robocopy $build $carpeta /E /NFL /NDL /NJH /NJS /NP /XD "*_DoNotShip" "*_BackUpThisFolder_ButDontShipItWithYourGame" | Out-Null
    if ($LASTEXITCODE -ge 8) { Salir "Fallo la copia del juego (robocopy $LASTEXITCODE)." }
    Set-Content -Path (Join-Path $carpeta "VERSION.txt") -Value "Shinobi Empires $version" -Encoding utf8

    Write-Host "Comprimiendo..."
    & tar.exe -a -c -f $zip -C $tmp "ShinobiEmpires"
    if ($LASTEXITCODE -ne 0) { Salir "Fallo al comprimir." }
    $mb = [math]::Round((Get-Item $zip).Length / 1MB, 1)
    Write-Host "ZIP listo: $mb MB"
    if ($mb -gt 1990) { Salir "El ZIP pasa los 2 GB que permite GitHub por archivo." }

    if ($Prueba) {
        $destino = Join-Path ([Environment]::GetFolderPath("Desktop")) "ShinobiEmpires_prueba.zip"
        Move-Item $zip $destino -Force
        Write-Host ""; Write-Host "Prueba OK (no se subio nada): $destino" -ForegroundColor Green
        exit 0
    }

    if (-not $Notas) { $Notas = "Build del $($fecha.ToString('dd/MM/yyyy HH:mm')). Descomprimi el ZIP y abri ShinobiEmpires.exe." }
    Write-Host "Subiendo a GitHub (puede tardar unos minutos)..."
    gh release create $version $zip --repo $repo --title "Shinobi Empires $version" --notes $Notas --latest
    if ($LASTEXITCODE -ne 0) { Salir "Fallo la subida a GitHub." }

    Write-Host ""
    Write-Host "Publicado $version ($mb MB)." -ForegroundColor Green
    Write-Host "Pagina: https://freshkz.github.io/shinobi-empires-web/"
}
finally {
    if (Test-Path $tmp) { Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue }
}
