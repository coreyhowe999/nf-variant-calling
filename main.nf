#!/usr/bin/env nextflow

/*
 * nf-variant-calling
 *
 * Entry point: parse samplesheet + reference, run the variant calling
 * subworkflow, and hand its outputs to MultiQC.
 */

nextflow.enable.dsl = 2

include { VARIANT_CALLING } from './workflows/variant_calling.nf'

workflow {
    if (!params.samplesheet) {
        exit 1, "Missing --samplesheet <csv>. See README.md for the expected schema."
    }
    if (!params.fasta) {
        exit 1, "Missing --fasta <reference.fasta>."
    }

    samplesheet_ch = Channel.fromPath(params.samplesheet, checkIfExists: true)
    fasta_ch       = Channel.fromPath(params.fasta,       checkIfExists: true)

    VARIANT_CALLING(samplesheet_ch, fasta_ch)
}

workflow.onComplete {
    log.info "Pipeline finished at: ${workflow.complete}"
    log.info "Status              : ${workflow.success ? 'OK' : 'FAILED'}"
    log.info "Duration            : ${workflow.duration}"
    log.info "Results             : ${params.outdir}"
}
