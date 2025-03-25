# Sigil - Documentation

## Introduction

**Sigil** is a powerful and user-friendly command-line tool designed to simplify the generation of:

1. **Self-signed SSL certificates** for securing gRPC communications
2. **Asymmetric keys** for signing and verifying JWT tokens:
   - RSA keys
   - RSA-PSS keys
   - EdDSA (Ed25519) keys
   - ECDSA keys (P-256, P-384, P-521 curves)

This tool is perfect for developers who need to quickly set up secure communication channels or implement JWT-based authentication in their applications. With an intuitive interface powered by [Gum CLI](https://github.com/charmbracelet/gum), Sigil makes certificate and key generation a breeze.

---

## Features

- **Self-signed SSL Certificates**:
  - Generate Certificate Authority (CA) certificates
  - Create server certificates signed by the CA
  - Automatically configure DNS names for the certificates
  - Export certificates and keys in PEM format for gRPC

- **JWT Key Generation**:
  - **RSA Keys**:
    - Generate RSA private and public keys for JWT token signing
    - Choose key sizes (2048, 3072, or 4096 bits) for security and performance trade-offs
  - **RSA-PSS Keys**:
    - Generate RSA-PSS keys (probabilistic signature scheme variant of RSA)
  - **EdDSA (Ed25519) Keys**:
    - Generate modern Ed25519 keys for JWT signing
    - Smaller keys with better performance than RSA
    - Similar security to 3000+ bit RSA keys
  - **ECDSA Keys**:
    - Generate ECDSA keys using prime256v1 (P-256), secp384r1 (P-384), or secp521r1 (P-521) curves
    - Support for ES256, ES384, and ES512 algorithms
  - Set appropriate file permissions for security

- **Interactive Interface**:
  - Powered by Gum CLI for a delightful user experience
  - Guided prompts for configuring certificates and keys
  - Real-time feedback and progress indicators
  - Option to generate multiple key types simultaneously

- **Configuration Management**:
  - Save default settings for future use
  - Load configurations from file
  - Support for both interactive and non-interactive modes

- **Cross-Platform Support**:
  - Works on Linux, macOS, and other Unix-like systems
  - Automatically detects and installs dependencies
  - Checks for OpenSSL version compatibility with modern algorithms

---

## Dependencies

Before using Sigil, ensure the following dependencies are installed:

1. **OpenSSL** (version 1.1.1 or later for Ed25519 and modern ECDSA support):
   - Required for generating SSL certificates and keys
   - Install on Ubuntu/Debian:

     ```bash
     sudo apt install openssl
     ```

   - Install on CentOS/RHEL:

     ```bash
     sudo yum install openssl
     ```

   - Install on macOS:

     ```bash
     brew install openssl
     ```

2. **Gum CLI**:
   - Required for the interactive interface
   - Install using the following command:

     ```bash
     brew install gum
     ```

   - Alternatively, visit the [Gum CLI GitHub page](https://github.com/charmbracelet/gum) for installation instructions

---

## Installation

You can install Sigil directly using a single command. The installation script will:

1. Download the latest version of Sigil
2. Install dependencies (if not already installed)
3. Make Sigil executable and place it in a directory included in your `$PATH` (e.g., `/usr/local/bin`)

### For Bash or Zsh

Run the following command in your terminal:

```bash
curl -fsSL https://raw.githubusercontent.com/gourdian25/sigil/master/install.sh | sh
```

### For Fish Shell

Fish shell requires explicit use of `bash` to interpret the script. Run:

```fish
curl -fsSL https://raw.githubusercontent.com/gourdian25/sigil/master/install.sh | bash
```

### Manual Installation

If the above methods don't work, you can manually download and install Sigil:

1. Download the script:

   ```bash
   curl -fsSL https://raw.githubusercontent.com/gourdian25/sigil/master/install.sh -o install.sh
   ```

2. Make it executable:

   ```bash
   chmod +x install.sh
   ```

3. Run the script:

   ```bash
   ./install.sh
   ```

---

## Usage

### Basic Usage

```bash
sigil [options]
```

### Options

| Option | Description |
|--------|-------------|
| `-i`   | Run in interactive mode |
| `-c FILE` | Use specific config file |
| `-h`   | Show help message |

### Step-by-Step Guide

1. **Welcome Screen**:
   - Sigil will display a welcome message and ask what you'd like to generate (SSL certificates, JWT keys, or both)

2. **SSL Certificates**:
   - If you choose to generate SSL certificates:
     - Specify the directory to store the certificates (default: `ssl`)
     - Provide the server's Common Name (CN) (default: `localhost`)
     - Configure additional DNS names for the certificate (optional)
     - Sigil will generate:
       - A Certificate Authority (CA) key and certificate
       - A server key and certificate signed by the CA
       - A PEM file for gRPC

3. **JWT Keys**:
   - If you choose to generate JWT keys:
     - Select key type(s): RSA, EdDSA (Ed25519), or both
     - For RSA keys:
       - Choose the key size (2048, 3072, or 4096 bits)
     - Specify the directory to store the keys (default: `keys`)
     - Sigil will generate:
       - For RSA: `rsa_private.pem` and `rsa_public.pem`
       - For EdDSA: `ed25519_private.pem` and `ed25519_public.pem`

4. **Final Summary**:
   - Sigil will display a summary of the generated files and their locations

---

## Examples

### Generating SSL Certificates

```bash
sigil
```

1. Select **SSL Certificates**
2. Choose the directory (default: `ssl`)
3. Enter the server's Common Name (default: `localhost`)
4. Add additional DNS names if needed
5. Sigil will generate the certificates and keys in the specified directory

### Generating JWT Keys

```bash
sigil
```

1. Select **JWT Keys**
2. Choose key type(s): RSA, EdDSA, or both
3. For RSA, select the key size (default: 2048 bits)
4. Choose the directory (default: `keys`)
5. Sigil will generate the selected keys in the specified directory

---

## Advanced Usage

### Interactive Mode

You can run Sigil in interactive mode by specifying options directly. For example:

```bash
sigil -i
```

This will ask users for values for all prompts.

## Configuration

### Default Configuration File

Sigil can save your preferences in `~/.config/sigil/sigil.defaults.conf`

### Configuration Options

```ini
SSL_DIR="ssl"                  # Directory for SSL files
SERVER_CN="localhost"          # Server Common Name
COUNTRY="US"                   # 2-letter country code
STATE="California"             # State or province
LOCALITY="San Francisco"       # City
ORGANIZATION="My Company Inc." # Organization name
JWT_DIR="keys"                 # Directory for JWT keys
KEY_SIZE="2048"                # RSA key size (2048, 3072, 4096)
KEY_TYPE="RSA"                 # Key types (RSA, RSA-PSS, EdDSA, ECDSA)
ADDITIONAL_DNS=""              # Additional DNS names for SSL certs
ECDSA_CURVE="prime256v1"       # ECDSA curve (prime256v1, secp384r1, secp521r1)
```

### Custom Configuration File

You can specify a custom configuration file using the `-c` option:

```bash
sigil -c /path/to/config.conf
```

The configuration file should contain key-value pairs for all required settings. For example:

```ini
SSL_DIR="ssl"
SERVER_CN="localhost"
COUNTRY="US"
STATE="California"
LOCALITY="San Francisco"
ORGANIZATION="My Company Inc."
JWT_DIR="keys"
KEY_SIZE="2048"
KEY_TYPE="RSA"  # or "EdDSA" or "RSA,EdDSA"
ADDITIONAL_DNS="example.com,api.example.com"
```

---

## File Structure

### SSL Certificates (default: `ssl/`)

| File | Description |
|------|-------------|
| `ca.key` | CA private key (keep secure) |
| `ca.crt` | CA certificate |
| `server.key` | Server private key |
| `server.csr` | Certificate signing request |
| `server.crt` | Server certificate |
| `server.pem` | Server key in PEM format |

### JWT Keys (default: `keys/`)

| Key Type | Private Key | Public Key |
|----------|-------------|------------|
| RSA | `rsa_private.pem` | `rsa_public.pem` |
| RSA-PSS | `rsa_pss_private.pem` | `rsa_pss_public.pem` |
| EdDSA | `ed25519_private.pem` | `ed25519_public.pem` |
| ECDSA | `ec{256,384,521}_private.pem` | `ec{256,384,521}_public.pem` |

---

## Key Type Comparison

| Feature          | RSA       | RSA-PSS   | EdDSA (Ed25519) | ECDSA (P-256) |
|------------------|-----------|-----------|-----------------|---------------|
| Key Size         | 2048-4096 | 2048-4096 | 256 bits        | 256 bits      |
| Performance      | Moderate  | Moderate  | Fastest         | Fast          |
| Security         | Good      | Better    | Excellent       | Excellent     |
| Compatibility    | Excellent | Good      | Modern systems  | Widely supported |
| JWT Algorithms   | RS256, RS384, RS512 | PS256, PS384, PS512 | EdDSA | ES256, ES384, ES512 |

---

## Best Practices

1. **Key Security**:
   - Always keep private keys secure (600 permissions)
   - Never commit private keys to version control
   - Consider using a secrets management system for production

2. **Certificate Lifespan**:
   - Default certificates are valid for 10 years (3650 days)
   - For production, consider shorter validity periods (90-365 days)

3. **Key Rotation**:
   - Regularly rotate your JWT signing keys
   - Have a key rotation strategy in place

---

## Troubleshooting

### Common Issues

1. **OpenSSL version too old**:
   - Error: "Your OpenSSL version doesn't support Ed25519"
   - Solution: Upgrade OpenSSL to version 1.1.1 or later

2. **Permission denied**:
   - Error: When trying to write to directories
   - Solution: Ensure you have write permissions or run with `sudo`

3. **Gum CLI not found**:
   - Error: "Gum CLI is not installed"
   - Solution: Install Gum CLI or use non-interactive mode with config file

---

## References

- **Gum CLI**: [https://github.com/charmbracelet/gum](https://github.com/charmbracelet/gum)
- **OpenSSL Documentation**: [https://www.openssl.org/docs/](https://www.openssl.org/docs/)
- **gRPC SSL/TLS Setup**: [https://grpc.io/docs/guides/auth/](https://grpc.io/docs/guides/auth/)
- **EdDSA vs RSA**: [https://blog.mozilla.org/security/2017/11/02/eddsa-in-firefox/](https://blog.mozilla.org/security/2017/11/02/eddsa-in-firefox/)

---

## Contributing

Contributions to Sigil are welcome! If you'd like to contribute, please follow these steps:

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

---

## License

Sigil is open-source and licensed under the **MIT License**. See the [LICENSE](https://github.com/gourdian25/sigil/blob/master/LICENSE) file for more details.

---

## Support

If you encounter any issues or have questions, please open an issue on the [GitHub repository](https://github.com/gourdian25/sigil/issues).

---

## Authors

Sigil is developed and maintained by:

- [gourdian25](https://github.com/gourdian25)
- [lordofthemind](https://github.com/lordofthemind)

---

Thank you for using Sigil! 🚀.
