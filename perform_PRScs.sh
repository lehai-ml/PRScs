#!/bin/bash



while getopts "hb:c:l:t:o:n:" arg; do
    case $arg in
	b) base_file=${OPTARG};;
	c) IFS=, read -r -a columns <<< "${OPTARG}" ;; #split the string by comma
	n) number_of_cases=${OPTARG};;
	l) ld_folder=${OPTARG};;
	t) target_file=${OPTARG};;
	o) output_file=${OPTARG};;
	h) 
	    echo "-h: help menu"
	    echo "-b:path to summary statistics base file. Make sure the file is not compressed .gz : Your summary statistics must be of the following format to work: SNP A1 A2 Beta(OR) P. If it is not in that format, you can provide the argument p "
	    echo "-c: this argument is used to call select the columns SNP A1 A2 Beta(OR) P from the base file provided in argument -b. For ASD(Grove2019) that is 2,4,5,7,9. SCZ(2022) is 2,4,5,9,11. ASD(Spark) is 2,5,6,7,9"
	    echo "NOTE: PRScs expect the SNP in 1000G and the other two files to match. So you may need to map chr:bp to rsid in all of your files. However, I have changed the PRScs.py to match by chr:bp instead of rsid."
	    echo "-n: number of cases in the summary statistics. ASD(Grove) - 46350. SCZ (175799)"
	    echo "-l: path to the ld folder. This is downloaded from the original PRScs repository"
	    echo "-t: path to target b-file" 
	    echo "-o: path to the output file"
	    exit 0;;
	?) exit 1;;
    esac
done

[[ -z "${base_file}" ]] && echo "ERROR: -b base file is missing" && exit 1
[[ -z "${target_file}" ]] && echo "ERROR: -t target file is missing" && exit 1
[[ -z "${ld_folder}" ]] && echo "ERROR: -l ld folder is missing" && exit 1
[[ -z "${output_file}" ]] && echo "ERROR: -o output file is missing " && exit 1

#### CHECK that the base file is of the correct format SNP A1 A2 OR P

second_row=$(head -n 2 $base_file | tail -n 1)
number_of_col=$(echo $second_row| awk '{print NF}')
[[ ! $number_of_col -eq 5 ]] && [[ -z "${columns}" ]] && echo "ERROR: column is not defined when the base file is not in the correct format or the base file provided do not have 5 columns" && exit 1
example_id=$(echo $second_row | awk '{print $1}') #make sure that the id is chr:bp
[[ $number_of_col -eq 5 ]] && [[ ! $example_id = *':'* ]] && echo "The ID is not in the chr:bp format" && exit 1

#the PRScs.py requires the SNPs in the reference (1000G) and the other two files to match. 
#So need to map chr:bp to rsid in all of your files.
#your summary statistics header must be in the following format. SNP A1 A2 BETA(or OR) P

# convenience function to output a new file tab separated table, by defining the column numbers.
# usage output_columns source_table output_table [columns separated by space]

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
## scz - return 2 4 5 9 11
## asd spark - 2 5 6 7 9
##if [ ! -f $output_folder/$preprocessed_summary_stat ]; then
##    return_columns $summary_stat $output_folder/$preprocessed_summary_stat 2 4 5 7 9
##fi

if [[ ! $number_of_col -eq 5 ]] && [[ ! -z ${columns} ]]; then
    echo "You want to select 5 columns from the base file"
    return_columns $base_file ${output_file}.preprocessed_summary_stat ${columns[@]}
    [[ ! -f $output_file.preprocessed_summary_stat ]] && echo $output_file.preprocessed_summary_stat && exit 1
    base_file=$output_file.preprocessed_summary_stat
fi


### Running PRS CS

#asd -n = 46350
##scz -n 175799
##asd spark -n = 55420


echo "######## Performing PRScs########"
python ~/Desktop/dHCP_genetics/codes/gene_set/PRScs/PRScs.py \
 --ref_dir=$ld_folder \
 --bim_prefix=$target_file \
 --sst_file=$base_file \
 --n_gwas=$number_of_cases \
 --n_iter=1000 \
 --out_dir=$output_file

##Concatenate all files to one file
cat ${output_file}_pst_eff_a1*.txt > ${output_file}_all.txt

awk '{print $1"\t"$1":"$3"\t"$3"\t"$4"\t"$5"\t"$6}' ${output_file}_all.txt > ${output_file}_preprocessed.txt

#####Calculate the scores######
###using plink score ####


echo "Calculate PRS score using PLINK"
plink --bfile $target_file --score ${output_file}_preprocessed.txt 2 4 6 sum --out ${output_file}.PRScs
