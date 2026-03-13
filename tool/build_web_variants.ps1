$ErrorActionPreference = 'Stop'

$prodUrl = 'https://st3fez2.github.io/NightRadar/'
$demoUrl = 'https://st3fez2.github.io/NightRadar/demo/'

flutter build web --release `
  --base-href /NightRadar/ `
  --dart-define=APP_FLAVOR=prod `
  --dart-define=PUBLIC_APP_URL=$prodUrl

if (Test-Path build/site) {
  Remove-Item build/site -Recurse -Force
}

New-Item -ItemType Directory -Path build/site | Out-Null
Copy-Item build/web/* build/site -Recurse

flutter build web --release `
  --base-href /NightRadar/demo/ `
  --dart-define=APP_FLAVOR=demo `
  --dart-define=PUBLIC_APP_URL=$demoUrl

New-Item -ItemType Directory -Path build/site/demo -Force | Out-Null
Copy-Item build/web/* build/site/demo -Recurse

Write-Host 'Web variants assembled in build/site'
