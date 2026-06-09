# Eklavya.AI — Release AAB builder
# Usage: .\build_release.ps1 -BackendUrl "https://your-backend.com"
param(
    [Parameter(Mandatory=$true)]
    [string]$BackendUrl
)

$SUPABASE_URL     = "https://uhfydykjgbeqjwejtzip.supabase.co"
$SUPABASE_ANON    = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVoZnlkeWtqZ2JlcWp3ZWp0emlwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ5NjczNDMsImV4cCI6MjA5MDU0MzM0M30.StiG0hh84qmQMpOySUOCBYfTOaTmW94BySktoNq8jzE"

Write-Host "Building release AAB for backend: $BackendUrl" -ForegroundColor Cyan

flutter build appbundle --release `
    "--dart-define=BACKEND_URL=$BackendUrl" `
    "--dart-define=SUPABASE_URL=$SUPABASE_URL" `
    "--dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON"

if ($LASTEXITCODE -eq 0) {
    Write-Host "`nBuild successful!" -ForegroundColor Green
    Write-Host "AAB: build\app\outputs\bundle\release\app-release.aab" -ForegroundColor Green
} else {
    Write-Host "`nBuild failed." -ForegroundColor Red
}
