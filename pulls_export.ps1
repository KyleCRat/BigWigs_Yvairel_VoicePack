# pulls_export.ps1
# Reads YvairelVoicePackDB from WoW SavedVariables, generates per-pull .md files
# in the Pulls/ folder, then clears the pulls from the SavedVariables file.

# --- Lua Table Parser ---

function Read-LuaTable {
    param([string]$content)

    $script:pos = 0
    $script:text = $content

    function Skip-Whitespace {
        while ($script:pos -lt $script:text.Length) {
            $c = $script:text[$script:pos]
            if ($c -match '\s') {
                $script:pos++
                continue
            }
            # Skip single-line comments
            if ($script:pos + 1 -lt $script:text.Length -and $script:text[$script:pos] -eq '-' -and $script:text[$script:pos + 1] -eq '-') {
                while ($script:pos -lt $script:text.Length -and $script:text[$script:pos] -ne "`n") {
                    $script:pos++
                }
                continue
            }
            break
        }
    }

    function Read-String {
        $quote = $script:text[$script:pos]
        $script:pos++
        $result = ""
        while ($script:pos -lt $script:text.Length) {
            $c = $script:text[$script:pos]
            if ($c -eq '\' -and ($script:pos + 1) -lt $script:text.Length) {
                $next = $script:text[$script:pos + 1]
                if ($next -eq '\') { $result += '\'; $script:pos += 2; continue }
                if ($next -eq $quote) { $result += $quote; $script:pos += 2; continue }
                if ($next -eq 'n') { $result += "`n"; $script:pos += 2; continue }
                if ($next -eq 't') { $result += "`t"; $script:pos += 2; continue }
                $result += $c
                $script:pos++
                continue
            }
            if ($c -eq $quote) {
                $script:pos++
                return $result
            }
            $result += $c
            $script:pos++
        }
        return $result
    }

    function Read-Value {
        Skip-Whitespace

        if ($script:pos -ge $script:text.Length) { return $null }

        $c = $script:text[$script:pos]

        # String
        if ($c -eq '"' -or $c -eq "'") {
            return Read-String
        }

        # Table
        if ($c -eq '{') {
            return Read-Table
        }

        # Read a word/number token
        $start = $script:pos
        while ($script:pos -lt $script:text.Length -and $script:text[$script:pos] -match '[A-Za-z0-9_.+-]') {
            $script:pos++
        }
        $token = $script:text.Substring($start, $script:pos - $start)

        if ($token -eq 'true') { return $true }
        if ($token -eq 'false') { return $false }
        if ($token -eq 'nil') { return $null }

        $num = 0
        if ([double]::TryParse($token, [ref]$num)) { return $num }

        return $token
    }

    function Read-Table {
        $script:pos++ # skip {
        $result = [ordered]@{}
        $arrayIndex = 1
        $isArray = $true

        while ($true) {
            Skip-Whitespace
            if ($script:pos -ge $script:text.Length) { break }
            if ($script:text[$script:pos] -eq '}') { $script:pos++; break }

            # Skip commas/semicolons
            if ($script:text[$script:pos] -eq ',' -or $script:text[$script:pos] -eq ';') {
                $script:pos++
                continue
            }

            Skip-Whitespace

            # Check for ["key"] = value
            if ($script:text[$script:pos] -eq '[') {
                $isArray = $false
                $script:pos++ # skip [
                Skip-Whitespace
                $key = Read-Value
                Skip-Whitespace
                if ($script:pos -lt $script:text.Length -and $script:text[$script:pos] -eq ']') { $script:pos++ }
                Skip-Whitespace
                if ($script:pos -lt $script:text.Length -and $script:text[$script:pos] -eq '=') { $script:pos++ }
                Skip-Whitespace
                $val = Read-Value
                $result["$key"] = $val
                continue
            }

            # Check for key = value (identifier key)
            $savedPos = $script:pos
            $maybeKey = ""
            while ($script:pos -lt $script:text.Length -and $script:text[$script:pos] -match '[A-Za-z0-9_]') {
                $maybeKey += $script:text[$script:pos]
                $script:pos++
            }
            Skip-Whitespace
            if ($maybeKey.Length -gt 0 -and $script:pos -lt $script:text.Length -and $script:text[$script:pos] -eq '=') {
                $isArray = $false
                $script:pos++ # skip =
                Skip-Whitespace
                $val = Read-Value
                $result[$maybeKey] = $val
                continue
            }

            # Otherwise it's an array value, rewind and read
            $script:pos = $savedPos
            $val = Read-Value
            $result["$arrayIndex"] = $val
            $arrayIndex++
        }

        # Convert to array if all keys are sequential integers
        if ($isArray -and $result.Count -gt 0) {
            $arr = @()
            for ($i = 1; $i -le $result.Count; $i++) {
                $arr += $result["$i"]
            }
            return $arr
        }

        return $result
    }

    # Find the table assignment: YvairelVoicePackDB = { ... }
    $match = [regex]::Match($content, 'YvairelVoicePackDB\s*=\s*')
    if (-not $match.Success) {
        return $null
    }

    $script:pos = $match.Index + $match.Length
    return Read-Value
}

# --- Markdown Generation ---

function Build-AbilityTable {
    param($abilities)

    if (-not $abilities -or $abilities.Count -eq 0) {
        return "No abilities recorded."
    }

    $lines = @()

    foreach ($key in $abilities.Keys) {
        $a = $abilities[$key]
        $spellId = $key
        $name = $a["spellName"]
        $sound = $a["defaultSound"]
        $casts = $a["casts"]
        $castCount = if ($casts) { $casts.Count } else { 0 }

        $lines += "| Spell ID | Ability Name | Default Sound | Casts |"
        $lines += "|---|---|---|---|"
        $lines += "| $spellId | $name | $sound | x$castCount |"
        $lines += ""
        $lines += "| Time | On Me | Played |"
        $lines += "|---|---|---|"

        if ($casts) {
            foreach ($cast in $casts) {
                $time = $cast["time"]
                $onMe = if ($cast["isOnMe"]) { "Yes" } else { "No" }
                $played = $cast["played"]
                if ($played -eq "fallback") { $played = "**fallback**" }
                $lines += "| ${time}s | $onMe | $played |"
            }
        }
        $lines += ""
    }

    return $lines -join "`n"
}

function Build-PullMarkdown {
    param($pull)

    $resultUpper = ($pull["result"]).ToUpper()
    $lines = @()
    $lines += "# $($pull["boss"]) - $($pull["difficulty"]) ($resultUpper)"
    $lines += ""
    $lines += "| | |"
    $lines += "|---|---|"
    $lines += "| **Date** | $($pull["startTime"]) |"
    $lines += "| **Duration** | $($pull["duration"]) |"
    $lines += "| **Group Size** | $($pull["groupSize"]) |"
    $lines += "| **Encounter ID** | $($pull["encounterId"]) |"
    $lines += ""
    $lines += "## Abilities"
    $lines += ""
    $lines += Build-AbilityTable $pull["abilities"]
    $lines += ""
    $lines += "## Debug Log"
    $lines += ""

    $logEntries = $pull["log"]
    if (-not $logEntries -or $logEntries.Count -eq 0) {
        $lines += "No log entries."
    }
    else {
        $lines += '```'
        foreach ($entry in $logEntries) {
            $lines += $entry
        }
        $lines += '```'
    }

    return $lines -join "`n"
}

function ConvertTo-FileTimestamp {
    param([string]$timestamp)
    # "2026-03-27 20:31:02" -> "2026-03-27_2031"
    $clean = $timestamp -replace ':', ''
    $clean = $clean -replace '\s+', '_'
    $clean = $clean.Substring(0, 15) # "2026-03-27_2031"

    return $clean
}

function ConvertTo-SafeFilename {
    param([string]$name)
    $clean = $name -replace "['\u2019]", ''
    $clean = $clean -replace '[^A-Za-z0-9_ -]', ''
    $clean = $clean.Trim() -replace '\s+', '_'

    return $clean
}

# --- Main ---

Clear-Host
Write-Host "=== YVP Pull Exporter ===" -ForegroundColor Yellow
Write-Host ""

$addonDir = $PSScriptRoot
$pullsDir = Join-Path $addonDir "Pulls"

# Find SavedVariables file
$wowRoot = (Resolve-Path (Join-Path $addonDir "..\..\..")).Path
$wtfAccount = Join-Path $wowRoot "WTF\Account"

if (-not (Test-Path $wtfAccount)) {
    Write-Host "Could not find WTF\Account folder at: $wtfAccount" -ForegroundColor Red
    exit 1
}

$svFiles = Get-ChildItem -Path $wtfAccount -Recurse -Filter "BigWigs_Yvairels_VoicePack.lua" -File |
    Where-Object { $_.Directory.Name -eq "SavedVariables" }

if ($svFiles.Count -eq 0) {
    Write-Host "No SavedVariables file found. Run WoW at least once with the addon enabled." -ForegroundColor Red
    exit 1
}

if ($svFiles.Count -eq 1) {
    $svFile = $svFiles[0]
}
else {
    Write-Host "Found multiple SavedVariables files:" -ForegroundColor Yellow
    for ($i = 0; $i -lt $svFiles.Count; $i++) {
        $relative = $svFiles[$i].FullName.Replace($wtfAccount, '').TrimStart('\')
        Write-Host "  [$i] $relative" -ForegroundColor Cyan
    }
    $choice = Read-Host "Select file [0]"
    if (-not $choice) { $choice = 0 }
    $svFile = $svFiles[$choice]
}

Write-Host "Reading: $($svFile.FullName)" -ForegroundColor DarkGray
$content = Get-Content -Path $svFile.FullName -Raw -Encoding UTF8

$db = Read-LuaTable $content
if (-not $db) {
    Write-Host "Failed to parse SavedVariables file." -ForegroundColor Red
    exit 1
}

$pulls = $db["pulls"]
if (-not $pulls -or $pulls.Count -eq 0) {
    Write-Host "No pulls found in SavedVariables." -ForegroundColor Yellow
    exit 0
}

Write-Host "Found $($pulls.Count) pull(s)." -ForegroundColor Green
Write-Host ""

# Create Pulls directory
if (-not (Test-Path $pullsDir)) {
    New-Item -ItemType Directory -Path $pullsDir | Out-Null
}

$exported = 0
foreach ($pull in $pulls) {
    $timestamp = ConvertTo-FileTimestamp $pull["startTime"]
    $bossClean = ConvertTo-SafeFilename $pull["boss"]
    $diff = ConvertTo-SafeFilename $pull["difficulty"]
    $result = $pull["result"]
    $filename = "${timestamp}_${bossClean}_${diff}_${result}.md"
    $filepath = Join-Path $pullsDir $filename

    # Don't overwrite, append a number if needed
    $counter = 2
    while (Test-Path $filepath) {
        $filename = "${timestamp}_${bossClean}_${diff}_${result}_${counter}.md"
        $filepath = Join-Path $pullsDir $filename
        $counter++
    }

    $markdown = Build-PullMarkdown $pull
    Set-Content -Path $filepath -Value $markdown -Encoding UTF8
    Write-Host "  Saved: $filename" -ForegroundColor Green
    $exported++
}

# Delete SavedVariables file — WoW rebuilds it on next login
Write-Host ""
Remove-Item $svFile.FullName -Force
Write-Host "  Deleted SavedVariables file (will regenerate on next login)." -ForegroundColor Green

Write-Host ""
Write-Host "Done. Exported $exported pull(s) to $pullsDir" -ForegroundColor Yellow
