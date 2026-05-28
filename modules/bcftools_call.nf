/*
 * bcftools mpileup | bcftools call
 *
 * Per-sample germline variant calling. Pileup with quality filters, then
 * call SNVs and small indels with the multiallelic / variants-only model.
 * Output is bgzipped + tabix-indexed VCF.
 *
 * For diploid samples params.ploidy=2 (default). Use ploidy=1 for haploid
 * (bacterial, viral, mtDNA) and bcftools will switch its prior accordingly.
 */

process BCFTOOLS_CALL {
    tag        "${meta.sample}"
    label      'process_medium'
    publishDir "${params.outdir}/bcftools", mode: params.publish_mode

    conda      'bioconda::bcftools=1.19'
    container  'quay.io/biocontainers/bcftools:1.19--h8b25389_0'

    input:
    tuple val(meta), path(bam), path(bai)
    tuple path(fasta), path(fai)

    output:
    tuple val(meta), path("${meta.sample}.vcf.gz"), path("${meta.sample}.vcf.gz.tbi"), emit: vcf

    script:
    """
    bcftools mpileup \\
        --fasta-ref ${fasta} \\
        --min-MQ ${params.min_mapq} \\
        --min-BQ ${params.min_baseq} \\
        --annotate FORMAT/AD,FORMAT/DP,FORMAT/SP,INFO/AD \\
        --threads ${task.cpus} \\
        ${bam} \\
      | bcftools call \\
        --multiallelic-caller \\
        --variants-only \\
        --ploidy ${params.ploidy} \\
        --threads ${task.cpus} \\
        -Oz -o ${meta.sample}.vcf.gz

    bcftools index --tbi ${meta.sample}.vcf.gz
    """
}
