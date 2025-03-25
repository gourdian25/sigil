# Sigil - Documentation

## Introduction

**Sigil** is a powerful and user-friendly command-line tool designed to simplify the generation of:

1. **Self-signed SSL certificates** for securing gRPC communications
2. **RSA keys** for signing and verifying JWT tokens
3. **EdDSA (Ed25519) keys** for modern JWT token signing

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
  - **EdDSA (Ed25519) Keys**:
    - Generate modern Ed25519 keys for JWT signing
    - Smaller keys with better performance than RSA
    - Similar security to 3000+ bit RSA keys
  - Set appropriate file permissions for security

- **Interactive Interface**:
  - Powered by Gum CLI for a delightful user experience
  - Guided prompts for configuring certificates and keys
  - Real-time feedback and progress indicators
  - Option to generate both RSA and EdDSA keys simultaneously

- **Cross-Platform Support**:
  - Works on Linux, macOS, and other Unix-like systems
  - Automatically detects and installs dependencies
  - Checks for OpenSSL version compatibility with Ed25519

---

## Dependencies

Before using Sigil, ensure the following dependencies are installed:

1. **OpenSSL** (version 1.1.1 or later for Ed25519 support):
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

### Running Sigil

To start using Sigil, simply run the following command:

```bash
sigil
```

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

## File Structure

### SSL Certificates

If you generate SSL certificates, the following files will be created in the specified directory (default: `ssl`):

- `ca.key`: Certificate Authority private key (keep secure).
- `ca.crt`: Certificate Authority trust certificate.
- `server.key`: Server private key (password protected).
- `server.csr`: Server certificate signing request.
- `server.crt`: Server certificate signed by the CA.
- `server.pem`: Server private key in PEM format for gRPC.

### JWT Keys

If you generate JWT keys, the following files will be created in the specified directory (default: `keys`):

- **RSA Keys**:
  - `rsa_private.pem`: Private key for signing JWT tokens (keep secure)
  - `rsa_public.pem`: Public key for verifying JWT tokens

- **EdDSA Keys**:
  - `ed25519_private.pem`: Ed25519 private key for signing JWT tokens (keep secure)
  - `ed25519_public.pem`: Ed25519 public key for verifying JWT tokens

---

## Advanced Usage

### Interactive Mode

You can run Sigil in interactive mode by specifying options directly. For example:

```bash
sigil -i
```

This will ask users for values for all prompts.

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

### Non-Interactive Mode

For automated scripts, you can use Sigil non-interactively by providing all configuration in a file:

```bash
sigil -c /path/to/config.conf
```

---

## Key Type Comparison

| Feature          | RSA Keys                  | EdDSA (Ed25519) Keys       |
|------------------|--------------------------|---------------------------|
| Key Size         | 2048-4096 bits           | 256 bits                 |
| Performance      | Slower signing/verifying | Faster operations        |
| Security         | Good (2048-bit)          | Excellent (≈3000-bit RSA)|
| Compatibility    | Widely supported         | Modern systems only      |
| Recommended Use  | Legacy systems           | New development          |

---

## References

- **Gum CLI**: [https://github.com/charmbracelet/gum](https://github.com/charmbracelet/gum)
- **OpenSSL Documentation**: [https://www.openssl.org/docs/](https://www.openssl.org/docs/)
- **gRPC SSL/TLS Setup**: [https://grpc.io/docs/guides/auth/](https://grpc.io/docs/guides/auth/)
- **EdDSA vs RSA**: [https://blog.mozilla.org/security/2017/11/02/eddsa-in-firefox/](https://blog.mozilla.org/security/2017/11/02/eddsa-in-firefox/)

---

## Contributing

Contributions to Sigil are welcome! If you'd like to contribute, please follow these steps:

1. Fork the repository: [https://github.com/gourdian25/sigil](https://github.com/gourdian25/sigil)
2. Create a new branch for your feature or bugfix
3. Submit a pull request with a detailed description of your changes

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
