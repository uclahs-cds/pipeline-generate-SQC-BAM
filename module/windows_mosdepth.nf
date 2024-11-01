/*
*   mosdepth WGS window-based coverage assessment
*
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

    output:
        path "${output_filename}*"
        path ".command.*"

    script:
    output_filename = generate_standard_filename("mosdepth-${params.picard_version}",
        params.dataset_id,
        sm_id,
        [:])
    fast_algorithm_arg = params.mosdepth_use_fast_algorithm ? "--fast-mode" : ""
    per_base_output_arg = params.mosdepth_per_base_output ? "" : "--no-per-base"

    """
    set -euo pipefail
    mosdepth \
        ${fast_algorithm_arg} \
        ${per_base_output_arg} \
        --threads ${task.cpus} \
        --by ${params.mosdepth_window_size} \
        ${params.mosdepth_additional_options} \
        ${output_filename}-window${params.mosdepth_window_size} \
        ${bam}
    """
}
