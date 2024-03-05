# SQC-BAM

  1. [Overview](#overview)
  2. [How To Run](#how-to-run)
  3. [Flow Diagram](#flow-diagram)
  4. [Pipeline Steps](#pipeline-steps)
  5. [Inputs](#inputs)
  6. [Outputs](#outputs)
  7. [Discussions](#discussions)
  8. [Contributors](#contributors)
  9. [References](#references)
## Overview

This pipeline takes BAMs and corresponding indices and runs selected Quality Control (QC) steps. Available algorithms are currently `SAMtools stats`, `Picard CollectWgsMetrics` and `Qualimap bamqc`. Generally either `Qualimap bamqc` or `SAMtools stats and Picard CollectWgsMetrics` should be run, not both. `Qualimap bamqc` uses a lot of memory and should not be run within `uclahs-cds/metapipeline-DNA`. Input can include any combination of BAMs: tumor, normal, DNA, RNA. Each will be processed independently. RNA specific QC is not yet implemented but is expected soon. 

---

## How To Run

1. Update the params section of the .config file  ([Example config](config/template.config)).

2. Update the input yaml ([Template YAMLs](input/)).

3. See the submission script, [here](https://github.com/uclahs-cds/tool-submit-nf), to submit your pipeline

---

## Flow Diagram

A directed acyclic graph of your pipeline.

![alt text](pipeline-name-DAG.png?raw=true)

---

## Pipeline Steps
Each of the below algorithms, if selected, will run in parallel subject to available resources.

### 1. SAMtools stats
[samtools stats](https://www.htslib.org/doc/samtools-stats.html) collects basic statistics from BAM files including read counts, qualities, GC content, insert sizes, read lengths, proper pairing, and duplicated bases. 

### 2. Picard CollectWgsMetrics
[picard CollectWgsMetrics](https://gatk.broadinstitute.org/hc/en-us/articles/4414602403355-CollectWgsMetrics-Picard) collects coverage metrics from WGS BAM files.

### 3. Qualimap bamqc
[qualimap bamqc](http://qualimap.conesalab.org/doc_html/analysis.html#bam-qc) collects basic statistics and coverage metrics from BAM files. Example output: [html](https://kokonech.github.io/qualimap/HG00096.chr20_bamqc/qualimapReport.html) [pdf](https://kokonech.github.io/qualimap/ERR089819_report.pdf). `Qualimap bamqc` uses a lot of memory and should not be run within `uclahs-cds/metapipeline-DNA`.

---

## Inputs

### Input YAML

 Example:
```yaml
---
patient_id: 'patient_id'
dataset_id: 'dataset_id'
input:
  normal:
    - path: /absolute/path/to/normal.bam
      read_length: length
  tumor:
    - path: /absolute/path/to/tumor.bam
      read_length: length
```

### Config

| Field | Type | Required | Description |
| ----- | ---- | ------------ | ------------------------ |
| `algorithms` | list | no | List of tools to be run: ['stats', 'collectwgsmetrics', 'bamqc'], default = ['stats', 'collectwgsmetrics'] |
| `reference` | path | yes/no | Reference fasta is required only for `CollectWgsMetrics` |
| `output_dir` | path | yes | Must set if `blcds_registered_dataset` = `false` |
| `blcds_registered_dataset` | boolean | no | Default is `false`. Only `uclahs_cds` users should change this. When true BLCDS folder structure is used |
| `work_dir` | path | no | Path of working directory for Nextflow. When included, Nextflow intermediate files and logs will be saved to this directory. With `uclahs_cds` = `true`, the default is `/scratch` and should only be changed for testing/development. Changing this directory to `/hot` or `/tmp` can lead to high server latency and potential disk space limitations, respectively. |

#### SAMtools specific configuration
| Field | Type | Required | Description |
| ----- | ---- | ------------ | ------------------------ |
| remove_duplicates | boolean | no | collect stats based on deduplicated reads. default = `false` |
| samtools_stats_additional_options | string | no | add any additional options recognized by `samtools stats` |

#### Picard specific configuration
| Field | Type | Required | Description |
| ----- | ---- | ------------ | ------------------------ |
| cwm_coverage_cap | integer | no | Cap coverage at this value. Default = 250 |
| cwm_minimum_mapping_quality | integer | no | Ignore reads with mapping quality below this value. Default = 20 |
| cwm_minimum_base_quality | integer | no | Ignore bases with quality below this value. Default = 20 |
| cwm_use_fast_algorithm | boolean | no | If `true`, fast algorithm is used |
| cwm_additional_options | string | no | add any additional options recognized by `CollectWgsMetrics`

#### Qualimap specific configuration
| Field | Type | Required | Description |
| ----- | ---- | ------------ | ------------------------ |
| bamqc_additional_options | string | no | add any additional options recognized by `bamqc` |

#### Base resource allocation updaters
To update the base resource (cpus or memory) allocations for processes, use the following structure and add the necessary parts. The default allocations can be found in the [node-specific config files](./config/)
```Nextflow
base_resource_update {
    memory = [
        [['process_name', 'process_name2'], <multiplier for resource>],
        [['process_name3', 'process_name4'], <different multiplier for resource>]
    ]
    cpus = [
        [['process_name', 'process_name2'], <multiplier for resource>],
        [['process_name3', 'process_name4'], <different multiplier for resource>]
    ]
}
```
> **Note** Resource updates will be applied in the order they're provided so if a process is included twice in the memory list, it will be updated twice in the order it's given.

Examples:

- To double memory of all processes:
```Nextflow
base_resource_update {
    memory = [
        [[], 2]
    ]
}
```
- To double memory for `run_CollectWgsMetrics_Picard` and triple memory for `run_stats_SAMtools` and `run_bamqc_Qualimap`:
```Nextflow
base_resource_update {
    memory = [
        ['run_CollectWgsMetrics_Picard', 2],
        [['run_stats_SAMtools', 'run_bamqc_Qualimap'], 3]
    ]
}
```
- To double CPUs and memory for `run_CollectWgsMetrics_Picard` and double memory for `run_stats_SAMtools`:
```Nextflow
base_resource_update {
    cpus = [
        ['run_CollectWgsMetrics_Picard', 2]
    ]
    memory = [
        [['run_CollectWgsMetrics_Picard', 'run_stats_SAMtools'], 2]
    ]
}
```
---

## Outputs

<!-- List and describe the final output(s) of the pipeline. -->

| Output | Description |
| ------------ | ------------------------ |
| `{tool-version}_{dataset_id}_{sample_id}_stats.txt` | SAMtools stats results
| `{tool-version}_{dataset_id}_{sample_id}_wgs-metrics.txt` | Picard CollectWgsMetrics results
| `{tool-version}_{dataset_id}_{sample_id}_out` | Directory of Qualimap results, including `qualimapReport.html`, `genome_results.txt` and supporting directories

---

## Testing and Validation

### Test Data Set

A 2-3 sentence description of the test data set(s) used to validate and test this pipeline. If possible, include references and links for how to access and use the test dataset

### Validation <version number\>

 Input/Output | Description | Result  
 | ------------ | ------------------------ | ------------------------ |
| metric 1 | 1 - 2 sentence description of the metric | quantifiable result |
| metric 2 | 1 - 2 sentence description of the metric | quantifiable result |
| metric n | 1 - 2 sentence description of the metric | quantifiable result |

- [Reference/External Link/Path 1 to any files/plots or other validation results](<link>)
- [Reference/External Link/Path 2 to any files/plots or other validation results](<link>)
- [Reference/External Link/Path n to any files/plots or other validation results](<link>)

### Validation Tool

Included is a template for validating your input files. For more information on the tool check out: https://github.com/uclahs-cds/tool-validate-nf

---

## References

1. [Reference 1](<links-to-papers/external-code/documentation/metadata/other-repos/or-anything-else>)
2. [Reference 2](<links-to-papers/external-code/documentation/metadata/other-repos/or-anything-else>)
3. [Reference n](<links-to-papers/external-code/documentation/metadata/other-repos/or-anything-else>)

---

## Discussions

- [Issue tracker](<link-to-repo-issues-page>) to report errors and enhancement ideas.
- Discussions can take place in [<pipeline> Discussions](<link-to-repo-discussions-page>)
- [<pipeline> pull requests](<link-to-repo-pull-requests>) are also open for discussion

---

## Contributors

> Update link to repo-specific URL for GitHub Insights Contributors page.

Please see list of [Contributors](https://github.com/uclahs-cds/template-NextflowPipeline/graphs/contributors) at GitHub.

---

## License

[pipeline name] is licensed under the GNU General Public License version 2. See the file LICENSE for the terms of the GNU GPL license.

<one line to give the program's name and a brief idea of what it does.>

Copyright (C) 2023 University of California Los Angeles ("Boutros Lab") All rights reserved.

This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
