/*
*   SAMtools stats
*   This module runs SAMtools stats on a BAM file
*
*/


include { generate_standard_filename } from '../external/pipeline-Nextflow-module/modules/common/generate_standardized_filename/main.nf'

process run_stats_SAMtools {
    container params.docker_image_samtools

    publishDir path: "${params.workflow_output_dir}/output",
        pattern: "*stats.txt",
        mode: "copy",
        enabled: true,
        saveAs: { "${outdir}/${file(it).getName()}" }
    ext log_dir_suffix: { "-${outdir}/${filename_id}" }

    input:
        tuple path(path), val(orig_id), val(sm_id), val(rg_arg), val(rg_id), val(lib_id), val(sm_type), val(read_length)

    output:
        path "*stats.txt"
        path ".command.*"

    script:
    if (params.stat_mode == "sample") {
        filename_id = sm_id
        outdir = "by-sample"
    } else if (params.stat_mode == "library") {
        filename_id = sm_id + "-" + lib_id
        outdir = "by-library"
    } else if (params.stat_mode == "readgroup") {
        filename_id = sm_id + "-" + lib_id + "-" + rg_id
        outdir = "by-readgroup"
    }
    output_filename = generate_standard_filename("SAMtools-${params.samtools_version}",
        params.dataset_id,
        filename_id,
        [:])

    rmdups = params.stats_remove_duplicates ? "--remove-dups" : ""

    """
    set -euo pipefail
    samtools view -h ${rg_arg} ${path} | samtools stats ${rmdups} ${params.stats_additional_options} > ${output_filename}_stats.txt
    """
}
