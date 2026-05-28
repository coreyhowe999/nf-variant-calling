/*
 * samtools faidx
 *
 * Build a .fai index for the reference FASTA. bcftools mpileup needs this
 * to do random access into the reference during pileup.
 */

process SAMTOOLS_FAIDX {
    tag        "${fasta.baseName}"
    label      'process_low'
    publishDir "${params.outdir}/reference", mode: params.publish_mode

    conda      'bioconda::samtools=1.19.2'
    container  'quay.io/biocontainers/samtools:1.19.2--h50ea8bc_1'

    input:
    path fasta

    output:
    tuple path(fasta), path("${fasta}.fai"), emit: fai

    script:
    """
    samtools faidx ${fasta}
    """
}
