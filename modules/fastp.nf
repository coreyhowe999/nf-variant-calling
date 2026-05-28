/*
 * fastp
 *
 * Adapter + quality trimming with default Illumina settings. Emits trimmed
 * paired FASTQs plus the fastp JSON (consumed by MultiQC for trim stats).
 */

process FASTP {
    tag        "${meta.sample}"
    label      'process_medium'
    publishDir "${params.outdir}/fastp", mode: params.publish_mode

    conda      'bioconda::fastp=0.23.4'
    container  'quay.io/biocontainers/fastp:0.23.4--hadf994f_2'

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("${meta.sample}.trim_*.fastq.gz"), emit: reads
    tuple val(meta), path("${meta.sample}.fastp.json"),      emit: json
    tuple val(meta), path("${meta.sample}.fastp.html"),      emit: html

    script:
    def paired = reads instanceof List && reads.size() == 2
    if (paired) {
        """
        fastp \\
            --in1 ${reads[0]} --in2 ${reads[1]} \\
            --out1 ${meta.sample}.trim_1.fastq.gz \\
            --out2 ${meta.sample}.trim_2.fastq.gz \\
            --json ${meta.sample}.fastp.json \\
            --html ${meta.sample}.fastp.html \\
            --thread ${task.cpus}
        """
    } else {
        """
        fastp \\
            --in1 ${reads} \\
            --out1 ${meta.sample}.trim_1.fastq.gz \\
            --json ${meta.sample}.fastp.json \\
            --html ${meta.sample}.fastp.html \\
            --thread ${task.cpus}
        """
    }
}
