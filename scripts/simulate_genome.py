#!/usr/bin/env python3
import random
import sys


def simulate_genome(output_path, n_chromosomes, chr_length, seed=42):
    random.seed(seed)
    bases = "ACGT"
    line_width = 60
    with open(output_path, "w") as fh:
        for i in range(1, n_chromosomes + 1):
            fh.write(f">chr{i}\n")
            seq = "".join(random.choices(bases, k=chr_length))
            for j in range(0, len(seq), line_width):
                fh.write(seq[j : j + line_width] + "\n")


if __name__ == "__main__":
    output_path = sys.argv[1]
    n_chromosomes = int(sys.argv[2]) if len(sys.argv) > 2 else 5
    chr_length = int(sys.argv[3]) if len(sys.argv) > 3 else 5_000_000
    simulate_genome(output_path, n_chromosomes, chr_length)
