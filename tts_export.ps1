Add-Type -AssemblyName System.Speech

$synth = New-Object System.Speech.Synthesis.SpeechSynthesizer

# --- List voices ---
function Show-Voices {
    $voices = $synth.GetInstalledVoices() | Where-Object { $_.Enabled }
    $i = 0
    foreach ($v in $voices) {
        $info = $v.VoiceInfo
        Write-Host "  [$i] $($info.Name) ($($info.Culture.Name))" -ForegroundColor Cyan
        $i++
    }

    return $voices
}

# --- Export function ---
function Export-TTS {
    param($text, $filename, $rate, $volume, $outputDir)

    $resolvedDir = (Resolve-Path $outputDir).Path
    $wavPath = Join-Path $outputDir "$filename.wav"
    $oggPath = Join-Path $outputDir "$filename.ogg"
    $resolvedWav = [System.IO.Path]::GetFullPath($wavPath)
    $resolvedOgg = [System.IO.Path]::GetFullPath($oggPath)

    if (-not $resolvedWav.StartsWith($resolvedDir) -or -not $resolvedOgg.StartsWith($resolvedDir)) {
        Write-Host "  SKIPPED (path escape detected): $filename" -ForegroundColor Red
        return
    }

    $synth.Rate = $rate
    $synth.Volume = $volume
    $ssml = "<speak version='1.0' xmlns='http://www.w3.org/2001/10/synthesis' xml:lang='en-US'>$text</speak>"
    $synth.SetOutputToWaveFile($resolvedWav)
    $synth.SpeakSsml($ssml)
    $synth.SetOutputToDefaultAudioDevice()

    & ffmpeg -y -i $resolvedWav -c:a libvorbis -q:a 5 $resolvedOgg 2>$null

    if ($LASTEXITCODE -eq 0) {
        Remove-Item $resolvedWav -Force
        Write-Host "  Saved: $resolvedOgg" -ForegroundColor Green
    }
    else {
        Write-Host "  ffmpeg conversion failed. WAV kept at: $resolvedWav" -ForegroundColor Red
    }
}

# --- Sanitize ability name for filenames ---
function ConvertTo-FileName {
    param($text)
    $clean = $text -replace '\s*\(.*?\)\s*', '' # strip parenthetical like (Targeted)
    $clean = $clean -replace "['\u2019]", ''     # strip apostrophes
    $clean = $clean.Trim() -replace '\s+', '_'   # spaces to underscores
    $clean = $clean -replace '[^A-Za-z0-9_-]', '' # remove remaining special chars

    return $clean
}

# --- Build short boss name for SharedMedia display ---
function Get-ShortBossName {
    param($boss)
    switch ($boss) {
        "Belo'ren Child of Al'ar" { return "Belo'ren" }
        "Imperator Averzian"      { return "Averzian" }
        "Fallen-King Salhadaar"   { return "Salhadaar" }
        "Vaelgor & Ezzorak"       { return "Vaelgor & Ezzorak" }
        "Lightblinded Vanguard"   { return "Vanguard" }
        "Crown of the Cosmos"     { return "Crown" }
        default                   { return $boss }
    }
}

# --- Convert raid name to filename suffix ---
function ConvertTo-RaidFileSuffix {
    param($raid)
    $clean = $raid -replace "['\u2019]", ''
    $clean = ($clean -split '\s+' | ForEach-Object {
        $_.Substring(0,1).ToUpper() + $_.Substring(1)
    }) -join ''

    return $clean
}

# --- Build a markdown table from rows and column definitions ---
function Build-MarkdownTable {
    param($columns, $rows)

    $lines = @()
    $header = "| " + ($columns -join " | ") + " |"
    $separator = "|" + (($columns | ForEach-Object { "---" }) -join "|") + "|"
    $lines += $header
    $lines += $separator

    foreach ($row in $rows) {
        $cells = foreach ($col in $columns) {
            $val = $row.$col
            if ($null -eq $val) { "" } else { $val }
        }
        $lines += "| " + ($cells -join " | ") + " |"
    }

    return $lines -join "`n"
}

# --- Main ---
Clear-Host
Write-Host "=== TTS Exporter (CSV Batch Mode) ===" -ForegroundColor Yellow
Write-Host ""

# Check ffmpeg
if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
    Write-Host "ffmpeg not found in PATH. Install with: winget install ffmpeg" -ForegroundColor Red
    exit 1
}

# Output directory
$outputDir = Join-Path $PSScriptRoot "Sounds"
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir | Out-Null
}

# CSV paths
$voiceKeysPath = Join-Path $PSScriptRoot "VoiceKeys.csv"
$privateAurasPath = Join-Path $PSScriptRoot "PrivateAuras.csv"

$hasVoiceKeys = Test-Path $voiceKeysPath
$hasPrivateAuras = Test-Path $privateAurasPath

if (-not $hasVoiceKeys -and -not $hasPrivateAuras) {
    Write-Host "No CSV files found. Expected VoiceKeys.csv and/or PrivateAuras.csv" -ForegroundColor Red
    exit 1
}

# Voice selection
Write-Host "Available voices:" -ForegroundColor Yellow
$voices = Show-Voices
Write-Host ""
$voiceIdx = Read-Host "Select voice [0]"
if (-not $voiceIdx) { $voiceIdx = 0 }
$selectedVoice = $voices[$voiceIdx].VoiceInfo.Name
$synth.SelectVoice($selectedVoice)
Write-Host "  Using: $selectedVoice" -ForegroundColor Green
Write-Host ""

# Rate
$rateInput = Read-Host "Rate (-10 to 10) [1]"
if (-not $rateInput) { $rateInput = 1 }
$rate = [int]$rateInput

# Volume
$volInput = Read-Host "Volume (0-100) [100]"
if (-not $volInput) { $volInput = 100 }
$volume = [int]$volInput

Write-Host ""
Write-Host "Settings: voice=$selectedVoice, rate=$rate, volume=$volume" -ForegroundColor DarkGray
Write-Host "Output:   $outputDir" -ForegroundColor DarkGray
Write-Host ""

$generated = 0
$skipped = 0
$expectedOggs = @{}

# --- Process VoiceKeys.csv ---
if ($hasVoiceKeys) {
    Write-Host "=== Processing VoiceKeys.csv ===" -ForegroundColor Yellow
    $rows = Import-Csv $voiceKeysPath

    foreach ($row in $rows) {
        $spellId = $row.'Spell ID'
        $abilityName = $row.'Ability Name'
        $customString = $row.'TTS'
        $customStringOnMe = $row.'TTS (On Me)'

        # Regular sound (filename is spell ID for voice pack compatibility)
        if ($customString -and $customString.Trim() -ne '') {
            $expectedOggs["$spellId.ogg"] = $true
            Write-Host "  [$spellId] $abilityName -> `"$($customString.Trim())`"" -ForegroundColor Cyan
            Export-TTS -text $customString.Trim() -filename $spellId -rate $rate -volume $volume -outputDir $outputDir
            $generated++
        }
        else {
            $skipped++
        }

        # On-me variant (y suffix)
        if ($customStringOnMe -and $customStringOnMe.Trim() -ne '') {
            $expectedOggs["${spellId}y.ogg"] = $true
            Write-Host "  [${spellId}y] $abilityName (On Me) -> `"$($customStringOnMe.Trim())`"" -ForegroundColor Magenta
            Export-TTS -text $customStringOnMe.Trim() -filename "${spellId}y" -rate $rate -volume $volume -outputDir $outputDir
            $generated++
        }
        else {
            $skipped++
        }
    }
}

# --- Process PrivateAuras.csv and generate Sounds.lua ---
$soundsLuaEntries = @()

if ($hasPrivateAuras) {
    Write-Host ""
    Write-Host "=== Processing PrivateAuras.csv ===" -ForegroundColor Yellow
    $rows = Import-Csv $privateAurasPath

    # Track duplicate SharedMedia names so we can append numbers
    $nameCount = @{}

    foreach ($row in $rows) {
        $spellId = $row.'Spell ID'
        $abilityName = $row.'Ability Name'
        $raid = $row.'Raid'
        $boss = $row.'Boss'
        $customString = $row.'TTS'

        # Build filenames from CSV data
        $cleanName = ConvertTo-FileName $abilityName
        $cleanRaid = ConvertTo-FileName $raid
        $oggFilename = "$cleanRaid-$spellId-$cleanName"

        # Build SharedMedia display name
        $shortBoss = Get-ShortBossName $boss
        $displayAbility = $abilityName -replace '\s*\(.*?\)\s*', '' # strip parenthetical
        $displayAbility = $displayAbility.Trim()
        $baseMediaName = "${raid} - ${shortBoss}: $displayAbility"

        # Handle duplicate SharedMedia names by appending a number
        if ($nameCount.ContainsKey($baseMediaName)) {
            $nameCount[$baseMediaName]++
            $mediaName = "$baseMediaName $($nameCount[$baseMediaName])"
        }
        else {
            $nameCount[$baseMediaName] = 1
            $mediaName = $baseMediaName
        }

        # Only generate TTS and register in SharedMedia if custom string is filled in
        if ($customString -and $customString.Trim() -ne '') {
            $expectedOggs["$oggFilename.ogg"] = $true
            $soundsLuaEntries += "`t{`"$mediaName`", `"$oggFilename.ogg`"},"
            Write-Host "  [$spellId] $abilityName -> `"$($customString.Trim())`" ($oggFilename.ogg)" -ForegroundColor Cyan
            Export-TTS -text $customString.Trim() -filename $oggFilename -rate $rate -volume $volume -outputDir $outputDir
            $generated++
        }
        else {
            $skipped++
        }
    }
}

# --- Generate Sounds.lua ---
$soundsLuaPath = Join-Path $PSScriptRoot "Sounds.lua"
Write-Host ""
Write-Host "=== Generating Sounds.lua ===" -ForegroundColor Yellow

$luaContent = @"

-- This file is auto-generated by tts_export.ps1 from PrivateAuras.csv
-- Do not edit manually. Re-run the export script to regenerate.

local LSM = LibStub("LibSharedMedia-3.0")
local SOUND = LSM.MediaType and LSM.MediaType.SOUND or "sound"
local addonPath = "Interface\\AddOns\\BigWigs_Yvairels_VoicePack\\Sounds\\"
local COLOR = "|cff9b59b6"

local sounds = {
$($soundsLuaEntries -join "`n")
}

for _, entry in next, sounds do
	LSM:Register(SOUND, COLOR .. entry[1] .. "|r", addonPath .. entry[2])
end
"@

Set-Content -Path $soundsLuaPath -Value $luaContent -Encoding UTF8
Write-Host "  Saved: $soundsLuaPath" -ForegroundColor Green

# --- Generate SpellIDs .md files from VoiceKeys.csv ---
if ($hasVoiceKeys) {
    Write-Host ""
    Write-Host "=== Generating SpellIDs .md files ===" -ForegroundColor Yellow
    $vkRows = Import-Csv $voiceKeysPath
    $vkColumns = @("Spell ID", "Ability Name", "Notes", "TTS", "TTS (On Me)")

    $raidGroups = $vkRows | Group-Object -Property 'Raid'
    foreach ($raidGroup in $raidGroups) {
        $raidName = $raidGroup.Name
        $suffix = ConvertTo-RaidFileSuffix $raidName
        $mdPath = Join-Path $PSScriptRoot "SpellIDs_$suffix.md"

        $mdLines = @()
        $mdLines += "# $raidName - Spell IDs for Voice Files"
        $mdLines += ""

        $bossGroups = $raidGroup.Group | Group-Object -Property 'Boss'
        foreach ($bossGroup in $bossGroups) {
            $mdLines += "## $($bossGroup.Name)"
            $mdLines += ""

            $stageGroups = $bossGroup.Group | Group-Object -Property 'Stage/Section'
            foreach ($stageGroup in $stageGroups) {
                if ($stageGroup.Name -and $stageGroup.Name.Trim() -ne '') {
                    $mdLines += "### $($stageGroup.Name)"
                    $mdLines += ""
                }
                $mdLines += Build-MarkdownTable -columns $vkColumns -rows $stageGroup.Group
                $mdLines += ""
            }
        }

        Set-Content -Path $mdPath -Value ($mdLines -join "`n") -Encoding UTF8
        Write-Host "  Saved: $mdPath" -ForegroundColor Green
    }
}

# --- Generate PrivateAuras .md files from PrivateAuras.csv ---
if ($hasPrivateAuras) {
    Write-Host ""
    Write-Host "=== Generating PrivateAuras .md files ===" -ForegroundColor Yellow
    $paRows = Import-Csv $privateAurasPath
    $paColumns = @("Spell ID", "Ability Name", "Default Sound", "Notes", "TTS")

    $raidGroups = $paRows | Group-Object -Property 'Raid'
    foreach ($raidGroup in $raidGroups) {
        $raidName = $raidGroup.Name
        $suffix = ConvertTo-RaidFileSuffix $raidName
        $mdPath = Join-Path $PSScriptRoot "PrivateAuras_$suffix.md"

        $mdLines = @()
        $mdLines += "# $raidName - Private Auras"
        $mdLines += ""

        $bossGroups = $raidGroup.Group | Group-Object -Property 'Boss'
        foreach ($bossGroup in $bossGroups) {
            $mdLines += "## $($bossGroup.Name)"
            $mdLines += ""
            $mdLines += Build-MarkdownTable -columns $paColumns -rows $bossGroup.Group
            $mdLines += ""
        }

        Set-Content -Path $mdPath -Value ($mdLines -join "`n") -Encoding UTF8
        Write-Host "  Saved: $mdPath" -ForegroundColor Green
    }
}

# --- Remove orphaned .ogg files ---
$removed = 0
$resolvedSoundsDir = (Resolve-Path $outputDir).Path
$existingOggs = Get-ChildItem -Path $resolvedSoundsDir -Filter "*.ogg" -File
foreach ($file in $existingOggs) {
    if (-not $expectedOggs.ContainsKey($file.Name)) {
        $resolvedFile = [System.IO.Path]::GetFullPath($file.FullName)
        if ($resolvedFile.StartsWith($resolvedSoundsDir) -and $resolvedFile.EndsWith(".ogg")) {
            Remove-Item $resolvedFile -Force
            Write-Host "  Removed orphan: $($file.Name)" -ForegroundColor Red
            $removed++
        }
    }
}

if ($removed -gt 0) {
    Write-Host "  Removed $removed orphaned .ogg file(s)" -ForegroundColor Red
}

Write-Host ""
Write-Host "Done. Generated: $generated, Skipped (no custom string): $skipped, Removed: $removed" -ForegroundColor Yellow

$synth.Dispose()
