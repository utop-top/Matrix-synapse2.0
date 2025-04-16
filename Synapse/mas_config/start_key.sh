#!/bin/bash

# 脚本名称：generate_secrets.sh
# 功能：在当前目录生成 secrets.yaml 和 home.yaml，client_id 为 ULID，导入 matrix.secret 和 clients 字段

# 检查是否安装了 openssl
if ! command -v openssl &> /dev/null; then
    echo "Error: openssl is not installed. Please install it first."
    exit 1
fi

# 生成随机 kid（10 字符）
generate_kid() {
    openssl rand -hex 5 | head -c 10
}

# 生成随机 secret（32 字符 Base64）
generate_secret() {
    openssl rand -base64 24 | head -c 32
}

# 生成 ULID（26 字符，Crockford Base32 编码）
generate_ulid() {
    base32_chars="0123456789ABCDEFGHJKMNPQRSTVWXYZ"
    timestamp=$(date +%s%3N)
    ts_part=""
    num=$timestamp
    for ((i=0; i<10; i++)); do
        remainder=$((num % 32))
        ts_part="${base32_chars:$remainder:1}$ts_part"
        num=$((num / 32))
    done
    ts_part=$(printf "%10s" "$ts_part" | tr ' ' '0')
    random_part=""
    for ((i=0; i<16; i++)); do
        rand=$((RANDOM % 32))
        random_part="$random_part${base32_chars:$rand:1}"
    done
    echo "$ts_part$random_part"
}

# 创建 secrets.yaml 和 home.yaml 文件
secrets_file="secrets.yaml"
home_file="home.yaml"
echo "Generating $secrets_file and $home_file in $(pwd)..."

# 生成 256 位 encryption 密钥（64 字符十六进制）
encryption_key=$(openssl rand -hex 32)

# 写入 secrets.yaml
cat > "$secrets_file" << EOF
secrets:
  encryption: "$encryption_key"
  keys:
EOF

# 生成 RSA 密钥
rsa_kid=$(generate_kid)
rsa_key=$(openssl genrsa 2048 2>/dev/null)
echo "    - kid: $rsa_kid" >> "$secrets_file"
echo "      key: |" >> "$secrets_file"
echo "$rsa_key" | sed 's/^/        /' >> "$secrets_file"

# 生成三个 EC 密钥（prime256v1 曲线）
for i in 1 2 3; do
    ec_kid=$(generate_kid)
    ec_key=$(openssl ecparam -name prime256v1 -genkey -noout 2>/dev/null)
    echo "    - kid: $ec_kid" >> "$secrets_file"
    echo "      key: |" >> "$secrets_file"
    echo "$ec_key" | sed 's/^/        /' >> "$secrets_file"
done

# 生成 matrix 和 clients 配置
matrix_secret=$(generate_secret)
client_id=$(generate_ulid)
client_secret=$(generate_secret)

cat >> "$secrets_file" << EOF

matrix:
  homeserver: example.com
  secret: '$matrix_secret'
  endpoint: https://example.com/

clients:
  - client_id: $client_id
    client_auth_method: client_secret_basic
    client_secret: '$client_secret'
EOF

# 写入 home.yaml
cat > "$home_file" << EOF
experimental_features:
  msc3266_enabled: true
  msc4222_enabled: true
  msc4108_enabled: true
  msc3861:
    enabled: true
    issuer: https://auth.example.com
    client_id: $client_id
    client_auth_method: client_secret_basic
    client_secret: '$client_secret'
    admin_token: '$matrix_secret'
    account_management_url: "https://auth.example.com/account"
EOF

# 设置文件权限
chmod 600 "$secrets_file" "$home_file"

echo "Done! Generated $secrets_file and $home_file."
echo "Copy the contents to your dev_config.yaml and homeserver configuration."