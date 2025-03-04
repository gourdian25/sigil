#!/bin/bash
# Sigil - A powerful tool for generating:
# 1. Self-signed SSL certificates for gRPC
# 2. RSA keys for JWT token signing
#
# Written by: https://github.com/gourdian25
# Inspired by:
# - https://github.com/grpc/grpc-java/tree/master/examples#generating-self-signed-certificates-for-use-with-grpc
# - https://github.com/grpc/grpc-java/tree/master/examples/example-tls
# Enhanced with Gum CLI (https://github.com/charmbracelet/gum) for a delightful user experience.

set -e  # Exit on any error to ensure the script stops if something goes wrong

#################################################
# INTRODUCTION
#################################################
# Sigil is a versatile and user-friendly tool designed to simplify the generation of:
# - Self-signed SSL certificates for securing gRPC communications.
# - RSA keys for signing and verifying JWT tokens.
#
# This tool is perfect for developers who need to quickly set up secure communication
# channels or implement JWT-based authentication in their applications. With an intuitive
# interface powered by Gum CLI, Sigil makes certificate and key generation a breeze.

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
# WELCOME MESSAGE
#################################################
# Calculate the width of the terminal
TERMINAL_WIDTH=$(tput cols)
BOX_WIDTH=$((TERMINAL_WIDTH / 2))

# Welcome message with double border and centered text
WELCOME_MSG=$(gum style --margin "1" --border double --padding "1 2" --border-foreground 212 --width $BOX_WIDTH --align center "Welcome to $(gum style --foreground 212 'Sigil')")
DESCRIPTION_MSG=$(gum style --margin "1" --width $BOX_WIDTH --align center "Your go-to tool for generating SSL certificates and JWT RSA keys with ease.")

# Combine the welcome message and description
WELCOME_BOX=$(gum join --vertical "$WELCOME_MSG" "$DESCRIPTION_MSG")

# Display the welcome box
echo -e "\n$WELCOME_BOX\n"

#################################################
# USER INPUT: SELECT WHAT TO GENERATE
#################################################
# Ask the user what they want to generate (SSL certificates, JWT RSA keys, or both)
gum style --margin "1" --foreground 99 "Please select what you would like to generate:"
OPTIONS=$(gum choose --no-limit --header "What would you like to generate?" "SSL Certificates" "JWT RSA Keys")

#################################################
# USER INPUT: DIRECTORY SELECTION
#################################################
# Ask for directories based on the selected options
if grep -q "SSL Certificates" <<< "$OPTIONS"; then
    gum style --margin "1" --foreground 99 "Where do you want to store the generated SSL certificates?"
    gum style --margin "1" --foreground 7 --italic "This directory will contain the CA certificate, server certificate, and keys."
    SSL_DIR=$(gum input --placeholder "SSL directory (default: ssl)" --value "ssl")
    SSL_DIR=${SSL_DIR:-ssl}
    
    # Create the SSL directory if it doesn't exist
    gum spin --spinner dot --title "Creating SSL directory..." -- mkdir -p "${SSL_DIR}"
    
    # Ask for the server Common Name (CN) for SSL certificate generation
    gum style --margin "1" --foreground 99 "The server Common Name (CN) is used for SSL certificate generation."
    gum style --margin "1" --foreground 7 --italic "This should match your server's hostname or domain name."
    SERVER_CN=$(gum input --placeholder "Server Common Name (default: localhost)" --value "localhost")
    SERVER_CN=${SERVER_CN:-localhost}
fi

if grep -q "JWT RSA Keys" <<< "$OPTIONS"; then
    gum style --margin "1" --foreground 99 "Where do you want to store the JWT RSA keys?"
    gum style --margin "1" --foreground 7 --italic "This directory will contain the private and public keys for JWT token signing."
    JWT_DIR=$(gum input --placeholder "JWT keys directory (default: keys)" --value "keys")
    JWT_DIR=${JWT_DIR:-keys}
    
    # Create the JWT directory if it doesn't exist
    gum spin --spinner dot --title "Creating JWT directory..." -- mkdir -p "${JWT_DIR}"
fi

#################################################
# PART 1: GENERATE SSL CERTIFICATES
#################################################
if grep -q "SSL Certificates" <<< "$OPTIONS"; then
    gum style --margin "1" --border normal --padding "1 2" --border-foreground 99 "$(gum style --foreground 99 'SSL Certificate Generation')"

    # Interactive certificate configuration
    gum style --margin "1" --foreground 99 "Let's configure your SSL certificate details:"
    
    # Load default values from a config file if it exists
    CONFIG_FILE="${SSL_DIR}/cert_defaults.conf"
    if [ -f "$CONFIG_FILE" ]; then
        gum style --margin "1" --foreground 7 --italic "Loading default values from $CONFIG_FILE"
        source "$CONFIG_FILE"
    fi

    # Set defaults if not loaded from file
    COUNTRY=${COUNTRY:-IN}
    STATE=${STATE:-Karnataka}
    LOCALITY=${LOCALITY:-Bengaluru}
    ORGANIZATION=${ORGANIZATION:-manishh.sh}
    
    # Interactive inputs for certificate details
    gum style --margin "1" --foreground 212 "Certificate Details (press Enter to accept default values):"
    
    gum style --margin "1" --foreground 7 "Enter the two-letter country code (e.g., US, UK, IN):"
    COUNTRY=$(gum input --placeholder "Country code (default: $COUNTRY)" --value "$COUNTRY")
    COUNTRY=${COUNTRY:-IN}
    
    gum style --margin "1" --foreground 7 "Enter the state or province where your organization is located:"
    STATE=$(gum input --placeholder "State or Province (default: $STATE)" --value "$STATE")
    STATE=${STATE:-Karnataka}
    
    gum style --margin "1" --foreground 7 "Enter the city where your organization is located:"
    LOCALITY=$(gum input --placeholder "City or Locality (default: $LOCALITY)" --value "$LOCALITY")
    LOCALITY=${LOCALITY:-Bengaluru}
    
    gum style --margin "1" --foreground 7 "Enter your organization or company name:"
    ORGANIZATION=$(gum input --placeholder "Organization name (default: $ORGANIZATION)" --value "$ORGANIZATION")
    ORGANIZATION=${ORGANIZATION:-manishh.sh}
    
    # Additional DNS names for the certificate
    gum style --margin "1" --foreground 212 "Additional DNS names for the certificate:"
    gum style --margin "1" --foreground 7 "These are additional hostnames that this certificate will be valid for."
    gum style --margin "1" --foreground 7 "Your certificate will already be valid for '$SERVER_CN' and '127.0.0.1'."
    gum style --margin "1" --foreground 7 "Enter additional domain names separated by commas (e.g., example.com,api.example.com)"
    
    ADDITIONAL_DNS=$(gum input --placeholder "Additional DNS names (optional)")
    
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
    
    # Save current values as defaults for next time
    gum confirm "Save these certificate details as defaults for future use?" && {
        mkdir -p "$(dirname "$CONFIG_FILE")"
        cat > "$CONFIG_FILE" << EOF
COUNTRY="$COUNTRY"
STATE="$STATE"
LOCALITY="$LOCALITY"
ORGANIZATION="$ORGANIZATION"
EOF
        gum style --margin "1" --foreground 10 "✓ Default values saved to $CONFIG_FILE"
    }

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
    
    # Show SSL files information
    gum style --margin "1" --foreground 212 --italic "SSL files generated in '${SSL_DIR}' directory:"
    SSL_FILES=(
        "ca.key: Certificate Authority private key (keep secure)"
        "ca.crt: Certificate Authority trust certificate"
        "server.key: Server private key, password protected"
        "server.csr: Server certificate signing request"
        "server.crt: Server certificate signed by the CA"
        "server.pem: Server private key in PEM format for gRPC"
    )
    
    echo ""
    for FILE in "${SSL_FILES[@]}"; do
        gum style --margin "1" "  • ${FILE}"
    done
    echo ""
fi

#################################################
# PART 2: GENERATE RSA KEYS FOR JWT
#################################################
if grep -q "JWT RSA Keys" <<< "$OPTIONS"; then
    gum style --margin "1" --border normal --padding "1 2" --border-foreground 99 "$(gum style --foreground 99 'JWT RSA Key Generation')"

    # Define output file paths
    RSA_PRIVATE_KEY="${JWT_DIR}/rsa_private.pem"
    RSA_PUBLIC_KEY="${JWT_DIR}/rsa_public.pem"

    # Ask for key size with explanation
    gum style --margin "1" --foreground 99 "Select the RSA key size:"
    gum style --margin "1" --foreground 7 --italic "The key size determines the security level of your JWT tokens."
    gum style --margin "1" --foreground 7 --italic "Larger keys provide more security but may have performance impact."
    gum style --margin "1" --foreground 7 "2048 bits: Standard security, good performance"
    gum style --margin "1" --foreground 7 "3072 bits: Enhanced security, slightly lower performance"
    gum style --margin "1" --foreground 7 "4096 bits: Maximum security, may impact performance"
    
    KEY_SIZE=$(gum choose --header "Select RSA key size:" "2048" "3072" "4096")
    KEY_SIZE=${KEY_SIZE:-2048}

    # Generate RSA private key
    gum spin --spinner pulse --title "Generating RSA private key (${KEY_SIZE} bits)..." -- \
    openssl genpkey -algorithm RSA -out "${RSA_PRIVATE_KEY}" -pkeyopt rsa_keygen_bits:${KEY_SIZE}

    # Extract public key from the private key
    gum spin --spinner pulse --title "Extracting public key from private key..." -- \
    openssl rsa -in "${RSA_PRIVATE_KEY}" -pubout -out "${RSA_PUBLIC_KEY}"

    # Set appropriate permissions
    gum spin --spinner pulse --title "Setting appropriate file permissions..." -- bash -c "
    chmod 600 \"${RSA_PRIVATE_KEY}\"  # Restrictive permissions for private key
    chmod 644 \"${RSA_PUBLIC_KEY}\"   # Public key can be readable
    "

    gum style --margin "1" --foreground 10 "✓ JWT RSA key generation completed successfully"
    
    # Show JWT files information
    gum style --margin "1" --foreground 212 --italic "JWT RSA files generated in '${JWT_DIR}' directory:"
    gum style --margin "1" "  • Private Key: ${RSA_PRIVATE_KEY}"
    gum style --margin "1" "    (Keep this secure! Used to sign your JWT tokens)"
    gum style --margin "1" "  • Public Key: ${RSA_PUBLIC_KEY}"
    gum style --margin "1" "    (Share this with services that need to verify JWT tokens)"
    echo ""
fi

#################################################
# FINAL SUMMARY
#################################################
SUMMARY_TITLE=$(gum style --margin "1" --foreground 10 "All operations completed successfully!")

# Create SSL summary box if SSL was generated
if grep -q "SSL Certificates" <<< "$OPTIONS"; then
    SSL_SUMMARY=$(gum style --margin "1" --padding "1 2" --border normal --border-foreground 99 \
    "$(gum style --foreground 212 'SSL Certificates (HTTPs/gRPC)')
    
• Server Certificate: \"${SSL_DIR}/server.crt\"
• Server Private Key: \"${SSL_DIR}/server.pem\"")
fi

# Create JWT summary box if JWT was generated
if grep -q "JWT RSA Keys" <<< "$OPTIONS"; then
    JWT_SUMMARY=$(gum style --margin "1" --padding "1 2" --border normal --border-foreground 212 \
    "$(gum style --foreground 99 'JWT Token Signing')
    
• Private Key Path: \"${RSA_PRIVATE_KEY}\"
• Public Key Path: \"${RSA_PUBLIC_KEY}\"")
fi

# Join the summary boxes horizontally or vertically based on terminal width
if [[ $(tput cols) -gt 100 ]] && [[ -n "$SSL_SUMMARY" ]] && [[ -n "$JWT_SUMMARY" ]]; then
    echo -e "\n$SUMMARY_TITLE\n"
    gum join --horizontal "$SSL_SUMMARY" "$JWT_SUMMARY"
else
    echo -e "\n$SUMMARY_TITLE\n"
    [[ -n "$SSL_SUMMARY" ]] && echo -e "$SSL_SUMMARY\n"
    [[ -n "$JWT_SUMMARY" ]] && echo -e "$JWT_SUMMARY\n"
fi

# Final goodbye
NAME=$(whoami)
GOODBYE=$(gum style --margin "1" --border double --padding "1 2" --border-foreground 57 --width $BOX_WIDTH --align center \
    "Thanks for using $(gum style --foreground 212 'Sigil'), $(gum style --foreground 212 "$NAME")!")
echo -e "\n$GOODBYE"


