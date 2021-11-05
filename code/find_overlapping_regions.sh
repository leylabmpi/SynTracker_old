#!/bin/bash
# Title 


#create variables for the flags:

length="${l:=2000}"
minimal_coverage="${c:=70}"
minimal_identity="${i:=97}"

while getopts t:r:o:c:i:l: flag
do
    case "${flag}" in
        t) target=${OPTARG};; #metagenome assemlies/genomes
        r) central_regions=${OPTARG};; #central regions, used as blast queries
        o) output=${OPTARG};; #output and temp folders will be written to this path
        i) minimal_identity=${OPTARG};; #minimal blast identity
        c) minimal_coverage=${OPTARG};; #blast qcov_hsp_perc
        l) length=${OPTARG};; #length of flanking sequences (on the retrieved traget sequence)
    esac
done

# step 1: add sample names to the fasta headers in each genome/assembly fasta files:
rm -f "$target/combined_genomes.fasta"
for infile in $target/*; do
	insert="$(basename "${infile%.*}")"
	sed "s/>/>${insert}_/" < "$infile" >> "$target/combined_genomes.fasta" ;
done;

echo " Merging genomes files is complete"


# step 2:  Make a blast database, from all the contigs. 
#          Rerunning this step overrides the previous blast DB - pay attention!
newdir="$output/blastDB"
echo "newdir: $newdir"
rm -rf "$newdir"
mkdir "$newdir"
makeblastdb -in  "$target/combined_genomes.fasta" -out "$newdir/GroupsDB" -title "GroupsDB" -parse_seqids -dbtype nucl

# Step 3: #run blast per genome => per region
#a. make output folder
#b. for each genome, make an output folder
#c. for each region run blast

newdir1="$(dirname "$output")/blast_output"
rm -rf "$newdir1"
mkdir "$newdir1"

#run blast 
#cd "$newdir"

for folder in "$central_regions"/*; do
	#echo "$folder"
	#echo "$newdir1/"$(basename "${folder%.*}")""
	rm -rf "$newdir1/"$(basename "${folder%.*}")""
	mkdir "$newdir1/"$(basename "${folder%.*}")""
	for query in "$folder"/*.fasta; do
	blastn -query "$query" -db "$newdir/GroupsDB" -out "$newdir1/"$(basename "${folder%.*}")"/$(basename "${query%.*}").tab"  -outfmt "6 qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore sstrand" -perc_identity "$minimal_identity" -qcov_hsp_perc "$minimal_coverage" -num_threads 8;
	echo "blastn -query "$query" -db "$newdir/GroupsDB" -out "$newdir1/"$(basename "${folder%.*}")"/$(basename "${query%.*}").tab"  -outfmt "6 qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore sstrand" -perc_identity "$minimal_identity" -qcov_hsp_perc "$minimal_coverage" -num_threads 8;";
	done
done

echo "BLAST search is complete"




# Step 4: delete blast output files with less than 2 hits
#for folder in "$newdir1/"*; do
#	for seqfolder in "$folder"/*; do
	#echo "$seqfolder"
#	find "$seqfolder" -type f -exec awk -v x=2 'NR==x{exit 1}' {} \; -exec rm -f {} \;
#done
#done



# Step 5: Use the blast output file to:
# a. check the orientation of the hit (minus or plus strand). If minus, change the order of start and end of hit. 
# b. take the 2/9/10/13 columns of the output (query id/start/end/strand). add/remove x base pairs on each side of the hit (columns 9-10).
# c. pipe to xargs, execute "blastdbcmd", to fetch the sequence in each hit, with x basepairs on each side.
# d. write to file to be analyzed in R synteny pipeline

set --
newdir2="$(dirname "$output")/blastcmddb_output"
rm -rf "$newdir2"
mkdir "$newdir2"
export blastDB="$newdir/GroupsDB"
#export length=$length
for folder in "$newdir1"/*; do
    #echo "Folder: $folder"
	mkdir "$newdir2/$(basename "${folder%.*}")"
	for tabular in "$folder"/*.tab; do 
	awk -v "len=$length" '{if ($13 == "minus") print $2"\t"$10-len"\t"$9+len"\t"$13"\t"; else print $2"\t"$9-len"\t"$10+len"\t"$13}' "$tabular" | xargs -n 4 sh -c 'blastdbcmd -db "$blastDB" -entry "$0" -range "$1"-"$2" -strand "$3"  -outfmt %f'  >  "$newdir2"/$(basename "${folder%.*}")/$(basename "${tabular%.*}").fasta;
	#awk '{if ($13 == "minus") print $2"\t"$10-$length"\t"$9+$length"\t"$13"\t"; else print $2"\t"$9-$length"\t"$10+$length"\t"$13}' "$tabular" | xargs -n 4 sh -c 'blastdbcmd -db "$blastDB" -entry "$0" -range "$1"-"$2" -strand "$3"  -outfmt %f'  >  "$newdir2"/$(basename "${folder%.*}")/$(basename "${tabular%.*}").fasta;
	#awk -v "len=$length" '{if ($13 == "minus") print $2"\t"$10-2000"\t"$9+2000"\t"$13"\t"; else print $2"\t"$9-len"\t"$10+len"\t"$13}' "$tabular" ;
	done
done 








