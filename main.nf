#!/usr/bin/env nextflow

nextflow.enable.dsl=2
include { run_validate_PipeVal } from './external/pipeline-Nextflow-module/modules/PipeVal/validate/main.nf' addParams(
    options: [
        docker_image_version: params.pipeval_version,
        main_process: "./" //Save logs in <log_dir>/process-log/run_validate_PipeVal
        ]
    )
include { run_stats_SAMtools } from './module/stats_samtools' addParams(
    workflow_output_dir: "${params.output_dir_base}/SAMtools-${params.samtools_version}",
    workflow_log_output_dir: "${params.log_output_dir}/process-log/SAMtools-${params.samtools_version}"
    )

include { run_CollectWgsMetrics_Picard } from './module/collectWgsMetrics_picard' addParams(
    workflow_output_dir: "${params.output_dir_base}/Picard-${params.picard_version}",
    workflow_log_output_dir: "${params.log_output_dir}/process-log/Picard-${params.picard_version}"
    )

include { run_bamqc_Qualimap } from './module/bamqc_qualimap' addParams(
    workflow_output_dir: "${params.output_dir_base}/Qualimap-${params.qualimap_version}",
    workflow_log_output_dir: "${params.log_output_dir}/process-log/Qualimap-${params.qualimap_version}"
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
        algorithm(s): ${params.algorithms}
        dataset_id: ${params.dataset_id}
        patient_id: ${params.patient_id}
        tumor: ${params.samples_to_process.findAll{ it.sample_type == 'tumor' }['path']}
        tumor read length: ${params.samples_to_process.findAll{ it.sample_type == 'tumor' }['read_length']}
        normal: ${params.samples_to_process.findAll{ it.sample_type == 'normal' }['path']}
        normal read length: ${params.samples_to_process.findAll{ it.sample_type == 'normal' }['read_length']}
        reference: ${params.reference}

    - sample names extracted from input BAM files and sanitized:
        tumor in: ${params.samples_to_process.findAll{ it.sample_type == 'tumor' }['orig_id']}
        tumor out: ${params.samples_to_process.findAll{ it.sample_type == 'tumor' }['id']}
        normal in: ${params.samples_to_process.findAll{ it.sample_type == 'normal' }['orig_id']}
        normal out: ${params.samples_to_process.findAll{ it.sample_type == 'normal' }['id']}

    - output:
        output_dir: ${params.output_dir_base}
        log_output_dir: ${params.log_output_dir}

    - option:
        ucla_cds: ${params.ucla_cds}
        save_intermediate_files: ${params.save_intermediate_files}
        docker_container_registry: ${params.docker_container_registry}

    - samtools stats options:
        samtools_version: ${params.samtools_version}
        samtools_stats_additional_options: ${params.samtools_stats_additional_options}

    - picard CollectWgsMetrics options:
        picard_version: ${params.picard_version}
        cwm_minimum_coverage_cap: ${params.cwm_coverage_cap}
        cwm_minimum_mapping_quality: ${params.cwm_minimum_mapping_quality}
        cwm_minimum_base_quality: ${params.cwm_minimum_base_quality}
        cwm_use_fast_algorithm: ${params.cwm_use_fast_algorithm}
        cwm_additional_options: ${params.cwm_additional_options}

    - Qualimap bamqc options:
        qualimap_version: ${params.qualimap_version}
        bamqc_additional_options: ${params.bamqc_additional_options}
"""

params.reference_index = "${params.reference}.fai"
params.reference_dict = "${file(params.reference).parent / file(params.reference).baseName}.dict"

Channel
    .fromList(params.samples_to_process)
    .map { sample ->
        return tuple(sample.orig_id, sample.id, sample.path, sample.read_length, sample.sample_type)
    }
    .set { samplesToProcessChannel }

Channel
    .fromList(params.samples_to_process)
    .map{ it -> [it['path'], indexFile(it['path'])] }
    .flatten()
    .set { files_to_validate_ch }

Channel
    .from(
        params.reference,
        params.reference_index,
        params.reference_dict
        )
    .set { reference_ch }

files_to_validate_ch = files_to_validate_ch
    .mix(reference_ch)

workflow {
    // Input file validation
    run_validate_PipeVal(files_to_validate_ch)
    run_validate_PipeVal.out.validation_result.collectFile(
        name: 'input_validation.txt', newLine: true,
        storeDir: "${params.output_dir_base}/validation"
        )

    if ('stats' in params.algorithms) {
        run_stats_SAMtools(
            samplesToProcessChannel
            )
        }

    if ('collectwgsmetrics' in params.algorithms) {
        run_CollectWgsMetrics_Picard(
            samplesToProcessChannel,
            params.reference,
            params.reference_index
            )
        }
    if ('bamqc' in params.algorithms) {
        run_bamqc_Qualimap(
            samplesToProcessChannel,
            )
        }
    }
