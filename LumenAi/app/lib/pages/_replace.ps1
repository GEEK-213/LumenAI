$basePath = "C:\Users\faari\OneDrive\Desktop\FinalProject\LumenAI\LumenAi\app\lib\pages"
$files = Get-ChildItem -Path $basePath -Recurse -Include *.dart
foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw
    if ($content -match 'Colors\.blueAccent') {
        $newContent = $content -replace 'Colors\.blueAccent', 'Theme.of(context).primaryColor'
        Set-Content $file.FullName $newContent -NoNewline
        Write-Host "Updated: $($file.Name)"
    }
}
