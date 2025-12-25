#!/bin/bash

set -euo pipefail

WEB_ROOT="/var/www/html"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SRC_PAGE="$REPO_ROOT/web/index.html"

echo "Installing portal home page..."
mkdir -p "$WEB_ROOT"

if [ -f "$SRC_PAGE" ]; then
  echo "Using source page: $SRC_PAGE"
  cp "$SRC_PAGE" "$WEB_ROOT/index.html"
else
  echo "Source page not found; installing minimal placeholder."
  cat > "$WEB_ROOT/index.html" <<'HTML'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>NanoPi Portal</title>
  <style>
    :root { --bg:#0f172a; --card:#1e293b; --text:#e2e8f0; --muted:#94a3b8; --accent:#38bdf8; --accent2:#22c55e; --accent3:#f59e0b; }
    * { box-sizing: border-box; }
    body { margin:0; font-family: system-ui, -apple-system, Segoe UI, Roboto, Ubuntu, Cantarell, 'Helvetica Neue', Arial, 'Noto Sans', 'Apple Color Emoji','Segoe UI Emoji','Segoe UI Symbol'; background: linear-gradient(120deg,#0b1224,#0f172a 40%,#0b1224); color: var(--text); }
    .wrap { max-width: 960px; margin: 0 auto; padding: 40px 20px; }
    header { text-align: center; margin-bottom: 24px; }
    header h1 { margin:0; font-size: 2rem; letter-spacing: 0.4px; }
    header p { color: var(--muted); margin-top: 8px; }
    .grid { display: grid; grid-template-columns: repeat(2, minmax(240px, 1fr)); gap: 16px; }
    @media (max-width: 640px) { .grid { grid-template-columns: 1fr; } }
    .card { background: linear-gradient(180deg, rgba(255,255,255,0.06), rgba(255,255,255,0.02)); border: 1px solid rgba(255,255,255,0.08); backdrop-filter: blur(4px); border-radius: 12px; padding: 20px; transition: transform 120ms ease, box-shadow 120ms ease; }
    .card:hover { transform: translateY(-2px); box-shadow: 0 6px 20px rgba(0,0,0,0.25); }
    .card h2 { margin: 0 0 8px; font-size: 1.1rem; }
    .card p { margin: 0 0 12px; color: var(--muted); font-size: 0.95rem; }
    .btn { display: inline-block; padding: 10px 14px; border-radius: 8px; text-decoration: none; color: #0b1224; font-weight: 600; background: var(--accent); }
    .btn.secondary { background: var(--accent2); }
    .btn.warn { background: var(--accent3); }
    .row { display: flex; gap: 10px; flex-wrap: wrap; }
    .mono { font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, 'Liberation Mono', 'Courier New', monospace; background: rgba(15,23,42,0.6); border: 1px solid rgba(255,255,255,0.08); border-radius: 8px; padding: 10px; }
    footer { margin-top: 28px; text-align: center; color: var(--muted); font-size: 0.9rem; }
  </style>
  <script>
    const host = window.location.hostname;
    function smbPath() { return "\\\\" + host + "\\downloads"; }
    function copySmb() {
      const path = smbPath();
      navigator.clipboard.writeText(path).then(() => {
        const el = document.getElementById('copyStatus');
        el.textContent = 'Copied! Use Win+R → paste to open.';
        setTimeout(() => el.textContent = '', 2500);
      }).catch(() => { alert('Copy failed. Path: ' + path); });
    }
    document.addEventListener('DOMContentLoaded', () => {
      const hostEl = document.getElementById('deviceHost');
      if (hostEl) hostEl.textContent = host;
      document.getElementById('smbPath').textContent = smbPath();
    });
  </script>
  <link rel="icon" href="data:,">
</head>
<body>
  <div class="wrap">
    <header>
      <h1>DietPi NanoPi Portal</h1>
      <p>Jump quickly to services hosted on this box.</p>
      <p style="color: var(--muted);">Device Address: <span class="mono" id="deviceHost">loading...</span></p>
    </header>

    <section class="grid">
      <div class="card">
        <h2>AriaNg</h2>
        <p>Web UI for Aria2 downloads.</p>
        <a class="btn" href="/ariang" rel="noopener">Open AriaNg</a>
      </div>

      <div class="card">
        <h2>VPN Control</h2>
        <p>Toggle VPN and update subscription.</p>
        <a class="btn secondary" href="/vpn.php" rel="noopener">Open VPN UI</a>
      </div>

      <div class="card">
        <h2>Samba Share</h2>
        <p>Windows network share path for downloads.</p>
        <div class="mono" id="smbPath">calculating...</div>
        <div class="row">
          <button class="btn warn" onclick="copySmb()">Copy Path</button>
          <span id="copyStatus" style="align-self:center;color:var(--muted)"></span>
        </div>
        <p style="margin-top:8px;color:var(--muted)">Tip: Press Win+R, paste the path, hit Enter.</p>
      </div>

      <div class="card">
        <h2>Project Home</h2>
        <p>GitHub repository and documentation.</p>
        <a class="btn" href="https://github.com/lishuren/DietPi-NanoPi" target="_blank" rel="noopener">Open GitHub</a>
      </div>
    </section>

    <footer>
      Served by Lighttpd • DocumentRoot: /var/www/html
    </footer>
  </div>
</body>
<!--
Notes:
- AriaNg is installed under /var/www/html/ariang by install_ariang.sh
- VPN UI lives at /var/www/html/vpn.php from install_vpn_web_ui.sh
- Samba share path defaults to \\HOST\downloads (HOST resolves via location.hostname)
-->

</html>
HTML
fi

chown -R www-data:www-data "$WEB_ROOT/index.html" 2>/dev/null || true
echo "Portal home page ready at http://<ip>/"
