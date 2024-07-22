/*
*   Picard CollectWgsMetrics
*   This module runs Picard CollectWgsMetrics on a BAM file
*
*/

include { generate_standard_filename } from '../external/pipeline-Nextflow-module/modules/common/generate_standardized_filename/main.nf'

process run_CollectWgsMetrics_Picard {
    container params.docker_image_picard

    publishDir path: "${params.workflow_output_dir}/output",
        pattern: "*_wgs-metrics.txt",
        mode: "copy",
        enabled: true

    ext log_dir_suffix: { "-${sm_id}" }

    input:
        tuple path(path), val(orig_id), val(sm_id), val(rg_arg), val(rg_id), val(lib_id), val(sm_type), val(read_length)
        path reference
        path reference_index

    output:
        path "*_wgs-metrics.txt"
        path ".command.*"

    script:
    output_filename = generate_standard_filename("Picard-${params.picard_version}",
        params.dataset_id,
        sm_id,
        [:])
    read_length_arg = read_length ? "-READ_LENGTH ${read_length}" : ""
    fast_algorithm_arg = params.cwm_use_fast_algorithm ? "-USE_FAST_ALGORITHM" : ""
    coverage_cap_arg = (params.cwm_coverage_cap != null) ? "-COVERAGE_CAP ${params.cwm_coverage_cap}" : ""
    minimum_mapping_quality_arg = (params.cwm_minimum_mapping_quality != null) ? "-MINIMUM_MAPPING_QUALITY ${params.cwm_minimum_mapping_quality}" : ""
    minimum_base_quality_arg = (params.cwm_minimum_base_quality != null) ? "-MINIMUM_BASE_QUALITY ${params.cwm_minimum_base_quality}" : ""

    """
    set -euo pipefail
    java -Xmx${(task.memory * params.jvm_fraction).getMega()}M \
        -Dpicard.useLegacyParser=false \
        -jar /usr/local/share/picard-slim-${params.picard_version}-0/picard.jar \
        CollectWgsMetrics \
        -INPUT ${path} \
        ${read_length_arg} \
        -OUTPUT ${output_filename}_wgs-metrics.txt \
        -REFERENCE_SEQUENCE ${reference} \
        ${coverage_cap_arg} \
        ${minimum_mapping_quality_arg} \
        ${minimum_base_quality_arg} \
        ${fast_algorithm_arg} \
        -TMP_DIR ${params.work_dir} \
        ${params.cwm_additional_options}
    """
}
