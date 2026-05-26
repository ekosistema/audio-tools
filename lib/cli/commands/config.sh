# Audio Tools — Config subcommand
# Manage audio-tools configuration

if [ -z "$(type -t log_info)" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../utils/logging.sh"
fi
if [ -z "$(type -t log_error)" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../utils/errors.sh"
fi
if [ -z "$(type -t init_output)" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../ui/output.sh"
fi

# Default config file
CONFIG_FILE="${AUDIO_TOOLS_CONFIG:-$HOME/.config/audio-tools/config.sh}"

cmd_config() {
    local subcommand="${1:-}"

    # Check for help
    if [ "$subcommand" = "-h" ] || [ "$subcommand" = "--help" ]; then
        cat << 'EOF'
Manage audio-tools configuration

USAGE:
  audio-tools config <subcommand> [options]

SUBCOMMANDS:
  list          Show all settings
  get KEY       Get a configuration value
  set KEY VALUE Set a configuration value
  reset         Reset to defaults
  edit          Open config file in $EDITOR
  path          Show config file path

EXAMPLES:
  audio-tools config list
  audio-tools config get output_dir
  audio-tools config set output_dir mp3s
  audio-tools config edit
EOF
        return 0
    fi

    case "$subcommand" in
        list)
            cmd_config_list "$@"
            ;;
        get)
            cmd_config_get "$2"
            ;;
        set)
            cmd_config_set "$2" "$3"
            ;;
        reset)
            cmd_config_reset
            ;;
        edit)
            cmd_config_edit
            ;;
        path)
            echo "$CONFIG_FILE"
            ;;
        *)
            log_error "Usage: audio-tools config <list|get|set|reset|edit|path>"
            return "$EX_USAGE"
            ;;
    esac
}

cmd_config_list() {
    init_output

    if [ ! -f "$CONFIG_FILE" ]; then
        if [ "$AUDIO_TOOLS_QUIET" != "yes" ]; then
            log_warn "No config file found at $CONFIG_FILE"
        fi
        return 0
    fi

    if [ "$AUDIO_TOOLS_JSON" = "yes" ]; then
        printf '{"config_file":"%s","settings":{\n' "$CONFIG_FILE"
        grep "^export AUDIO_TOOLS" "$CONFIG_FILE" | while read -r line; do
            local key=$(echo "$line" | sed 's/export AUDIO_TOOLS_//' | cut -d= -f1)
            local val=$(echo "$line" | cut -d= -f2- | tr -d '"')
            printf '"%s":"%s",\n' "$key" "$val"
        done | sed '$ s/,$//'
        printf '}}\n'
    elif [ "$AUDIO_TOOLS_QUIET" != "yes" ]; then
        echo "Configuration file: $CONFIG_FILE"
        echo ""
        echo "Current settings:"
        grep "^export AUDIO_TOOLS" "$CONFIG_FILE" | sed 's/^export /  /'
    fi
}

cmd_config_get() {
    local key="$1"

    [ -n "$key" ] || { log_error "Key is required"; return "$EX_USAGE"; }

    init_output

    if [ ! -f "$CONFIG_FILE" ]; then
        log_error "Config file not found: $CONFIG_FILE"
        return "$EX_IOERR"
    fi

    local val=$(grep "^export AUDIO_TOOLS_${key^^}" "$CONFIG_FILE" 2>/dev/null | cut -d= -f2- | tr -d '"')

    if [ -z "$val" ]; then
        if [ "$AUDIO_TOOLS_JSON" = "yes" ]; then
            printf '{"key":"%s","value":null,"found":false}\n' "$key"
        else
            log_warn "Key not found: $key"
        fi
        return 0
    fi

    if [ "$AUDIO_TOOLS_JSON" = "yes" ]; then
        printf '{"key":"%s","value":"%s","found":true}\n' "$key" "$val"
    elif [ "$AUDIO_TOOLS_QUIET" != "yes" ]; then
        echo "$val"
    fi
}

cmd_config_set() {
    local key="$1"
    local value="$2"

    [ -n "$key" ] || { log_error "Key is required"; return "$EX_USAGE"; }
    [ -n "$value" ] || { log_error "Value is required"; return "$EX_USAGE"; }

    init_output

    # Create config directory if needed
    local config_dir=$(dirname "$CONFIG_FILE")
    mkdir -p "$config_dir" 2>/dev/null || true

    # Create config file if it doesn't exist
    if [ ! -f "$CONFIG_FILE" ]; then
        cat > "$CONFIG_FILE" << 'EOF'
# Audio Tools Configuration
# Set defaults for audio-tools behavior

EOF
    fi

    # Update or add the key
    local key_upper="${key^^}"
    local key_pattern="AUDIO_TOOLS_$key_upper"

    if grep -q "^export $key_pattern" "$CONFIG_FILE" 2>/dev/null; then
        # Update existing key
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' "s/^export $key_pattern=.*/export $key_pattern=\"$value\"/" "$CONFIG_FILE"
        else
            sed -i "s/^export $key_pattern=.*/export $key_pattern=\"$value\"/" "$CONFIG_FILE"
        fi
    else
        # Add new key
        echo "export $key_pattern=\"$value\"" >> "$CONFIG_FILE"
    fi

    if [ "$AUDIO_TOOLS_JSON" = "yes" ]; then
        printf '{"status":"success","key":"%s","value":"%s"}\n' "$key" "$value"
    elif [ "$AUDIO_TOOLS_QUIET" != "yes" ]; then
        output_success "Configuration updated: $key = $value"
    fi
}

cmd_config_reset() {
    init_output

    if [ ! -f "$CONFIG_FILE" ]; then
        if [ "$AUDIO_TOOLS_JSON" = "yes" ]; then
            printf '{"status":"success","message":"No config file to reset"}\n'
        elif [ "$AUDIO_TOOLS_QUIET" != "yes" ]; then
            log_info "No config file found"
        fi
        return 0
    fi

    # Confirmation
    if [ "$AUDIO_TOOLS_FORCE" != "yes" ] && [ "$AUDIO_TOOLS_QUIET" != "yes" ]; then
        read -p "Delete config file? (yes/no): " response
        [ "$response" = "yes" ] || { log_info "Cancelled"; return 0; }
    fi

    rm -f "$CONFIG_FILE"

    if [ "$AUDIO_TOOLS_JSON" = "yes" ]; then
        printf '{"status":"success","message":"Config file deleted"}\n'
    elif [ "$AUDIO_TOOLS_QUIET" != "yes" ]; then
        output_success "Configuration reset"
    fi
}

cmd_config_edit() {
    local editor="${EDITOR:-nano}"

    init_output

    # Create config directory if needed
    local config_dir=$(dirname "$CONFIG_FILE")
    mkdir -p "$config_dir" 2>/dev/null || true

    # Create config file if it doesn't exist
    if [ ! -f "$CONFIG_FILE" ]; then
        cat > "$CONFIG_FILE" << 'EOF'
# Audio Tools Configuration
# Set defaults for audio-tools behavior
# Example:
#   export AUDIO_TOOLS_CONVERTED_DIR="mp3s"
#   export AUDIO_TOOLS_FORCE="yes"

EOF
    fi

    # Open in editor
    if [ "$AUDIO_TOOLS_QUIET" != "yes" ]; then
        log_info "Opening config file in $editor..."
    fi

    "$editor" "$CONFIG_FILE"

    if [ "$AUDIO_TOOLS_QUIET" != "yes" ]; then
        output_success "Config file saved"
    fi
}

export -f cmd_config cmd_config_list cmd_config_get cmd_config_set cmd_config_reset cmd_config_edit
