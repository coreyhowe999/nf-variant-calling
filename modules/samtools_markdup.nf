/*
 * samtools markdup
 *
 * Mark PCR / optical duplicates on a coordinate-sorted BAM. Uses the
 * fixmate → sort-by-name → markdup → re-sort dance internally; we accept
 * a coord-sorted BAM and re-name-sort because markdup needs name-sorted
 * input with MC/ms tags from fixmate.
 *
 * Skip with `--skip_markdup true` for amplicon panels where duplicates
 * are expected to be near-universal and marking them removes signal.
 */

process SAMTOOLS_MARKDUP {
    tag        "${meta.sample}"
    label      'process_medium'
    publishDir "${params.outdir}/bwa", mode: params.publish_mode, pattern: '*.sorted.markdup.bam'

    conda      'bioconda::samtools=1.19.2'
    container  'quay.io/biocontainers/samtools:1.19.2--h50ea8bc_1'

    input:
    tuple val(meta), path(bam)

    output:
    tuple val(meta), path("${meta.sample}.sorted.markdup.bam"), emit: bam

    script:
    """
    samtools sort -n -@ ${task.cpus} ${bam} -o ${meta.sample}.name_sorted.bam
    samtools fixmate -m -@ ${task.cpus} ${meta.sample}.name_sorted.bam ${meta.sample}.fixmate.bam
    samtools sort -@ ${task.cpus} ${meta.sample}.fixmate.bam -o ${meta.sample}.fixmate.sorted.bam
    samtools markdup -@ ${task.cpus} ${meta.sample}.fixmate.sorted.bam ${meta.sample}.sorted.markdup.bam
    rm -f ${meta.sample}.name_sorted.bam ${meta.sample}.fixmate.bam ${meta.sample}.fixmate.sorted.bam
    """
}
