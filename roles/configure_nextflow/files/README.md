# Configuring and running Nextflow

## Running a nextflow pipeline

You must always use the configuration files provided by this repository when you
are running a Nextflow pipeline on the CycleCloud Slurm HPC.

There should be one configuration file and one parameter file for the pipeline
and the species of interest. Then you would need to specify at least an input file,
usually a sample sheet, and an output directory.

The nf-core documentation is usually very good, so if you want to know more about
the pipeline or see if there is a parameter which could help you just open [this](https://nf-co.re/)


### Bulk RNA-seq pipeline

- nf-core documentation: [nf-core/rnaseq](https://nf-co.re/rnaseq/3.18.0/)
- version: 3.18.0

It was decided to use STAR and Salmon to align the reads and do the quantification
as the results can be used with the [differentialabundance|Differential-expression-go-enrichment]
pipeline.


#### Preparing the samplesheet CSV file (`--input`)

```
sample,fastq_1,fastq_2,strandedness
sample1,/path/to/sample1_1.fq.gz,/path/to/sample1_2.fq.gz,auto
sample2,/path/to/sample2_1.fq.gz,/path/to/sample2_2.fq.gz,auto
...
```


#### Running the pipeline

```bash
nextflow run nf-core/rnaseq -r 3.18.0 -c /shared/data/nextflow/rnaseq.config -params-file /shared/data/nextflow/rnaseq-mouse-110-params.yml --input samplesheet.csv --outdir rnaseq
```


### Differential expression - GO Enrichment

- nf-core documentation: [nf-core/differentialabundance](https://nf-co.re/differentialabundance/1.5.0/)
- version: 1.5.0


#### Preparing the samplesheet CSV file (`--input`)

The file is slightly different from the rnaseq pipeline, but you should use it
as starting point

```
sample,fastq_1,fastq_2,condition,replicate,batch
sample1,/path/to/sample1_1.fq.gz,/path/to/sample1_2.fq.gz,control,1,A
sample2,/path/to/sample2_1.fq.gz,/path/to/sample2_2.fq.gz,treated,1,B
...
```


#### Preparing the contrast (`--contrasts`)

The file indicate which samples should be included to calculate the differential
expressions. It uses DESeq2 and I recommend reading the [nf-core documentation](https://nf-co.re/differentialabundance/1.5.0/docs/usage/#contrasts-file)
and probably also the [DESeq2 documentation](https://bioconductor.org/packages/devel/bioc/vignettes/DESeq2/inst/doc/DESeq2.html).

The values in the `variable` column must match a column found in the samplesheet
CSV. The values in the `reference` and `target` columns must match values found in
the `variable` column.

```
id,variable,reference,target
control_vs_treated,condition,control,treated
...
```

#### Preparing the matrix file (`--matrix`)

If you ran the nf-core/rnaseq pipeline, you can simply use the quantification file
from salmon: `/path/to/outdir/rnaseq/star_salmon/salmon.merged.gene_counts.tsv`

If you are running the pipeline with quantification data from a different pipeline, you should read the nf-core documentation


#### Preparing the transcrict lenght file (`--transcript_lenght_matrix`)

If you ran the nf-core/rnaseq pipeline, you can simply use the transcript
length file from salmon: `/path/to/outdir/rnaseq/star_salmon/salmon.merged.gene_lengths.tsv`

If you are running the pipeline with quantification data from a different pipeline, you should read the nf-core documentation


#### Providing the species for gProfiler (`--gprofiler_species`)

The documentation is wrong on the nf-core website. The parameter can be provided
but it is not used when the Rscript is run. We need to provide the GMT file. If
the parameter was working, the analysis would download the file in the background.
The GMT file is provided through the params file.


#### Running the pipeline

```bash
nextflow run nf-core/differentialabundance -r 1.5.0 -c /shared/data/nextflow/differentialabundance.config -params-file /shared/data/nextflow/differentialabundance-mouse-110-params.yml --input differentialabundance.csv --matrix rnaseq/star_salmon/salmon.merged.gene_counts.tsv --transcript_length_matrix rnaseq/star_salmon/salmon.merged.gene_lengths.tsv --contrasts contrasts.csv --outdir differentialabundance
```


## Single cell RNA-seq pipeline

- nf-core documentation: [nf-core/scrnaseq](https://nf-co.re/scrnaseq/4.0.0/)
- version: 4.0.0


### Preparing the samplesheet CSV (`--input`)

```
sample,fastq_1,fastq_2
sample1,/path/to/sample1_1.fq.gz,/path/to/sample1_2.fq.gz
sample2,/path/to/sample2_1.fq.gz,/path/to/sample2_2.fq.gz
...
```


### Getting the library chemistry (`--protocol`)

Unless you are using CellRanger, which is able to detect the chemistry, you will
need to know which chemistry was used to sequence the reads. The aligner selected
need this information to use the optimised settings. The choice is:

- 10XV1
- 10XV2
- 10XV3
- 10XV4

If you used multiple chemistries for your data, you cannot specify a chemistry per
sample. There is no simple options and all require manual intervention. The options are to:

- run the pipeline with a sample with all the samples and changing the protocol
  whenever the pipeline fails with the Nextflow option `-resume`
- run the pipeline for each chemistry


#### Running the pipeline

```bash
nextflow run nf-core/scrnaseq -r 4.0.0 -c /shared/data/nextflow/scrnaseq.config -params-file /shared/data/nextflow/scrnaseq-human-112-params.yml --input samplesheet.csv --protocol 10XV2 --outdir scrnaseq
```


## Configuring a nextflow pipeline

If you are preparing a new 


### Preparing the config files

#### The pipeline configuration file `<pipeline name>.config`

You should start from one of the existing config file or use the basic.config file
which just sets limits.

It is simpler to run the pipeline with the default parameters as they are defined
so they work everywhere. Then from this run you can set more refined requirements.


##### Memory limits

Slurm doesn't let you use the full amount of RAM as some is needed for the OS/VM.
Currently only 95% can be used be the jobs. So for a 8GB VM, the maximum memory
that could be requested is 7782MB. However it is better to check the cluster.

For the `htc` queue, it is:

```bash
scontrol --oneliner show node  | grep htc | sed 's/.*RealMemory=\([0-9]\+\).*/\1/' | sort -u
7168
```


##### Time limits

Slurm kills job when they reach the time limits. But the time limits also helps
Slurm for scheduling. If you did run the pipeline on a bare metal server, you would
need to multiply the runtime by 2 or 4 times to approximate how long it would take
on the HPC.


#### The pipepline parameter file `<pipeline name>-<species>-<ensembl release>-params.yml`

Any parameters which will not change like a genome index or a flag can be set in
the file. Mostly it will be the FASTA file to the genome and the GTF file to the
annotation.


##### Creating index files

In many cases the index files for an aligner is done using an annotation file.
For some reasons, the indexing is quite slow on the HPC so for time and compute,
it needs to be done once and reused through the params file.

The pipeline should be run once either on a faster machine or in the HPC and then
the files should be copied. The copy can take some time, STAR index is around 30GB
for the human genome.


###### STAR index

```bash
find work -type d -name "star"
```


###### Salmon index

```bash
find work -type d -name "salmon"
```


###### Simpleaf index

```bash
find work -type d -name "simpleaf_index"
```