#!/usr/bin/env python

bit_strings = []

def gen_all_bit_strings(n, arr, i):
    if i == n:
        bit_strings.append(arr.copy())
        return
    arr[i] = 0
    gen_all_bit_strings(n, arr, i + 1)
    arr[i] = 1
    gen_all_bit_strings(n, arr, i + 1)

n = 6
arr = [None] * n
gen_all_bit_strings(n, arr, 0)

bit_str = []

for a in bit_strings:
    bit_str.append(''.join(str(e) for e in a))

in_str = "c"
out_str = "d"

print("unique case({})".format(in_str))
for x in range(n+1):
    last_s = None
    for s in range(len(bit_strings)):
        if sum(bit_strings[s]) == x:
            print("{}'b{}".format(n, bit_str[s]), end=", ")
            last_s = s
    print("\b\b : begin {} <= {}'b{}; end".format(out_str, n, ''.join(sorted(bit_str[last_s]))))
print("endcase")
