<!DOCTYPE html>
<html>
<head>
    <title>VPN Control</title>
    <style>
        body { font-family: sans-serif; text-align: center; padding: 50px; max-width: 600px; margin: 0 auto; }
        .btn { padding: 15px 30px; font-size: 20px; margin: 10px; cursor: pointer; border: none; border-radius: 5px; color: white; }
        .on { background-color: #4CAF50; }
        .off { background-color: #f44336; }
        .update { background-color: #2196F3; font-size: 16px; padding: 10px 20px; }
        .status { margin-top: 20px; font-size: 18px; margin-bottom: 30px; }
        .section { border-top: 1px solid #ccc; margin-top: 30px; padding-top: 30px; }
        input[type="text"] { padding: 10px; width: 70%; border-radius: 5px; border: 1px solid #ccc; }
        .message { margin-top: 15px; padding: 10px; border-radius: 5px; }
        .success { background-color: #dff0d8; color: #3c763d; }
        .error { background-color: #f2dede; color: #a94442; }
        
        /* Proxy Manager Styles */
        .proxy-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(150px, 1fr)); gap: 10px; margin-top: 15px; text-align: left; }
        .proxy-card { background: #fff; border: 1px solid #ddd; padding: 10px; border-radius: 6px; cursor: pointer; transition: all 0.2s; position: relative; }
        .proxy-card.active { background: #e8f5e9; border-color: #4CAF50; box-shadow: 0 0 0 1px #4CAF50; }
        .proxy-card:hover { transform: translateY(-2px); box-shadow: 0 2px 5px rgba(0,0,0,0.1); }
        .proxy-name { font-weight: 600; margin-bottom: 6px; font-size: 13px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
        .proxy-meta { display: flex; justify-content: space-between; align-items: center; font-size: 11px; color: #666; }
        .latency-tag { background: #eee; padding: 2px 6px; border-radius: 4px; min-width: 40px; text-align: center; }
        .latency-tag.good { background: #dff0d8; color: #2e7d32; }
        .latency-tag.fair { background: #fff3e0; color: #ef6c00; }
        .latency-tag.poor { background: #ffebee; color: #c62828; }
        select { padding: 8px; border-radius: 4px; border: 1px solid #ccc; width: 100%; max-width: 300px; margin-bottom: 10px; }
    </style>
</head>
<body>
    <h1>VPN Control</h1>
    
    <?php
    $message = "";
    $msg_type = "";

    if ($_SERVER['REQUEST_METHOD'] === 'POST') {
        if (isset($_POST['action'])) {
            $action = $_POST['action'];
            // Try both common paths for systemctl
            $cmd = "sudo /usr/bin/systemctl";
            if (!file_exists('/usr/bin/systemctl') && file_exists('/bin/systemctl')) {
                $cmd = "sudo /bin/systemctl";
            }
            
            if ($action == 'on') {
                exec("$cmd start mihomo 2>&1", $output, $return_var);
                if ($return_var === 0) {
                    $message = "VPN Turned ON";
                    $msg_type = "success";
                } else {
                    $message = "Error: " . implode(" ", $output);
                    $msg_type = "error";
                }
            } elseif ($action == 'off') {
                exec("$cmd stop mihomo 2>&1", $output, $return_var);
                if ($return_var === 0) {
                    $message = "VPN Turned OFF";
                    $msg_type = "success";
                } else {
                    $message = "Error: " . implode(" ", $output);
                    $msg_type = "error";
                }
            }
        } elseif (isset($_POST['update_url'])) {
            $url = $_POST['update_url'];
            if (!empty($url)) {
                // Download subscription and update config
                $temp_file = '/tmp/clash_sub_' . time() . '.yaml';
                
                // Use curl instead of file_get_contents for better reliability
                // -L: Follow redirects
                // -s: Silent
                // -o: Output file
                // --fail: Fail on HTTP errors
                $curl_cmd = "curl -L -s --fail -o " . escapeshellarg($temp_file) . " " . escapeshellarg($url) . " 2>&1";
                exec($curl_cmd, $dl_output, $dl_return);
                
                if ($dl_return === 0 && file_exists($temp_file) && filesize($temp_file) > 0) {
                    // Validate it's not just an HTML error page (basic check)
                    $first_line = fgets(fopen($temp_file, 'r'));
                    if (strpos($first_line, '<!DOCTYPE') !== false || strpos($first_line, '<html') !== false) {
                         $message = "Update Failed: The URL returned HTML instead of YAML/Config. Check your link.";
                         $msg_type = "error";
                         unlink($temp_file);
                    } else {
                        // Use helper script to move file and restart service
                        exec("sudo /usr/local/bin/update_mihomo " . escapeshellarg($temp_file) . " 2>&1", $output, $return_var);
                        
                        if ($return_var === 0) {
                            $message = "Subscription Updated Successfully!";
                            $msg_type = "success";
                            
                            // Wait a moment for service to restart
                            sleep(2);
                            
                            // Fetch provider info if available
                            $providerInfo = @file_get_contents("http://127.0.0.1:9090/providers/proxies");
                            if ($providerInfo) {
                                $pData = json_decode($providerInfo, true);
                                // Logic to extract expiration/usage if standard headers are used or provider metadata exists
                                // This is highly dependent on the subscription format, but we can try to parse the subscription info header from the curl response if we had access to headers.
                                // For now, we'll rely on the user seeing the updated proxy list.
                            }
                        } else {
                            $message = "Update Failed (Script): " . implode(" ", $output);
                            $msg_type = "error";
                        }
                        // Cleanup handled by script or here if script failed
                        if (file_exists($temp_file)) unlink($temp_file);
                    }
                } else {
                    $message = "Update Failed (Download): " . implode(" ", $dl_output);
                    $msg_type = "error";
                }
            }
        }
    }

    // Check Status
    $status_cmd = "systemctl is-active mihomo";
    if (file_exists('/usr/bin/systemctl')) $status_cmd = "/usr/bin/systemctl is-active mihomo";
    elseif (file_exists('/bin/systemctl')) $status_cmd = "/bin/systemctl is-active mihomo";
    
    $status = exec($status_cmd);
    $is_active = ($status == 'active');
    ?>

    <?php if (!empty($message)): ?>
        <div class="message <?php echo $msg_type; ?>">
            <?php echo htmlspecialchars($message); ?>
        </div>
    <?php endif; ?>

    <div class="status">
        Current Status: <strong><?php echo $is_active ? '<span style="color:green">ON</span>' : '<span style="color:red">OFF</span>'; ?></strong>
    </div>

    <form method="post">
        <button type="submit" name="action" value="on" class="btn on" <?php if($is_active) echo 'disabled'; ?>>Turn ON</button>
        <button type="submit" name="action" value="off" class="btn off" <?php if(!$is_active) echo 'disabled'; ?>>Turn OFF</button>
    </form>
    
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

    <div class="section">
        <h2>Update Subscription</h2>
        <form method="post">
            <input type="text" name="update_url" placeholder="Paste Subscription URL here..." required>
            <br><br>
            <button type="submit" class="btn update">Update Subscription</button>
        </form>
    </div>

    <p style="margin-top: 50px;"><a href="/">Back to Portal</a> | <a href="/ariang/">Open AriaNg</a></p>

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
