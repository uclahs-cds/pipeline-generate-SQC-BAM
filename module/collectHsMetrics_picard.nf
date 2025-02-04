/*
*   Picard CollectHsMetrics
*   This module runs Picard CollectHsMetrics on a BAM file
*
*/

include { generate_standard_filename } from '../external/pipeline-Nextflow-module/modules/common/generate_standardized_filename/main.nf'

process run_CollectHsMetrics_Picard {
    container params.docker_image_picard

    publishDir path: "${params.workflow_output_dir}/output",
        pattern: "*_hs-metrics.txt",
        mode: "copy",
        enabled: true

    ext log_dir_suffix: { "-${sm_id}" }

    input:
        tuple path(bam), path(bam_index), val(orig_id), val(sm_id), val(rg_arg), val(rg_id), val(lib_id), val(sm_type), val(read_length)
        path target_intervals
        path bait_intervals
        path reference
        path reference_index

    output:
        path "*_hs-metrics.txt"
        path ".command.*"

    script:
    output_filename = generate_standard_filename("Picard-${params.picard_version}",
        params.dataset_id,
        sm_id,
        [:])

     // if bait_intervals not provided, use target_intervals as bait_intervals
    def bait_arg = bait_intervals.getName() == 'NO_BAIT_FILE.bed' ?
        "-BAIT_INTERVALS ${target_intervals}" :
        "-BAIT_INTERVALS ${bait_intervals}"

    coverage_cap_arg = (params.chm_coverage_cap != null) ? "-COVERAGE_CAP ${params.chm_coverage_cap}" : ""
    minimum_mapping_quality_arg = (params.chm_minimum_mapping_quality != null) ? "-MINIMUM_MAPPING_QUALITY ${params.chm_minimum_mapping_quality}" : ""
    minimum_base_quality_arg = (params.chm_minimum_base_quality != null) ? "-MINIMUM_BASE_QUALITY ${params.chm_minimum_base_quality}" : ""
    per_base_output_arg = (params.chm_per_base_output) ? "--PER_BASE_COVERAGE ${output_filename}_per-base-coverage" : ""

    """
    set -euo pipefail
    java -Xmx${(task.memory * params.jvm_fraction).getMega()}M \
        -Dpicard.useLegacyParser=false \
        -jar /usr/local/share/picard-slim-${params.picard_version}-0/picard.jar \
        CollectHsMetrics \
        -INPUT ${bam} \
        -OUTPUT ${output_filename}_hs-metrics.txt \
        -REFERENCE_SEQUENCE ${reference} \
        -TARGET_INTERVALS ${target_intervals} \
        ${bait_arg} \
        ${per_base_output_arg} \
        ${coverage_cap_arg} \
        ${minimum_mapping_quality_arg} \
        ${minimum_base_quality_arg} \
        -TMP_DIR ${params.work_dir} \
        ${params.chm_additional_options}
    """
}
