$root = (Resolve-Path "$PSScriptRoot\..").Path
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add('http://localhost:5500/')
$listener.Start()
Write-Host "Serving $root on http://localhost:5500/"
$mime = @{'.html'='text/html';'.js'='application/javascript';'.json'='application/json';'.css'='text/css';'.geojson'='application/json';'.png'='image/png';'.jpg'='image/jpeg';'.svg'='image/svg+xml'}
while ($listener.IsListening) {
  try {
    $ctx = $listener.GetContext()
    $req = $ctx.Request
    $res = $ctx.Response
    $path = [System.Uri]::UnescapeDataString($req.Url.AbsolutePath)
    if ($path -eq '/') { $path = '/index.html' }
    $file = Join-Path $root $path.TrimStart('/')
    if (Test-Path -LiteralPath $file -PathType Leaf) {
      $ext = [System.IO.Path]::GetExtension($file).ToLower()
      $res.ContentType = if ($mime.ContainsKey($ext)) { $mime[$ext] } else { 'application/octet-stream' }
      $bytes = [System.IO.File]::ReadAllBytes($file)
      $res.ContentLength64 = $bytes.Length
      $res.OutputStream.Write($bytes, 0, $bytes.Length)
    } else {
      $res.StatusCode = 404
    }
    $res.Close()
  } catch { Write-Host "err: $_" }
}
