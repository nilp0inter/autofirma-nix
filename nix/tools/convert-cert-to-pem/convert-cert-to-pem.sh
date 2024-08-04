if [[ -z "$1" ]] || [[ -z "$2" ]]; then
    echo "Usage: $0 <cert-file> <out>"
    exit 1
fi

cert_file="$1"
out="$2"

# Check the certificate type and convert to PEM
if openssl x509 -in "$cert_file" -noout 2>&1; then
    # It's an X.509 certificate (DER or PEM)
    echo "Converting X.509 certificate: $cert_file"
    openssl x509 -in "$cert_file" -out "$out"
    exit 0
fi

if openssl pkcs7 -in "$cert_file" -noout 2>&1; then
    # It's a PKCS7 certificate
    echo "Converting PKCS7 certificate: $cert_file"
    openssl pkcs7 -print_certs -in "$cert_file" -out "$out"
    exit 0
fi

if openssl pkcs12 -in "$cert_file" -nodes -nocerts -out /dev/null 2>&1; then
    # It's a PKCS12 certificate
    echo "Converting PKCS12 certificate: $cert_file"
    openssl pkcs12 -in "$cert_file" -out "$out" -nodes -nokeys
    exit 0
fi

echo "Unsupported certificate type: $cert_file"
exit 1
