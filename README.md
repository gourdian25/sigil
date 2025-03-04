# Sigil - Documentation

## Introduction

**Sigil** is a powerful and user-friendly command-line tool designed to simplify the generation of:
1. **Self-signed SSL certificates** for securing gRPC communications.
2. **RSA keys** for signing and verifying JWT tokens.

This tool is perfect for developers who need to quickly set up secure communication channels or implement JWT-based authentication in their applications. With an intuitive interface powered by [Gum CLI](https://github.com/charmbracelet/gum), Sigil makes certificate and key generation a breeze.

---

## Features

- **Self-signed SSL Certificates**:
  - Generate Certificate Authority (CA) certificates.
  - Create server certificates signed by the CA.
  - Automatically configure DNS names for the certificates.
  - Export certificates and keys in PEM format for gRPC.

- **RSA Keys for JWT**:
  - Generate RSA private and public keys for JWT token signing.
  - Choose key sizes (2048, 3072, or 4096 bits) for security and performance trade-offs.
  - Set appropriate file permissions for security.

- **Interactive Interface**:
  - Powered by Gum CLI for a delightful user experience.
  - Guided prompts for configuring certificates and keys.
  - Real-time feedback and progress indicators.

---

## Dependencies

Before using Sigil, ensure the following dependencies are installed:

1. **OpenSSL**:
   - Required for generating SSL certificates and RSA keys.
   - Install on Ubuntu/Debian:
     ```bash
     sudo apt install openssl
     ```
   - Install on macOS:
     ```bash
     brew install openssl
     ```

2. **Gum CLI**:
   - Required for the interactive interface.
   - Install using the following command:
     ```bash
     brew install gum
     ```
   - Alternatively, visit the [Gum CLI GitHub page](https://github.com/charmbracelet/gum) for installation instructions.

---

## Installation

You can install Sigil directly using a single command. However, the installation method depends on your shell:

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

This script will:
1. Download the latest version of Sigil.
2. Make it executable.
3. Place it in a directory included in your `$PATH` (e.g., `/usr/local/bin`).

---

## Usage

### Running Sigil

To start using Sigil, simply run the following command:

```bash
sigil
```

### Step-by-Step Guide

1. **Welcome Screen**:
   - Sigil will display a welcome message and ask what you'd like to generate (SSL certificates, RSA keys, or both).

2. **SSL Certificates**:
   - If you choose to generate SSL certificates:
     - Specify the directory to store the certificates (default: `ssl`).
     - Provide the server's Common Name (CN) (default: `localhost`).
     - Configure additional DNS names for the certificate (optional).
     - Sigil will generate:
       - A Certificate Authority (CA) key and certificate.
       - A server key and certificate signed by the CA.
       - A PEM file for gRPC.

3. **RSA Keys for JWT**:
   - If you choose to generate RSA keys:
     - Specify the directory to store the keys (default: `keys`).
     - Choose the key size (2048, 3072, or 4096 bits).
     - Sigil will generate:
       - A private key (`rsa_private.pem`).
       - A public key (`rsa_public.pem`).

4. **Final Summary**:
   - Sigil will display a summary of the generated files and their locations.

---

## Examples

### Generating SSL Certificates

```bash
sigil
```

1. Select **SSL Certificates**.
2. Choose the directory (default: `ssl`).
3. Enter the server's Common Name (default: `localhost`).
4. Add additional DNS names if needed.
5. Sigil will generate the certificates and keys in the specified directory.

### Generating RSA Keys for JWT

```bash
sigil
```

1. Select **JWT RSA Keys**.
2. Choose the directory (default: `keys`).
3. Select the key size (default: 2048 bits).
4. Sigil will generate the RSA keys in the specified directory.

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

### RSA Keys for JWT

If you generate RSA keys, the following files will be created in the specified directory (default: `keys`):

- `rsa_private.pem`: Private key for signing JWT tokens (keep secure).
- `rsa_public.pem`: Public key for verifying JWT tokens.

---

## References

- **Gum CLI**: [https://github.com/charmbracelet/gum](https://github.com/charmbracelet/gum)
- **OpenSSL Documentation**: [https://www.openssl.org/docs/](https://www.openssl.org/docs/)
- **gRPC SSL/TLS Setup**: [https://grpc.io/docs/guides/auth/](https://grpc.io/docs/guides/auth/)

---

## Contributing

Contributions to Sigil are welcome! If you'd like to contribute, please follow these steps:

1. Fork the repository: [https://github.com/gourdian25/sigil](https://github.com/gourdian25/sigil).
2. Create a new branch for your feature or bugfix.
3. Submit a pull request with a detailed description of your changes.

---

## License

Sigil is open-source and licensed under the **MIT License**. See the [LICENSE](https://github.com/gourdian25/sigil/blob/main/LICENSE) file for more details.

---

## Support

If you encounter any issues or have questions, please open an issue on the [GitHub repository](https://github.com/gourdian25/sigil/issues).

---

## Author

Sigil is developed and maintained by [gourdian25](https://github.com/gourdian25) and [lordofthemind](https://github.com/lordofthemind).

---

Thank you for using Sigil! 🚀

---