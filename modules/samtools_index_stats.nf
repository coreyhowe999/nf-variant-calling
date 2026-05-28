/*
 * samtools index + flagstat + stats
 *
 * Index the final BAM (so callers and IGV can random-access it) and
 * produce flagstat / stats summaries for MultiQC.
 */

process SAMTOOLS_INDEX_STATS {
    tag        "${meta.sample}"
    label      'process_low'
    publishDir "${params.outdir}/samtools", mode: params.publish_mode, pattern: '*.{flagstat,stats}'
    publishDir "${params.outdir}/bwa",      mode: params.publish_mode, pattern: '*.bai'

    conda      'bioconda::samtools=1.19.2'
    container  'quay.io/biocontainers/samtools:1.19.2--h50ea8bc_1'

    input:
    tuple val(meta), path(bam)

    output:
    tuple val(meta), path(bam), path("${bam}.bai"), emit: bam_indexed
    tuple val(meta), path("${meta.sample}.flagstat"), emit: flagstat
    tuple val(meta), path("${meta.sample}.stats"),    emit: stats

    script:
    """
    samtools index -@ ${task.cpus} ${bam}
    samtools flagstat -@ ${task.cpus} ${bam} > ${meta.sample}.flagstat
    samtools stats -@ ${task.cpus} ${bam}    > ${meta.sample}.stats
    """
}
