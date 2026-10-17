#!/usr/bin/env bash
# Convert line endings to Unix format
sed -i 's/\r$//' "$0" 2>/dev/null || true

set -euo pipefail
trap 'echo -e "${RED}[AutoUpdate] Error on line $LINENO${NC}"' ERR

# Color definitions
BLUE='\033[0;34m'; BOLD_BLUE='\033[1;34m'
WHITE='\033[0;37m'; GREEN='\033[0;32m'
YELLOW='\033[0;33m'; RED='\033[0;31m'
MAGENTA='\033[0;35m'; CYAN='\033[0;36m'
NC='\033[0m'

# ============================================================================
# UPDATE VERIFICATION
# ============================================================================
# Ed25519 public key of the update API. Every update package comes with a
# manifest signed by this key. It names the repository, both versions and the
# SHA-256 of the package, and nothing is installed unless all of it matches.
# Generate a key pair with: version-api generate-keypair
PUBLIC_KEY_BASE64="5MpxNNMkROJLixsSTk/PDBAFRF3bP+zr3U0lzzK/py4="

# Signed manifests older than this are rejected (seconds). Update packages only
# live 24 hours on the API, so an older manifest means an old response is being
# replayed.
MAX_MANIFEST_AGE=172800

# Print a string field of a single-line JSON document, with the escapes the API
# uses (\n and \") decoded. Fails if the field is missing or uses any other
# escape, so the result is always byte for byte what the API signed.
# Usage: json_string_field <json> <key>
json_string_field() {
    local json="$1" key="$2" raw
    raw=$(printf '%s' "$json" | grep -oE "\"${key}\":\"([^\"\\\\]|\\\\.)*\"" | head -n 1) || return 1
    [[ -n "$raw" ]] || return 1
    raw="${raw#\"${key}\":\"}"
    raw="${raw%\"}"
    if printf '%s' "$raw" | grep -q '\\[^n"]'; then
        return 1
    fi
    printf '%s' "$raw" | sed -e 's/\\n/\n/g' -e 's/\\"/"/g'
}

# Print the value of a manifest line (key=value)
manifest_field() {
    sed -n "s/^$2=//p" "$1" | head -n 1
}

# Verify a downloaded update package against the signed manifest
# Usage: verify_update <zip_file> <api_response> <from_version> <to_version>
# Returns: 0 only if the signature and every field match
verify_update() {
    local tool
    for tool in openssl sha256sum base64; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            echo -e "${RED}[AutoUpdate] ✗ ${tool} is not available, the update can't be verified${NC}"
            return 1
        fi
    done

    echo -e "${CYAN}[AutoUpdate] 🔐 Verifying signed manifest...${NC}"

    local temp_dir result=0
    temp_dir=$(mktemp -d)
    check_manifest "$temp_dir" "$@" || result=1
    rm -rf "$temp_dir"
    return $result
}

check_manifest() {
    local temp_dir="$1" zip_file="$2" response="$3" from_version="$4" to_version="$5"
    local pub_key_file="$temp_dir/public.pem"
    local manifest_file="$temp_dir/manifest"
    local sig_file="$temp_dir/manifest.sig"

    # Convert base64 public key to PEM format for Ed25519
    # (Ed25519 OID prefix MCowBQYDK2VwAyEA + base64 public key)
    {
        echo "-----BEGIN PUBLIC KEY-----"
        echo "MCowBQYDK2VwAyEA${PUBLIC_KEY_BASE64}" | fold -w 64
        echo "-----END PUBLIC KEY-----"
    } > "$pub_key_file"

    if ! json_string_field "$response" manifest > "$manifest_file" || [[ ! -s "$manifest_file" ]]; then
        echo -e "${RED}[AutoUpdate] ✗ The API response contains no valid manifest${NC}"
        return 1
    fi
    if ! json_string_field "$response" manifest_signature | base64 -d > "$sig_file" 2>/dev/null; then
        echo -e "${RED}[AutoUpdate] ✗ Failed to decode the manifest signature${NC}"
        return 1
    fi

    if ! openssl pkeyutl -verify -pubin -inkey "$pub_key_file" -rawin \
        -in "$manifest_file" -sigfile "$sig_file" >/dev/null 2>&1; then
        echo -e "${RED}[AutoUpdate] ✗ Signature verification FAILED!${NC}"
        echo -e "${RED}[AutoUpdate]   The update may have been tampered with.${NC}"
        echo -e "${RED}[AutoUpdate]   Update will NOT be applied for security reasons.${NC}"
        return 1
    fi
    echo -e "${GREEN}[AutoUpdate] ✓ Signature verified${NC}"

    # The manifest is authentic. Now make sure it is the update we asked for.
    local format repository from to sha256 created_at actual_hash age
    format=$(manifest_field "$manifest_file" format)
    repository=$(manifest_field "$manifest_file" repository)
    from=$(manifest_field "$manifest_file" from)
    to=$(manifest_field "$manifest_file" to)
    sha256=$(manifest_field "$manifest_file" sha256)
    created_at=$(manifest_field "$manifest_file" created_at)

    if [[ "$format" != "version-api-update-manifest/1" ]]; then
        echo -e "${RED}[AutoUpdate] ✗ Unknown manifest format: ${format}${NC}"
        return 1
    fi
    if [[ "${repository,,}" != "${REPO_OWNER,,}/${REPO_NAME,,}" ]]; then
        echo -e "${RED}[AutoUpdate] ✗ The update belongs to another repository: ${repository}${NC}"
        return 1
    fi
    if [[ "$from" != "$from_version" || "$to" != "$to_version" ]]; then
        echo -e "${RED}[AutoUpdate] ✗ The update is for ${from} → ${to}, expected ${from_version} → ${to_version}${NC}"
        return 1
    fi

    actual_hash=$(sha256sum "$zip_file" | cut -d' ' -f1)
    if [[ -z "$sha256" || "$actual_hash" != "$sha256" ]]; then
        echo -e "${RED}[AutoUpdate] ✗ Hash mismatch!${NC}"
        echo -e "${RED}[AutoUpdate]   Expected: ${sha256}${NC}"
        echo -e "${RED}[AutoUpdate]   Actual:   ${actual_hash}${NC}"
        return 1
    fi

    if ! [[ "$created_at" =~ ^[0-9]{1,12}$ ]]; then
        echo -e "${RED}[AutoUpdate] ✗ The manifest has no valid creation time${NC}"
        return 1
    fi
    age=$(( $(date +%s) - 10#$created_at ))
    if (( age > MAX_MANIFEST_AGE )); then
        echo -e "${RED}[AutoUpdate] ✗ The manifest is too old (${age}s), refusing to install it${NC}"
        return 1
    fi

    echo -e "${GREEN}[AutoUpdate] ✓ Update verified: ${repository} ${from} → ${to}, hash ${actual_hash:0:16}...${NC}"
    return 0
}

# Header function
header() {
  echo -e "${BLUE}───────────────────────────────────────────────${NC}"
  echo -e "${BOLD_BLUE}[AutoUpdate] $1${NC}"
}

# Configuration via environment variables
AUTOUPDATE_STATUS="${AUTOUPDATE_STATUS:-true}"
AUTOUPDATE_FORCE="${AUTOUPDATE_FORCE:-false}"
VERSION_FILE="/home/container/VERSION"
API_BASE_URL="https://api.tavuru.de"
REPO_OWNER="Ym0T"
REPO_NAME="pterodactyl-nginx-egg"
CONTAINER_ROOT="/home/container"
TEMP_DIR="/home/container/tmp/autoupdate"

# Check for staged self-update
check_staged_update() {
  local staging_dir="${CONTAINER_ROOT}/.autoupdate_staged"
  
  if [[ -d "$staging_dir/autoupdate" ]]; then
    echo -e "${YELLOW}[AutoUpdate] 🔄  Staged self-update detected${NC}"
    echo -e "${CYAN}[AutoUpdate] Applying staged auto-update module...${NC}"
    
    # Backup current autoupdate module
    local backup_dir="${CONTAINER_ROOT}/.autoupdate_backup_$(date +%s)"
    mkdir -p "$backup_dir"
    cp -r "${CONTAINER_ROOT}/modules/autoupdate" "$backup_dir/" 2>/dev/null || true
    
    # Apply staged update
    if cp -r "$staging_dir/autoupdate" "${CONTAINER_ROOT}/modules/" 2>/dev/null; then
      chmod +x "${CONTAINER_ROOT}/modules/autoupdate/start.sh" 2>/dev/null || true
      echo -e "${GREEN}[AutoUpdate] ✓ Self-update applied successfully${NC}"
      echo -e "${CYAN}[AutoUpdate] Backup saved to: $backup_dir${NC}"
      
      # Clean up staging
      rm -rf "$staging_dir" 2>/dev/null || true
      
      echo -e "${BOLD_BLUE}[AutoUpdate] Now running updated auto-update module${NC}"
    else
      echo -e "${RED}[AutoUpdate] Failed to apply staged update${NC}"
      echo -e "${YELLOW}[AutoUpdate] Continuing with current version${NC}"
    fi
  fi
}

# Function to check if auto-update should be enabled
enabled() { [[ "$1" =~ ^(true|1)$ ]]; }

# Skip if auto-update is disabled
if ! enabled "$AUTOUPDATE_STATUS"; then
  exit 0
fi

# Check for staged self-update first
check_staged_update

# Start header
header "Checking for Updates"

# Create temp directory for downloads
mkdir -p "$TEMP_DIR"

# Function to get current version from file
get_current_version() {
  if [[ -f "$VERSION_FILE" ]] && [[ -s "$VERSION_FILE" ]]; then
    local version
    version=$(cat "$VERSION_FILE" 2>/dev/null | tr -d '\n\r' | head -1)
    if [[ -n "$version" && "$version" != "unknown" ]]; then
      echo "$version"
      return 0
    fi
  fi
  
  echo "unknown"
}

# Function to get latest version from API
get_latest_version() {
  local api_url="${API_BASE_URL}/version/${REPO_OWNER}/${REPO_NAME}"
  echo -e "${WHITE}[AutoUpdate] Fetching latest version from API...${NC}"
  echo -e "${CYAN}[AutoUpdate] API URL: ${api_url}${NC}"
  
  local response
  local temp_file="${TEMP_DIR}/api_response.json"
  
  # Try to get response using wget
  if command -v wget >/dev/null 2>&1; then
    if wget --timeout=30 --tries=2 -q -O "$temp_file" "$api_url" 2>/dev/null; then
      if [[ -s "$temp_file" ]]; then
        response=$(cat "$temp_file")
        echo -e "${GREEN}[AutoUpdate] Successfully fetched API response${NC}"
      else
        echo -e "${RED}[AutoUpdate] Empty response from API${NC}"
        rm -f "$temp_file"
        return 1
      fi
    else
      echo -e "${RED}[AutoUpdate] wget failed to fetch from API${NC}"
      rm -f "$temp_file"
      return 1
    fi
  elif command -v curl >/dev/null 2>&1; then
    response=$(curl -s --max-time 30 "$api_url" 2>/dev/null)
    if [[ -z "$response" ]]; then
      echo -e "${RED}[AutoUpdate] curl failed to fetch from API${NC}"
      return 1
    fi
    echo -e "${GREEN}[AutoUpdate] Successfully fetched API response (curl)${NC}"
  else
    echo -e "${RED}[AutoUpdate] Neither wget nor curl available${NC}"
    return 1
  fi
  
  if [[ -z "$response" ]]; then
    echo -e "${RED}[AutoUpdate] Empty response from API${NC}"
    return 1
  fi
  
  echo -e "${CYAN}[AutoUpdate] Raw API response: ${response:0:200}...${NC}"
  
  # Extract version using basic text processing
  local version
  version=$(echo "$response" | grep -o '"version":"[^"]*"' | cut -d'"' -f4 | head -1)
  
  if [[ -z "$version" ]]; then
    echo -e "${YELLOW}[AutoUpdate] Trying alternative parsing...${NC}"
    version=$(echo "$response" | grep -o '"version": *"[^"]*"' | cut -d'"' -f4 | head -1)
    if [[ -z "$version" ]]; then
      version=$(echo "$response" | grep -o 'v[0-9]\+\.[0-9]\+\.[0-9]\+' | head -1)
    fi
  fi
  
  # Clean up temp file
  rm -f "$temp_file"
  
  if [[ -n "$version" ]]; then
    echo -e "${GREEN}[AutoUpdate] Parsed version: ${version}${NC}"
    echo "$version"
  else
    echo -e "${RED}[AutoUpdate] Could not extract version from response${NC}"
    echo -e "${YELLOW}[AutoUpdate] Full response: ${response}${NC}"
    return 1
  fi
}

# Function to compare versions with proper semantic versioning
version_compare() {
  local current="$1"
  local latest="$2"
  
  # Convert to lowercase for case-insensitive comparison
  current=$(echo "$current" | tr '[:upper:]' '[:lower:]')
  latest=$(echo "$latest" | tr '[:upper:]' '[:lower:]')
  
  # Remove 'v' prefix if present
  current="${current#v}"
  latest="${latest#v}"
  
  # Handle exact match
  if [[ "$current" == "$latest" ]]; then
    return 0  # Equal
  fi
  
  # Split versions into arrays (major.minor.patch)
  IFS='.' read -ra current_parts <<< "$current"
  IFS='.' read -ra latest_parts <<< "$latest"
  
  # Pad arrays to same length (fill missing parts with 0)
  local max_length=$(( ${#current_parts[@]} > ${#latest_parts[@]} ? ${#current_parts[@]} : ${#latest_parts[@]} ))
  
  # Ensure we have at least 3 parts for comparison
  while [[ ${#current_parts[@]} -lt $max_length ]] || [[ ${#current_parts[@]} -lt 3 ]]; do
    current_parts+=("0")
  done
  
  while [[ ${#latest_parts[@]} -lt $max_length ]] || [[ ${#latest_parts[@]} -lt 3 ]]; do
    latest_parts+=("0")
  done
  
  # Compare each version component numerically
  for i in $(seq 0 $((max_length - 1))); do
    local current_part="${current_parts[$i]:-0}"
    local latest_part="${latest_parts[$i]:-0}"
    
    # Remove leading zeros and ensure numeric comparison
    # Handle non-numeric parts by defaulting to 0
    if [[ "$current_part" =~ ^[0-9]+$ ]]; then
      current_part=$((10#$current_part))
    else
      current_part=0
    fi
    
    if [[ "$latest_part" =~ ^[0-9]+$ ]]; then
      latest_part=$((10#$latest_part))
    else
      latest_part=0
    fi
    
    if [[ $current_part -lt $latest_part ]]; then
      return 1  # Current is older
    elif [[ $current_part -gt $latest_part ]]; then
      return 2  # Current is newer
    fi
    # If equal, continue to next component
  done
  
  # All components are equal
  return 0
}

# Function to safely create or update version file
update_version_file() {
  local new_version="$1"
  
  if printf "%s\n" "$new_version" > "$VERSION_FILE" 2>/dev/null; then
    echo -e "${GREEN}[AutoUpdate] Version file updated to ${new_version}${NC}"
  else
    echo -e "${YELLOW}[AutoUpdate] Could not write version file, but update was successful${NC}"
  fi
}

# ============================================================================
# PRE-UPDATE BACKUP
# ============================================================================
# Creates a timestamped backup of every file that is about to be overwritten.
# Only files that already exist on disk AND appear in the update package are
# backed up – so the snapshot reflects exactly what will change.
#
# Backup location:
#   /home/container/.autoupdate_prebackup_<fromVer>_to_<toVer>_<timestamp>/
#
# A human-readable .backup_info file is written into the backup root so you
# can always tell at a glance what the backup contains and when it was made.
# ============================================================================
create_pre_update_backup() {
  local extract_dir="$1"
  local from_version="$2"
  local to_version="$3"

  local timestamp
  timestamp=$(date +%Y%m%d_%H%M%S)
  local backup_dir="${CONTAINER_ROOT}/.autoupdate_prebackup_${from_version}_to_${to_version}_${timestamp}"
  mkdir -p "$backup_dir"

  echo -e "${CYAN}[AutoUpdate] 💾 Creating pre-update backup...${NC}"
  local backed_up=0

  # Walk every file present in the extracted update package
  while IFS= read -r -d '' extracted_file; do
    local rel_path="${extracted_file#${extract_dir}/}"
    local live_file="${CONTAINER_ROOT}/${rel_path}"

    # Only back up files that actually exist on disk right now
    if [[ -f "$live_file" ]]; then
      local target_dir
      target_dir=$(dirname "${backup_dir}/${rel_path}")
      mkdir -p "$target_dir"
      cp "$live_file" "${backup_dir}/${rel_path}"
      backed_up=$((backed_up + 1))
    fi
  done < <(find "$extract_dir" -type f -print0)

  if [[ $backed_up -gt 0 ]]; then
    # Write human-readable info file
    {
      echo "Pre-update backup"
      echo "From version : $from_version"
      echo "To version   : $to_version"
      echo "Created at   : $(date)"
      echo "Files backed up: $backed_up"
    } > "${backup_dir}/.backup_info"

    echo -e "${GREEN}[AutoUpdate] ✓ Backed up ${backed_up} file(s) → $(basename "$backup_dir")${NC}"
    echo -e "${CYAN}[AutoUpdate] Backup location: ${backup_dir}${NC}"
  else
    echo -e "${YELLOW}[AutoUpdate] No existing files to back up${NC}"
    rmdir "$backup_dir" 2>/dev/null || true
  fi
}

# Function to download and apply diff
apply_update() {
  local from_version="$1"
  local to_version="$2"
  
  echo -e "${CYAN}[AutoUpdate] Downloading update from ${from_version} to ${to_version}...${NC}"
  
  # Get diff information with ZIP generation
  local diff_url="${API_BASE_URL}/diff/${REPO_OWNER}/${REPO_NAME}/${from_version}/${to_version}?zip=true"
  local diff_response
  local temp_diff_file="${TEMP_DIR}/diff_response.json"
  
  # Download diff information using wget
  if command -v wget >/dev/null 2>&1; then
    if ! wget --timeout=60 --tries=2 -q -O "$temp_diff_file" "$diff_url" 2>/dev/null; then
      echo -e "${RED}[AutoUpdate] Failed to fetch diff information${NC}"
      rm -f "$temp_diff_file"
      return 1
    fi
    diff_response=$(cat "$temp_diff_file")
  elif command -v curl >/dev/null 2>&1; then
    diff_response=$(curl -s --max-time 60 "$diff_url" 2>/dev/null)
  else
    echo -e "${RED}[AutoUpdate] No download tool available (wget/curl)${NC}"
    return 1
  fi
  
  if [[ -z "$diff_response" ]]; then
    echo -e "${RED}[AutoUpdate] Empty diff response${NC}"
    rm -f "$temp_diff_file"
    return 1
  fi
  
  # Extract download URL from response
  local download_url
  download_url=$(echo "$diff_response" | grep -o '"download_url":"[^"]*"' | cut -d'"' -f4)

  if [[ -z "$download_url" ]]; then
    echo -e "${RED}[AutoUpdate] No download URL found in diff response${NC}"
    rm -f "$temp_diff_file"
    return 1
  fi

  # Every update must come with a signed manifest
  if [[ "$diff_response" != *'"manifest_signature":"'* ]]; then
    echo -e "${RED}[AutoUpdate] ✗ The update is not signed, aborting for security reasons${NC}"
    rm -f "$temp_diff_file"
    return 1
  fi
  echo -e "${CYAN}[AutoUpdate] 🔐 Signed update detected${NC}"

  # Extract file change information for logging
  local total_changes files_added files_modified files_removed
  total_changes=$(echo "$diff_response" | grep -o '"total_changes":[0-9]*' | cut -d':' -f2)
  files_added=$(echo "$diff_response" | grep -o '"files_added":[0-9]*' | cut -d':' -f2)
  files_modified=$(echo "$diff_response" | grep -o '"files_modified":[0-9]*' | cut -d':' -f2)
  files_removed=$(echo "$diff_response" | grep -o '"files_removed":[0-9]*' | cut -d':' -f2)
  
  echo -e "${WHITE}[AutoUpdate] Update summary:${NC}"
  echo -e "${MAGENTA}  • Total changes: ${total_changes:-0}${NC}"
  echo -e "${MAGENTA}  • Files added: ${files_added:-0}${NC}"
  echo -e "${MAGENTA}  • Files modified: ${files_modified:-0}${NC}"
  echo -e "${MAGENTA}  • Files removed: ${files_removed:-0}${NC}"
  
  # Download the diff ZIP file
  local zip_file="${TEMP_DIR}/update.zip"
  echo -e "${WHITE}[AutoUpdate] Downloading update package...${NC}"
  
  if command -v wget >/dev/null 2>&1; then
    if ! wget --timeout=120 --tries=2 -q -O "$zip_file" "$download_url" 2>/dev/null; then
      echo -e "${RED}[AutoUpdate] Failed to download update package with wget${NC}"
      rm -f "$temp_diff_file" "$zip_file"
      return 1
    fi
  elif command -v curl >/dev/null 2>&1; then
    if ! curl -s --max-time 120 -o "$zip_file" "$download_url"; then
      echo -e "${RED}[AutoUpdate] Failed to download update package with curl${NC}"
      rm -f "$temp_diff_file" "$zip_file"
      return 1
    fi
  else
    echo -e "${RED}[AutoUpdate] No download tool available${NC}"
    rm -f "$temp_diff_file"
    return 1
  fi
  
  # Clean up diff response file
  rm -f "$temp_diff_file"
  
  # Verify ZIP file was downloaded
  if [[ ! -f "$zip_file" ]] || [[ ! -s "$zip_file" ]]; then
    echo -e "${RED}[AutoUpdate] Downloaded file is empty or missing${NC}"
    rm -f "$zip_file"
    return 1
  fi

  # Verify the package against the signed manifest before extracting anything
  if ! verify_update "$zip_file" "$diff_response" "$from_version" "$to_version"; then
    echo -e "${RED}[AutoUpdate] ✗ Update verification failed - aborting update${NC}"
    rm -f "$zip_file"
    return 1
  fi

  echo -e "${WHITE}[AutoUpdate] Extracting and applying updates...${NC}"
  
  # Extract to temporary directory
  local extract_dir="${TEMP_DIR}/extracted"
  mkdir -p "$extract_dir"
  
  if ! unzip -q "$zip_file" -d "$extract_dir" 2>/dev/null; then
    echo -e "${RED}[AutoUpdate] Failed to extract update package${NC}"
    rm -f "$zip_file"
    return 1
  fi

  # Apply updates only to allowed directories and files
  local updated_files=0
  local allowed_dirs=("modules" "nginx" "php")
  local allowed_files=("start-modules.sh" "README.md" "LICENSE")
  # Files that must never be overwritten by updates (relative to CONTAINER_ROOT)
  local protected_files=("nginx/conf.d/default.conf")
  local self_update_required=false

  # Remove protected files from the extraction directory before backup and copy.
  # This ensures they are neither backed up (they won't change) nor overwritten.
  echo -e "${CYAN}[AutoUpdate] Applying file protection rules...${NC}"
  for protected in "${protected_files[@]}"; do
    local protected_path="${extract_dir}/${protected}"
    if [[ -f "$protected_path" ]]; then
      rm -f "$protected_path"
      echo -e "${YELLOW}[AutoUpdate] 🔒 Protected (skipped): ${protected}${NC}"
    fi
  done

  # Back up every file that exists on disk and is about to be overwritten.
  # Runs AFTER protected files are removed so the backup only covers what
  # will actually change.
  create_pre_update_backup "$extract_dir" "$from_version" "$to_version"

  # Check if autoupdate module itself needs updating
  if [[ -f "${extract_dir}/modules/autoupdate/start.sh" ]]; then
    echo -e "${YELLOW}[AutoUpdate] ⚠ Auto-update module itself has updates${NC}"
    echo -e "${CYAN}[AutoUpdate] Self-update will be applied after server restart${NC}"
    self_update_required=true
  fi
  
  # Update allowed directories (skip autoupdate if it needs self-update)
  for dir in "${allowed_dirs[@]}"; do
    if [[ -d "${extract_dir}/${dir}" ]]; then
      if [[ "$dir" == "modules" && "$self_update_required" == "true" ]]; then
        echo -e "${CYAN}[AutoUpdate] Updating directory: ${dir} (excluding autoupdate)${NC}"
        
        # Copy all module directories except autoupdate
        for module_subdir in "${extract_dir}/${dir}"/*; do
          if [[ -d "$module_subdir" ]]; then
            local module_name=$(basename "$module_subdir")
            if [[ "$module_name" != "autoupdate" ]]; then
              echo -e "${WHITE}[AutoUpdate] Updating module: ${module_name}${NC}"
              cp -r "$module_subdir" "${CONTAINER_ROOT}/${dir}/" 2>/dev/null || true
              find "${CONTAINER_ROOT}/${dir}/${module_name}" -type f -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
            fi
          fi
        done
        
        # Stage autoupdate for next restart in protected location
        local staging_dir="${CONTAINER_ROOT}/.autoupdate_staged"
        mkdir -p "$staging_dir"
        cp -r "${extract_dir}/modules/autoupdate" "$staging_dir/" 2>/dev/null || true
        chmod +x "$staging_dir/autoupdate/start.sh" 2>/dev/null || true
        echo "$(date): Auto-update module staged for next restart" > "$staging_dir/.staging_info"
        echo -e "${YELLOW}[AutoUpdate] Auto-update module staged for next restart${NC}"
        
      else
        echo -e "${CYAN}[AutoUpdate] Updating directory: ${dir}${NC}"
        cp -r "${extract_dir}/${dir}/"* "${CONTAINER_ROOT}/${dir}/" 2>/dev/null || true
        find "${CONTAINER_ROOT}/${dir}" -type f -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
      fi
      updated_files=$((updated_files + 1))
    fi
  done
  
  # Update allowed files
  for file in "${allowed_files[@]}"; do
    if [[ -f "${extract_dir}/${file}" ]]; then
      echo -e "${CYAN}[AutoUpdate] Updating file: ${file}${NC}"
      cp "${extract_dir}/${file}" "${CONTAINER_ROOT}/${file}"
      if [[ "$file" == "start-modules.sh" ]]; then
        chmod +x "${CONTAINER_ROOT}/${file}"
      fi
      updated_files=$((updated_files + 1))
    fi
  done
  
  # Clean up temporary files
  rm -rf "$extract_dir" "$zip_file"
  
  if [[ $updated_files -gt 0 ]]; then
    echo -e "${GREEN}[AutoUpdate] Successfully updated ${updated_files} components${NC}"
    
    # Update version file
    update_version_file "$to_version"
    
    # Show self-update notice if applicable
    if [[ "$self_update_required" == "true" ]]; then
      echo -e " "
      echo -e "${BOLD_BLUE}[AutoUpdate] 🔄  IMPORTANT NOTICE:${NC}"
      echo -e "${YELLOW}[AutoUpdate] The auto-update module itself has been updated${NC}"
      echo -e "${YELLOW}[AutoUpdate] Changes will take effect on next server restart${NC}"
      echo -e "${CYAN}[AutoUpdate] Staged location: /home/container/.autoupdate_staged${NC}"
    fi
    
    return 0
  else
    echo -e "${YELLOW}[AutoUpdate] No applicable updates found${NC}"
    return 1
  fi
}

# Main update logic
main() {
  local current_version
  local latest_version
  
  # Get current version
  current_version=$(get_current_version)
  echo -e "${WHITE}[AutoUpdate] Current version: ${current_version}${NC}"
  
  # Test basic connectivity first using wget
  echo -e "${CYAN}[AutoUpdate] Testing connectivity to ${API_BASE_URL}...${NC}"
  local temp_health_file="${TEMP_DIR}/health_check.tmp"
  
  if command -v wget >/dev/null 2>&1; then
    if wget --timeout=10 --tries=1 -q -O "$temp_health_file" "${API_BASE_URL}/health" 2>/dev/null; then
      echo -e "${GREEN}[AutoUpdate] API connectivity OK (wget)${NC}"
    else
      echo -e "${YELLOW}[AutoUpdate] API health check failed, trying direct version check...${NC}"
    fi
    rm -f "$temp_health_file"
  elif command -v curl >/dev/null 2>&1; then
    if curl -s --max-time 10 "${API_BASE_URL}/health" >/dev/null 2>&1; then
      echo -e "${GREEN}[AutoUpdate] API connectivity OK (curl)${NC}"
    else
      echo -e "${YELLOW}[AutoUpdate] API health check failed, trying direct version check...${NC}"
    fi
  else
    echo -e "${RED}[AutoUpdate] No HTTP client available (need wget or curl)${NC}"
    echo -e "${YELLOW}[AutoUpdate] Skipping update check${NC}"
    return 0
  fi
  
  # Get latest version from API
  if ! latest_version=$(get_latest_version | tail -n 1); then
    echo -e "${YELLOW}[AutoUpdate] Could not fetch latest version from API${NC}"
    echo -e "${CYAN}[AutoUpdate] This could be due to:${NC}"
    echo -e "${CYAN}  • Network connectivity issues${NC}"
    echo -e "${CYAN}  • API server temporarily unavailable${NC}"
    echo -e "${CYAN}  • Repository not found: ${REPO_OWNER}/${REPO_NAME}${NC}"
    echo -e "${CYAN}  • API response format changed${NC}"
    echo -e "${YELLOW}[AutoUpdate] Skipping update check${NC}"
    return 0
  fi
  
  if [[ -z "$latest_version" ]]; then
    echo -e "${YELLOW}[AutoUpdate] Could not determine latest version, skipping update${NC}"
    return 0
  fi
  
  echo -e "${WHITE}[AutoUpdate] Latest version: ${latest_version}${NC}"
  
  # If current version is unknown, just save the latest version and continue
  if [[ "$current_version" == "unknown" ]]; then
    echo -e "${CYAN}[AutoUpdate] No version information found, saving current latest version${NC}"
    update_version_file "$latest_version"
    echo -e "${GREEN}[AutoUpdate] ✓ Version tracking initialized with ${latest_version}${NC}"
    return 0
  fi
  
  # Compare versions
  if version_compare "$current_version" "$latest_version"; then
    echo -e "${GREEN}[AutoUpdate] ✓ You are running the newest version${NC}"
    return 0
  elif [[ $? -eq 1 ]]; then
    echo -e "${YELLOW}[AutoUpdate] ⚠ Update available: ${current_version} → ${latest_version}${NC}"
    
    # Check if we should force update
    if enabled "$AUTOUPDATE_FORCE"; then
      header "Applying Update"
      
      if apply_update "$current_version" "$latest_version"; then
        echo -e "${GREEN}[AutoUpdate] ✓ Update completed successfully${NC}"
        echo -e "${CYAN}[AutoUpdate] Server will continue with new version${NC}"
      else
        echo -e "${YELLOW}[AutoUpdate] ⚠ Update failed, continuing with current version${NC}"
      fi
    else
      echo -e "${CYAN}[AutoUpdate] Auto-update is enabled but force update is disabled${NC}"
      echo -e "${CYAN}[AutoUpdate] Set AUTOUPDATE_FORCE=true to enable automatic updates${NC}"
    fi
  else
    echo -e "${MAGENTA}[AutoUpdate] Current version appears newer than latest release${NC}"
  fi
}

# Run main update logic - with proper error handling
main || echo -e "${YELLOW}[AutoUpdate] Update check completed${NC}"

# Clean up temp directory
rm -rf "$TEMP_DIR" 2>/dev/null || true
