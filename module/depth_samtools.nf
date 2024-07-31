/*
*   SAMtools depth
*   This module runs SAMtools depth on a BAM file
*
*/

include { generate_standard_filename } from '../external/pipeline-Nextflow-module/modules/common/generate_standardized_filename/main.nf'

process run_depth_SAMtools {
    container params.docker_image_samtools

    publishDir path: "${params.workflow_output_dir}/output",
        pattern: "*_depth.txt",
        mode: "copy",
        enabled: true,
        saveAs: { "${outdir}/${file(it).getName()}" }
    ext log_dir_suffix: { "-${sm_id}" }

    input:
        tuple path(path), val(orig_id), val(sm_id), val(rg_arg), val(rg_id), val(lib_id), val(sm_type), val(read_length)

    output:
        path "*_depth.txt"
        path ".command.*"

    script:
    output_filename = generate_standard_filename("SAMtools-${params.samtools_version}",
        params.dataset_id,
        sm_id,
        [:])

    all_positions_arg = params.depth_output_all_positions ? "-a" : ""
    minMQ_arg = (params.depth_minimum_mapping_quality != null) ? "--min-MQ ${params.depth_minimum_mapping_quality}" : ""
    minBQ_arg = (params.depth_minimum_base_quality != null) ? "--min-BQ ${params.depth_minimum_base_quality}" : ""
    overlaps_arg = params.depth_single_count_overlaps ? "-s" : ""
    deletion_reads_arg = params.depth_include_deletion_reads ? "-J" : ""
    header_arg = params.depth_include_header ? "-H" : ""

    args = "${all_positions_arg} ${minMQ_arg} ${minBQ_arg} ${overlaps_arg} ${deletion_reads_arg} ${header_arg}".trim()

    """
    set -euo pipefail
    samtools depth ${args} ${params.depth_additional_options} -o ${output_filename}_depth.txt ${path}
    """
}
