#!/bin/bash
DATA=""
relatorio_base="relatorioFilas.csv";
output="RELATORIO_DE_ATENDIMENTO_-_VOIP.txt";
remove_old_csv(){
FILE=$(ls relatorioFilas*.csv);
if [ $FILE ];
then
   rm relatorioFilas*.csv;
fi
}

interative_menu(){
    echo -e "ATENCAO! A PESQUISA PODE DEMORAR ATE 2 MINUTOS, POR FAVOR AGUARDE SEU TERMINO"
    echo -e "FORAM ENCONTRADAS INFORMACÕES COM AS SEGUINTES DATAS:\n"
    print_day;
    echo -e "\nDIGITE A DATA QUE DESEJA EFETUAR A AVALIACAO:";
    read -p "ESCOLHA: " opcao;

    if [[ ($opcao == 0) || ($opcao == "todos") || ($opcao == "TODOS") ]]; then
    	DATA="*"
    	convert_ALL_xls_to_csv
    else
    	if [[ ($opcao == "sair") || ($opcao == "SAIR") ]]; then
    		echo "Bye"
    	else
    		DATA=${vetor[$opcao]}
    	
    		convert_xls_to_csv;
    	fi
    fi
    echo -e "\nAGUARDE, ESCANEAMENTO SENDO EXECUTADO...\n";

}
print_day(){
	x=$(ls | grep xls | wc -l)
	z=$(ls | grep xls)
	if [[ $x > 0 ]]; then
		echo "0 - TODOS OS DIAS"
		for (( i = 1; i < (x+1); i++ )); do
			vetor[i]=$(echo $z | awk -F' ' '{print substr($'$i',16,2)"/"substr($'$i',19,2)}')
			echo $i" - "${vetor[i]}
		done
	fi
}
convert_xls_to_csv(){
	data_inicio=$DATA
	data_fim=$DATA
	DATA=$(echo $DATA | awk '{print substr($0,4,2)"/"substr($0,1,2)}');
	firstfile=$(echo $DATA | awk '{print "relatorioFilas_" substr($0,4,2)"-"substr($0,1,2)"-2019.xls"}');
	ssconvert $firstfile $relatorio_base
}
convert_ALL_xls_to_csv(){
	x=$(ls | grep xls | wc -l)
	z=$(ls | grep xls)
	DATA="*"
	firstfile=$(echo $z | awk -F' ' '{print $1".csv"}')
	data_inicio=$(echo $z | awk -F' ' '{print substr($1,16,2)"/"substr($1,19,2)}')
	for (( i = 1; i < (x+1); i++ )); do
		file=$(echo $z | awk -F' ' '{print $'$i'}')
		file_out=$(echo $z | awk -F' ' '{print $'$i'".csv"}');	
		ssconvert $file $file_out
		if [[ $i > 1 ]]; then
			sed 1d $file_out >> $firstfile;
		fi
		rm $file_out;
	done
	data_fim=$(echo $z | awk -F' ' '{print substr($'$x',16,2)"/"substr($'$x',19,2)}')
	mv $firstfile $relatorio_base;
}
init_documment(){
echo "
						QUICKNET
RELATORIO DE ATENDIMENTO - VOIP

DIAS AVALIADOS: $data_inicio a $data_fim

EVENTOS AVALIADOS:

	1 - CLIENTE ENTROU NA FILA
	2 - CHAMADAS CONECTADAS
	3 - FINALIZADAS PELO OPERADOR
	4 - FINALIZADAS PELO CLIENTE
	5 - CHAMADAS ABANDONADAS
	6 - SAIDA POR TIMEOUT
"  > $output;
}
extract_ENTERQUEUE(){

	echo -e "\n\n1 - CLIENTE ENTROU NA FILA" >> $output;
	#TODOS
	total=$(sort $relatorio_base | grep -E "$DATA*.*ENTERQUEUE" | wc -l)
	if [[ $total > 0 ]]; then
		echo -e "\n	FILA:				TODAS" >> $output;
		echo "	TOTAL DE OCORRENCIAS:		"$total >> $output;
	fi
	#FILA X
	for (( FILA = 100; FILA < 107; FILA++ )); do
		total=$(sort $relatorio_base | grep -E "$DATA*.*$FILA.*ENTERQUEUE" | wc -l)
		if [[ $total > 0 ]]; then
			echo -e "\n	FILA:				"$FILA >> $output;
			echo "	TOTAL DE OCORRENCIAS:		"$total >> $output;
		fi
	done
}
extract_CONNECT(){

	echo -e "\n\n2 - CHAMADAS CONECTADAS" >> $output;
	#TODOS
	total=$(sort $relatorio_base | grep -E "$DATA*.*CONNECT" | wc -l)
	if [[ $total > 0 ]]; then
		echo -e "\n	FILA:				TODAS" >> $output;
		echo "	TOTAL DE OCORRENCIAS:		"$total >> $output;
		campo1=$(sort $relatorio_base | grep -E "$DATA*.*CONNECT" | awk -F',' '{print $6}' | paste -sd+ | bc)
		campo1=$(echo "scale=1; ($campo1/$total)" | bc -l)
		campo2=$(sort $relatorio_base | grep -E "$DATA*.*CONNECT" | awk -F',' '{print $8}' | paste -sd+ | bc)
		campo2=$(echo "scale=1; ($campo2/$total)" | bc -l)
		echo "	MEDIA DE TEMPO DE ESPERA:	"$campo1 >> $output;
		echo "	MEDIA DE TEMPO DE TOQUE:	"$campo2 >> $output;
	fi
	#FILA X
	for (( FILA = 100; FILA < 107; FILA++ )); do
		total=$(sort $relatorio_base | grep -E "$DATA*.*$FILA.*CONNECT" | wc -l)
		if [[ $total > 0 ]]; then
			campo1=$(sort $relatorio_base | grep -E "$DATA*.*$FILA.*CONNECT" | awk -F',' '{print $6}' | paste -sd+ | bc)
			campo1=$(echo "scale=1; ($campo1/$total)" | bc -l)
			campo2=$(sort $relatorio_base | grep -E "$DATA*.*$FILA.*CONNECT" | awk -F',' '{print $8}' | paste -sd+ | bc)
			campo2=$(echo "scale=1; ($campo2/$total)" | bc -l)
			echo -e "\n	FILA:				"$FILA >> $output;
			echo "	TOTAL DE OCORRENCIAS:		"$total >> $output;
			echo "	MEDIA DE TEMPO DE ESPERA:	"$campo1" seg." >> $output;
			echo "	MEDIA DE TEMPO DE TOQUE:	"$campo2" seg." >> $output;
		fi
	done	
}
extract_COMPLETEAGENT(){

	echo -e "\n\n3 - FINALIZADAS PELO OPERADOR" >> $output;
	#TODOS
	total=$(sort $relatorio_base | grep -E "$DATA*.*COMPLETEAGENT" | wc -l)
	if [[ $total > 0 ]]; then
		echo -e "\n	FILA:				TODAS" >> $output;
		echo "	TOTAL DE OCORRENCIAS:		"$total >> $output;
		campo1=$(sort $relatorio_base | grep -E "$DATA*.*COMPLETEAGENT" | awk -F',' '{print $6}' | paste -sd+ | bc)
		campo1=$(echo "scale=1; ($campo1/$total)" | bc -l)
		campo2=$(sort $relatorio_base | grep -E "$DATA*.*COMPLETEAGENT" | awk -F',' '{print $7}' | paste -sd+ | bc)
		campo2=$(echo "scale=1; ($campo2/$total)" | bc -l)
		echo "	MEDIA DE TEMPO DE ESPERA:	"$campo1" seg." >> $output;
		echo "	MEDIA DE TEMPO DE CHAMADA:	"$campo2" seg." >> $output;
	fi
	#FILA X
	for (( FILA = 100; FILA < 107; FILA++ )); do
		total=$(sort $relatorio_base | grep -E "$DATA*.*$FILA.*COMPLETEAGENT" | wc -l)
		if [[ $total > 0 ]]; then
			campo1=$(sort $relatorio_base | grep -E "$DATA*.*$FILA.*COMPLETEAGENT" | awk -F',' '{print $6}' | paste -sd+ | bc)
			campo1=$(echo "scale=1; ($campo1/$total)" | bc -l)
			campo2=$(sort $relatorio_base | grep -E "$DATA*.*$FILA.*COMPLETEAGENT" | awk -F',' '{print $7}' | paste -sd+ | bc)
			campo2=$(echo "scale=1; ($campo2/$total)" | bc -l)
			echo -e "\n	FILA:				"$FILA >> $output;
			echo "	TOTAL DE OCORRENCIAS:		"$total >> $output;
			echo "	MEDIA DE TEMPO DE ESPERA:	"$campo1" seg." >> $output;
			echo "	MEDIA DE TEMPO DE CHAMADA:	"$campo2" seg." >> $output;
		fi
	done	
}
extract_COMPLETECALLER(){

	echo -e "\n\n4 - FINALIZADAS PELO CLIENTE" >> $output;
	#TODOS
	total=$(sort $relatorio_base | grep -E "$DATA*.*COMPLETECALLER" | wc -l)
	if [[ $total > 0 ]]; then
		echo -e "\n	FILA:				TODAS" >> $output;
		echo "	TOTAL DE OCORRENCIAS:		"$total >> $output;
		campo1=$(sort $relatorio_base | grep -E "$DATA*.*COMPLETECALLER" | awk -F',' '{print $6}' | paste -sd+ | bc)
		campo1=$(echo "scale=1; ($campo1/$total)" | bc -l)
		campo2=$(sort $relatorio_base | grep -E "$DATA*.*COMPLETECALLER" | awk -F',' '{print $7}' | paste -sd+ | bc)
		campo2=$(echo "scale=1; ($campo2/$total)" | bc -l)
		echo "	MEDIA DE TEMPO DE ESPERA:	"$campo1" seg." >> $output;
		echo "	MEDIA DE TEMPO DE CHAMADA:	"$campo2" seg." >> $output;
	fi
	#FILA X
	for (( FILA = 100; FILA < 107; FILA++ )); do
		total=$(sort $relatorio_base | grep -E "$DATA*.*$FILA.*COMPLETECALLER" | wc -l)
		if [[ $total > 0 ]]; then
			campo1=$(sort $relatorio_base | grep -E "$DATA*.*$FILA.*COMPLETECALLER" | awk -F',' '{print $6}' | paste -sd+ | bc)
			campo1=$(echo "scale=1; ($campo1/$total)" | bc -l)
			campo2=$(sort $relatorio_base | grep -E "$DATA*.*$FILA.*COMPLETECALLER" | awk -F',' '{print $7}' | paste -sd+ | bc)
			campo2=$(echo "scale=1; ($campo2/$total)" | bc -l)
			echo -e "\n	FILA:				"$FILA >> $output;
			echo "	TOTAL DE OCORRENCIAS:		"$total >> $output;
			echo "	MEDIA DE TEMPO DE ESPERA:	"$campo1" seg." >> $output;
			echo "	MEDIA DE TEMPO DE CHAMADA:	"$campo2" seg." >> $output;
		fi
	done
}
extract_ABANDON(){

	echo -e "\n\n5 - CHAMADAS ABANDONADAS" >> $output;
	#TODOS
	total=$(sort $relatorio_base | grep -E "$DATA*.*ABANDON" | wc -l)
	if [[ $total > 0 ]]; then
		echo -e "\n	FILA:				TODAS" >> $output;
		echo "	TOTAL DE OCORRENCIAS:		"$total >> $output;
		campo1=$(sort $relatorio_base | grep -E "$DATA*.*ABANDON" | awk -F',' '{print $7}' | paste -sd+ | bc)
		campo1=$(echo "scale=1; ($campo1/$total)" | bc -l)
		campo2=$(sort $relatorio_base | grep -E "$DATA*.*ABANDON" | awk -F',' '{print $8}' | paste -sd+ | bc)
		campo2=$(echo "scale=1; ($campo2/$total)" | bc -l)
		echo "	MEDIA DA POSICAO ORIGINAL:	"$campo1 >> $output;
		echo "	MEDIA DE TEMPO EM ESPERA:	"$campo2" seg." >> $output;
	fi
	#FILA X
	for (( FILA = 100; FILA < 107; FILA++ )); do
		total=$(sort $relatorio_base | grep -E "$DATA*.*$FILA.*ABANDON" | wc -l)
		if [[ $total > 0 ]]; then
			campo1=$(sort $relatorio_base | grep -E "$DATA*.*$FILA.*ABANDON" | awk -F',' '{print $7}' | paste -sd+ | bc)
			campo1=$(echo "scale=1; ($campo1/$total)" | bc -l)
			campo2=$(sort $relatorio_base | grep -E "$DATA*.*$FILA.*ABANDON" | awk -F',' '{print $8}' | paste -sd+ | bc)
			campo2=$(echo "scale=1; ($campo2/$total)" | bc -l)
			echo -e "\n	FILA:				"$FILA >> $output;
			echo "	TOTAL DE OCORRENCIAS:		"$total >> $output;
			echo "	MEDIA DA POSICAO ORIGINAL:	"$campo1 >> $output;
			echo "	MEDIA DE TEMPO EM ESPERA:	"$campo2" seg." >> $output;
		fi
	done
}
extract_EXITWITHTIMEOUT(){

	echo -e "\n\n6 - SAIDA POR TIMEOUT" >> $output;
	#TODOS
	total=$(sort $relatorio_base | grep -E "$DATA*.*EXITWITHTIMEOUT" | wc -l)
	if [[ $total > 0 ]]; then
		echo -e "\n	FILA:				TODAS" >> $output;
		echo "	TOTAL DE OCORRENCIAS:		"$total >> $output;
		campo1=$(sort $relatorio_base | grep -E "$DATA*.*EXITWITHTIMEOUT" | awk -F',' '{print $7}' | paste -sd+ | bc)
		campo2=$(sort $relatorio_base | grep -E "$DATA*.*EXITWITHTIMEOUT" | awk -F',' '{print $8}' | paste -sd+ | bc)
		campo1=$(echo "scale=1; ($campo1/$total)" | bc -l)
		campo2=$(echo "scale=1; ($campo2/$total)" | bc -l)
		echo "	MEDIA DA POSICAO ORIGINAL:	"$campo1 >> $output;
		echo "	MEDIA DE TEMPO EM ESPERA:	"$campo2" seg." >> $output;
	fi
	#FILA X
	for (( FILA = 100; FILA < 107; FILA++ )); do
		total=$(sort $relatorio_base | grep -E "$DATA*.*$FILA.*EXITWITHTIMEOUT" | wc -l)
		if [[ $total > 0 ]]; then
			campo1=$(sort $relatorio_base | grep -E "$DATA*.*$FILA.*EXITWITHTIMEOUT" | awk -F',' '{print $7}' | paste -sd+ | bc)
			campo1=$(echo "scale=1; ($campo1/$total)" | bc -l)
			campo2=$(sort $relatorio_base | grep -E "$DATA*.*$FILA.*EXITWITHTIMEOUT" | awk -F',' '{print $8}' | paste -sd+ | bc)
			campo2=$(echo "scale=1; ($campo2/$total)" | bc -l)
			echo -e "\n	FILA:				"$FILA >> $output;
			echo "	TOTAL DE OCORRENCIAS:		"$total >> $output;
			echo "	MEDIA DA POSICAO ORIGINAL:	"$campo1 >> $output;
			echo "	MEDIA DE TEMPO EM ESPERA:	"$campo2" seg." >> $output;
		fi
	done
}
convert_csv_to_pdf(){
enscript -p output.ps $output ;
ps2pdf output.ps RELATORIO_DE_ATENDIMENTO_-_VOIP.pdf ;
rm output.ps;
}


modulo_caller_functions(){
	remove_old_csv;
	interative_menu;
	init_documment;
	extract_ENTERQUEUE;
	extract_CONNECT;
	extract_COMPLETEAGENT;
	extract_COMPLETECALLER;
	extract_ABANDON;
	extract_EXITWITHTIMEOUT;
	cat $output;
}
modulo_caller_functions;
convert_csv_to_pdf;