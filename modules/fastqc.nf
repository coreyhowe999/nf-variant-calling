/*
 * FastQC
 *
 * Per-sample raw or trimmed read QC. The `stage` tag ("raw" or "trimmed")
 * lets the same module run twice in the workflow and publish into
 * separate subdirectories.
 */

process FASTQC {
    tag        "${meta.sample}|${stage}"
    label      'process_low'
    publishDir "${params.outdir}/fastqc/${stage}", mode: params.publish_mode

    conda      'bioconda::fastqc=0.12.1'
    container  'quay.io/biocontainers/fastqc:0.12.1--hdfd78af_0'

    input:
    tuple val(meta), path(reads)
    val   stage

    output:
    tuple val(meta), path("*_fastqc.{zip,html}"), emit: results

    script:
    """
    fastqc --quiet --threads ${task.cpus} ${reads}
    """
}
