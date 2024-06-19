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
        tuple path(bam), path(bam_index), val(unused), val(sm_id), val(unused), val(unused), val(unused), val(unused), val(unused)

    output:
        path "${output_filename}*"
        path ".command.*"

    script:
    output_filename = generate_standard_filename("mosdepth${params.picard_version}",
        params.dataset_id,
        sm_id,
        [:])
    fast_algorithm_arg = params.mosdepth_use_fast_algorithm ? "--fast-mode" : ""

    """
    set -euo pipefail
    mosdepth \
        --no-per-base \
        ${fast_algorithm_arg} \
        --threads ${task.cpus} \
        --by ${params.mosdepth_window_size} \
        ${params.mosdepth_additional_options} \
        ${output_filename}-window${params.mosdepth_window_size} \
        ${bam}
    """
}
