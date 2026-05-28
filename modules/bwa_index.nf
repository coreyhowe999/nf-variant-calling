/*
 * BWA-MEM2 index for a reference FASTA.
 *
 * Emits the FASTA itself together with the 5 BWA-MEM2 index files
 * (.0123, .amb, .ann, .bwt.2bit.64, .pac) under a single directory so
 * downstream alignment can stage them as one input.
 */

process BWA_INDEX {
    tag        "${fasta.baseName}"
    label      'process_low'
    publishDir "${params.outdir}/reference", mode: params.publish_mode

    conda      'bioconda::bwa-mem2=2.2.1'
    container  'quay.io/biocontainers/bwa-mem2:2.2.1--he70b90d_6'

    input:
    path fasta

    output:
    tuple path(fasta), path("${fasta}.*"), emit: index

    script:
    """
    bwa-mem2 index ${fasta}
    """
}
