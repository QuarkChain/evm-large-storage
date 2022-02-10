# evm-large-storage

The repo offers a gas-efficient large-object key-value store using contract code as storage space.  It also provides CRUD semantics to get/put/remove the entries in the store.

# Gas Comparison

|       | 1k | 4k | 8k | 12k |
| ----------- | ----------- | --- | --- | --- |
| Local storage (get) | 96212 | 310514 | 596473 | 882688 |
| Local storage (put)   |  771051 | 2949132 | 5853295 | 8757522 |
| Code storage (get) | 30502 (1/3.15x) | 38987 (1/7.96x) | 50525 (1/11.8x)| 62319 (1 / 14.1x) |
| Code storage (put) | 387383 (1/ 2x) | 1128673 (1/2.61x) | 2117788 (1/2.76x)| 3104698 (1 / 2.82x)|

