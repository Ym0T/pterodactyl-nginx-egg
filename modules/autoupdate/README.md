# Auto-Update Module

This module automatically checks for and applies updates to the Pterodactyl Nginx Egg using the [GitHub Version API](https://github.com/Ym0T/github-version-api) hosted at `api.tavuru.de`. It runs as the first module during container startup to ensure you're always running the latest version.

## Features

- ✅ **Automatic version checking** using the GitHub Version API
- ✅ **Smart differential updates** - only downloads changed files
- ✅ **Selective file updates** - only updates allowed directories and files
- ✅ **Version tracking** via local version file
- ✅ **Detailed logging** with colored output
- ✅ **Safe update process** with rollback protection
- ✅ **Configurable update behavior** via environment variables
- ✅ **Network timeout protection** for reliable operations

## Configuration

| Environment Variable | Default | Description |
|---------------------|---------|-------------|
| `AUTOUPDATE_STATUS` | `true` | Enable (`true`/`1`) or disable (`false`/`0`) auto-update |
| `AUTOUPDATE_FORCE` | `true` | Enable automatic downloading and applying of updates |

## Update Scope

The auto-update module only updates specific directories and files to maintain system stability:

### **Allowed Directories:**
- `modules/` - All module scripts and configurations
- `nginx/` - Nginx configuration files
- `php/` - PHP configuration files

### **Allowed Files:**
- `start-modules.sh` - Main orchestration script
- `README.md` - Documentation
- `LICENSE` - License file

### **Protected Areas:**
- `www/` - User web content (never touched)
- `logs/` - Log files
- `tmp/` - Temporary files
- User data and configurations

## How It Works

1. **Version Check**: Reads current version from `/home/container/VERSION`
2. **API Query**: Fetches latest version from `https://api.tavuru.de/version/Ym0T/pterodactyl-nginx-egg`
3. **Comparison**: Compares current vs latest version
4. **Diff Download**: If update available, downloads differential update package
5. **Selective Apply**: Applies only changes to allowed directories/files
6. **Version Update**: Updates version file with new version

## API Integration

This module uses the [GitHub Version API](https://github.com/Ym0T/github-version-api), hosted at `api.tavuru.de`. The source code is public, and [SIGNING.md](https://github.com/Ym0T/github-version-api/blob/main/SIGNING.md) describes the signed manifest the module checks before installing an update:

### Version API
```bash
GET https://api.tavuru.de/version/Ym0T/pterodactyl-nginx-egg
```

### Diff API
```bash
GET https://api.tavuru.de/diff/Ym0T/pterodactyl-nginx-egg/{from}/{to}?zip=true
```

## Update Behavior

### Conservative Mode (Default)
- `AUTOUPDATE_STATUS=true`
- `AUTOUPDATE_FORCE=false`
- **Behavior**: Checks for updates and shows availability, but doesn't auto-apply

### Automatic Mode
- `AUTOUPDATE_STATUS=true` 
- `AUTOUPDATE_FORCE=true`
- **Behavior**: Automatically downloads and applies updates

### Disabled Mode
- `AUTOUPDATE_STATUS=false`
- **Behavior**: Skips all update operations

## Example Output

```bash
───────────────────────────────────────────────
[AutoUpdate] Checking for Updates
[AutoUpdate] Current version: v2.1.0
[AutoUpdate] Fetching latest version from API...
[AutoUpdate] Latest version: v2.2.0
[AutoUpdate] ⚠ Update available: v2.1.0 → v2.2.0
───────────────────────────────────────────────
[AutoUpdate] Applying Update
[AutoUpdate] Downloading update from v2.1.0 to v2.2.0...
[AutoUpdate] Update summary:
  • Total changes: 15
  • Files added: 3
  • Files modified: 8
  • Files removed: 2
[AutoUpdate] Downloading update package...
[AutoUpdate] Extracting and applying updates...
[AutoUpdate] Updating directory: modules
[AutoUpdate] Updating file: start-modules.sh
[AutoUpdate] Successfully updated 2 components
[AutoUpdate] Version updated to v2.2.0
[AutoUpdate] ✓ Update completed successfully
[AutoUpdate] Update check completed
```

## Egg JSON Configuration

Add these variables to your `egg-nginx-v2.json`:

```json
{
  "name": "Enable Auto-Update",
  "description": "Automatically check for and apply updates on startup",
  "env_variable": "AUTOUPDATE_STATUS",
  "default_value": "1",
  "user_viewable": true,
  "user_editable": true,
  "rules": "required|boolean",
  "field_type": "text"
},
{
  "name": "Force Auto-Update",
  "description": "Automatically download and apply updates without confirmation",
  "env_variable": "AUTOUPDATE_FORCE",
  "default_value": "0",
  "user_viewable": true,
  "user_editable": true,
  "rules": "required|boolean",
  "field_type": "text"
}
```

## Security Considerations

- **Signed Updates**: Every update package comes with a manifest signed by the API. The module checks the signature with the public key embedded in `start.sh`, and that the manifest names this repository, the installed and the new version, the SHA-256 of the package and a recent creation time. Anything that doesn't match is not installed
- **Limited Scope**: Only updates approved directories and files
- **Version Verification**: Uses official API for version information
- **Safe Downloads**: Temporary files are cleaned up after use
- **Network Timeouts**: Prevents hanging on network issues
- **Rollback Safety**: Original files remain untouched during download

## Troubleshooting

### Common Issues

1. **Network connectivity**: Module will fail gracefully if API is unreachable
2. **Version file missing**: Automatically creates with 'unknown' version
3. **Permission issues**: Ensures scripts are executable after update
4. **Download failures**: Cleans up partial downloads automatically

### Debug Information

Check the console output during startup for detailed information about:
- Current and latest versions
- Update availability
- Download progress
- File changes applied
- Any errors encountered

### When an Update Fails

There is no separate log file. When a request fails, the module prints everything needed to find the cause to the console during startup: the request, the HTTP status, the error code and message returned by the API, and the request ID. The server starts anyway and keeps the version it had.

```text
[AutoUpdate] ✗ Fetching the update information failed
[AutoUpdate]   Request:     https://api.tavuru.de/diff/Ym0T/pterodactyl-nginx-egg/v3.2.7/v3.2.8?zip=true
[AutoUpdate]   HTTP status: 422
[AutoUpdate]   API error:   versions_not_sequential
[AutoUpdate]   Message:     ZIP archives require to_version to be a descendant of from_version
[AutoUpdate]   Request ID:  4edd76ef-f19d-45b4-835c-70022189b0c3
[AutoUpdate] → The installed version is not part of the history of the new version in the repository, [...]
[AutoUpdate] ⚠ Update failed, continuing with current version
```

When you report a failed update, include these lines. The request ID points to the exact request in the API's log.

| Output | Meaning | What to do |
|---|---|---|
| `Reason: Could not resolve host …`, `… timed out …` | The server can't reach the API | Check DNS and that outgoing HTTPS (port 443) to `api.tavuru.de` is allowed |
| `versions_not_sequential` | The installed version is not part of the history of the new version, for example after a release tag was moved | Has to be fixed in the repository, please [report it](https://github.com/Ym0T/pterodactyl-nginx-egg/issues) |
| `version_not_found` | The version in `/home/container/VERSION` is not a release | Check that the file contains a released version such as `v3.2.8` |
| `zip_target_not_latest` | A newer version was released during the update | Nothing, the update is retried on the next restart |
| `rate_limited`, `server_busy`, `github_unavailable`, HTTP 5xx | Temporary problem on the API side | Nothing, the update is retried on the next restart |
| `diff_too_large`, `unsupported_change`, … | The update can't be packaged for automatic installation | Please [report it](https://github.com/Ym0T/pterodactyl-nginx-egg/issues) |

Every error response of the API has the same format, see the [API documentation](https://github.com/Ym0T/github-version-api#endpoints).

### Manual Version Reset

To reset version tracking:
```bash
echo "unknown" > /home/container/VERSION
```

## Best Practices

1. **Test Updates**: Consider using conservative mode in production
2. **Monitor Logs**: Review update logs for any issues
3. **Backup Important Data**: Always backup your `www/` directory
4. **Network Stability**: Ensure stable internet connection during startup
5. **Version Tracking**: Don't manually edit the version file

## Module Dependencies

- **curl** (or **wget** as fallback): For API requests and file downloads
- **unzip**: For extracting update packages  
- **openssl/sha256sum/base64**: For verifying signed updates (without them, updates are refused)
- **grep/cut**: For JSON parsing (lightweight approach)
- Standard Unix utilities (cp, chmod, mkdir, etc.)

All dependencies are included in the base container image.