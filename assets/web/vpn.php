<?php
// Handle subscription update POST
$subMsg = '';
if ($_SERVER['REQUEST_METHOD'] === 'POST' && !empty($_POST['update_url'])) {
    $url = trim($_POST['update_url']);
    // Download subscription config from URL
    $configPath = '/etc/mihomo/config.yaml';
    $output = null;
    $result = false;
    if (filter_var($url, FILTER_VALIDATE_URL)) {
        // Use curl to fetch the config
        $cmd = "curl -fsSL " . escapeshellarg($url) . " -o " . escapeshellarg($configPath);
        exec($cmd, $output, $code);
        if ($code === 0) {
            // Reload mihomo service
            exec('sudo systemctl restart mihomo', $output2, $code2);
            if ($code2 === 0) {
                $subMsg = '<div class="message success">Subscription updated and VPN reloaded.</div>';
                $result = true;
            } else {
                $subMsg = '<div class="message error">Config updated, but failed to reload VPN service.</div>';
            }
        } else {
            $subMsg = '<div class="message error">Failed to download subscription config.</div>';
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
    <style>
        :root {
            --bg: #0f172a;
            --card: #1e293b;
            --text: #e2e8f0;
            --muted: #94a3b8;
            --accent: #38bdf8;
            --accent2: #22c55e;
            --accent3: #f59e0b;
        }
        * { box-sizing: border-box; }
        body {
            margin: 0;
            font-family: system-ui, -apple-system, Segoe UI, Roboto, Ubuntu, Cantarell, 'Helvetica Neue', Arial, 'Noto Sans', 'Apple Color Emoji','Segoe UI Emoji','Segoe UI Symbol';
            background: linear-gradient(120deg,#0b1224,#0f172a 40%,#0b1224);
            color: var(--text);
            min-height: 100vh;
        }
        .wrap {
            max-width: 520px;
            margin: 0 auto;
            padding: 40px 20px;
        }
        header {
            text-align: center;
            margin-bottom: 24px;
        }
        header h1 {
            margin: 0;
            font-size: 2rem;
            letter-spacing: 0.4px;
        }
        .btn {
            padding: 12px 24px;
            font-size: 1rem;
            margin: 10px 6px;
            cursor: pointer;
            border: none;
            border-radius: 8px;
            color: #0b1224;
            font-weight: 600;
            background: var(--accent);
            transition: background 0.15s;
        }
        .btn.on { background: var(--accent2); color: #fff; }
        .btn.off { background: #f44336; color: #fff; }
        .btn.update { background: var(--accent); color: #0b1224; }
        .status {
            margin-top: 20px;
            font-size: 1.1rem;
            margin-bottom: 30px;
        }
        .section {
            background: linear-gradient(180deg, rgba(255,255,255,0.06), rgba(255,255,255,0.02));
            border: 1px solid rgba(255,255,255,0.08);
            border-radius: 12px;
            padding: 24px 20px;
            max-width: 420px;
            margin: 40px auto 0;
            box-shadow: 0 2px 12px rgba(0,0,0,0.08);
        }
        input[type="text"] {
            padding: 12px;
            width: 100%;
            max-width: 320px;
            border-radius: 8px;
            border: 1px solid #ccc;
            font-size: 1rem;
        }
        .message {
            margin-top: 15px;
            padding: 12px;
            border-radius: 8px;
            font-size: 1rem;
        }
        .success { background-color: #134e1c; color: #a7f3d0; }
        .error { background-color: #7f1d1d; color: #fecaca; }
        /* Proxy Manager Styles */
        .proxy-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(150px, 1fr)); gap: 10px; margin-top: 15px; text-align: left; }
        .proxy-card { background: var(--card); border: 1px solid #334155; padding: 10px; border-radius: 8px; cursor: pointer; transition: all 0.2s; position: relative; }
        .proxy-card.active { background: #134e1c; border-color: var(--accent2); box-shadow: 0 0 0 1px var(--accent2); }
        .proxy-card:hover { transform: translateY(-2px); box-shadow: 0 2px 5px rgba(0,0,0,0.1); }
        .proxy-name { font-weight: 600; margin-bottom: 6px; font-size: 13px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
        .proxy-meta { display: flex; justify-content: space-between; align-items: center; font-size: 11px; color: var(--muted); }
        .latency-tag { background: #334155; padding: 2px 6px; border-radius: 4px; min-width: 40px; text-align: center; }
        .latency-tag.good { background: #134e1c; color: #a7f3d0; }
        .latency-tag.fair { background: #f59e0b; color: #fff; }
        .latency-tag.poor { background: #7f1d1d; color: #fff; }
        select { padding: 8px; border-radius: 4px; border: 1px solid #ccc; width: 100%; max-width: 300px; margin-bottom: 10px; }
        a { color: var(--accent); text-decoration: none; }
        a:hover { text-decoration: underline; }
    </style>
</head>
<body>
    <div class="wrap">
    <header>
        <h1>VPN Control</h1>
    </header>

    <div class="status">
        Current Status: <strong id="vpnStatus">Loading...</strong>
    </div>
    <div style="text-align:center;">
        <button type="button" id="vpnOnBtn" class="btn on">Turn ON</button>
        <button type="button" id="vpnOffBtn" class="btn off">Turn OFF</button>
        <span id="vpnMsg" class="message" style="display:none;"></span>
    </div>
        <script>

        async function pollVpnStatus() {
            try {
                const res = await fetch('api/clash.php?action=proxies');
                const data = await res.json();
                let running = false;
                if (!data.error && data.groups && Object.keys(data.groups).length > 0) {
                    running = true;
                }
                console.log('[VPN] pollVpnStatus:', {running, groups: data.groups, error: data.error});
                document.getElementById('vpnStatus').innerHTML = running ? '<span style="color:green">ON</span>' : '<span style="color:red">OFF</span>';
                document.getElementById('vpnOnBtn').disabled = running || window.vpnSwitching;
                document.getElementById('vpnOffBtn').disabled = !running || window.vpnSwitching;
                if (!window.vpnSwitching) {
                    document.getElementById('vpnMsg').style.display = 'none';
                }
                return running;
            } catch (e) {
                console.log('[VPN] pollVpnStatus error:', e);
                document.getElementById('vpnStatus').textContent = 'unknown';
                return null;
            }
        }

        async function vpnAction(action) {
            window.vpnSwitching = true;
            const msg = document.getElementById('vpnMsg');
            msg.style.display = 'inline-block';
            msg.textContent = 'Switching...';
            document.getElementById('vpnOnBtn').disabled = true;
            document.getElementById('vpnOffBtn').disabled = true;
            let expected = (action === 'on');
            let success = false;
            try {
                console.log('[VPN] vpnAction start', action);
                const res = await fetch('api/vpn_control.php', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ action })
                });
                const data = await res.json();
                console.log('[VPN] vpnAction response', data);
                // Poll status until it matches expected, or timeout
                let tries = 0;
                while (tries < 10) {
                    let running = await pollVpnStatus();
                    console.log('[VPN] vpnAction poll', {tries, running, expected});
                    if (running === expected) {
                        success = true;
                        break;
                    }
                    await new Promise(r => setTimeout(r, 500));
                    tries++;
                }
                if (success) {
                    msg.textContent = expected ? 'VPN is ON' : 'VPN is OFF';
                    msg.className = 'message success';
                } else {
                    msg.textContent = 'Switching failed or timed out';
                    msg.className = 'message error';
                }
                setTimeout(()=>{ msg.style.display = 'none'; }, 4000);
            } catch (e) {
                console.log('[VPN] vpnAction error:', e);
                msg.textContent = 'Network error';
                msg.className = 'message error';
            } finally {
                window.vpnSwitching = false;
                pollVpnStatus();
            }
        }

        document.addEventListener('DOMContentLoaded', () => {
            pollVpnStatus();
            setInterval(pollVpnStatus, 5000);
            document.getElementById('vpnOnBtn').onclick = () => vpnAction('on');
            document.getElementById('vpnOffBtn').onclick = () => vpnAction('off');
        });
        </script>
    
    <div class="section" id="proxySection" style="display:none;">
        <h2>Proxy Selection</h2>
        
        <!-- Subscription Info Card -->
        <div id="subInfo" style="background:#f8f9fa; border:1px solid #e9ecef; border-radius:8px; padding:15px; margin-bottom:20px; display:none; text-align:left;">
            <div style="font-weight:bold; font-size:1.1rem; margin-bottom:5px;" id="subName">Subscription</div>
            <div style="font-size:0.9rem; color:#666; margin-bottom:8px;" id="subDomain"></div>
            <div style="height:6px; background:#e9ecef; border-radius:3px; overflow:hidden; margin-bottom:8px;">
                <div id="subBar" style="width:0%; height:100%; background:#28a745;"></div>
            </div>
            <div style="display:flex; justify-content:space-between; font-size:0.85rem; color:#666;">
                <span id="subUsage">0 GB / 0 GB</span>
                <span id="subExpire">Expires: —</span>
            </div>
        </div>

        <div style="margin-bottom: 15px;">
            <select id="groupSelector" onchange="renderNodes()"></select>
            <button type="button" class="btn update" style="padding: 8px 15px; font-size: 14px;" onclick="testAllLatency()">⚡ Test Connectivity</button>
            <button type="button" class="btn update" style="padding: 8px 15px; font-size: 14px; background-color:#6c757d;" onclick="checkIp()">🔍 Check IP</button>
            <span id="ipResult" style="margin-left:10px; font-weight:bold;"></span>
        </div>
        <div id="nodeList" class="proxy-grid">Loading proxies...</div>
    </div>

    <div class="section" style="background: linear-gradient(180deg, rgba(255,255,255,0.06), rgba(255,255,255,0.02)); border: 1px solid rgba(255,255,255,0.08); border-radius: 12px; padding: 24px 20px; max-width: 420px; margin: 40px auto 0; box-shadow: 0 2px 12px rgba(0,0,0,0.08);">
        <?php if (!empty($subMsg)) echo $subMsg; ?>
        <form method="post" style="display: flex; flex-direction: column; align-items: center; gap: 18px;">
            <input type="text" name="update_url" placeholder="Paste Subscription URL here..." required style="padding: 12px; width: 100%; max-width: 320px; border-radius: 8px; border: 1px solid #ccc; font-size: 1rem;">
            <button type="submit" class="btn update" style="background: var(--accent,#38bdf8); color: #0b1224; font-weight: 600; border-radius: 8px; font-size: 1rem; padding: 12px 24px; width: 100%; max-width: 220px;">Update Subscription</button>
        </form>
    </div>

    <p style="margin-top: 50px; text-align:center;"><a href="/">Back to Portal</a></p>
    </div>

    <script>
        const isActive = <?php echo $is_active ? 'true' : 'false'; ?>;
        let proxyData = {};
        let currentGroup = '';

        document.addEventListener('DOMContentLoaded', () => {
            if (isActive) {
                document.getElementById('proxySection').style.display = 'block';
                fetchProxies();
                fetchSubscriptionInfo();
            }
        });

        async function fetchSubscriptionInfo() {
            try {
                const res = await fetch('api/clash.php?action=provider');
                const data = await res.json();
                
                if (data.info) {
                    const info = data.info; // { Upload: 123, Download: 456, Total: 789, Expire: 123456789 }
                    const total = info.Total ?? 0;
                    const used = (info.Upload ?? 0) + (info.Download ?? 0);
                    const expire = info.Expire ?? 0;
                    
                    if (total > 0) {
                        document.getElementById('subInfo').style.display = 'block';
                        document.getElementById('subName').textContent = data.name || 'Subscription';
                        
                        // Format bytes
                        const fmt = (b) => {
                            if (b===0) return '0 B';
                            const u = ['B','KB','MB','GB','TB'];
                            let i=0; while(b>=1024 && i<u.length-1){b/=1024;i++}
                            return b.toFixed(2) + ' ' + u[i];
                        };
                        
                        document.getElementById('subUsage').textContent = `${fmt(used)} / ${fmt(total)}`;
                        
                        const pct = Math.min(100, (used/total)*100);
                        const bar = document.getElementById('subBar');
                        bar.style.width = pct + '%';
                        if(pct > 90) bar.style.background = '#dc3545';
                        else if(pct > 75) bar.style.background = '#ffc107';
                        
                        if (expire > 0) {
                            const date = new Date(expire * 1000);
                            document.getElementById('subExpire').textContent = 'Expires: ' + date.toLocaleDateString();
                        } else {
                            document.getElementById('subExpire').textContent = 'No Expiration';
                        }
                    }
                }
            } catch (e) {
                console.log('Failed to fetch sub info', e);
            }
        }

        async function checkIp() {
            const el = document.getElementById('ipResult');
            el.textContent = 'Checking...';
            el.style.color = '#666';
            try {
                const res = await fetch('api/clash.php?action=check_ip');
                const data = await res.json();
                if (data.ip) {
                    el.textContent = 'IP: ' + data.ip;
                    el.style.color = 'green';
                } else {
                    el.textContent = 'Error: ' + (data.error || 'Unknown');
                    el.style.color = 'red';
                }
            } catch (e) {
                el.textContent = 'Network Error';
                el.style.color = 'red';
            }
        }

        async function fetchProxies() {
            try {
                const res = await fetch('api/clash.php?action=proxies');
                const data = await res.json();
                
                if (data.error) {
                    document.getElementById('nodeList').innerHTML = `<div style="color:red">${data.error}</div>`;
                    return;
                }

                proxyData = data;
                const selector = document.getElementById('groupSelector');
                selector.innerHTML = '';
                
                // Populate groups
                // Prioritize "GLOBAL" or "Proxy" or "Select"
                const groups = Object.keys(data.groups).sort((a,b) => {
                    const p = ['GLOBAL', 'Proxy', 'Select'];
                    const ia = p.indexOf(a);
                    const ib = p.indexOf(b);
                    if(ia !== -1 && ib !== -1) return ia - ib;
                    if(ia !== -1) return -1;
                    if(ib !== -1) return 1;
                    return a.localeCompare(b);
                });

                groups.forEach(g => {
                    const opt = document.createElement('option');
                    opt.value = g;
                    opt.textContent = g;
                    selector.appendChild(opt);
                });

                if (groups.length > 0) {
                    currentGroup = groups[0];
                    renderNodes();
                }
            } catch (e) {
                console.error(e);
            }
        }

        function renderNodes() {
            const selector = document.getElementById('groupSelector');
            currentGroup = selector.value;
            const group = proxyData.groups[currentGroup];
            const container = document.getElementById('nodeList');
            container.innerHTML = '';

            if (!group) return;

            group.all.forEach(nodeName => {
                const node = proxyData.nodes[nodeName];
                // Skip incompatible types if needed, but usually show all
                
                const card = document.createElement('div');
                card.className = `proxy-card ${nodeName === group.now ? 'active' : ''}`;
                card.onclick = () => selectProxy(nodeName);
                card.dataset.name = nodeName;

                const nameEl = document.createElement('div');
                nameEl.className = 'proxy-name';
                nameEl.textContent = nodeName;
                nameEl.title = nodeName;

                const metaEl = document.createElement('div');
                metaEl.className = 'proxy-meta';
                
                const typeSpan = document.createElement('span');
                typeSpan.textContent = node.type;
                
                const latSpan = document.createElement('span');
                latSpan.className = 'latency-tag';
                latSpan.textContent = '— ms';
                latSpan.id = `lat-${nodeName.replace(/\s+/g, '_')}`; // Simple ID sanitization

                metaEl.appendChild(typeSpan);
                metaEl.appendChild(latSpan);
                
                card.appendChild(nameEl);
                card.appendChild(metaEl);
                container.appendChild(card);
            });
        }

        async function selectProxy(name) {
            // Optimistic UI update
            const cards = document.querySelectorAll('.proxy-card');
            cards.forEach(c => c.classList.remove('active'));
            const target = Array.from(cards).find(c => c.dataset.name === name);
            if(target) target.classList.add('active');

            try {
                await fetch(`api/clash.php?action=select&group=${encodeURIComponent(currentGroup)}&name=${encodeURIComponent(name)}`);
                // Update local state
                if(proxyData.groups[currentGroup]) {
                    proxyData.groups[currentGroup].now = name;
                }
            } catch (e) {
                alert('Failed to switch proxy');
            }
        }

        async function testAllLatency() {
            const group = proxyData.groups[currentGroup];
            if (!group) return;

            const nodes = group.all;
            // Run in batches to avoid overwhelming
            for (const name of nodes) {
                testLatency(name);
                await new Promise(r => setTimeout(r, 50)); // Small delay
            }
        }

        async function testLatency(name) {
            const id = `lat-${name.replace(/\s+/g, '_')}`;
            const el = document.getElementById(id);
            if (!el) return;

            el.textContent = '...';
            try {
                const res = await fetch(`api/clash.php?action=latency&name=${encodeURIComponent(name)}`);
                const data = await res.json();
                
                if (data.delay) {
                    el.textContent = data.delay + ' ms';
                    el.className = 'latency-tag ' + (data.delay < 200 ? 'good' : (data.delay < 500 ? 'fair' : 'poor'));
                } else {
                    el.textContent = 'Timeout';
                    el.className = 'latency-tag poor';
                }
            } catch (e) {
                el.textContent = 'Err';
            }
        }
    </script>
</body>
</html>
