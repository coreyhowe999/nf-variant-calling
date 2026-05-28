/*
 * bcftools stats
 *
 * VCF-level QC: ts/tv ratio, indel size distribution, per-sample variant
 * counts, etc. Output text file is parsed by MultiQC.
 */

process BCFTOOLS_STATS {
    tag        "${meta.sample}"
    label      'process_low'
    publishDir "${params.outdir}/bcftools", mode: params.publish_mode

    conda      'bioconda::bcftools=1.19'
    container  'quay.io/biocontainers/bcftools:1.19--h8b25389_0'

    input:
    tuple val(meta), path(vcf), path(tbi)

    output:
    tuple val(meta), path("${meta.sample}.bcftools_stats.txt"), emit: stats

    script:
    """
    bcftools stats ${vcf} > ${meta.sample}.bcftools_stats.txt
    """
}
