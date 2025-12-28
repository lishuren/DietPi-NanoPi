# Local Configurations

This folder contains configuration files that will be deployed to the Pi.

These files are **committed to git** as the "golden configuration" and can be edited locally before deployment.

## 📝 Files

### Systemd Services
- `mihomo.service` - Systemd unit for Mihomo (Clash) VPN service
- `aria2.service` - Systemd unit for Aria2 download manager

### Application Configs
- `aria2.conf` - Aria2 configuration (download paths, RPC settings, etc.)
- `smb.conf` - Samba configuration for file sharing
- `nginx.conf` - Nginx web server configuration
- `clash_config.yaml` - Clash proxy runtime configuration

### Web Files
- `index.html` - Custom homepage/portal
- `nginx-default-site` - Nginx site config (includes /proxy/ for php-proxy-app)

## 🧩 Web Apps

### php-proxy-app
- Place the php-proxy-app code in `assets/web/proxy/`.
- It will be deployed to `/var/www/html/proxy/` and accessible at `http://<your-pi>/proxy/`.
- **Important:** The `config.php` file must have a non-empty `$config['app_key']` (e.g., `'DietPI-PHP-Proxy'`). This is required for the proxy to work.

## 🔄 Workflow

1. **Download from Pi**: `./download.sh` - Get current configs from running Pi
2. **Edit locally**: Modify files in this folder on your PC
3. **Deploy to Pi**: `./deploy.sh` - Upload and activate changes
4. **Version control**: Commit changes to git

## 📋 Initial Setup

If you don't have these files yet:

1. Set up your Pi with DietPi and install services
2. Run `./download.sh` to pull current configs
3. Edit as needed
4. Commit to git as your baseline configuration

## 🚀 Deployment

```bash
# Edit a config file
nano local_configs/aria2.conf

# Deploy to Pi
./deploy.sh

# Check status
./status.sh
```
