# PhoenixDDoS changelog

## 1.1.22

- fix: jail and suspicious-ip entries never expired with Cachex 4 (`ttl:` ignored, now passes `expire:` too) — reported on GitHub
- fix: `Jail.suspicious_ip?/1` binary clause
- fix: rate-limit counters are keyed per window, no carry-over from an expired window (no false rejections right after a window ends)
- fix: the triggering counter is reset when an ip is jailed (no immediate re-jail on release)
- fix: templates declared as `@external_resource`
- fix: request path protections match the path as the Phoenix router sees it (empty segments, percent-encoding) — thanks @milanalexandre (#6)

## 1.1.19

- fix: phoenix router instropection too slow on big projects

## 1.1.18

- fix: phoenix router instropection fail on module Hex.API
## 1.1.17

- fix: more warning fixes
- fix: manager multi router routes on telemetry and sentry events

## 1.1.16

- fix: minor fixes

## 1.1.15

- feature: adding request context on sentry and telemetry events

## 1.1.14

- feature: small refactors on Jail module, documentation and accessors (list banned ip functions, ...)

## 1.1.13

- chore: remove router requirement, this was not a good idea !

## 1.1.12

- feature: new telemetry event [:phoenix_ddos, :request, :new]
- minor readme fixes

## 1.1.11

- chore: improve bulk cachex incr performance

## 1.1.10

- feature: http method filter on PhoenixDDoS.IpRateLimitPerRequestPath

## 1.1.9

- start to supply changelog file :)
- various sentry notification payload fixes
- improve performances & scaling on blocklist/whitelist ips

## 0.7

Project kickoff
