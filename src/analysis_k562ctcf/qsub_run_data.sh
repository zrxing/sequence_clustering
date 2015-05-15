MEM=20g

LOG_DIR="$HOME/projects/sequence_analysis/results/analysis_k562ctcf/logs/"
if [ ! -d "${LOG_DIR}" ]; then
	    mkdir ${LOG_DIR}
fi

PROCESS_NAME=`echo "k562_cluster"`
echo "/data/tools/R-3.1.1/bin/Rscript run_data.R" | \
qsub -l h_vmem=${MEM} -v PATH -cwd -N ${PROCESS_NAME} \
		        -o ${LOG_DIR}${PROCESS_NAME}"_log.out" -e ${LOG_DIR}${PROCESS_NAME}"_log.err"


