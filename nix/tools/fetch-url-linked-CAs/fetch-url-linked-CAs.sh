URLS=$(curl -s --output - "$1" \
	| htmlq a --base "$1" -B --attribute href \
	| grep -P '\.(ce?rt|pem)$')

for url in $URLS; do
	path=$(nix-prefetch-url --type sha256 --print-path "$url" | grep -P '^/')
	[[ "$(openssl x509 -in "$path" -noout -issuer -subject | cut -d= -f2- | uniq | wc -l)" != "1" ]] && continue
	hash=$(nix-hash --type sha256 --to-sri "$(nix-hash --type sha256 --flat "$path")")
	jq -n --arg url "$url" --arg hash "$hash" '{ url: $url, hash: $hash }'
done | jq -s
