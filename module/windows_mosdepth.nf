nextflow.enable.dsl = 2

/*
 * mosdepth window-based coverage assessment
 */

include { generate_standard_filename } from '../external/pipeline-Nextflow-module/modules/common/generate_standardized_filename/main.nf'

process assess_coverage_mosdepth {
    container params.docker_image_mosdepth

    publishDir path: "${params.workflow_output_dir}/output",
        pattern: "${output_filename}*",
        mode: "copy",
        enabled: true
    ext log_dir_suffix: { "-${sm_id}" }

    input:
        tuple path(bam), path(bam_index), val(orig_id), val(sm_id), val(rg_arg), val(rg_id), val(lib_id), val(sm_type), val(read_length)
        path intervals

    output:
        path "${output_filename}*"
        path ".command.*"

    script:
    def use_windows = ( intervals.getName() == 'NO_TARGET_FILE.bed' )

    def mosdepth_arg
    if (use_windows) {
        mosdepth_arg = "--by ${params.mosdepth_windows}"
        output_suffix = "-window${params.mosdepth_windows}"
    }
    else {
        if ( params.mosdepth_windows ) {
            log.warn "Ignoring mosdepth_windows because intervals are specified"
        }
        mosdepth_arg = "--by ${intervals}"
        output_suffix = "_targets"
    }

    output_filename = generate_standard_filename(
        "mosdepth-${params.mosdepth_version}",
        params.dataset_id,
        sm_id + output_suffix,
        [:])

    def fast_algorithm_arg = params.mosdepth_use_fast_algorithm ? \
        "--fast-mode" : ""
    def per_base_output_arg = params.mosdepth_per_base_output ? \
        "" : "--no-per-base"

    """
    set -euo pipefail

    mosdepth \\
        ${fast_algorithm_arg} \\
        ${per_base_output_arg} \\
        --threads ${task.cpus} \\
        ${mosdepth_arg} \\
        ${params.mosdepth_additional_options} \\
        ${output_filename} \\
        ${bam}
    """
}

