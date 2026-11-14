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

## TLS test server

```
openssl s_server -cert leaf.crt -cert_chain inter.crt -key leaf.key -port 4433 -www
```

- `-cert_chain`: intermediates to send. Never the root.
- Server ignores SNI/hostname; always sends the same cert.

## TLS client (s_client)

```
openssl s_client -connect localhost:4433 -CAfile root.crt -verify_return_error -brief </dev/null
openssl s_client -connect localhost:4433 -CAfile root.crt -showcerts </dev/null 2>&1 | grep -E '^ *[0-9] s:|i:|Verif'
openssl s_client -connect localhost:4433 -CAfile root.crt -tls1_3 -brief </dev/null
openssl s_client -connect github.com:443 -servername github.com -showcerts </dev/null
```

- Without `-CAfile`: error 20 (root not in default store).
- Without `-verify_return_error`: errors are printed but the connection continues.

## Hostname check

```
openssl s_client -connect 127.0.0.1:4433 -CAfile root.crt -verify_hostname localhost -brief </dev/null
openssl s_client -connect localhost:4433 -CAfile root.crt -verify_ip 127.0.0.1 -brief </dev/null
```

- Client-side only: expected name vs leaf SAN. Mismatch → error 62.
- `s_client` checks only if `-verify_hostname` / `-verify_ip` given. curl, browsers always check.
- Chain valid ≠ right site; hostname check binds cert to intended name.
- SNI (`-servername`) = hint to the server for choosing a cert; not verification.

## curl with private CA

```
curl --cacert root.crt https://localhost:4433/
curl -v --cacert root.crt https://localhost:4433/
```

## Trust model

- Trust is client-side: client trusts root → accepts any leaf under it.
- Server must send leaf + intermediates.
- Trust stores are separate: macOS Keychain, openssl cert.pem, Java cacerts, Firefox, certifi, Node.
- Constrain internal roots with nameConstraints.

## Client cert (mTLS)

`client.ext`:

```
basicConstraints=critical,CA:false
keyUsage=critical,digitalSignature
extendedKeyUsage=clientAuth
```

```
openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:P-256 -out client.key
openssl req -new -key client.key -subj "/CN=alice" -out client.csr
openssl x509 -req -in client.csr -CA inter.crt -CAkey inter.key -CAcreateserial \
  -days 30 -extfile client.ext -out client.crt
openssl verify -CAfile root.crt -untrusted inter.crt -purpose sslclient client.crt
```

- EKU: `clientAuth` for clients, `serverAuth` for servers.

## mTLS server

```
openssl s_server -cert leaf.crt -cert_chain inter.crt -key leaf.key -port 4433 \
  -CAfile root.crt -Verify 1 -verify_return_error -www
```

- `-Verify 1`: require client cert (depth 1). `-verify`: only request.
- `-CAfile`: trust anchor for client certs.
- Server log shows client chain (`depth=`) and subject.

## mTLS client

```
openssl s_client -connect localhost:4433 -CAfile root.crt \
  -cert client.crt -key client.key -cert_chain inter.crt -brief </dev/null
printf 'GET / HTTP/1.0\r\n\r\n' | openssl s_client -connect localhost:4433 -CAfile root.crt \
  -cert client.crt -key client.key -cert_chain inter.crt -quiet
```

- `-cert_chain`: send intermediates; the server has only the root.
- TLS 1.3: `-brief </dev/null` shows CONNECTION ESTABLISHED even when the server rejects. The rejection arrives after, on the first read. Send a request (second form) or check the server log.
- System curl (SecureTransport/LibreSSL 3.3.6) failed against this mTLS server (`alert decode error`). Use `s_client`, or `brew install curl` (untested).

## mTLS failure signatures

- No client cert: `tlsv13 alert certificate required` (alert 116); server: `peer did not return a certificate`.
- Cert from unknown CA (self-signed, same CN): `alert unknown ca` (48); server: `self-signed certificate`.
- Server leaf used as client cert: `alert unsupported certificate` (43); server: `unsuitable certificate purpose` (EKU).
