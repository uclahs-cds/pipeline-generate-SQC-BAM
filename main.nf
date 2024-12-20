#!/usr/bin/env nextflow

nextflow.enable.dsl=2
include { run_validate_PipeVal } from './external/pipeline-Nextflow-module/modules/PipeVal/validate/main.nf' addParams(
    options: [
        docker_image_version: params.pipeval_version,
        main_process: "./" //Save logs in <log_dir>/process-log/run_validate_PipeVal
        ]
    )
include { run_stats_SAMtools as run_statsReadgroups_SAMtools } from './module/stats_samtools' addParams(
    workflow_output_dir: "${params.output_dir_base}/SAMtools-${params.samtools_version}",
    workflow_log_output_dir: "${params.log_output_dir}/process-log/SAMtools-${params.samtools_version}",
    stat_mode: "readgroup"
    )

include { run_stats_SAMtools as run_statsLibraries_SAMtools } from './module/stats_samtools' addParams(
    workflow_output_dir: "${params.output_dir_base}/SAMtools-${params.samtools_version}",
    workflow_log_output_dir: "${params.log_output_dir}/process-log/SAMtools-${params.samtools_version}",
    stat_mode: "library"
    )

include { run_stats_SAMtools as run_statsSamples_SAMtools } from './module/stats_samtools' addParams(
    workflow_output_dir: "${params.output_dir_base}/SAMtools-${params.samtools_version}",
    workflow_log_output_dir: "${params.log_output_dir}/process-log/SAMtools-${params.samtools_version}",
    stat_mode: "sample"
    )

include { assess_ReadQuality_FastQC as assess_ReadQualityReadgroups_FastQC } from './module/fastqc' addParams(
    workflow_output_dir: "${params.output_dir_base}/FastQC-${params.fastqc_version}",
    workflow_log_output_dir: "${params.log_output_dir}/process-log/FastQC-${params.fastqc_version}",
    stat_mode: "readgroup"
    )

include { assess_ReadQuality_FastQC as assess_ReadQualityLibraries_FastQC } from './module/fastqc' addParams(
    workflow_output_dir: "${params.output_dir_base}/FastQC-${params.fastqc_version}",
    workflow_log_output_dir: "${params.log_output_dir}/process-log/FastQC-${params.fastqc_version}",
    stat_mode: "library"
    )

include { assess_ReadQuality_FastQC as assess_ReadQualitySamples_FastQC } from './module/fastqc' addParams(
    workflow_output_dir: "${params.output_dir_base}/FastQC-${params.fastqc_version}",
    workflow_log_output_dir: "${params.log_output_dir}/process-log/FastQC-${params.fastqc_version}",
    stat_mode: "sample"
    )

include { run_CollectWgsMetrics_Picard } from './module/collectWgsMetrics_picard' addParams(
    workflow_output_dir: "${params.output_dir_base}/Picard-${params.picard_version}",
    workflow_log_output_dir: "${params.log_output_dir}/process-log/Picard-${params.picard_version}"
    )

include { run_bamqc_Qualimap } from './module/bamqc_qualimap' addParams(
    workflow_output_dir: "${params.output_dir_base}/Qualimap-${params.qualimap_version}",
    workflow_log_output_dir: "${params.log_output_dir}/process-log/Qualimap-${params.qualimap_version}"
    )

include { assess_coverage_mosdepth } from './module/windows_mosdepth' addParams(
    workflow_output_dir: "${params.output_dir_base}/mosdepth-${params.mosdepth_version}",
    workflow_log_output_dir: "${params.log_output_dir}/process-log/mosdepth-${params.mosdepth_version}"
    )

include { quantize_coverage_mosdepth } from './module/quantize_mosdepth' addParams(
    workflow_output_dir: "${params.output_dir_base}/mosdepth-${params.mosdepth_version}",
    workflow_log_output_dir: "${params.log_output_dir}/process-log/mosdepth-${params.mosdepth_version}"
    )

include { indexFile } from './external/pipeline-Nextflow-module/modules/common/indexFile/main.nf'

log.info """\
    ------------------------------------
    S Q C - D N A  P I P E L I N E
    ------------------------------------
    Boutros Lab

    Current Configuration:
    - pipeline:
        name: ${workflow.manifest.name}
        version: ${workflow.manifest.version}

    - tool docker images:
        samtools: ${params.docker_image_samtools}
        picard: ${params.docker_image_picard}
        qualimap: ${params.docker_image_qualimap}

    - input:
        algorithm(s): ${params.algorithm}
        dataset_id: ${params.dataset_id}
        patient_id: ${params.patient_id}
        tumor: ${params.samples_to_process.findAll{ it.sample_type == 'tumor' }['bam']}
        tumor read length: ${params.samples_to_process.findAll{ it.sample_type == 'tumor' }['read_length']}
        normal: ${params.samples_to_process.findAll{ it.sample_type == 'normal' }['bam']}
        normal read length: ${params.samples_to_process.findAll{ it.sample_type == 'normal' }['read_length']}
        reference: ${params.reference}

    - sample names extracted from input BAM files and sanitized:
        tumor in: ${params.samples_to_process.findAll{ it.sample_type == 'tumor' }['orig_id']}
        tumor out: ${params.samples_to_process.findAll{ it.sample_type == 'tumor' }['sm_id']}
        normal in: ${params.samples_to_process.findAll{ it.sample_type == 'normal' }['orig_id']}
        normal out: ${params.samples_to_process.findAll{ it.sample_type == 'normal' }['sm_id']}

    - output:
        output_dir: ${params.output_dir_base}
        log_output_dir: ${params.log_output_dir}

    - option:
        ucla_cds: ${params.ucla_cds}
        save_intermediate_files: ${params.save_intermediate_files}
        docker_container_registry: ${params.docker_container_registry}

    - samtools stats options:
        samtools_version: ${params.samtools_version}
        stats_max_rgs_per_sample: ${params.stats_max_rgs_per_sample}
        stats_max_libs_per_sample: ${params.stats_max_libs_per_sample}
        stats_remove_duplicates: ${params.stats_remove_duplicates}
        stats_additional_options: ${params.stats_additional_options}

    - FastQC options:
        fastqc_version: ${params.fastqc_version}
        fastqc_level: ${params.fastqc_level}
        fastqc_additional_options: ${params.fastqc_additional_options}

    - mosdepth options:
        mosdepth_version: ${params.mosdepth_version}
    - mosdepth coverage options:
        mosdepth_use_fast_algorithm: ${params.mosdepth_use_fast_algorithm}
        mosdepth_window_size: ${params.mosdepth_window_size}
        mosdepth_per_base_output: ${params.mosdepth_per_base_output}
        mosdepth_additional_options: ${params.mosdepth_additional_options}
    - mosdepth quantize options:
        mosdepth_quantize_cutoffs: ${params.mosdepth_quantize_cutoffs}
        mosdepth_quantize_use_fast_algorithm: ${params.mosdepth_quantize_use_fast_algorithm}
        mosdepth_q0_label: ${params.mosdepth_q0_label}
        mosdepth_q1_label: ${params.mosdepth_q1_label}
        mosdepth_q2_label: ${params.mosdepth_q2_label}
        mosdepth_q3_label: ${params.mosdepth_q3_label}
        mosdepth_quantize_additional_options: ${params.mosdepth_quantize_additional_options}

    - picard CollectWgsMetrics options:
        picard_version: ${params.picard_version}
        cwm_coverage_cap: ${params.cwm_coverage_cap}
        cwm_minimum_mapping_quality: ${params.cwm_minimum_mapping_quality}
        cwm_minimum_base_quality: ${params.cwm_minimum_base_quality}
        cwm_use_fast_algorithm: ${params.cwm_use_fast_algorithm}
        cwm_additional_options: ${params.cwm_additional_options}

    - Qualimap bamqc options:
        qualimap_version: ${params.qualimap_version}
        bamqc_output_format: ${params.bamqc_output_format}
        bamqc_additional_options: ${params.bamqc_additional_options}
"""

Channel
    .fromList(params.samples_to_process)
    .map { sm ->
        def rg_arg = ""
        return tuple(sm.bam, indexFile(sm.bam), sm.orig_id, sm.sm_id, rg_arg, null, null, sm.sample_type, sm.read_length)
    }
    .set { samples_to_process_ch }

Channel
    .fromList(params.libraries_to_process)
    .map { lib ->
        def rg_arg = lib.rgs.collect { "-r ${it}" }.join(' ')
        return tuple(lib.bam, indexFile(lib.bam), null, lib.sm_id, rg_arg, null, lib.lib_id, null, null)
    }
    .set { libraries_to_process_ch }

Channel
    .fromList(params.readgroups_to_process)
    .map { rg ->
        def rg_arg = "-r ${rg.orig_rg_id}"
        return tuple(rg.bam, indexFile(rg.bam), null, rg.sm_id, rg_arg, rg.rg_id, rg.lib_id, null, null)
    }
    .set { readgroups_to_process_ch }

// For stats, avoid re-processing samples with only one library or readgroup,
// and samples with more than the specified maximum number of libraries or readgroups
def stats_libraries = params.libraries_to_process.findAll { lib ->
    def sample_libs = params.libraries_to_process.findAll { it.sm_id == lib.sm_id }
    return sample_libs.size() > 1 && sample_libs.size() <= params.stats_max_libs_per_sample
    }

Channel
    .fromList(stats_libraries)
    .map { lib ->
        def rg_arg = lib.rgs.collect { "-r ${it}" }.join(' ')
        return tuple(lib.bam, indexFile(lib.bam), null, lib.sm_id, rg_arg, null, lib.lib_id, null, null)
    }
    .set { stats_libraries_ch }

def stats_readgroups = params.readgroups_to_process.findAll { rg ->
    def sample_rgs = params.readgroups_to_process.findAll { it.sm_id == rg.sm_id }
    return sample_rgs.size() > 1 && sample_rgs.size() <= params.stats_max_rgs_per_sample
    }

Channel
    .fromList(stats_readgroups)
    .map { rg ->
        def rg_arg = "-r ${rg.orig_rg_id}"
        return tuple(rg.bam, indexFile(rg.bam), null, rg.sm_id, rg_arg, rg.rg_id, rg.lib_id, null, null)
    }
    .set { stats_readgroups_ch }

// Set up file validation channel
Channel
    .fromList(params.samples_to_process)
    .map{ it -> [it['bam'], indexFile(it['bam'])] }
    .flatten()
    .set { files_to_validate_ch }

if ('collectwgsmetrics' in params.algorithm) {
    if (!params.reference) {
        throw new Exception("Reference genome is required when using the 'collectwgsmetrics' algorithm. Please check the config file and try again.")
        }

    params.reference_index = "${params.reference}.fai"
    Channel
        .from(
            params.reference,
            params.reference_index,
            )
        .set { reference_ch }
    files_to_validate_ch = files_to_validate_ch
        .mix(reference_ch)
    }

workflow {
    run_validate_PipeVal(files_to_validate_ch)
    run_validate_PipeVal.out.validation_result.collectFile(
        name: 'input_validation.txt', newLine: true,
        storeDir: "${params.output_dir_base}/validation"
        )

    if ('samtools_stats' in params.algorithm) {
        run_statsReadgroups_SAMtools(
            stats_readgroups_ch
            )
        run_statsLibraries_SAMtools(
            stats_libraries_ch
            )
        run_statsSamples_SAMtools(
            samples_to_process_ch
            )
        }
    if ('fastqc' in params.algorithm) {
        if (params.fastqc_level == 'readgroup') {
            assess_ReadQualityReadgroups_FastQC(
                readgroups_to_process_ch
                )
            }
        else if (params.fastqc_level == 'library') {
            assess_ReadQualityLibraries_FastQC(
                libraries_to_process_ch
                )
            }
        else if (params.fastqc_level == 'sample') {
            assess_ReadQualitySamples_FastQC(
                samples_to_process_ch
                )
            }
        }
    if ('mosdepth_coverage' in params.algorithm) {
        assess_coverage_mosdepth(
            samples_to_process_ch
            )
        }
    if ('mosdepth_quantize' in params.algorithm) {
        quantize_coverage_mosdepth(
            samples_to_process_ch
            )
        }
    if ('collectwgsmetrics' in params.algorithm) {
        run_CollectWgsMetrics_Picard(
            samples_to_process_ch,
            params.reference,
            params.reference_index
            )
        }
    if ('qualimap_bamqc' in params.algorithm) {
        run_bamqc_Qualimap(
            samples_to_process_ch,
            )
        }
    }
