# OpenResty Service

This service runs OpenResty with automatic SSL certificate management via lua-resty-auto-ssl, request ID tracking, and pgmoon for PostgreSQL connectivity.

## Features

- OpenResty (based on Alpine)
- Automatic SSL certificate management with lua-resty-auto-ssl
- Global UUIDv7-based request ID system
- pgmoon for PostgreSQL connectivity
- HTTP to HTTPS redirection
- Automatic SSL certificates for all domains
- Modern HTTP/2 support
- Modular configuration system

## Directory Structure

```
@openresty/
├── config/                 # Configuration files
│   └── nginx/             
│       ├── nginx.conf     # Main configuration file
│       └── conf.d/        # Modular configurations
│           ├── init.conf           # Module initialization
│           ├── ssl.conf           # SSL/TLS settings
│           ├── realip.conf        # Real IP configuration
│           ├── auto_ssl.conf      # Auto-SSL settings
│           ├── request_id.conf    # Request ID handling
│           └── domain_includes/   # Domain-specific configs
│               ├── example.com.conf       # Example domain config
│               ├── subdomain.example.com.conf
│               └── another-domain.com.conf
├── src/                   # Application source code
│   └── lua/              # Custom Lua modules
│       ├── request_id.lua # Request ID generation
│       └── db-test.lua   # Database connectivity test
├── data/                  # Runtime data
│   └── auto-ssl/         # SSL certificates and challenges
├── docker-compose.yml    # Service orchestration
├── Dockerfile            # Container configuration
├── .env                  # Environment variables
├── .gitignore           # Git ignore rules
└── README.md            # This file
```

## Setup

1. Configure environment variables in `.env`:
   ```
   DB_HOST=your_postgres_host
   DB_PORT=your_postgres_port
   DB_USER=your_postgres_user
   DB_PASSWORD=your_postgres_password
   DB_NAME=your_postgres_db
   ```

2. Start the service:
   ```bash
   docker-compose up -d
   ```

The service will automatically:
- Request/renew SSL certificates for accessed domains using Let's Encrypt
- Configure OpenResty with SSL settings
- Add UUIDv7 request IDs to all requests
- Redirect HTTP to HTTPS
- Use Docker's internal DNS (127.0.0.11) for service discovery
- Connect to PostgreSQL using container DNS resolution

## Configuration Structure

The configuration is modularized for better maintainability:

1. **Main Configuration** (`nginx.conf`):
   - Basic settings and includes
   - Environment variables for database connection
   - Log formats
   - Module loading order

2. **Shared Configurations** (`conf.d/`):
   - `init.conf`: Module initialization and shared dictionaries
   - `ssl.conf`: SSL/TLS settings and fallback server
   - `realip.conf`: Real IP configuration for proxies
   - `auto_ssl.conf`: Auto-SSL challenge server
   - `request_id.conf`: Request ID handling
   - `logging.conf`: Logging format and Docker DNS resolver settings

3. **Domain Configurations** (`conf.d/domain_includes/`):
   - Separate `.conf` file for each domain
   - HTTP to HTTPS redirection
   - SSL certificate management
   - Domain-specific locations and settings

## Request ID System

The service implements a global request ID system:
- Every request receives a UUIDv7-based request ID
- IDs are added as `X-Request-ID` headers to responses
- Existing request IDs are preserved if provided
- IDs are logged in the access log for tracing
- UUIDv7 format ensures timestamp-based ordering

## SSL Certificates

The service uses lua-resty-auto-ssl for automatic SSL certificate management:
- Certificates are automatically obtained from Let's Encrypt when domains are accessed
- Certificates are automatically renewed before expiration
- A fallback self-signed certificate is used during the certificate issuance process
- Supports multiple domains (e.g., example.com, subdomain.example.com)

## Development

### Adding Custom Lua Modules
1. Place them in the `src/lua` directory
2. They will be automatically mounted at `/usr/local/openresty/lualib/custom/`
3. Add initialization code to `init.conf` if needed
4. Restart the service to apply changes

### Adding New Domains

To add a new domain:
1. Create a new config file in `conf.d/domain_includes/` (e.g., `your-domain.com.conf`)
2. Copy the structure from the example domain config
3. Update the `server_name` directive with your domain
4. Ensure DNS records point to your server
5. Restart the service to apply changes

## Port Forwarding Configuration (AT&T Router)

To make your OpenResty server accessible from the internet, you'll need to configure port forwarding on your AT&T router:

1. Access your router's admin interface at `192.168.1.254`

2. Navigate to:
   Firewall → NAT/Gaming

3. Set up Custom Services:
   - Click "Custom Services"
   - Create two services:
     ```
     HTTP Server:
     - Global Port Range: 80-80
     - Protocol: TCP
     - Host Port: 80

     HTTPS Server:
     - Global Port Range: 443-443
     - Protocol: TCP
     - Host Port: 443
     ```

4. Configure Port Forwarding:
   - Return to NAT/Gaming
   - Add both custom services (*HTTP Server and *HTTPS Server)
   - Set "Needed by Device" to your machine's device name
   - Note: Use the simple device name (e.g., "MacBookPro") rather than the full hostname

5. Verify Configuration:
   - Ensure your device shows as "on" in the network device list
   - Test locally using `localhost` or your local IP
   - Test externally using your public IP (find it at whatismyip.com)

### Troubleshooting
- If connection fails, check "Packet Filter" is disabled
- Ensure "Firewall Advanced" settings aren't blocking web traffic
- Verify your machine's firewall allows incoming connections on ports 80/443

### Security Notes
- SSL certificates are automatically managed and renewed by lua-resty-auto-ssl
- HTTP traffic is automatically redirected to HTTPS
- Strong SSL configuration with modern ciphers and protocols
- Keep your OpenResty and system software updated
- Configure your Mac's firewall appropriately
- Consider using Cloudflare or similar services for additional security

### Common Issues

1. Certificate Issues:
   - Check OpenResty logs for certificate-related errors
   - Ensure ports 80/443 are accessible for ACME challenges
   - Wait for Let's Encrypt rate limits to reset if exceeded

2. Connection Issues:
   - Verify ports 80/443 are forwarded correctly
   - Check OpenResty logs: `docker-compose logs openresty`
   - Ensure your public IP is accessible

3. DNS Issues:
   - Verify DNS records point to your public IP
   - Allow time for DNS propagation
   - Check DNS resolution: `dig your.domain.com`

4. Configuration Issues:
   - Check syntax: `docker-compose exec openresty nginx -t`
   - Verify file permissions in container
   - Check logs for initialization errors

That's all - your server will be accessible over HTTPS with automatic certificate management.