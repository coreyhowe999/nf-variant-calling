/*
 * MultiQC
 *
 * Aggregate every per-sample QC artifact (FastQC, fastp, samtools stats,
 * bcftools stats) into a single HTML report and machine-readable TSVs.
 */

process MULTIQC {
    label      'process_low'
    publishDir "${params.outdir}/multiqc", mode: params.publish_mode

    conda      'bioconda::multiqc=1.21'
    container  'quay.io/biocontainers/multiqc:1.21--pyhdfd78af_0'

    input:
    path '*'

    output:
    path "multiqc_report.html",  emit: report
    path "multiqc_data",         emit: data

    script:
    """
    multiqc --force --filename multiqc_report.html .
    """
}
