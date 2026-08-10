#!/bin/sh
# Refresh the cf_v4/cf_v6 firewall ipsets from Cloudflare's published ranges.
# Run from cron; safe to run repeatedly. Entries live in /etc/config/firewall
# so they survive a reboot and a `fw4 reload`.
set -e

V4=$(uclient-fetch -qO- https://www.cloudflare.com/ips-v4)
V6=$(uclient-fetch -qO- https://www.cloudflare.com/ips-v6)

# A truncated or error-page response would silently shrink the allowlist and
# lock out legitimate traffic, so refuse anything that looks wrong. Cloudflare
# publishes ~15 v4 and ~7 v6 prefixes; well under that means the fetch failed.
count() { printf '%s\n' "$1" | grep -c '^[0-9a-fA-F:.]*/[0-9]*$' || true; }
[ "$(count "$V4")" -ge 10 ] || { echo "cf-allowlist: bad v4 list, keeping current" >&2; exit 1; }
[ "$(count "$V6")" -ge 5 ] || { echo "cf-allowlist: bad v6 list, keeping current" >&2; exit 1; }

set_ipset() {
  name=$1; family=$2; list=$3
  uci -q delete "firewall.$name" || true
  uci set "firewall.$name=ipset"
  uci set "firewall.$name.name=$name"
  uci set "firewall.$name.family=$family"
  uci set "firewall.$name.match=src_net"
  for prefix in $list; do
    uci add_list "firewall.$name.entry=$prefix"
  done
}

set_ipset cf_v4 ipv4 "$V4"
set_ipset cf_v6 ipv6 "$V6"

uci commit firewall
/etc/init.d/firewall reload >/dev/null 2>&1
echo "cf-allowlist: $(count "$V4") v4 + $(count "$V6") v6 prefixes applied"
