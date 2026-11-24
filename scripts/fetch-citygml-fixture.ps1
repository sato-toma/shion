$ErrorActionPreference = 'Stop'

# Source: 3D都市モデル（Project PLATEAU）太地町（2021年度）
# Dataset page: https://www.geospatial.jp/ckan/dataset/plateau-30422-taiji-cho-2021
# Usage terms: MLIT Site Policy, PDL 1.0; compatible with CC BY 4.0. Attribution is required.
# Attribution: 3D都市モデル（Project PLATEAU）太地町（2021年度）
# Processing: Downloads one original building mesh file without modification.
$sourceUrl = 'https://assets.cms.plateau.reearth.io/assets/0c/0c3f1b-fd1f-40b5-95b1-18d41897b5ce/30422_taiji-cho_city_2021_citygml_5_op/udx/bldg/50352795_bldg_6697_op.gml'
$expectedSha256 = '352BB48C7DDEDA0A098D48322EA2AEFF773C3BDAA24509C6F92A25767C8CC8A9'

$repositoryRoot = Split-Path -Parent $PSScriptRoot
$fixtureDirectory = Join-Path $repositoryRoot '.local\test-data\citygml'
$fixturePath = Join-Path $fixtureDirectory '50352795_bldg_6697_op.gml'

New-Item -ItemType Directory -Path $fixtureDirectory -Force | Out-Null

if (Test-Path -LiteralPath $fixturePath) {
    $currentSha256 = (Get-FileHash -LiteralPath $fixturePath -Algorithm SHA256).Hash
    if ($currentSha256 -eq $expectedSha256) {
        Write-Output "CityGML fixture is already verified: $fixturePath"
        return
    }
}

$temporaryPath = Join-Path $fixtureDirectory ([guid]::NewGuid().ToString('N') + '.download')

try {
    Invoke-WebRequest -Uri $sourceUrl -OutFile $temporaryPath -UseBasicParsing -TimeoutSec 120

    $actualSha256 = (Get-FileHash -LiteralPath $temporaryPath -Algorithm SHA256).Hash
    if ($actualSha256 -ne $expectedSha256) {
        throw "CityGML fixture SHA-256 mismatch. Expected $expectedSha256, got $actualSha256."
    }

    $xmlSettings = New-Object System.Xml.XmlReaderSettings
    $xmlSettings.DtdProcessing = [System.Xml.DtdProcessing]::Prohibit
    $xmlSettings.XmlResolver = $null
    $xmlReader = [System.Xml.XmlReader]::Create($temporaryPath, $xmlSettings)
    try {
        while ($xmlReader.Read()) {
        }
    }
    finally {
        $xmlReader.Dispose()
    }

    Move-Item -LiteralPath $temporaryPath -Destination $fixturePath -Force
    $fixtureSize = (Get-Item -LiteralPath $fixturePath).Length
    Write-Output "Fetched and verified CityGML fixture: $fixturePath ($fixtureSize bytes)"
    Write-Output "SHA-256: $actualSha256"
}
finally {
    if (Test-Path -LiteralPath $temporaryPath) {
        Remove-Item -LiteralPath $temporaryPath
    }
}
