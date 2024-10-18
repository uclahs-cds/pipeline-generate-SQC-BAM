# generate-SQC-BAM

[![GitHub release](https://img.shields.io/github/v/release/uclahs-cds/pipeline-generate-SQC-BAM)](https://github.com/uclahs-cds/pipeline-generate-SQC-BAM/actions/workflows/prepare-release.yaml)

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

This pipeline takes BAMs and runs selected Quality Control (QC) steps. Available algorithms are currently `SAMtools stats`, `Picard CollectWgsMetrics` and `Qualimap bamqc`. Generally either `Qualimap bamqc` or `SAMtools stats and Picard CollectWgsMetrics` should be run, not both. `Qualimap bamqc` uses a lot of memory and should not be run within `uclahs-cds/metapipeline-DNA`. Input can include any combination of tumor and normal BAMs from a single donor. Each will be processed independently. RNA specific QC is not yet implemented but is expected soon.

---

## How To Run

1. Update the params section of the `.config file`  ([Example config](config/template.config)).

2. Update the input YAML ([Template YAMLs](input/)).

3. See the submission script, [here](https://github.com/uclahs-cds/tool-submit-nf), to submit your pipeline

### Requirements
Currently supported Nextflow versions: `v23.04.2`

---

## Flow Diagram

![flowchart_sqc-bam](./docs/sqc-bam-flow.svg)

---

## Pipeline Steps
Each of the below algorithms, if selected, will run in parallel subject to available resources.
 - Note about duplicated reads: `SAMtools stats` does not ignore reads marked as duplicate by default. The option `samtools_remove_duplicates` can be set to `true` to override this. `Picard CollectWgsMetrics` and `Qualimap bamqc` do ignore reads marked as duplicate by default.

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
| `algorithm` | list | no | List of tools to be run: ['stats', 'collectwgsmetrics', 'bamqc'], default = ['stats', 'collectwgsmetrics'] |
| `reference` | path | yes/no | Reference fasta is required only for `CollectWgsMetrics` |
| `output_dir` | path | yes | Not required if `blcds_registered_dataset` = `true` |
| `blcds_registered_dataset` | boolean | no | Default is `false`. Only `uclahs_cds` users should change this. When `true`, BLCDS folder structure is used |
| `work_dir` | path | no | Path of working directory for Nextflow. When included, Nextflow intermediate files and logs will be saved to this directory. With `uclahs_cds` = `true`, the default is `/scratch` and should only be changed for testing/development. Changing this directory to `/hot` or `/tmp` can lead to high server latency and potential disk space limitations, respectively. |

#### SAMtools specific configuration
| Field | Type | Required | Description |
| ----- | ---- | ------------ | ------------------------ |
| stats_max_rgs_per_sample | integer | no | If a sample has more than this number of readgroups, `SAMtools stats` will not run per readgroup analysis. Default = 20 |
| stats_max_libs_per_sample | integer | no | If a sample has more than this number of libraries, `SAMtools stats` will not run per library analysis. Default = 20 |
| stats_remove_duplicates | boolean | no | Ignore reads marked as duplicate. default = `false` |
| stats_additional_options | string | no | Any additional options recognized by `samtools stats` |

#### FastQC specific configuration
| Field | Type | Required | Description |
| ----- | ---- | ------------ | ------------------------ |
| fastqc_level | string | yes | 'readgroup', 'library' or 'sample' |
| fastqc_additional_options | string | no | Any additional options recognized by `FastQC` |

#### Picard specific configuration
| Field | Type | Required | Description |
| ----- | ---- | ------------ | ------------------------ |
| cwm_coverage_cap | integer | no | Cap coverage at this value. Default = 250 |
| cwm_minimum_mapping_quality | integer | no | Ignore reads with mapping quality below this value. Default = 20 |
| cwm_minimum_base_quality | integer | no | Ignore bases with quality below this value. Default = 20 |
| cwm_use_fast_algorithm | boolean | no | If `true`, fast algorithm is used |
| cwm_additional_options | string | no | Any additional options recognized by `CollectWgsMetrics` |

#### Qualimap specific configuration
| Field | Type | Required | Description |
| ----- | ---- | ------------ | ------------------------ |
| bamqc_output_format | string | no | Choice of 'pdf' or 'html', default = 'pdf' |
| bamqc_additional_options | string | no | Any additional options recognized by `bamqc` |

#### Base resource allocation updaters
To update the base resource (cpus or memory) allocations for processes, use the following structure. The default allocations can be found in the [node-specific config files](./config/)
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
- To double memory for `run_CollectWgsMetrics_Picard` and triple memory for `run_statsSamples_SAMtools` and `run_bamqc_Qualimap`:
```Nextflow
base_resource_update {
    memory = [
        ['run_CollectWgsMetrics_Picard', 2],
        [['run_statsSamples_SAMtools', 'run_bamqc_Qualimap'], 3]
    ]
}
```
- To double CPUs and memory for `run_CollectWgsMetrics_Picard` and double memory for `run_statsSamples_SAMtools`:
```Nextflow
base_resource_update {
    cpus = [
        ['run_CollectWgsMetrics_Picard', 2]
    ]
    memory = [
        [['run_CollectWgsMetrics_Picard', 'run_statsSamples_SAMtools'], 2]
    ]
}
```
---

## Outputs

| Output | Description |
| ------------ | ------------------------ |
| `{SAMtools-version}_{dataset_id}_{sample_id}_stats.txt` | SAMtools stats results |
| `{Picard-version}_{dataset_id}_{sample_id}_wgs-metrics.txt` | Picard CollectWgsMetrics results |
| `{Qualimap-version}_{dataset_id}_{sample_id}_stats` | Directory of Qualimap results, including, `genome_results.txt` and either `.pdf` or `.html and supporting directories`|

---

## References

1. [SAMtools stats](https://www.htslib.org/doc/samtools-stats.html)
2. [Picard CollectWgsMetrics](https://gatk.broadinstitute.org/hc/en-us/articles/4414602403355-CollectWgsMetrics-Picard)
3. [Qualimap bamqc](http://qualimap.conesalab.org/doc_html/analysis.html#bam-qc)

---

## Discussions

- [Issue Tracker](https://github.com/uclahs-cds/pipeline-generate-SQC-BAM/issues) to report errors and enhancement ideas.
- Discussions can take place in [generate-SQC-BAM Discussions](https://github.com/uclahs-cds/pipeline-generate-SQC-BAM/discussions)
- [generate-SQC-BAM Pull Requests](https://github.com/uclahs-cds/pipeline-generate-SQC-BAM/pulls) are also open for discussion

---

## Contributors

Please see list of [Contributors](https://github.com/uclahs-cds/pipeline-generate-SQC-BAM/graphs/contributors) at GitHub.

---

## License

Generate-SQC-BAM is licensed under the GNU General Public License version 2. See the file LICENSE for the terms of the GNU GPL license.

Generate-SQC-BAM takes BAM files and generates per sample QC metrics

Copyright (C) 2024 University of California Los Angeles ("Boutros Lab") All rights reserved.

This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
