configfile: "config.yaml"

_use_denet_raw = config.get("use_denet", False)
use_denet = _use_denet_raw if isinstance(_use_denet_raw, bool) else str(_use_denet_raw).lower() in ("true", "1", "yes")

outdir = config.get("outdir", "results")
n_reads = config.get("n_reads", 1_000_000)
n_chromosomes = config.get("n_chromosomes", 3)
chr_length = config.get("chr_length", 1_000_000)
bench_repeats = config.get("benchmark_repeats", 5)


def wrap(cmd, step):
    if use_denet:
        out = f"{outdir}/denet_metrics/{step}.jsonl"
        return f"mkdir -p {outdir}/denet_metrics && denet --out {out} -i 100 -m 100 run -- {cmd}"
    return cmd


rule all:
    input:
        f"{outdir}/results/aligned.bam.bai",
        expand(
            "{outdir}/benchmarks/{step}.tsv",
            outdir=outdir,
            step=[
                "simulate_genome",
                "index_genome",
                "simulate_reads",
                "align",
                "sort_bam",
                "index_bam",
            ],
        ),


rule simulate_genome:
    output:
        fa=f"{outdir}/data/genome.fa",
    log:
        f"{outdir}/logs/simulate_genome.log",
    benchmark:
        repeat(f"{outdir}/benchmarks/simulate_genome.tsv", bench_repeats)
    conda:
        "envs/genome_tools.yaml"
    shell:
        wrap(
            f"python scripts/simulate_genome.py {{output.fa}} {n_chromosomes} {chr_length}",
            "simulate_genome",
        ) + " 2> {log}"


rule index_genome:
    input:
        fa=f"{outdir}/data/genome.fa",
    output:
        multiext(
            f"{outdir}/data/genome",
            ".1.bt2",
            ".2.bt2",
            ".3.bt2",
            ".4.bt2",
            ".rev.1.bt2",
            ".rev.2.bt2",
        ),
    log:
        f"{outdir}/logs/index_genome.log",
    benchmark:
        repeat(f"{outdir}/benchmarks/index_genome.tsv", bench_repeats)
    conda:
        "envs/genome_tools.yaml"
    shell:
        wrap(
            f"bowtie2-build {{input.fa}} {outdir}/data/genome",
            "index_genome",
        ) + " > {log} 2>&1"


rule simulate_reads:
    input:
        fa=f"{outdir}/data/genome.fa",
    output:
        r1=f"{outdir}/data/reads_1.fq.gz",
        r2=f"{outdir}/data/reads_2.fq.gz",
    log:
        f"{outdir}/logs/simulate_reads.log",
    benchmark:
        repeat(f"{outdir}/benchmarks/simulate_reads.tsv", bench_repeats)
    conda:
        "envs/genome_tools.yaml"
    shell:
        wrap(
            f"bash -c 'wgsim -N {n_reads} -1 150 -2 150 -e 0.01 -r 0.001 "
            f"{{input.fa}} {outdir}/data/reads_1.fq {outdir}/data/reads_2.fq "
            f"&& gzip -f {outdir}/data/reads_1.fq {outdir}/data/reads_2.fq'",
            "simulate_reads",
        ) + " > {log} 2>&1"


rule align:
    input:
        r1=f"{outdir}/data/reads_1.fq.gz",
        r2=f"{outdir}/data/reads_2.fq.gz",
        idx=multiext(
            f"{outdir}/data/genome",
            ".1.bt2",
            ".2.bt2",
            ".3.bt2",
            ".4.bt2",
            ".rev.1.bt2",
            ".rev.2.bt2",
        ),
    output:
        bam=f"{outdir}/results/aligned_unsorted.bam",
    log:
        f"{outdir}/logs/align.log",
    benchmark:
        repeat(f"{outdir}/benchmarks/align.tsv", bench_repeats)
    conda:
        "envs/genome_tools.yaml"
    threads: 4
    shell:
        wrap(
            f"bowtie2 -x {outdir}/data/genome "
            "-1 {input.r1} -2 {input.r2} -p {threads} "
            "| samtools view -bS -o {output.bam}",
            "align",
        ) + " 2> {log}"


rule sort_bam:
    input:
        bam=f"{outdir}/results/aligned_unsorted.bam",
    output:
        bam=f"{outdir}/results/aligned.bam",
    log:
        f"{outdir}/logs/sort_bam.log",
    benchmark:
        repeat(f"{outdir}/benchmarks/sort_bam.tsv", bench_repeats)
    conda:
        "envs/genome_tools.yaml"
    shell:
        wrap(
            "samtools sort -o {output.bam} {input.bam}",
            "sort_bam",
        ) + " 2> {log}"


rule index_bam:
    input:
        bam=f"{outdir}/results/aligned.bam",
    output:
        bai=f"{outdir}/results/aligned.bam.bai",
    log:
        f"{outdir}/logs/index_bam.log",
    benchmark:
        repeat(f"{outdir}/benchmarks/index_bam.tsv", bench_repeats)
    conda:
        "envs/genome_tools.yaml"
    shell:
        wrap(
            "samtools index {input.bam}",
            "index_bam",
        ) + " 2> {log}"
