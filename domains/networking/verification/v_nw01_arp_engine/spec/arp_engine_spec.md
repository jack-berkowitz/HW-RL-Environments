# `arp_engine` — specification

An address-resolution engine. It answers lookups of the form "what MAC address
belongs to this IP address" from a small cache, and when the cache cannot
answer it asks the network, retries, and eventually gives up. It also answers
other stations' requests for its own address, and learns from every ARP frame
it sees.

Clauses marked **latitude** are choices the implementation is free to make;
your testbench must not require either answer.

---

## 0. Configuration — pinned

| quantity | value |
|---|---|
| request retry count | **4** |
| request retry interval | **64** cycles |
| request timeout | **256** cycles |
| cache capacity | **4** entries |
| `rst_i` | **synchronous**, **active high** |

`local_mac_i`, `local_ip_i`, `gateway_ip_i` and `subnet_mask_i` are inputs, not
constants; hold them steady while the engine is running.

## F. The ARP frame

An ARP frame is an Ethernet frame with `eth_type` **`0x0806`** whose payload is
**28 bytes**, sent most significant byte first:

| bytes | field | value on the wire |
|---|---|---|
| 0–1 | hardware type | `0x0001` |
| 2–3 | protocol type | `0x0800` |
| 4 | hardware length | `6` |
| 5 | protocol length | `4` |
| 6–7 | **operation** | `1` request, `2` reply |
| 8–13 | sender MAC (SHA) | |
| 14–17 | sender IP (SPA) | |
| 18–23 | target MAC (THA) | |
| 24–27 | target IP (TPA) | |

The header (`*_dest_mac`, `*_src_mac`, `*_eth_type`) is presented on its own
handshake, ahead of the payload stream.

## Q. Lookups

- **Q1.** A lookup whose address is already in the cache is answered from the
  cache: `resp_valid_o` with `resp_error_o` low and `resp_mac_o` the cached MAC,
  and **no frame is transmitted**.
- **Q2.** A lookup whose address is not in the cache causes an ARP **request**
  frame to be transmitted, broadcast to `ff:ff:ff:ff:ff:ff`, carrying
  `SHA = local_mac_i`, `SPA = local_ip_i` and `THA = 0`.
- **Q3.** The address asked for is the looked-up address itself when it is
  **inside the local subnet** — that is, when
  `(ip & subnet_mask_i) == (local_ip_i & subnet_mask_i)` — and
  `gateway_ip_i` otherwise.
- **Q4.** If no answer arrives, **exactly 4** request frames are transmitted in
  total, and consecutive requests are between **64 and 80 cycles** apart. The
  count is exact; the spacing is a window, because a handshake takes a cycle or
  two that this contract does not fix.
- **Q5.** If no answer arrives, the lookup is answered with `resp_valid_o` and
  `resp_error_o` **high**, between **256 and 300 cycles** after the fourth
  request — and not before.
- **Q6.** An ARP **reply** whose `SPA` is the address being asked for resolves
  the outstanding lookup: `resp_valid_o` with `resp_error_o` low and
  `resp_mac_o` equal to that reply's `SHA`. No further request is transmitted.

## A. Answering other stations

- **A1.** A received ARP **request** whose `TPA` equals `local_ip_i` is answered
  with an ARP **reply** carrying `operation = 2`, `SHA = local_mac_i`,
  `SPA = local_ip_i`, `THA` the requester's `SHA` and `TPA` the requester's
  `SPA`, sent to `dest_mac` equal to the requester's `SHA`.
- **A2.** A received ARP request whose `TPA` is **not** `local_ip_i` is not
  answered.
- **A3.** A received frame whose `eth_type` is not `0x0806` is ignored
  entirely: it is neither answered nor learned from.

## C. The cache

- **C1.** Every received ARP frame — request or reply — inserts the pair
  (`SPA`, `SHA`) into the cache. A lookup of that address afterwards is
  answered from the cache under Q1.
- **C2.** The cache holds **4** entries. An insert never fails; when the cache
  is full it displaces an existing entry.
- **C3.** `clear_cache_i` empties the cache. Every address is unknown
  afterwards, so the next lookup of any address goes to the network under Q2.

## X. Reset and liveness

- **X1.** `rst_i` is **synchronous** and **active high**. While it is high no
  output valid is asserted.
- **X2.** After reset the cache is empty and no lookup is outstanding.
- **X3 (liveness bound).** The engine makes forward progress in both
  directions, with the response channel held ready:
  - a lookup offered on `req_valid_i` is accepted within **32** cycles, and one
    that hits the cache is answered within **32** cycles of acceptance; and
  - a received frame's header, and each byte of its payload, is accepted within
    **32** cycles of being offered.

---

## L. Latitude — named, and deliberately unconstrained

- **L1.** **Which entry a full cache displaces.** Entries are placed by a
  function of the address that this contract does not fix, so which older
  entries survive an insert is unspecified. Do not require any particular one
  to still be there — only the one just inserted (C1) and the effect of C3.
- **L2.** `resp_mac_o` when `resp_error_o` is high. There is no address to
  report, so nothing is required of it.
- **L3.** The exact cycle on which a response or a frame appears, subject to
  the counts and intervals Q4, Q5 and X3 fix.

These three are the whole of the latitude in this contract.

---

## What this contract does not say

It says nothing about frames whose payload is shorter or longer than 28 bytes,
nor about `s_payload_user_i`, nor about what happens if a second lookup is
offered while one is outstanding. It places no requirement on the transmitted
payload beyond the fields F names.
