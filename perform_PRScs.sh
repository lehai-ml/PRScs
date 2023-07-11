#!/bin/bash

src=$(pwd)
genetic_dataset=genetic_dataset
#summary_stat=$src/$genetic_dataset/base_files/asd/iPSYCH-PGC_ASD_Nov2017.info_filtered_and_noambiguous_alt2
#summary_stat=$src/$genetic_dataset/base_files/scz/PGC3_SCZ_european.filtered_and_noambiguous_alt2
#summary_stat=$src/$genetic_dataset/base_files/asd/ASD_spark_sumstat.nodup.noamb.tsv
target_bim=$src/$genetic_dataset/target_files/batch2/euro_batch2_imputed
ld_file=$src/ldblk_1kg_eur
#preprocessed_summary_stat=summary_stat_ASD_Grove.txt
#preprocessed_summary_stat=summary_stat_SCZ.txt
preprocessed_summary_stat=summary_stat_ASD_Spark.txt
#output_prefix=SCZ
#output_folder=asd
#output_folder=scz
output_folder=asd_spark
output_prefix=ASD_Spark
#output_folder=asd
#output_prefix=ASD

#the PRScs.py requires the SNPs in the reference (1000G) and the other two files to match. 
#So need to map chr:bp to rsid in all of your files.
#your summary statistics header must be in the following format. SNP A1 A2 BETA(or OR) P

# convenience function to output a new file tab separated table, by defining the column numbers.
# usage output_columns source_table output_table [columns separated by space]
mkdir -p $output_folder

function return_columns() {
    file=$1
    output=$2
    shift 2
    to_parse=($@)
    to_print=()
    for column in ${to_parse[@]}; do
        if [[ $column == ${to_parse[$(( ${#to_parse[*]} - 1 ))]} ]]; then
            to_print+=(\$${column})
        else
            to_print+=(\$${column}'"\t"')
        fi
    done
    to_print=$(IFS="" ; echo "${to_print[*]}")
    cmd=(awk "'{print $to_print}'" $file)
    eval "${cmd[@]}" > $output
}

# asd grove - return 2 4 5 7 9
# scz - return 2 4 5 9 11
# asd spark - 2 5 6 7 9
if [ ! -f $output_folder/$preprocessed_summary_stat ]; then
    return_columns $summary_stat $output_folder/$preprocessed_summary_stat 2 5 6 7 9
fi
#asd -n = 46350
#scz -n 175799
#asd spark -n = 55420
# python PRScs.py \
# --ref_dir=$ld_file \
# --bim_prefix=$target_bim \
# --sst_file=$output_folder/$preprocessed_summary_stat \
# --n_gwas=55420 \
# --out_dir=$output_folder/$output_prefix
#
#Concatenate all files to one file
#cat $output_folder/${output_prefix}_pst_eff_a1*.txt > $output_folder/$output_prefix"_all.txt"

#awk '{print $1"\t"$1":"$3"\t"$3"\t"$4"\t"$5"\t"$6}' $output_folder/$output_prefix"_all.txt" > $output_folder/$output_prefix"_preprocessed.txt"

#####Calculate the scores######

##using plink score ####

plink --bfile $target_bim --score $output_folder/$output_prefix"_preprocessed.txt" 2 4 6 sum --out $output_folder/$output_prefix"_imputed"
