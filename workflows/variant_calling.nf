/*
 * Variant calling subworkflow.
 *
 * Composes per-process modules into the pipeline graph:
 *
 *   samplesheet ─► parse ─┐
 *                         ├─► FastQC(raw)
 *                         └─► fastp ─┬─► FastQC(trimmed)
 *                                    └─► BWA-MEM2 ─► (markdup) ─► index/stats ─► bcftools mpileup/call ─► bcftools stats
 *                                                                          │
 *  reference ─► BWA index + faidx ──────────────────────────────────────────┘
 *
 *   all QC outputs ─► MultiQC
 */

include { FASTQC as FASTQC_RAW       } from '../modules/fastqc.nf'
include { FASTQC as FASTQC_TRIMMED   } from '../modules/fastqc.nf'
include { FASTP                      } from '../modules/fastp.nf'
include { BWA_INDEX                  } from '../modules/bwa_index.nf'
include { SAMTOOLS_FAIDX             } from '../modules/samtools_faidx.nf'
include { BWA_MEM                    } from '../modules/bwa_mem.nf'
include { SAMTOOLS_MARKDUP           } from '../modules/samtools_markdup.nf'
include { SAMTOOLS_INDEX_STATS       } from '../modules/samtools_index_stats.nf'
include { BCFTOOLS_CALL              } from '../modules/bcftools_call.nf'
include { BCFTOOLS_STATS             } from '../modules/bcftools_stats.nf'
include { MULTIQC                    } from '../modules/multiqc.nf'

workflow VARIANT_CALLING {
    take:
    samplesheet
    fasta

    main:
    // Parse samplesheet into (meta, reads) tuples.
    reads_ch = samplesheet
        .splitCsv(header: true, sep: ',', strip: true)
        .map { row ->
            def meta = [sample: row.sample]
            def files = row.fastq_2 ? [file(row.fastq_1, checkIfExists: true),
                                       file(row.fastq_2, checkIfExists: true)]
                                    : file(row.fastq_1, checkIfExists: true)
            tuple(meta, files)
        }

    // Reference prep (once).
    BWA_INDEX(fasta)
    SAMTOOLS_FAIDX(fasta)

    // Raw read QC.
    FASTQC_RAW(reads_ch, 'raw')

    // Adapter / quality trim.
    FASTP(reads_ch)

    // Trimmed read QC.
    FASTQC_TRIMMED(FASTP.out.reads, 'trimmed')

    // Align trimmed reads to indexed reference.
    BWA_MEM(FASTP.out.reads, BWA_INDEX.out.index)

    // Optional duplicate marking.
    bam_ch = params.skip_markdup ? BWA_MEM.out.bam
                                 : SAMTOOLS_MARKDUP(BWA_MEM.out.bam).bam

    // Index + alignment QC.
    SAMTOOLS_INDEX_STATS(bam_ch)

    // Variant call against the indexed reference.
    BCFTOOLS_CALL(SAMTOOLS_INDEX_STATS.out.bam_indexed, SAMTOOLS_FAIDX.out.fai)
    BCFTOOLS_STATS(BCFTOOLS_CALL.out.vcf)

    // Aggregate QC into a single report.
    multiqc_inputs = FASTQC_RAW.out.results
        .mix(FASTQC_TRIMMED.out.results)
        .mix(FASTP.out.json)
        .mix(SAMTOOLS_INDEX_STATS.out.flagstat)
        .mix(SAMTOOLS_INDEX_STATS.out.stats)
        .mix(BCFTOOLS_STATS.out.stats)
        .map { it.last() }
        .collect()

    MULTIQC(multiqc_inputs)

    emit:
    vcf          = BCFTOOLS_CALL.out.vcf
    multiqc      = MULTIQC.out.report
}
