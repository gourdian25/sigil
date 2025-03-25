#!/bin/bash
# Sigil - A powerful tool for generating:
# 1. Self-signed SSL certificates for gRPC
# 2. RSA keys for JWT token signing
# 3. EdDSA (Ed25519) keys for JWT token signing
#
# Written by: https://github.com/gourdian25
# Inspired by:
# - https://github.com/grpc/grpc-java/tree/master/examples#generating-self-signed-certificates-for-use-with-grpc
# - https://github.com/grpc/grpc-java/tree/master/examples/example-tls
# Enhanced with Gum CLI (https://github.com/charmbracelet/gum) for a delightful user experience.

# Exit on any error to ensure the script stops if something goes wrong
set -e

#################################################
# INTERACTIVE MODE AND DEFAULTS
#################################################
INTERACTIVE=false
DEFAULT_CONFIG_FILE="$HOME/.config/sigil/sigil.defaults.conf"
CONFIG_FILE=""

# Display help text
show_help() {
  echo "Usage: $0 [options]"
  echo "Options:"
  echo "  -i                  Run in interactive mode"
  echo "  -c CONFIG_FILE      Use specific config file"
  echo "  -h                  Show this help"
  exit 0
}

# Parse command-line arguments
while getopts "ic:h" opt; do
  case $opt in
    i) INTERACTIVE=true ;;
    c) CONFIG_FILE="$OPTARG" ;;
    h) show_help ;;
    *) echo "Usage: $0 [-i] [-c CONFIG_FILE] [-h]"; exit 1 ;;
  esac
done

# Internal defaults - properly quoted to avoid issues
declare -A INTERNAL_DEFAULTS
INTERNAL_DEFAULTS=(
  ["SSL_DIR"]="ssl"
  ["SERVER_CN"]="localhost"
  ["COUNTRY"]="IN"
  ["STATE"]="Karnataka"
  ["LOCALITY"]="Bengaluru"
  ["ORGANIZATION"]="My Company Inc."
  ["JWT_DIR"]="keys"
  ["KEY_SIZE"]="2048"
  ["KEY_TYPE"]="RSA"  # Added default key type
  ["ADDITIONAL_DNS"]=""
)

# Function to create default config file from internal defaults
create_default_config() {
  local config_path="$1"
  
  # Create directory if it doesn't exist
  mkdir -p "$(dirname "$config_path")"
  
  echo "# Sigil default configuration" > "$config_path"
  echo "# Generated on: $(date)" >> "$config_path"
  echo "" >> "$config_path"
  
  # Write each default key-value pair to the config file
  for key in "${!INTERNAL_DEFAULTS[@]}"; do
    echo "$key=\"${INTERNAL_DEFAULTS[$key]}\"" >> "$config_path"
  done
  
  chmod 644 "$config_path"
  if $INTERACTIVE; then
    gum style --margin "1" --foreground 10 "✓ Default configuration file created at $config_path"
  fi
}

# Verify config file has all required variables
verify_config() {
  local config_file="$1"
  local missing=false
  
  # Check if each required key exists in the config file
  for key in "${!INTERNAL_DEFAULTS[@]}"; do
    if ! grep -q "^$key=" "$config_file" && ! grep -q "^$key=\"" "$config_file"; then
      if $INTERACTIVE; then
        gum style --margin "1" --foreground 9 "✗ Missing configuration: $key"
      fi
      missing=true
    fi
  done
  
  # Handle missing configurations
  if $missing; then
    if $INTERACTIVE; then
      gum style --margin "1" --foreground 9 "Configuration file is incomplete. Would you like to:"
      local action=$(gum choose "Add missing values from internal defaults" "Use internal defaults for everything" "Abort")
      
      case "$action" in
        "Add missing values from internal defaults")
          for key in "${!INTERNAL_DEFAULTS[@]}"; do
            if ! grep -q "^$key=" "$config_file" && ! grep -q "^$key=\"" "$config_file"; then
              echo "$key=\"${INTERNAL_DEFAULTS[$key]}\"" >> "$config_file"
              gum style --margin "1" --foreground 10 "✓ Added $key=\"${INTERNAL_DEFAULTS[$key]}\" to config"
            fi
          done
          ;;
        "Use internal defaults for everything")
          return 0
          ;;
        *)
          gum style --margin "1" --foreground 9 "Aborting..."
          exit 1
          ;;
      esac
    else
      # In non-interactive mode, use internal defaults if config is incomplete
      return 0
    fi
  fi
  
  return 0
}

# Load defaults from a config file
load_config_file() {
  local config_file="$1"
  if [ -f "$config_file" ]; then
    verify_config "$config_file"
    if $INTERACTIVE; then
      gum style --margin "1" --foreground 7 --italic "Loading configuration from $config_file"
    fi
    source "$config_file"
    return 0
  fi
  return 1
}

# Load defaults from available sources
load_defaults() {
  # If specific config file is provided, try to use it
  if [ -n "$CONFIG_FILE" ]; then
    if [ -f "$CONFIG_FILE" ]; then
      load_config_file "$CONFIG_FILE"
    else
      if $INTERACTIVE; then
        gum style --margin "1" --foreground 9 "Specified config file does not exist: $CONFIG_FILE"
        gum style --margin "1" --foreground 7 "Would you like to create it with internal defaults?"
        if gum confirm; then
          create_default_config "$CONFIG_FILE"
          load_config_file "$CONFIG_FILE"
        else
          gum style --margin "1" --foreground 7 --italic "Using internal defaults instead."
          set_internal_defaults
        fi
      else
        # In non-interactive mode, use internal defaults if config file doesn't exist
        set_internal_defaults
      fi
    fi
  # Otherwise try default config file
  elif [ -f "$DEFAULT_CONFIG_FILE" ]; then
    load_config_file "$DEFAULT_CONFIG_FILE"
  # If no config files exist, use internal defaults and offer to create default config
  else
    # This message should show after the welcome banner
    if $INTERACTIVE; then
      CONFIG_STATUS="No configuration file found. Using internal defaults."
    fi
    set_internal_defaults
  fi
}

# Set variables from internal defaults
set_internal_defaults() {
  for key in "${!INTERNAL_DEFAULTS[@]}"; do
    declare -g "$key"="${INTERNAL_DEFAULTS[$key]}"
  done
}

# Prompt user for input or use defaults
prompt_or_default() {
  local prompt="$1"
  local var_name="$2"
  local default_value="${!var_name}"
  if $INTERACTIVE; then
    gum style --margin "1" --foreground 212 "$prompt (default: $default_value):"
    read -r -p "> " input
    # Use default if input is empty
    if [ -z "$input" ]; then
      eval "$var_name=\$default_value"
    else
      eval "$var_name=\$input"
    fi
  else
    # In non-interactive mode, just use the default silently
    eval "$var_name=\$default_value"
  fi
}

# Show info text only in interactive mode
show_info() {
  local info_text="$1"
  if $INTERACTIVE; then
    gum style --margin "1" --foreground 7 --italic "$info_text"
  fi
}

# Load defaults at the start
load_defaults

#################################################
# DEPENDENCY CHECKS
#################################################
# Check if OpenSSL is installed (required for certificate and key generation)
if ! command -v openssl &> /dev/null; then
  echo "Error: OpenSSL is not installed. Please install it first."
  echo "On Ubuntu/Debian: sudo apt install openssl"
  echo "On macOS: brew install openssl"
  exit 1
fi

# Check if Gum CLI is installed (required for the interactive interface)
if ! command -v gum &> /dev/null; then
  echo "Error: Gum CLI is not installed. Please install it first."
  echo "Visit: https://github.com/charmbracelet/gum"
  exit 1
fi

#################################################
# TERMINAL WIDTH SETUP
#################################################
# Calculate the width of the terminal (slightly reduced to prevent wrapping)
TERMINAL_WIDTH=$(( $(tput cols) - 4 ))

#################################################
# WELCOME MESSAGE
#################################################
# Welcome message with thick border and full-width layout
WELCOME_MSG=$(gum style --margin "1" --border thick --padding "1 2" --border-foreground 212 --width $TERMINAL_WIDTH --align center "Welcome to $(gum style --foreground 212 'Sigil')
Your go-to tool for generating SSL certificates and JWT (RSA/EdDSA) keys with ease.")

# Display the welcome message
echo -e "\n$WELCOME_MSG\n"

# Show configuration status if it exists
if [ -n "$CONFIG_STATUS" ]; then
  gum style --margin "1" --foreground 7 --italic "$CONFIG_STATUS"
fi

#################################################
# USER INPUT: SELECT WHAT TO GENERATE
#################################################
gum style --margin "1" --foreground 99 "Please select what you would like to generate:"
OPTIONS=$(gum choose --no-limit --header "What would you like to generate?" "SSL Certificates" "JWT Keys")

#################################################
# USER INPUT: DIRECTORY SELECTION
#################################################
if grep -q "SSL Certificates" <<< "$OPTIONS"; then
  prompt_or_default "Where do you want to store the generated SSL certificates?" SSL_DIR
  show_info "This directory will contain the CA certificate, server certificate, and keys."
  
  # Create the SSL directory if it doesn't exist
  gum spin --spinner dot --title "Creating SSL directory..." -- mkdir -p "${SSL_DIR}"
  
  # Ask for the server Common Name (CN) for SSL certificate generation
  prompt_or_default "The server Common Name (CN) is used for SSL certificate generation." SERVER_CN
  show_info "This should match your server's hostname or domain name."
fi

if grep -q "JWT Keys" <<< "$OPTIONS"; then
  prompt_or_default "Where do you want to store the JWT keys?" JWT_DIR
  show_info "This directory will contain the private and public keys for JWT token signing."
  
  # Create the JWT directory if it doesn't exist
  gum spin --spinner dot --title "Creating JWT directory..." -- mkdir -p "${JWT_DIR}"

  # Ask for key type (RSA or EdDSA)
  if $INTERACTIVE; then
    gum style --margin "1" --foreground 99 "Select the type of JWT keys to generate:"
    gum style --margin "1" --foreground 7 --italic "RSA: Traditional algorithm, widely supported, larger keys"
    gum style --margin "1" --foreground 7 --italic "EdDSA (Ed25519): Modern algorithm, smaller keys, better performance"
    KEY_TYPE=$(gum choose --header "Key type" "RSA" "EdDSA")
  else
    # Use default in non-interactive mode
    KEY_TYPE="${INTERNAL_DEFAULTS[KEY_TYPE]}"
  fi
fi

#################################################
# USER INPUT: KEY CONFIGURATION
#################################################
if grep -q "JWT Keys" <<< "$OPTIONS" && [ "$KEY_TYPE" = "RSA" ]; then
  # Ask for key size with explanation - Only show the explanation in interactive mode
  if $INTERACTIVE; then
    gum style --margin "1" --foreground 99 "Select the RSA key size:"
    gum style --margin "1" --foreground 7 --italic "The key size determines the security level of your JWT tokens."
    gum style --margin "1" --foreground 7 --italic "Larger keys provide more security but may have performance impact."
    gum style --margin "1" --foreground 7 "2048 bits: Standard security, good performance"
    gum style --margin "1" --foreground 7 "3072 bits: Enhanced security, slightly lower performance"
    gum style --margin "1" --foreground 7 "4096 bits: Maximum security, may impact performance"
  fi
  
  prompt_or_default "Select RSA key size:" KEY_SIZE
fi

#################################################
# PART 1: GENERATE SSL CERTIFICATES
#################################################
if grep -q "SSL Certificates" <<< "$OPTIONS"; then
  gum style --margin "1" --border thick --padding "1 2" --border-foreground 99 --width $TERMINAL_WIDTH --align center "$(gum style --foreground 99 'SSL Certificate Generation')"
  
  if $INTERACTIVE; then
    gum style --margin "1" --foreground 99 "Let's configure your SSL certificate details:"
  fi
  
  # Prompt for certificate details
  prompt_or_default "Enter the two-letter country code (e.g., US, UK, IN):" COUNTRY
  prompt_or_default "Enter the state or province where your organization is located:" STATE
  prompt_or_default "Enter the city where your organization is located:" LOCALITY
  prompt_or_default "Enter your organization or company name:" ORGANIZATION
  
  # Additional DNS names for the certificate - only prompt in interactive mode
  if $INTERACTIVE; then
    gum style --margin "1" --foreground 212 "Additional DNS names for the certificate:"
    gum style --margin "1" --foreground 7 --italic "These are additional hostnames that this certificate will be valid for."
    gum style --margin "1" --foreground 7 --italic "Your certificate will already be valid for '$SERVER_CN' and '127.0.0.1'."
    gum style --margin "1" --foreground 7 "Enter additional domain names separated by commas (e.g., example.com,api.example.com)"
    
    ADDITIONAL_DNS=$(gum input --placeholder "Additional DNS names (optional)")
  fi
  
  # Create DNS entries for the config
  DNS_ENTRIES="DNS.1 = ${SERVER_CN}"$'\n'"DNS.2 = 127.0.0.1"
  DNS_COUNT=3
  
  if [ -n "$ADDITIONAL_DNS" ]; then
    IFS=',' read -ra DNS_ARRAY <<< "$ADDITIONAL_DNS"
    for DNS in "${DNS_ARRAY[@]}"; do
      DNS_ENTRIES+=$'\n'"DNS.$DNS_COUNT = $(echo "$DNS" | xargs)"  # xargs trims whitespace
      DNS_COUNT=$((DNS_COUNT+1))
    done
  fi
  
  # Create a configuration file for the extensions
  gum spin --spinner dot --title "Creating server certificate configuration..." -- bash -c "cat > \"${SSL_DIR}/server_cert_ext.cnf\" << EOF
[req]
distinguished_name = req_distinguished_name
req_extensions = req_ext
x509_extensions = v3_req
[req_distinguished_name]
countryName = $COUNTRY
countryName_default = $COUNTRY
stateOrProvinceName = $STATE
stateOrProvinceName_default = $STATE
localityName = $LOCALITY
localityName_default = $LOCALITY
organizationName = $ORGANIZATION
organizationName_default = $ORGANIZATION
commonName = ${SERVER_CN}
commonName_default = ${SERVER_CN}

[req_ext]
subjectAltName = @alt_names
[v3_req]
subjectAltName = @alt_names

[alt_names]
$DNS_ENTRIES
EOF"

  # Step 1: Generate Certificate Authority + Trust Certificate (ca.crt)
  gum spin --spinner line --title "Generating Certificate Authority key and certificate..." -- bash -c "
  openssl genrsa -passout pass:1111 -des3 -out \"${SSL_DIR}/ca.key\" 4096
  openssl req -passin pass:1111 -new -x509 -days 3650 -key \"${SSL_DIR}/ca.key\" -out \"${SSL_DIR}/ca.crt\" -subj \"/C=$COUNTRY/ST=$STATE/L=$LOCALITY/O=$ORGANIZATION/CN=${SERVER_CN}\"
  "

  # Step 2: Generate the Server Private Key (server.key)
  gum spin --spinner line --title "Generating server private key..." -- \
  openssl genrsa -passout pass:1111 -des3 -out "${SSL_DIR}/server.key" 4096

  # Step 3: Get a certificate signing request from the CA (server.csr)
  gum spin --spinner line --title "Creating certificate signing request..." -- \
  openssl req -passin pass:1111 -new -key "${SSL_DIR}/server.key" -out "${SSL_DIR}/server.csr" -subj "/C=$COUNTRY/ST=$STATE/L=$LOCALITY/O=$ORGANIZATION/CN=${SERVER_CN}" -config "${SSL_DIR}/server_cert_ext.cnf"

  # Step 4: Sign the certificate with the CA we created (it's called self-signing) - server.crt
  gum spin --spinner line --title "Signing the certificate with our CA..." -- \
  openssl x509 -req -passin pass:1111 -days 3650 -in "${SSL_DIR}/server.csr" -CA "${SSL_DIR}/ca.crt" -CAkey "${SSL_DIR}/ca.key" -set_serial 01 -out "${SSL_DIR}/server.crt" -extensions v3_req -extfile "${SSL_DIR}/server_cert_ext.cnf"

  # Step 5: Convert the server certificate to .pem format (server.pem) - usable by gRPC
  gum spin --spinner line --title "Converting server certificate to PEM format for gRPC..." -- \
  openssl pkcs8 -topk8 -nocrypt -passin pass:1111 -in "${SSL_DIR}/server.key" -out "${SSL_DIR}/server.pem"

  gum style --margin "1" --foreground 10 "✓ SSL certificate generation completed successfully"
  
  # Show SSL files information in a full-width box
  SSL_INFO=$(
    gum style --italic "SSL files generated in '${SSL_DIR}' directory:"
    for FILE in "ca.key: Certificate Authority private key (keep secure)" \
                "ca.crt: Certificate Authority trust certificate" \
                "server.key: Server private key, password protected" \
                "server.csr: Server certificate signing request" \
                "server.crt: Server certificate signed by the CA" \
                "server.pem: Server private key in PEM format for gRPC"; do
      gum style "  • ${FILE}"
    done
  )
  gum style --margin "1" --border thick --padding "1 2" --border-foreground 212 --width $TERMINAL_WIDTH --foreground 212 "$SSL_INFO"
fi

#################################################
# PART 2: GENERATE JWT KEYS
#################################################
if grep -q "JWT Keys" <<< "$OPTIONS"; then
  gum style --margin "1" --border thick --padding "1 2" --border-foreground 99 --width $TERMINAL_WIDTH --align center "$(gum style --foreground 99 'JWT Key Generation')"

  if [ "$KEY_TYPE" = "RSA" ]; then
    # RSA Key Generation
    gum style --margin "1" --foreground 99 "Generating RSA keys for JWT signing..."
    
    # Define output file paths
    PRIVATE_KEY="${JWT_DIR}/rsa_private.pem"
    PUBLIC_KEY="${JWT_DIR}/rsa_public.pem"

    # Generate RSA private key
    gum spin --spinner pulse --title "Generating RSA private key (${KEY_SIZE} bits)..." -- \
    openssl genpkey -algorithm RSA -out "${PRIVATE_KEY}" -pkeyopt rsa_keygen_bits:${KEY_SIZE}

    # Extract public key from the private key
    gum spin --spinner pulse --title "Extracting public key from private key..." -- \
    openssl rsa -in "${PRIVATE_KEY}" -pubout -out "${PUBLIC_KEY}"

    # Set appropriate permissions
    gum spin --spinner pulse --title "Setting appropriate file permissions..." -- bash -c "
    chmod 600 \"${PRIVATE_KEY}\"  # Restrictive permissions for private key
    chmod 644 \"${PUBLIC_KEY}\"   # Public key can be readable
    "

    gum style --margin "1" --foreground 10 "✓ RSA key generation completed successfully"
    
    # Show JWT files information in a full-width box
    JWT_INFO=$(
      gum style --italic "JWT RSA files generated in '${JWT_DIR}' directory:"
      gum style "  • Private Key: ${PRIVATE_KEY}"
      gum style "    (Keep this secure! Used to sign your JWT tokens)"
      gum style "  • Public Key: ${PUBLIC_KEY}"
      gum style "    (Share this with services that need to verify JWT tokens)"
    )
    
  elif [ "$KEY_TYPE" = "EdDSA" ]; then
    # EdDSA Key Generation
    gum style --margin "1" --foreground 99 "Generating EdDSA (Ed25519) keys for JWT signing..."
    
    # Define output file paths
    PRIVATE_KEY="${JWT_DIR}/ed25519_private.pem"
    PUBLIC_KEY="${JWT_DIR}/ed25519_public.pem"

    # Check if OpenSSL version supports Ed25519
    OPENSSL_VERSION=$(openssl version | awk '{print $2}')
    if [[ "$OPENSSL_VERSION" < "1.1.1" ]]; then
      gum style --margin "1" --foreground 9 "Error: Your OpenSSL version ($OPENSSL_VERSION) doesn't support Ed25519."
      gum style --margin "1" --foreground 9 "Please upgrade to OpenSSL 1.1.1 or later."
      exit 1
    fi

    # Generate Ed25519 private key
    gum spin --spinner pulse --title "Generating Ed25519 private key..." -- \
    openssl genpkey -algorithm ED25519 -out "${PRIVATE_KEY}"

    # Extract public key from the private key
    gum spin --spinner pulse --title "Extracting public key from private key..." -- \
    openssl pkey -in "${PRIVATE_KEY}" -pubout -out "${PUBLIC_KEY}"

    # Set appropriate permissions
    gum spin --spinner pulse --title "Setting appropriate file permissions..." -- bash -c "
    chmod 600 \"${PRIVATE_KEY}\"  # Restrictive permissions for private key
    chmod 644 \"${PUBLIC_KEY}\"   # Public key can be readable
    "

    gum style --margin "1" --foreground 10 "✓ EdDSA key generation completed successfully"
    
    # Show JWT files information in a full-width box
    JWT_INFO=$(
      gum style --italic "JWT EdDSA files generated in '${JWT_DIR}' directory:"
      gum style "  • Private Key: ${PRIVATE_KEY}"
      gum style "    (Keep this secure! Used to sign your JWT tokens)"
      gum style "  • Public Key: ${PUBLIC_KEY}"
      gum style "    (Share this with services that need to verify JWT tokens)"
      gum style ""
      gum style "Note: Ed25519 keys are much smaller than RSA keys while providing"
      gum style "similar security to RSA keys of 3000+ bits."
    )
  fi

  gum style --margin "1" --border thick --padding "1 2" --border-foreground 212 --width $TERMINAL_WIDTH --foreground 212 "$JWT_INFO"
fi

#################################################
# SAVE DEFAULTS FOR FUTURE USE
#################################################
if $INTERACTIVE && [ ! -f "$DEFAULT_CONFIG_FILE" ]; then
  gum style --margin "1" --foreground 7 "Would you like to save the current settings as default configuration for future use?"
  if gum confirm; then
    save_path="$DEFAULT_CONFIG_FILE"
    
    # Create the config directory if it doesn't exist
    mkdir -p "$(dirname "$save_path")"
    
    # Create or update the config file
    cat > "$save_path" << EOF
# Sigil configuration
# Generated on: $(date)

SSL_DIR="$SSL_DIR"
SERVER_CN="$SERVER_CN"
COUNTRY="$COUNTRY"
STATE="$STATE"
LOCALITY="$LOCALITY"
ORGANIZATION="$ORGANIZATION"
JWT_DIR="$JWT_DIR"
KEY_SIZE="$KEY_SIZE"
KEY_TYPE="$KEY_TYPE"
ADDITIONAL_DNS="$ADDITIONAL_DNS"
EOF
    
    gum style --margin "1" --foreground 10 "✓ Default configuration saved to $save_path"
  fi
fi

#################################################
# FINAL SUMMARY
#################################################
# Create a temporary file for the summary content
TEMP_SUMMARY_FILE=$(mktemp)

# Add title to the temporary file
echo "$(gum style --foreground 10 --align center "All operations completed successfully!")" > "$TEMP_SUMMARY_FILE"
echo "" >> "$TEMP_SUMMARY_FILE"  # Add blank line

# Add SSL summary if SSL was generated
if grep -q "SSL Certificates" <<< "$OPTIONS"; then
  echo "$(gum style --foreground 212 --align center "SSL Certificates (HTTPs/gRPC)")" >> "$TEMP_SUMMARY_FILE"
  echo "" >> "$TEMP_SUMMARY_FILE"
  echo "$(gum style "• Server Certificate: \"${SSL_DIR}/server.crt\"")" >> "$TEMP_SUMMARY_FILE"
  echo "$(gum style "• Server Private Key: \"${SSL_DIR}/server.pem\"")" >> "$TEMP_SUMMARY_FILE"
fi

# Add separator if both were generated
if grep -q "SSL Certificates" <<< "$OPTIONS" && grep -q "JWT Keys" <<< "$OPTIONS"; then
  echo "" >> "$TEMP_SUMMARY_FILE"
  echo "" >> "$TEMP_SUMMARY_FILE"
fi

# Add JWT summary if JWT was generated
if grep -q "JWT Keys" <<< "$OPTIONS"; then
  if [ "$KEY_TYPE" = "RSA" ]; then
    echo "$(gum style --foreground 99 --align center "JWT RSA Keys")" >> "$TEMP_SUMMARY_FILE"
    echo "" >> "$TEMP_SUMMARY_FILE"
    echo "$(gum style "• Private Key Path: \"${JWT_DIR}/rsa_private.pem\"")" >> "$TEMP_SUMMARY_FILE"
    echo "$(gum style "• Public Key Path: \"${JWT_DIR}/rsa_public.pem\"")" >> "$TEMP_SUMMARY_FILE"
  elif [ "$KEY_TYPE" = "EdDSA" ]; then
    echo "$(gum style --foreground 99 --align center "JWT EdDSA Keys")" >> "$TEMP_SUMMARY_FILE"
    echo "" >> "$TEMP_SUMMARY_FILE"
    echo "$(gum style "• Private Key Path: \"${JWT_DIR}/ed25519_private.pem\"")" >> "$TEMP_SUMMARY_FILE"
    echo "$(gum style "• Public Key Path: \"${JWT_DIR}/ed25519_public.pem\"")" >> "$TEMP_SUMMARY_FILE"
  fi
fi

# Display the final summary in a full-width box with thick border using the content from the temp file
gum style --margin "1" --border thick --padding "1 2" --border-foreground 57 --width $TERMINAL_WIDTH "$(cat "$TEMP_SUMMARY_FILE")"

# Clean up the temporary file
rm "$TEMP_SUMMARY_FILE"

# Final goodbye
NAME=$(whoami)
GOODBYE=$(gum style --margin "1" --border thick --padding "1 2" --border-foreground 57 --width $TERMINAL_WIDTH --align center \
    "Thanks for using $(gum style --foreground 212 'Sigil'), $(gum style --foreground 212 "$NAME")!")
echo -e "\n$GOODBYE"