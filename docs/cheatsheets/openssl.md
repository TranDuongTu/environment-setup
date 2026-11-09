# OpenSSL

Binary: `/opt/homebrew/bin/openssl` (OpenSSL 3). System `/usr/bin/openssl` is LibreSSL.

## Version / binary

```
openssl version
which openssl
```

## Generate private key

```
openssl genpkey -algorithm ed25519 -out key.pem
openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:3072 -out rsa.pem
openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:P-256 -out ec.pem
```

## Derive public key

```
openssl pkey -in key.pem -pubout -out pub.pem
```

## Inspect key

```
openssl pkey -in key.pem -text -noout
openssl pkey -in pub.pem -pubin -text -noout
```

## Passphrase-protect key

```
openssl pkey -in key.pem -aes-256-cbc -out key.enc.pem
openssl genpkey -algorithm ed25519 -aes-256-cbc -out secure.pem
```

## Remove passphrase

```
openssl pkey -in key.enc.pem -out key.dec.pem
```

## Sign / verify: Ed25519 (`pkeyutl -rawin`)

```
openssl pkeyutl -sign -rawin -inkey key.pem -in msg.txt -out sig.bin
openssl pkeyutl -verify -rawin -pubin -inkey pub.pem -in msg.txt -sigfile sig.bin
```

- `-pubin` only on verify. On sign it errors: "A private key is needed for this operation".
- Verify can also use `-inkey key.pem` without `-pubin`.

## Sign / verify: RSA, EC (`dgst`)

```
openssl dgst -sha256 -sign rsa.pem -out rsa.sig msg.txt
openssl dgst -sha256 -verify rsa.pub -signature rsa.sig msg.txt
openssl dgst -sha256 -sign ec.pem -out ec.sig msg.txt
openssl dgst -sha256 -verify ec.pub -signature ec.sig msg.txt
```

- `dgst -sign` does not work with Ed25519.
- Success: `Verified OK`. Failure: `Verification failure`, non-zero exit.

```
echo $?
```

## Tamper test

```
echo "changed" > msg.txt
printf 'X' | dd of=sig.bin bs=1 seek=0 conv=notrunc
```

## Sizes (reference)

- Ed25519: key 32 B, sig 64 B
- P-256: sig ~70-72 B (DER)
- RSA-3072: sig 384 B

## Hash / HMAC / random

```
openssl dgst -sha256 file
openssl dgst -sha256 -r file
shasum -a 256 file
echo -n "text" | openssl dgst -sha256
openssl dgst -sha256 -r file > file.sha256
shasum -a 256 -c file.sha256
openssl dgst -sha256 -hmac "$(cat hmac.key)" file
openssl rand -hex 32
openssl rand -base64 32
openssl rand -out rand.bin 32
```


## CSR

```
openssl req -new -key server.key -subj "/CN=localhost" -out server.csr
openssl req -in server.csr -text -noout
openssl req -in server.csr -verify -noout
```

## Self-signed cert (with SAN)

```
openssl req -x509 -new -key server.key -subj "/CN=localhost" -days 30 \
  -addext "subjectAltName=DNS:localhost,IP:127.0.0.1" \
  -addext "basicConstraints=critical,CA:false" \
  -out self.crt
```

## Inspect cert

```
openssl x509 -in c.crt -text -noout
openssl x509 -in c.crt -noout -subject -issuer -dates -serial
openssl x509 -in c.crt -noout -fingerprint -sha256
openssl x509 -in c.crt -noout -ext subjectAltName,basicConstraints,keyUsage
openssl x509 -in c.crt -noout -pubkey
```

## Cert matches key?

```
diff <(openssl x509 -in c.crt -noout -pubkey) <(openssl pkey -in c.key -pubout)
```

## Create root CA

```
openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:P-256 -aes-256-cbc -out ca.key
openssl req -x509 -new -key ca.key -subj "/CN=Lab Root CA" -days 365 \
  -addext "basicConstraints=critical,CA:true" \
  -addext "keyUsage=critical,keyCertSign,cRLSign" \
  -out ca.crt
```

## Sign CSR with own CA

`server.ext`:

```
subjectAltName=DNS:localhost,IP:127.0.0.1
basicConstraints=critical,CA:false
keyUsage=critical,digitalSignature
extendedKeyUsage=serverAuth
```

```
openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial \
  -days 30 -extfile server.ext -out server.crt
```

- `x509 -req` does not copy CSR extensions; set them in `-extfile`.
- `ca.srl` tracks serial numbers.

## Verify cert chain

```
openssl verify -CAfile ca.crt server.crt
openssl verify -CAfile ca.crt -untrusted inter.crt leaf.crt
openssl verify -CAfile ca.crt -inform DER server.der
```

- Without `-CAfile`: fails (issuer not trusted).
- Same subject name, different key: fails (signature check).

## Create intermediate CA (signed by root)

`inter.ext`:

```
basicConstraints=critical,CA:true,pathlen:0
keyUsage=critical,keyCertSign,cRLSign
```

```
openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:P-256 -out inter.key
openssl req -new -key inter.key -subj "/CN=Lab Intermediate CA" -out inter.csr
openssl x509 -req -in inter.csr -CA root.crt -CAkey root.key -CAcreateserial \
  -days 1825 -extfile inter.ext -out inter.crt
openssl verify -CAfile root.crt inter.crt
```

- `pathlen:0`: can sign leaves, not further CAs.

## Sign leaf with intermediate

```
openssl x509 -req -in leaf.csr -CA inter.crt -CAkey inter.key -CAcreateserial \
  -days 90 -extfile leaf.ext -out leaf.crt
```

## Verify chain with intermediate

```
openssl verify -CAfile root.crt -untrusted inter.crt leaf.crt
openssl verify -show_chain -CAfile root.crt -untrusted inter.crt leaf.crt
```

- `-untrusted`: helper certs to build the chain, not trust anchors.
- `verify` checks each cert in the target file separately; extra certs in it are not used as helpers. `verify -CAfile root.crt fullchain.crt` fails with error 20.
- Fix: `openssl verify -CAfile root.crt -untrusted fullchain.crt leaf.crt`

## Chain file for servers

```
cat leaf.crt inter.crt > fullchain.crt
```

- Order: leaf, then intermediates. Never include root.
- TLS clients build the chain from certs the server sends, so fullchain works there.
