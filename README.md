# nf-variant-calling

A small, reproducible **Nextflow DSL2** pipeline for germline short-variant calling from paired-end Illumina reads. Trims and QCs reads, aligns to a reference with **BWA-MEM2**, marks duplicates and sorts with **samtools**, calls SNVs and small indels with **bcftools mpileup/call**, then aggregates QC into a single **MultiQC** report.

```
FASTQ ─► FastQC ─┐
                 ├─► BWA-MEM2 ─► sort ─► markdup ─► index ─► bcftools mpileup/call ─► bcftools stats ─► MultiQC
       ─► fastp ─┘                                                                            ▲
                                                                                              │
                                                          reference FASTA ─► BWA index + faidx ┘
```

## Quickstart

The bundled test profile runs end-to-end against a tiny published genome (~30 KB) and matching FASTQs from [nf-core/test-datasets](https://github.com/nf-core/test-datasets), so a full run completes in a couple of minutes on a laptop.

```bash
# with Docker
nextflow run main.nf -profile test,docker

# with Singularity (HPC)
nextflow run main.nf -profile test,singularity

# with Conda
nextflow run main.nf -profile test,conda
```

Outputs land under `results/` (or whatever you pass via `--outdir`).

## Running on your own data

Provide a CSV samplesheet and a reference FASTA:

```bash
nextflow run main.nf \
    -profile docker \
    --samplesheet samples.csv \
    --fasta /path/to/reference.fasta \
    --outdir results
```

### Samplesheet schema

```csv
sample,fastq_1,fastq_2
NA12878,/data/NA12878_R1.fastq.gz,/data/NA12878_R2.fastq.gz
HG002,/data/HG002_R1.fastq.gz,/data/HG002_R2.fastq.gz
```

`fastq_2` is optional for single-end data.

### Parameters

| Parameter        | Default                     | Notes                                    |
|------------------|-----------------------------|------------------------------------------|
| `--samplesheet`  | _required_                  | CSV: `sample,fastq_1,fastq_2`            |
| `--fasta`        | _required_                  | Reference genome FASTA (indices built)   |
| `--outdir`       | `results`                   | Output directory                         |
| `--min_mapq`     | `20`                        | Minimum mapping quality for variant call |
| `--min_baseq`    | `20`                        | Minimum base quality for `bcftools mpileup` |
| `--ploidy`       | `2`                         | Diploid by default; use `1` for haploid/bacterial |
| `--skip_markdup` | `false`                     | Skip duplicate marking (amplicon panels) |
| `--max_cpus`     | `4`                         | Per-process cap                          |
| `--max_memory`   | `8.GB`                      | Per-process cap                          |
| `--max_time`     | `4.h`                       | Per-process cap                          |

## Output layout

```
results/
├── fastqc/{raw,trimmed}/<sample>_fastqc.{html,zip}
├── fastp/<sample>.{trim_1,trim_2}.fastq.gz + <sample>.fastp.json
├── bwa/<sample>.sorted.markdup.bam{,.bai}
├── samtools/<sample>.flagstat + <sample>.stats
├── bcftools/<sample>.vcf.gz{,.tbi} + <sample>.bcftools_stats.txt
└── multiqc/multiqc_report.html
```

## Repo map

```
nf-variant-calling/
├── main.nf
├── nextflow.config
├── workflows/variant_calling.nf
├── modules/
│   ├── fastqc.nf
│   ├── fastp.nf
│   ├── bwa_index.nf
│   ├── samtools_faidx.nf
│   ├── bwa_mem.nf
│   ├── samtools_sort.nf
│   ├── samtools_markdup.nf
│   ├── samtools_index_stats.nf
│   ├── bcftools_call.nf
│   ├── bcftools_stats.nf
│   └── multiqc.nf
├── conf/{base,test}.config
├── assets/samplesheet_test.csv
├── .github/workflows/ci.yml
├── README.md
├── LICENSE  (MIT)
└── .gitignore
```

## Software stack

| Tool        | Version  |
|-------------|----------|
| Nextflow    | `>=23.10` (DSL2) |
| BWA-MEM2    | 2.2.1    |
| samtools    | 1.19     |
| bcftools    | 1.19     |
| fastp       | 0.23.4   |
| FastQC      | 0.12.1   |
| MultiQC     | 1.21     |

All tools are pulled from BioContainers when running with `-profile docker|singularity`, or from Bioconda with `-profile conda`.

## Profiles

| Profile       | What it does                                              |
|---------------|-----------------------------------------------------------|
| `test`        | Tiny SARS-CoV-2 reference + reads, runs end-to-end in CI  |
| `docker`      | Run each process in its BioContainer via Docker           |
| `singularity` | Same containers via Singularity (HPC-friendly)            |
| `conda`       | Resolve each process env via Bioconda                     |
| `slurm`       | Submit each process as a Slurm job                        |

Profiles compose: `-profile test,docker` or `-profile slurm,singularity`.

## License

MIT - see [LICENSE](LICENSE).
