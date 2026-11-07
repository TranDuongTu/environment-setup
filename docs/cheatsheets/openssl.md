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
