# SynTracker: a pipeline to track closely related microbial strains using genome synteny
## SynTracker is a pipeline to determine the biological relatedness of same-species microbial strains (conspecific strains) using synteny blocks identified in pairs of genomes or metagenomic assemblies. 

```
## Requirements: 
```


## Input:
```
SynTracker requires as input three types of information:  
	a.	Reference genome: reference genomes could be provided complete or as a collection of contigs. If using a collection of contigs, all sequences should be kept in a single .fasta file. If using more than one reference genome (i.e., analyzing more than one species per run) all reference genome files should be located in the same folder.  
	b.	Metagenomic assemblies/genomes: These data are the metagenomic samples/full genomes that would be compared. (How did I keep the assembly files in metagenomes? Talking about folder organization).    
	c.	Metadata file: The metadata file contains essential information regarding the genomes/assemblies to be compared. Metadata file should be a tab delimited file. Headers should be “Sample/GroupA/GroupB/…” with each GroupX column corresponding to a different metadata field. Number of fields could be changed to the user preference, as long as the Relevant R function (put R function) is changed accordingly.   
```

## Running: 
```
The Syntracker pipeline is composed of three parts, each executed by running a dedicated script:  

a.	Fragmentation of the reference genome (or genomes) to a collection of 1 kbp “central-regions”, located 4 kbp apart.   
	This part is executed by running:*python central_regions.py (input_folder) (output_folder)*  
	•	Paths should be absolute paths.  
	•	input_folder: should contain the reference genomes, one fasta file per genome.  
	•	output_folder: will contain one directory per reference genome, each subdirectory will contain a collection of 1kbp “central regions”.  

b.	Executing a BLASTn search for each “central region” against a collection of metagenomic assemblies, or genomes. Output is collection of hits per “central region” and their flanking sequences (on the target metagenomic contig or genome).   
	Execution: ./find_overlapping_regions.sh -t (target_directory) -r (central_regions_directory) -o (output_directory) -i (minimal blast identity percent) -c (minimal blast query coverage percent) -l (length of flanking sequences retreived). 	
	•	Default values for -i, -c, -l flags, if not provided, are 97, 70 and 2000, correspondingly.  
	•	target_directory should contain the genomes/metagenome assemblies to be compared (it would be used to create a BLAST database i.e., would be used as the target of the BLAST search).  
	•	central_regions_directory: this is a directory that contains sub directories, each with a collection of central-regions. This is the output_folder from step a.   
	•	output_directory: contains the temporary files and the final output: genomic/metagenomic homologs of the central regions, with their flanking sequences. These will be compared in the next step.  

c.	Synteny analysis and calculation of Average Pairwise Synteny Scores (APSS) for each two conspecific strains (either in metagenomic samples or genome pairs).  
	This part is executed by running two R script:  
	•	SynTracker_functions.R: contains the functions used in the main R code.  
	•	SynTracker.R: executes the actual synteny analysis.   
```