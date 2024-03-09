# Changelog
All notable changes to the pipeline-name pipeline.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]
### Added
- Add `schema.yaml`
- Add `template.config`
- Add `Qualimap bamqc`
- Add `CollectWgsMetrics`
- Add `F4.config`
- Add NFTest
- Add `SAMtools stats` process
- Add `CODEOWNERS`
- Add example input YAMLs
- Add pipeline-Nexflow-config as submodule
- Add pipeline-Nextflow-module as submodule
- Add workflow to build and deploy documentation GitHub Pages
- Add workflow to run Nextflow configuration regression tests

### Changed
- Use defaults for `CollectWgsMetrics` parameters
- Pipeline name in output dir changed to `generate-SQC-BAM`
- Changed `remove_duplicates` option to `samtools_remove_duplicates`
- Update flow chart in README
- Update README template
- Update PR template
- Use external `indexFile` function
- Allow multiple BAM input
- Input `read_length` through YAML
- Use `sanitize_uclahs_cds_id` from `pipeline-Nextflow-config`
- Update SAMtools 1.16.1 -> 1.18
