# Konfiguration
$manifestUrl = "https://delboy.b-cdn.net/hmw/manifest.json"
$downloadBaseUrl = "https://delboy.b-cdn.net/hmw/"
$localPath = "$PSScriptRoot\files"

# Lokales Zielverzeichnis erstellen, falls nicht vorhanden
if (!(Test-Path $localPath)) {
    New-Item -ItemType Directory -Path $localPath | Out-Null
}

# Manifest laden
try {
    $manifestJson = Invoke-WebRequest -Uri $manifestUrl -UseBasicParsing
    $manifest = $manifestJson.Content | ConvertFrom-Json
} catch {
    Write-Error "Fehler beim Laden des Manifests: $_"
    exit 1
}

# Dateiabgleich
foreach ($file in $manifest.files) {
    $fileName = $file.name
    $expectedHash = $file.sha256
    $fileUrl = "$downloadBaseUrl$fileName"
    $localFilePath = Join-Path $localPath $fileName

    $needsDownload = $true

    if (Test-Path $localFilePath) {
        # Hash der lokalen Datei berechnen
        $localHash = Get-FileHash -Path $localFilePath -Algorithm SHA256
        if ($localHash.Hash -ieq $expectedHash) {
            Write-Host "✓ $fileName ist aktuell."
            $needsDownload = $false
        } else {
            Write-Host "↺ $fileName ist veraltet – wird neu geladen..."
        }
    } else {
        Write-Host "↓ $fileName fehlt – wird geladen..."
    }

    # Datei herunterladen, falls notwendig
    if ($needsDownload) {
        try {
            Invoke-WebRequest -Uri $fileUrl -OutFile $localFilePath -UseBasicParsing
            Write-Host "✔ $fileName wurde heruntergeladen."
        } catch {
            Write-Error "Fehler beim Herunterladen von $fileName: $_"
        }
    }
}
