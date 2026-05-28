/*
 * BWA-MEM2 alignment + samtools sort streamed into a single piped command.
 *
 * Read group is set to a minimal but valid RG line so downstream variant
 * callers can tell samples apart. Sort output goes straight to coordinate-
 * sorted BAM (markdup happens in a follow-up process).
 */

process BWA_MEM {
    tag        "${meta.sample}"
    label      'process_high'
    publishDir "${params.outdir}/bwa", mode: params.publish_mode, pattern: '*.sorted.bam'

    conda      'bioconda::bwa-mem2=2.2.1 bioconda::samtools=1.19.2'
    container  'quay.io/biocontainers/mulled-v2-fe8faa35dbf6dc65a0f7f5d4ea12e31a79f73e40:8df0caa3df2c8b81e9d9d50ba5ea65e30c34cc6f-0'

    input:
    tuple val(meta), path(reads)
    tuple path(fasta), path(fasta_indices)

    output:
    tuple val(meta), path("${meta.sample}.sorted.bam"), emit: bam

    script:
    def rg = "'@RG\\tID:${meta.sample}\\tSM:${meta.sample}\\tLB:${meta.sample}\\tPL:ILLUMINA'"
    def reads_args = (reads instanceof List && reads.size() == 2) ? "${reads[0]} ${reads[1]}" : "${reads}"
    """
    bwa-mem2 mem \\
        -t ${task.cpus} \\
        -R ${rg} \\
        ${fasta} \\
        ${reads_args} \\
      | samtools sort -@ ${task.cpus} -o ${meta.sample}.sorted.bam -
    """
}
