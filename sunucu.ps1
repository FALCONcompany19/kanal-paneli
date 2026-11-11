# Kanal Paneli - kucuk yerel sunucu (sadece bu bilgisayardan erisilebilir)
$port = 8765
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$port/")
try { $listener.Start() } catch {
  Write-Host "Sunucu baslatilamadi: $($_.Exception.Message)"
  Write-Host "Panel zaten aciksa tarayicida http://localhost:$port/index.html adresine git."
  Read-Host "Kapatmak icin Enter'a bas"
  exit
}
Start-Process "http://localhost:$port/index.html"
Write-Host "Panel acik: http://localhost:$port/index.html"
Write-Host "Paneli kullandigin surece bu pencere acik kalmali. Isin bitince pencereyi kapat."
$types = @{ '.html'='text/html; charset=utf-8'; '.js'='application/javascript; charset=utf-8'; '.css'='text/css; charset=utf-8'; '.png'='image/png'; '.jpg'='image/jpeg'; '.svg'='image/svg+xml'; '.ico'='image/x-icon' }
while ($listener.IsListening) {
  $ctx = $listener.GetContext()
  $res = $ctx.Response
  try {
    $path = [Uri]::UnescapeDataString($ctx.Request.Url.AbsolutePath.TrimStart('/'))
    if ([string]::IsNullOrEmpty($path)) { $path = 'index.html' }
    $full = [IO.Path]::GetFullPath((Join-Path $root $path))
    $ext = [IO.Path]::GetExtension($full).ToLower()
    if ($full.StartsWith($root) -and $types.ContainsKey($ext) -and (Test-Path -LiteralPath $full -PathType Leaf)) {
      $bytes = [IO.File]::ReadAllBytes($full)
      $res.ContentType = $types[$ext]
      $res.Headers.Add('Cache-Control','no-store')
      $res.OutputStream.Write($bytes, 0, $bytes.Length)
    } else { $res.StatusCode = 404 }
  } catch { $res.StatusCode = 500 }
  $res.Close()
}
