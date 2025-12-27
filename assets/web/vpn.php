<?php
// Handle subscription URL update
$subMsg = '';
$currentSubUrl = 'Unknown';
$configPath = '/etc/mihomo/config.yaml';

if (file_exists($configPath)) {
    $configContent = file_get_contents($configPath);
    if (preg_match('/url:\s*"([^"]+)"/', $configContent, $matches)) {
        $currentSubUrl = $matches[1];
    }
}

if ($_SERVER['REQUEST_METHOD'] === 'POST' && !empty($_POST['update_url'])) {
    $url = trim($_POST['update_url']);
    if (filter_var($url, FILTER_VALIDATE_URL)) {
        $configContent = file_get_contents($configPath);
        $newConfig = preg_replace('/url:\s*".*?"/', 'url: "' . addslashes($url) . '"', $configContent);
        if ($newConfig !== $configContent && file_put_contents($configPath, $newConfig) !== false) {
            exec('sudo systemctl restart mihomo');
            $subMsg = '<div class="message success">Subscription URL updated!</div>';
            $currentSubUrl = $url;
        } else {
            $subMsg = '<div class="message error">Failed to update URL.</div>';
        }
    } else {
        $subMsg = '<div class="message error">Invalid URL.</div>';
    }
}
?>
<!DOCTYPE html>
<html>
<head>
    <title>VPN Control</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
        :root {
            --bg: #0f172a;
            --card: #1e293b;
            --text: #e2e8f0;
            --muted: #94a3b8;
            --accent: #38bdf8;
            --on: #22c55e;
            --off: #f44336;
        }
        * { box-sizing: border-box; }
        body {
            margin: 0;
            font-family: system-ui, -apple-system, Segoe UI, Roboto, Ubuntu, Cantarell, Arial;
            background: var(--bg);
            color: var(--text);
            min-height: 100vh;
            padding: 20px 10px;
        }
        .container {
            max-width: 1000px;
            margin: 0 auto;
        }
        header {
            text-align: center;
            margin-bottom: 20px;
        }
        h1 { margin: 0; font-size: 1.8rem; }
        .back-btn {
            position: absolute;
            top: 20px;
            left: 10px;
            padding: 8px 16px;
            background: var(--card);
            border: none;
            border-radius: 8px;
            color: var(--text);
            text-decoration: none;
            font-size: 0.9rem;
        }
        .status-bar {
            background: var(--card);
            padding: 16px;
            border-radius: 12px;
            margin-bottom: 20px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            flex-wrap: wrap;
            gap: 12px;
        }
        .status-info {
            font-size: 1rem;
        }
        .vpn-state {
            font-weight: bold;
            color: var(--off);
        }
        .vpn-state.on { color: var(--on); }
        .toggle-switch {
            position: relative;
            display: inline-block;
            width: 60px;
            height: 34px;
        }
        .toggle-switch input {
            opacity: 0;
            width: 0;
            height: 0;
        }
        .slider {
            position: absolute;
            cursor: pointer;
            top: 0; left: 0; right: 0; bottom: 0;
            background-color: #ccc;
            transition: .4s;
            border-radius: 34px;
        }
        .slider:before {
            position: absolute;
            content: "";
            height: 26px;
            width: 26px;
            left: 4px;
            bottom: 4px;
            background-color: white;
            transition: .4s;
            border-radius: 50%;
        }
        input:checked + .slider {
            background-color: var(--on);
        }
        input:checked + .slider:before {
            transform: translateX(26px);
        }
        .main-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 20px;
            margin-bottom: 30px;
        }
        @media (max-width: 768px) {
            .main-grid { grid-template-columns: 1fr; }
        }
        .card {
            background: var(--card);
            border-radius: 12px;
            padding: 20px;
            box-shadow: 0 4px 12px rgba(0,0,0,0.2);
        }
        .card h2 {
            margin-top: 0;
            margin-bottom: 15px;
            font-size: 1.3rem;
        }
        input[type="text"] {
            width: 100%;
            padding: 10px;
            border-radius: 8px;
            border: 1px solid #444;
            background: #0f172a;
            color: var(--text);
            margin-bottom: 10px;
        }
        button {
            padding: 10px 16px;
            border: none;
            border-radius: 8px;
            cursor: pointer;
            font-weight: 600;
            margin-right: 8px;
            margin-bottom: 8px;
        }
        .btn-primary { background: var(--accent); color: #000; }
        .btn-secondary { background: var(--accent3); color: #000; }
        .btn-small { padding: 6px 12px; font-size: 0.9rem; }
        .proxy-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(140px, 1fr));
            gap: 10px;
            margin-top: 10px;
        }
        .proxy-card {
            background: #2d3748;
            padding: 10px;
            border-radius: 8px;
            text-align: center;
            cursor: pointer;
            transition: all 0.2s;
        }
        .proxy-card.active {
            background: #134e1c;
            border: 2px solid var(--on);
        }
        .latency {
            font-size: 0.8rem;
            color: var(--muted);
            margin-top: 4px;
        }
        .good { color: var(--on); }
        .fair { color: var(--accent3); }
        .poor { color: var(--off); }
        .traffic {
            margin-top: 10px;
            font-size: 0.9rem;
            color: var(--muted);
        }
        .message {
            padding: 10px;
            border-radius: 8px;
            margin: 10px 0;
        }
        .success { background: #134e1c; color: #a7f3d0; }
        .error { background: #7f1d1d; color: #fecaca; }
        .bottom-back {
            text-align: center;
            margin-top: 30px;
        }
    </style>
</head>
<body>
    <div class="container">
        <a href="/" class="back-btn">← Back to Portal</a>
        <header>
            <h1>VPN Control</h1>
        </header>

        <div class="status-bar">
            <div class="status-info" id="statusInfo">
                Loading status...
            </div>
            <label class="toggle-switch">
                <input type="checkbox" id="vpnToggle" onchange="toggleVPN(this.checked)">
                <span class="slider"></span>
            </label>
        </div>

        <div class="main-grid">
            <!-- Subscription Card -->
            <div class="card">
                <h2>Subscription</h2>
                <p><strong>Current URL:</strong><br><span id="currentUrl"><?php echo htmlspecialchars($currentSubUrl); ?></span></p>
                <form method="POST">
                    <input type="text" name="update_url" placeholder="New subscription URL" required>
                    <button type="submit" class="btn-primary">Update URL</button>
                </form>
                <button onclick="refreshSubscription()" class="btn-secondary">Refresh Now</button>
                <?php echo $subMsg; ?>
                <div id="subInfo"></div>
            </div>

            <!-- Proxy Manager Card -->
            <div class="card">
                <h2>Proxy Manager</h2>
                <div style="margin-bottom: 10px;">
                    <select id="groupSelector" onchange="renderNodes()"></select>
                    <button onclick="testAllLatency()" class="btn-small btn-secondary">Test All</button>
                </div>
                <div id="nodeList" class="proxy-grid"></div>
                <div id="trafficInfo" class="traffic">Traffic: Up 0 B/s | Down 0 B/s</div>
            </div>
        </div>

        <div class="bottom-back">
            <a href="/" class="btn-primary">← Back to Portal</a>
        </div>
    </div>

    <script>
        let proxyData = { groups: {}, nodes: {} };
        let currentGroup = '';
        let trafficInterval;

        async function loadAll() {
            await fetchStatus();
            await fetchProxies();
        }

        async function fetchStatus() {
            try {
                const res = await fetch('api/clash.php?action=status');
                const data = await res.json();

                const isOn = data.vpn_on || false;
                document.getElementById('vpnToggle').checked = isOn;
                document.querySelector('.vpn-state').className = isOn ? 'vpn-state on' : 'vpn-state';

                document.getElementById('statusInfo').innerHTML = `
                    <strong>VPN: <span class="vpn-state ${isOn ? 'on' : ''}">${isOn ? 'ON' : 'OFF'}</span></strong><br>
                    Current: ${data.current_proxy || 'DIRECT'}<br>
                    IP: ${data.proxy_ip || 'N/A'} (Proxy) | ${data.direct_ip || 'N/A'} (Direct)
                `;

                let subHtml = 'Subscription: N/A';
                if (data.provider) {
                    const info = data.provider.info || {};
                    subHtml = `
                        Subscription: ${data.provider.name || 'Unknown'}<br>
                        Updated: ${data.provider.updated || 'N/A'}<br>
                        Usage: ${formatBytes(info.Upload + info.Download || 0)} / ${formatBytes(info.Total || 0)}
                        ${info.Expire ? ' | Expire: ' + new Date(info.Expire * 1000).toLocaleDateString() : ''}
                    `;
                }
                document.getElementById('subInfo').innerHTML = subHtml;
            } catch (e) {
                document.getElementById('statusInfo').textContent = 'Error loading status';
            }
        }

        async function toggleVPN(checked) {
            const action = checked ? 'on' : 'off';
            try {
                const res = await fetch('api/vpn_control.php', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ action })
                });
                const data = await res.json();
                if (!data.success) alert(data.message || 'Failed');
                fetchStatus();
            } catch (e) {
                alert('Network error');
                document.getElementById('vpnToggle').checked = !checked;
            }
        }

        async function refreshSubscription() {
            try {
                const res = await fetch('api/clash.php?action=refresh_provider');
                const data = await res.json();
                alert(data.success ? 'Refreshed!' : 'Failed');
                fetchProxies();
            } catch (e) {
                alert('Error');
            }
        }

        async function fetchProxies() {
            try {
                const res = await fetch('api/clash.php?action=proxies');
                const data = await res.json();
                if (data.error) {
                    document.getElementById('nodeList').innerHTML = `<div style="color:red;">${data.error}</div>`;
                    return;
                }

                proxyData.groups = {};
                proxyData.nodes = {};
                Object.entries(data.proxies || {}).forEach(([name, item]) => {
                    if (item.type === 'Selector' || item.type === 'Select') {
                        proxyData.groups[name] = item;
                    } else if (item.type !== 'DIRECT') {
                        proxyData.nodes[name] = item;
                    }
                });

                renderGroups();
                startTrafficPoll();
            } catch (e) {
                console.error(e);
            }
        }

        function renderGroups() {
            const sel = document.getElementById('groupSelector');
            sel.innerHTML = '';
            const order = ['VPN-Switch', 'Proxy'];
            const sorted = Object.keys(proxyData.groups).sort((a, b) => {
                const ia = order.indexOf(a), ib = order.indexOf(b);
                if (ia !== -1 && ib !== -1) return ia - ib;
                if (ia !== -1) return -1;
                if (ib !== -1) return 1;
                return a.localeCompare(b);
            });

            sorted.forEach(g => {
                const opt = document.createElement('option');
                opt.value = g;
                opt.textContent = g + (g === proxyData.groups[g].now ? ' ✓' : '');
                sel.appendChild(opt);
            });

            if (sorted.length > 0) {
                currentGroup = sorted.includes('Proxy') ? 'Proxy' : sorted[0];
                sel.value = currentGroup;
                renderNodes();
            }
        }

        function renderNodes() {
            const group = proxyData.groups[currentGroup];
            if (!group) return;
            const container = document.getElementById('nodeList');
            container.innerHTML = '';

            (group.all || []).forEach(name => {
                const node = proxyData.nodes[name] || { type: 'Unknown' };
                const card = document.createElement('div');
                card.className = `proxy-card ${name === group.now ? 'active' : ''}`;
                card.onclick = () => selectProxy(name);

                card.innerHTML = `
                    <div><strong>${name}</strong></div>
                    <div>${node.type || ''}</div>
                    <div class="latency" id="lat-${name.replace(/\s+/g, '_')}">— ms</div>
                `;
                container.appendChild(card);
            });
        }

        async function selectProxy(name) {
            try {
                await fetch(`api/clash.php?action=select&group=${encodeURIComponent(currentGroup)}&name=${encodeURIComponent(name)}`);
                proxyData.groups[currentGroup].now = name;
                renderNodes();
                fetchStatus();
            } catch (e) {
                alert('Failed to switch');
            }
        }

        async function testAllLatency() {
            const group = proxyData.groups[currentGroup];
            if (!group) return;
            for (const name of group.all) {
                await testLatency(name);
                await new Promise(r => setTimeout(r, 60));
            }
        }

        async function testLatency(name) {
            const el = document.getElementById(`lat-${name.replace(/\s+/g, '_')}`);
            if (!el) return;
            el.textContent = '...';
            try {
                const res = await fetch(`api/clash.php?action=latency&name=${encodeURIComponent(name)}`);
                const data = await res.json();
                const delay = data.delay || 'Timeout';
                el.textContent = typeof delay === 'number' ? delay + ' ms' : delay;
                el.className = 'latency ' + (delay < 200 ? 'good' : delay < 500 ? 'fair' : 'poor');
            } catch (e) {
                el.textContent = 'Err';
                el.className = 'latency poor';
            }
        }

        function startTrafficPoll() {
            clearInterval(trafficInterval);
            trafficInterval = setInterval(async () => {
                try {
                    const res = await fetch('api/clash.php?action=traffic');
                    const d = await res.json();
                    document.getElementById('trafficInfo').textContent = 
                        `Traffic: ↑ ${formatBytes(d.up)}/s | ↓ ${formatBytes(d.down)}/s`;
                } catch (e) {}
            }, 3000);
        }

        function formatBytes(b) {
            if (b === 0) return '0';
            const units = ['B', 'KB', 'MB', 'GB'];
            let i = 0;
            while (b >= 1024 && i < units.length - 1) { b /= 1024; i++; }
            return b.toFixed(1) + ' ' + units[i];
        }

        // Initial load
        loadAll();
        setInterval(fetchStatus, 10000);
    </script>
</body>
</html>