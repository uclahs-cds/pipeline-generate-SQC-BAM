/*
*   mosdepth WGS quantized coverage assessment
*
*/

include { generate_standard_filename } from '../external/pipeline-Nextflow-module/modules/common/generate_standardized_filename/main.nf'

process quantize_coverage_mosdepth {
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
    def fast_algorithm_arg = params.mosdepth_use_fast_algorithm ? "--fast-mode" : ""
    def quantize_output_suffix = params.mosdepth_quantize_cutoffs.replace(':', '-')

    """
    set -euo pipefail
    export MOSDEPTH_Q0="${params.mosdepth_q0_label}"
    export MOSDEPTH_Q1="${params.mosdepth_q1_label}"
    export MOSDEPTH_Q2="${params.mosdepth_q2_label}"
    export MOSDEPTH_Q3="${params.mosdepth_q3_label}"
    mosdepth \
        --no-per-base \
        ${fast_algorithm_arg} \
        --threads ${task.cpus} \
        --quantize ${params.mosdepth_quantize_cutoffs} \
        ${params.mosdepth_quantize_additional_options} \
        ${output_filename}-quantize-${quantize_output_suffix} \
        ${bam}
    """
}
