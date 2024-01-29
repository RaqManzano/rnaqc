# ![nf-core/rnaqc](docs/images/nf-core-rnaqc_logo_light.png#gh-light-mode-only) ![nf-core/rnaqc](docs/images/nf-core-rnaqc_logo_dark.png#gh-dark-mode-only)

[![GitHub Actions CI Status](https://github.com/nf-core/rnaqc/workflows/nf-core%20CI/badge.svg)](https://github.com/nf-core/rnaqc/actions?query=workflow%3A%22nf-core+CI%22)
[![GitHub Actions Linting Status](https://github.com/nf-core/rnaqc/workflows/nf-core%20linting/badge.svg)](https://github.com/nf-core/rnaqc/actions?query=workflow%3A%22nf-core+linting%22)[![AWS CI](https://img.shields.io/badge/CI%20tests-full%20size-FF9900?labelColor=000000&logo=Amazon%20AWS)](https://nf-co.re/rnaqc/results)[![Cite with Zenodo](http://img.shields.io/badge/DOI-10.5281/zenodo.XXXXXXX-1073c8?labelColor=000000)](https://doi.org/10.5281/zenodo.XXXXXXX)

[![Nextflow](https://img.shields.io/badge/nextflow%20DSL2-%E2%89%A523.04.0-23aa62.svg)](https://www.nextflow.io/)
[![run with conda](http://img.shields.io/badge/run%20with-conda-3EB049?labelColor=000000&logo=anaconda)](https://docs.conda.io/en/latest/)
[![run with docker](https://img.shields.io/badge/run%20with-docker-0db7ed?labelColor=000000&logo=docker)](https://www.docker.com/)
[![run with singularity](https://img.shields.io/badge/run%20with-singularity-1d355c.svg?labelColor=000000)](https://sylabs.io/docs/)
[![Launch on Nextflow Tower](https://img.shields.io/badge/Launch%20%F0%9F%9A%80-Nextflow%20Tower-%234256e7)](https://tower.nf/launch?pipeline=https://github.com/nf-core/rnaqc)

[![Get help on Slack](http://img.shields.io/badge/slack-nf--core%20%23rnaqc-4A154B?labelColor=000000&logo=slack)](https://nfcore.slack.com/channels/rnaqc)[![Follow on Twitter](http://img.shields.io/badge/twitter-%40nf__core-1DA1F2?labelColor=000000&logo=twitter)](https://twitter.com/nf_core)[![Follow on Mastodon](https://img.shields.io/badge/mastodon-nf__core-6364ff?labelColor=FFFFFF&logo=mastodon)](https://mstdn.science/@nf_core)[![Watch on YouTube](http://img.shields.io/badge/youtube-nf--core-FF0000?labelColor=000000&logo=youtube)](https://www.youtube.com/c/nf-core)

## Introduction

:::note
Please note this is not an official nf-core pipeline but 
it was build with [nf-core tools](https://nf-co.re/tools)
. Documentation is not complete at the moment.
:::

**nf-core/rnaqc** is a bioinformatics pipeline that 
performs QC on RNA-seq BAMs. QC workflow comprises:

1. Read QC: [`FastQC`](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/)
2. Picard [`CollectRNASeqMEtrics`](https://broadinstitute.github.io/picard/picard-metric-definitions.html#RnaSeqMetrics)
3. GATK4 [`MarkDuplicates`](https://gatk.broadinstitute.org/hc/en-us/articles/360037052812-MarkDuplicates-Picard)
4. Picard [`InsertSizeMetrics`](https://broadinstitute.github.io/picard/picard-metric-definitions.html#InsertSizeMetrics)
5. Samtools [`Flagstat`](https://www.htslib.org/doc/samtools-flagstat.html)
6. Present QC for raw reads: [`MultiQC`](http://multiqc.info/)

QC subworkflow was mostly taken from [nf-core/rnafusion](https://github.com/nf-core/rnafusion/blob/3.0.1/subworkflows/local/qc_workflow.nf) 
and adapted to perform just QC.



## Usage

:::note
If you are new to Nextflow and nf-core, please refer to [this page](https://nf-co.re/docs/usage/installation) on how
to set-up Nextflow. 
:::

<!-- TODO nf-core: Describe the minimum required steps to execute the pipeline, e.g. how to prepare samplesheets.
     Explain what rows and columns represent. For instance (please edit as appropriate):

First, prepare a samplesheet with your input data that looks as follows:

`samplesheet.csv`:

```csv
sample,bam
CONTROL_REP1,AEG588A1_S1_L002_R1_001.bam
```

Each row represents a fastq file (single-end) or a pair of fastq files (paired end).

-->

Now, you can run the pipeline using:

```bash
nextflow run main.nf \
   -profile <docker/singularity/.../institute> \
   --input samplesheet.csv \
   --outdir <OUTDIR>
```

:::warning
Please provide pipeline parameters via the CLI or Nextflow `-params-file` option. Custom config files including those
provided by the `-c` Nextflow option can be used to provide any configuration _**except for parameters**_;
see [docs](https://nf-co.re/usage/configuration#custom-configuration-files).
:::

## Credits

nf-core/rnaqc was originally written by Raquel Manzano 
for internal purposes only. Anyone is welcome to use it 
if you think is useful.


## Contributions and Support

If you would like to contribute to this pipeline, please 
get in touch.


## Citations

<!-- TODO nf-core: Add citation for pipeline after first release. Uncomment lines below and update Zenodo doi and badge at the top of this file. -->
<!-- If you use  nf-core/rnaqc for your analysis, please cite it using the following doi: [10.5281/zenodo.XXXXXX](https://doi.org/10.5281/zenodo.XXXXXX) -->

<!-- TODO nf-core: Add bibliography of tools and data used in your pipeline -->

An extensive list of references for the tools used by the pipeline can be found in the [`CITATIONS.md`](CITATIONS.md) file.

You can cite the `nf-core` publication as follows:

> **The nf-core framework for community-curated bioinformatics pipelines.**
>
> Philip Ewels, Alexander Peltzer, Sven Fillinger, Harshil Patel, Johannes Alneberg, Andreas Wilm, Maxime Ulysse Garcia, Paolo Di Tommaso & Sven Nahnsen.
>
> _Nat Biotechnol._ 2020 Feb 13. doi: [10.1038/s41587-020-0439-x](https://dx.doi.org/10.1038/s41587-020-0439-x).
