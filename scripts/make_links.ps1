#Requires -Version 5.1
<#
.SYNOPSIS
    Writes the shortcut files in links\ (double-click one to open that page in
    the browser), each with its own icon.

.DESCRIPTION
    The pages: the request service's admin page and health check, the
    Cloudflare Worker and its database, the GitHub repository, releases and
    issues, and Google Play Console.

    Nothing is typed in here twice. The service address is read from
    lib\features\requests\data\requests_config.dart, the database id and Worker
    name from server\wrangler.toml, and the GitHub repository from the git
    remote called origin.

    The icons (links\icons\*.ico) are drawn by this script and kept in the
    repository, so they are only drawn when missing, or with -RedrawIcons.
    The .url files are rewritten every time. A .url file needs the full path of
    its icon, so they hold the location of this checkout: run the script again
    after moving the repository or cloning it somewhere else.

.PARAMETER RedrawIcons
    Draws every icon again, even the ones that exist.

.EXAMPLE
    .\scripts\make_links.ps1
#>
[CmdletBinding()]
param(
    [switch] $RedrawIcons
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$RepoRoot = Split-Path -Parent $PSScriptRoot
$LinksDir = Join-Path $RepoRoot 'links'
$IconsDir = Join-Path $LinksDir 'icons'
New-Item -ItemType Directory -Force -Path $IconsDir | Out-Null

# ---------------------------------------------------------- where things are ---

function Read-First([string] $Path, [string] $Pattern, [string] $What) {
    $match = [regex]::Match((Get-Content -Raw -LiteralPath $Path), $Pattern)
    if (-not $match.Success) { throw "Could not find $What in $Path." }
    $match.Groups[1].Value
}

$service = (Read-First (Join-Path $RepoRoot 'lib\features\requests\data\requests_config.dart') `
    "defaultRequestsUrl\s*=\s*'([^']+)'" 'defaultRequestsUrl').TrimEnd('/')
$wranglerToml = Join-Path $RepoRoot 'server\wrangler.toml'
$workerName = Read-First $wranglerToml '(?m)^name\s*=\s*"([^"]+)"' 'the Worker name'
$databaseId = Read-First $wranglerToml '(?m)^database_id\s*=\s*"([0-9a-fA-F-]{36})"' 'the D1 database_id'

$remote = (git -C $RepoRoot remote get-url origin).Trim()
$repoMatch = [regex]::Match($remote, 'github\.com[:/]([^/]+)/([^/]+?)(\.git)?$')
if (-not $repoMatch.Success) { throw "origin ($remote) is not a GitHub repository." }
$repo = "https://github.com/$($repoMatch.Groups[1].Value)/$($repoMatch.Groups[2].Value)"

# The dashboard turns :account into the signed-in account.
$dash = 'https://dash.cloudflare.com/?to=/:account'

# File name, address, icon name, tile colour.
$links = @(
    @('Dhikr admin',          "$service/admin",                                      'admin',    '#B8860B'),
    @('Service health',       "$service/health",                                     'health',   '#2E9E6B'),
    @('Cloudflare Worker',    "$dash/workers/services/view/$workerName/production",  'worker',   '#F38020'),
    @('Cloudflare database',  "$dash/workers/d1/databases/$databaseId",              'database', '#D9631A'),
    @('GitHub repository',    $repo,                                                 'repo',     '#24292F'),
    @('GitHub releases',      "$repo/releases",                                      'releases', '#6F42C1'),
    @('GitHub issues',        "$repo/issues",                                        'issues',   '#1F883D'),
    @('Google Play Console',  'https://play.google.com/console',                     'play',     '#01875F')
)

# ----------------------------------------------------------------- drawing ----
# Every picture is drawn on a 100 by 100 grid, white on a rounded coloured tile,
# and scaled to each icon size.

function Point([double] $x, [double] $y) { New-Object Drawing.PointF ([single] $x), ([single] $y) }

function Stroke([double] $width) {
    $pen = New-Object Drawing.Pen ([Drawing.Color]::White), ([single] $width)
    $pen.StartCap = 'Round'
    $pen.EndCap = 'Round'
    $pen.LineJoin = 'Round'
    $pen
}

function Draw-Tile($g, [Drawing.Color] $color) {
    $d = 44
    $tile = New-Object Drawing.Drawing2D.GraphicsPath
    $tile.AddArc(2, 2, $d, $d, 180, 90)
    $tile.AddArc(98 - $d, 2, $d, $d, 270, 90)
    $tile.AddArc(98 - $d, 98 - $d, $d, $d, 0, 90)
    $tile.AddArc(2, 98 - $d, $d, $d, 90, 90)
    $tile.CloseFigure()
    $light = [Drawing.Color]::FromArgb(255,
        [int] ($color.R + (255 - $color.R) * 0.22),
        [int] ($color.G + (255 - $color.G) * 0.22),
        [int] ($color.B + (255 - $color.B) * 0.22))
    $brush = New-Object Drawing.Drawing2D.LinearGradientBrush (Point 0 0), (Point 0 100), $light, $color
    $g.FillPath($brush, $tile)
    $brush.Dispose()
    $tile.Dispose()
}

$Pictures = @{
    # A shield with a keyhole.
    admin = {
        param($g, $bg)
        $white = [Drawing.Brushes]::White
        $hole = New-Object Drawing.SolidBrush $bg
        $p = New-Object Drawing.Drawing2D.GraphicsPath
        $p.AddLine(50, 13, 80, 25)
        $p.AddLine(80, 25, 80, 48)
        $p.AddBezier(80, 48, 80, 66, 67, 79, 50, 87)
        $p.AddBezier(50, 87, 33, 79, 20, 66, 20, 48)
        $p.AddLine(20, 48, 20, 25)
        $p.CloseFigure()
        $g.FillPath($white, $p)
        $g.FillEllipse($hole, 41, 35, 18, 18)
        $g.FillPolygon($hole, [Drawing.PointF[]] @((Point 45 49), (Point 55 49), (Point 58 69), (Point 42 69)))
        $hole.Dispose()
    }
    # A heartbeat line.
    health = {
        param($g, $bg)
        $pen = Stroke 8
        $g.DrawLines($pen, [Drawing.PointF[]] @(
            (Point 12 52), (Point 30 52), (Point 40 30), (Point 53 74), (Point 63 44), (Point 69 52), (Point 88 52)))
        $pen.Dispose()
    }
    # A cloud with a lightning bolt: a Worker.
    worker = {
        param($g, $bg)
        $white = [Drawing.Brushes]::White
        $cut = New-Object Drawing.SolidBrush $bg
        $g.FillEllipse($white, 14, 44, 34, 34)
        $g.FillEllipse($white, 30, 22, 42, 42)
        $g.FillEllipse($white, 54, 40, 34, 38)
        $g.FillRectangle($white, 31, 50, 40, 28)
        $g.FillPolygon($cut, [Drawing.PointF[]] @(
            (Point 55 38), (Point 41 60), (Point 50 60), (Point 45 79), (Point 63 53), (Point 53 53), (Point 60 38)))
        $cut.Dispose()
    }
    # A stack of disks: a database.
    database = {
        param($g, $bg)
        $white = [Drawing.Brushes]::White
        $g.FillRectangle($white, 22, 27, 56, 46)
        $g.FillEllipse($white, 22, 17, 56, 22)
        $g.FillEllipse($white, 22, 61, 56, 22)
        $line = New-Object Drawing.Pen $bg, ([single] 4.5)
        $line.StartCap = 'Round'
        $line.EndCap = 'Round'
        $g.DrawArc($line, 22, 33, 56, 22, 8, 164)
        $g.DrawArc($line, 22, 47, 56, 22, 8, 164)
        $line.Dispose()
    }
    # A branch: a repository.
    repo = {
        param($g, $bg)
        $pen = Stroke 7
        $g.DrawEllipse($pen, 22, 16, 20, 20)
        $g.DrawEllipse($pen, 22, 64, 20, 20)
        $g.DrawEllipse($pen, 58, 22, 20, 20)
        $g.DrawLine($pen, 32, 36, 32, 64)
        $g.DrawBezier($pen, 68, 42, 68, 62, 32, 46, 32, 62)
        $pen.Dispose()
    }
    # A tag: a release.
    releases = {
        param($g, $bg)
        $white = [Drawing.Brushes]::White
        $hole = New-Object Drawing.SolidBrush $bg
        $pen = Stroke 7
        $tag = [Drawing.PointF[]] @((Point 23 24), (Point 51 24), (Point 80 53), (Point 53 80), (Point 23 50))
        $g.FillPolygon($white, $tag)
        $g.DrawPolygon($pen, $tag)
        $g.FillEllipse($hole, 33, 34, 13, 13)
        $hole.Dispose()
        $pen.Dispose()
    }
    # A ring with a dot: an issue.
    issues = {
        param($g, $bg)
        $pen = Stroke 8
        $g.DrawEllipse($pen, 22, 22, 56, 56)
        $g.FillEllipse([Drawing.Brushes]::White, 40, 40, 20, 20)
        $pen.Dispose()
    }
    # A play triangle: Google Play.
    play = {
        param($g, $bg)
        $pen = Stroke 8
        $triangle = [Drawing.PointF[]] @((Point 36 26), (Point 36 74), (Point 77 50))
        $g.FillPolygon([Drawing.Brushes]::White, $triangle)
        $g.DrawPolygon($pen, $triangle)
        $pen.Dispose()
    }
}

function New-IconImage([int] $Size, [scriptblock] $Picture, [Drawing.Color] $Color) {
    $bitmap = New-Object Drawing.Bitmap $Size, $Size, ([Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [Drawing.Graphics]::FromImage($bitmap)
    $g.SmoothingMode = 'AntiAlias'
    $g.PixelOffsetMode = 'HighQuality'
    $g.CompositingQuality = 'HighQuality'
    $g.Clear([Drawing.Color]::Transparent)
    $g.ScaleTransform([single] ($Size / 100), [single] ($Size / 100))
    Draw-Tile $g $Color
    & $Picture $g $Color
    $g.Dispose()
    $stream = New-Object IO.MemoryStream
    $bitmap.Save($stream, [Drawing.Imaging.ImageFormat]::Png)
    $bitmap.Dispose()
    , $stream.ToArray()
}

# An .ico file holding PNG pictures (Windows Vista and later read them).
function Write-Icon([string] $Path, [scriptblock] $Picture, [Drawing.Color] $Color) {
    $sizes = 256, 64, 48, 32, 24, 16
    $images = @(foreach ($size in $sizes) { , (New-IconImage $size $Picture $Color) })
    $file = [IO.File]::Create($Path)
    try {
        $w = New-Object IO.BinaryWriter $file
        $w.Write([uint16] 0)
        $w.Write([uint16] 1)
        $w.Write([uint16] $sizes.Count)
        $offset = 6 + 16 * $sizes.Count
        for ($i = 0; $i -lt $sizes.Count; $i++) {
            $dimension = if ($sizes[$i] -ge 256) { 0 } else { $sizes[$i] }
            $w.Write([byte] $dimension)
            $w.Write([byte] $dimension)
            $w.Write([byte] 0)
            $w.Write([byte] 0)
            $w.Write([uint16] 1)
            $w.Write([uint16] 32)
            $w.Write([uint32] $images[$i].Length)
            $w.Write([uint32] $offset)
            $offset += $images[$i].Length
        }
        foreach ($image in $images) { $w.Write([byte[]] $image) }
        $w.Flush()
    }
    finally {
        $file.Dispose()
    }
}

# ------------------------------------------------------------------ writing ---

foreach ($link in $links) {
    $title, $url, $icon, $color = $link
    $iconPath = Join-Path $IconsDir "$icon.ico"
    if ($RedrawIcons -or -not (Test-Path -LiteralPath $iconPath)) {
        Write-Icon $iconPath $Pictures[$icon] ([Drawing.ColorTranslator]::FromHtml($color))
        Write-Host "Drew $iconPath" -ForegroundColor DarkGray
    }
    $text = "[InternetShortcut]`r`nURL=$url`r`nIconIndex=0`r`nIconFile=$iconPath`r`n"
    [IO.File]::WriteAllText((Join-Path $LinksDir "$title.url"), $text, [Text.Encoding]::ASCII)
    Write-Host ('{0,-22} {1}' -f $title, $url)
}
Write-Host "`nWrote $($links.Count) shortcuts to $LinksDir" -ForegroundColor Cyan
