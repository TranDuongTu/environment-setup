# TCP / network debugging (macOS)

## Layers

- DNS → TCP → TLS → HTTP. Each inside the one below. Debug bottom-up.
- TCP handshake: SYN, SYN-ACK, ACK.

## DNS

```
dig +short github.com
dig +short localhost
```

## Check port reachable

```
nc -vz host 443
nc -vz -G 3 host 443
```

- `-G 3`: connect timeout, seconds (macOS).
- `Connection refused`: host replied RST; nothing listening. Instant.
- `Operation timed out`: no reply (drop, firewall, bad IP). Waits full timeout.

## Raw TCP server / client

```
nc -l 9000
nc -v localhost 9000
```

## Who listens / connections

```
lsof -nP -iTCP:9000
lsof -nP -iTCP:9000 -sTCP:LISTEN
lsof -nP -iTCP -sTCP:LISTEN
netstat -an -p tcp | grep 9000
```

- `-n`: no host lookup. `-P`: no port names.
- NAME: `local:port->remote:port (STATE)`. `*:9000 (LISTEN)` = all interfaces; `127.0.0.1:9000` = loopback only.
- A local connection shows twice (server side, client side).
- States: LISTEN, SYN_SENT (no answer), ESTABLISHED, TIME_WAIT, CLOSE_WAIT (app didn't close).
- "Address already in use": find PID with `-sTCP:LISTEN`, then `kill`.

## Packets

```
sudo tcpdump -i lo0 -n -S 'tcp port 9000'
sudo tcpdump -i en0 -n 'host 1.2.3.4 and tcp port 443'
```

- `lo0`: loopback. `en0`: usual Wi-Fi/Ethernet.
- Flags: `[S]` SYN, `[S.]` SYN-ACK, `[.]` ACK, `[P.]` data, `[F.]` FIN, `[R.]` RST.

## TLS / HTTP layer

```
openssl s_client -connect host:443 -servername host -brief </dev/null
curl -v https://host -o /dev/null
curl -sS -o /dev/null -w 'dns=%{time_namelookup} tcp=%{time_connect} tls=%{time_appconnect} total=%{time_total}\n' https://host
```

- Timing is cumulative: tcp includes dns, tls includes tcp.

## Error → layer

- `Could not resolve host`: DNS.
- `refused`: TCP, no listener.
- Timeout/hang: TCP, packets dropped.
- `unable to get local issuer certificate`, `hostname mismatch`: TLS cert validation.
- `wrong version number`: TLS to a plain port or plain to a TLS port.
- `certificate required`, `bad certificate`, `unknown ca`: TLS, mTLS client cert.
