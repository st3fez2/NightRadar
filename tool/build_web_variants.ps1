$ErrorActionPreference = 'Stop'

$prodUrl = 'https://st3fez2.github.io/NightRadar/'
$demoUrl = 'https://st3fez2.github.io/NightRadar/demo/'

$prodBuildArgs = @(
  'build',
  'web',
  '--release',
  '--base-href',
  '/NightRadar/',
  "--dart-define=APP_FLAVOR=prod",
  "--dart-define=PUBLIC_APP_URL=$prodUrl"
)

if ($env:SUPABASE_URL) {
  $prodBuildArgs += "--dart-define=SUPABASE_URL=$($env:SUPABASE_URL)"
}

if ($env:SUPABASE_ANON_KEY) {
  $prodBuildArgs += "--dart-define=SUPABASE_ANON_KEY=$($env:SUPABASE_ANON_KEY)"
}

flutter @prodBuildArgs

if (Test-Path build/site) {
  Remove-Item build/site -Recurse -Force
}

New-Item -ItemType Directory -Path build/site | Out-Null
Copy-Item build/web/* build/site -Recurse

$demoBuildArgs = @(
  'build',
  'web',
  '--release',
  '--base-href',
  '/NightRadar/demo/',
  "--dart-define=APP_FLAVOR=demo",
  "--dart-define=PUBLIC_APP_URL=$demoUrl"
)

if ($env:SUPABASE_URL_DEMO) {
  $demoBuildArgs += "--dart-define=SUPABASE_URL_DEMO=$($env:SUPABASE_URL_DEMO)"
}

if ($env:SUPABASE_ANON_KEY_DEMO) {
  $demoBuildArgs += "--dart-define=SUPABASE_ANON_KEY_DEMO=$($env:SUPABASE_ANON_KEY_DEMO)"
}

flutter @demoBuildArgs

New-Item -ItemType Directory -Path build/site/demo -Force | Out-Null
Copy-Item build/web/* build/site/demo -Recurse

Write-Host 'Web variants assembled in build/site'
