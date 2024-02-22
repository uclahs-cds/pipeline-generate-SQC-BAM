# Changelog
All notable changes to the pipeline-name pipeline.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]
### Added
- Add `Qualimap bamqc`
- Add `CollectWgsMetrics`
- Add `F4.config`
- Add NFTest
- Add `SAMtools stats` process
- Add `CODEOWNERS`
- Add example input YAMLs
- Add pipeline-Nexflow-config as submodule
- Add pipeline-Nextflow-module as submodule

### Changed
- allow multiple BAM input
- input `readlength` through YAML
- Use `sanitize_uclahs_cds_id` from `pipeline-Nextflow-config`
- Update SAMtools 1.16.1 -> 1.18
