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

# --- Main ---
Clear-Host
Write-Host "=== TTS Preview ===" -ForegroundColor Yellow
Write-Host ""

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
$synth.Rate = [int]$rateInput

# Volume
$volInput = Read-Host "Volume (0-100) [100]"
if (-not $volInput) { $volInput = 100 }
$synth.Volume = [int]$volInput

Write-Host ""
Write-Host "Commands:" -ForegroundColor DarkGray
Write-Host "  q        - quit" -ForegroundColor DarkGray
Write-Host "  rate N   - change rate (-10 to 10)" -ForegroundColor DarkGray
Write-Host ""
Write-Host "SSML tags work inline:" -ForegroundColor DarkGray
Write-Host '  <emphasis level="strong">Spawning</emphasis>' -ForegroundColor DarkGray
Write-Host '  <prosody rate="90%" pitch="+5%">Spawning</prosody>' -ForegroundColor DarkGray
Write-Host '  Dodge <break time="100ms"/> now' -ForegroundColor DarkGray
Write-Host ""

while ($true) {
    $text = Read-Host "TTS"
    if ($text -eq 'q') { break }
    if (-not $text -or $text.Trim() -eq '') { continue }

    if ($text -match '^rate\s+(-?\d+)$') {
        $synth.Rate = [int]$Matches[1]
        Write-Host "  Rate set to $($Matches[1])" -ForegroundColor Yellow
        continue
    }

    $ssml = "<speak version='1.0' xmlns='http://www.w3.org/2001/10/synthesis' xml:lang='en-US'>$($text.Trim())</speak>"
    try {
        $synth.SpeakSsml($ssml)
    }
    catch {
        Write-Host "  SSML error: $_" -ForegroundColor Red
    }
}

$synth.Dispose()
