/*
*   Nextflow module for running FASTQC
*
*   @input fq_path path path to the input FASTQ file
*   @output fastqc_output_dir dir unzipped FASTQC output directory
*/

include { generate_standard_filename } from '../external/pipeline-Nextflow-module/modules/common/generate_standardized_filename/main.nf'

process assess_ReadQuality_FastQC {
    container params.docker_image_fastqc

    publishDir path: "${params.workflow_output_dir}/output",
        pattern: "${outdir}/${output_filename}_fastqc",
        mode: "copy",
        enabled: true
    ext log_dir_suffix: { "-${filename_id}" }

    input:
        tuple path(path), val(orig_id), val(sm_id), val(rg_arg), val(rg_id), val(lib_id), val(sm_type), val(read_length)

    output:
        path "${outdir}/${output_filename}_fastqc"
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

    output_filename = generate_standard_filename("FastQC-${params.fastqc_version}",
        params.dataset_id,
        filename_id,
        [:])

    """
    set -euo pipefail
    mkdir -p ${outdir}
    samtools view --threads ${task.cpus} --excl-flags 0x900 --with-header ${rg_arg} ${path} | \
        samtools fastq --threads ${task.cpus} | \
        fastqc \
        --threads ${task.cpus} \
        --outdir "${outdir}" \
        --format fastq \
        --extract \
        --delete \
        ${params.fastqc_additional_options} \
        stdin:${output_filename}
    """
}
