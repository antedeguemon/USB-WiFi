# Benchmarks

Benchmarking a wireless network adapter is hard - there are many variables
involved that dictate how an adapter will perform.

Even more, there are different use-cases (such as protocols supported, 
adapter range, network speed, etc.) that make it impossible to pin point a
single metric for a benchmark.

With that in mind, this little (draft) document has been created with the intent
of benchmarking different metrics to provide more information about
Linux-compatible.

Below are the metrics I plan on using for running adapters benchmarks, with
rules that ensure the quality of the benchmark.

## 1. RX Range

This is an _aggregation_ metric (is that the correct term?) based on how many
probes and other 802.11 packets sent by APs are received by the adapter.

Obviously, this metric depends on how many APs are near and their traffic - so,
benchmarks for this metric are only good when compared to each other and should
be run at the exact same time.

- Time-and-place dependency:
  - Benchmarks should be run at the same time
  - Benchmarks should be run at the same place
- The same channel hopping sequence and interval should used
- Antennas (if any) should be pointing on the same direction

## 2. TX/RX Range

How far an adapter can be from an AP and still be able to communicate with it?

- The AP should be the same for all benchmarked adapters
- A BPF should be used to prevent the Kernel from considering transmissions made
by other APs - which should prevent buffer bursting & other software
interferences
