#!/usr/bin/env nextflow

nextflow.enable.dsl=2

// Include processes and workflows here
include { run_validate_PipeVal } from '.external/pipeline-Nextflow-module/modules/PipeVal/validate/main.nf' addParams(
    options: [
        docker_image_version: params.pipeval_version,
        main_process: "./" //Save logs in <log_dir>/process-log/run_validate_PipeVal
        ]
    )
include { generate_standard_filename } from './external/pipeline-Nextflow-module/modules/common/generate_standardized_filename/main.nf'
include { stats_SAMtools } from './module/stats_SAMtools' addParams(
    workflow_output_dir: "${params.output_dir_base}/Stats-SAMtools-${params.samtools_version}",
    workflow_log_output_dir: "${params.log_output_dir}/process-log/Stats-SAMtools-${params.samtools_version}"
    output_filename: generate_standard_filename("SAMtools-${params.samtools_version}",
        params.dataset_id,
        params.patient_id,
        [:])
        )

// Log info here
log.info """\    
        ======================================
        S Q C - D N A  P I P E L I N E
        ======================================
        Boutros Lab

        Current Configuration:
        - pipeline:
            name: ${workflow.manifest.name}
            version: ${workflow.manifest.version}

        - input:
            algorithm: ${params.algorithm}
            sample_id: ${params.patient_id}
            tumor: ${params.input['tumor']['path']}
            normal: ${params.input['normal']['path']}
            dataset_id: ${params.dataset_id}
            reference: ${params.reference}
            reference_index: ${params.reference_index}
            regions: ${params.regions}
            regions_index: ${params.regions_index}
            targetted: ${params.targetted}
            input a: ${params.variable_name}

        - output: 
            output_dir: ${params.output_dir_base}
            log_output_dir: ${params.log_output_dir}

        - options:
            ucla_cds: ${params.ucla_cds}
            docker_container_registry: ${params.docker_container_registry}

        Tools Used:
            docker_image_SAMtools: ${params.docker_image_samtools}

        ------------------------------------
        Starting workflow...
        ------------------------------------
        """
        .stripIndent()

// Returns the index file for the given bam or vcf
def indexFile(bam_or_vcf) {
    if (bam_or_vcf.endsWith('.bam')) {
        return "${bam_or_vcf}.bai"
    } else if (bam_or_vcf.endsWith('vcf.gz')) {
        return "${bam_or_vcf}.tbi"
    } else {
        throw new Exception("Index file for ${bam_or_vcf} file type not supported. Use .bam or .vcf.gz files.")
    }
}

// Channels here
// Decription of input channel
Channel
    .from( params.input['tumor'] )
    .multiMap{ it ->
        tumor_bam: it['BAM']
        tumor_index: indexFile(it['BAM'])
    }
    .set { tumor_input }

Channel
    .from( params.input['normal'] )
    .multiMap{ it ->
        normal_bam: it['BAM']
        normal_index: indexFile(it['BAM'])
    }
    .set { normal_input }

// Pre-validation steps
tumor_input
    .mix ( normal_input )
    .set { ich_validation }

// Main workflow here
workflow {
    // Validation process
    run_validate_PipeVal(
        ich_validation
        )

    run_validate_PipeVal.out.val_file.collectFile(
        name: 'input_validation.txt', newLine: true,
        storeDir: "${params.output_dir_base}/validation"
        )

    // Workflow or process
//tumor_input
//
//    tool_name_command_name(
//        tumor_input.tumor_bam,
//        tumor_input.tumor_index,
//        normal_input.normal_bam,
//        normal_input.normal_index,
//        input_ch_variable_name
//        )
}
