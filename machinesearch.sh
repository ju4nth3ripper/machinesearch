#!/bin/bash

#Creado por Ju4nTh3R!pper

dataUrl="https://htbmachines.github.io/bundle.js"

function ctrl_c(){
        echo -e "\n\n[!] Saliendo...\n"
}

#Ctrl + C
trap ctrl_c INT

function helpPanel(){
	echo -e "\n[+] Uso: \n"
	echo -e "\np) Buscar por patrón o texto relacionado, ejemplo: ./machinesearch.sh 'oscp fácil active directory'\n"
	echo -e "h) Mostrar panel de ayuda.\n"
	echo -e "Con CTRL + C Sales del script.\n"
}

# Indicadores
declare -i parameter_counter=0

function searchMachine(){

	echo -e "\n\n[+] Buscando máquinas que coincidan con tu busqueda: '$machineName'...\n\n"

	argsCounter=$(echo "$machineName" | wc -w)

	dataFilteredAux=$(cat newjson.json)

	for i in $(seq 1 "$argsCounter"); do

		patternArg=$(echo "$machineName" | cut -d ' ' -f "$i")

		dataFiltered=$(echo "$dataFilteredAux" | jq "map(select(.[] | test(\"$patternArg\"; \"i\")))")

		dataFilteredAux="$dataFiltered"

	done


	if [ "$dataFilteredAux" != "[]" ]; then

		echo "$dataFilteredAux" | jq 'unique'

	else

		echo -e "\n\n[¡] No se encontraron máquinas que cumplan con tu patrón de busqueda.\n\n"

	fi


}

function createJson(){

	fileExists=$(find . -type f -name 'newjson.json')

	if [ -n "$fileExists" ]; then

		rm newjson.json

	fi

	ranges=$(grep -n "}" parsedData.txt | tr -d ':' | awk '{print $1}')
	machinesQuantity=$(grep -n "}" parsedData.txt | wc -l)
	declare -i pointer=1

	for i in $(seq 1 "$machinesQuantity"); do
		
		if [ "$i" -eq 1 ]; then
			echo $(echo '[' | tee -a newjson.json) >/dev/null
			startPoint=0
			endPoint=$(echo "$ranges" | awk -v pointer="$pointer" 'NR==pointer {print}')
		else

			startPoint=$(echo "$ranges" | awk -v pointer="$pointer" 'NR==pointer {print}')
			endPointAux=$(($pointer + 1))
			endPoint=$(echo "$ranges" | awk -v endPointAux="$endPointAux" 'NR==endPointAux {print}')
			let pointer+=1

		fi

		parsedData=$(cat parsedData.txt | awk -v startPoint="$startPoint" -v endPoint="$endPoint" 'NR>=startPoint && NR<=endPoint {print}')

		nombre=$(echo "$parsedData" | grep "name:" | cut -d ':' -f 2 | tr -d ' ,"')
		dificultad=$(echo "$parsedData" | grep "dificultad:" | cut -d ':' -f 2 | tr -d ' ,"')
		ip=$(echo "$parsedData" | grep "ip:" | cut -d ':' -f 2 | tr -d ' ,"')
		so=$(echo "$parsedData" | grep "so:" | cut -d ':' -f 2 | tr -d ' ,"')
		habilidades=$(echo "$parsedData" | grep "skills:" | awk -F "skills: " '{print $2}' | tr -d '",')
		certificaciones=$(echo "$parsedData" | grep "like:" | awk -F "like: " '{print $2}' | tr -d '",')
		youtube=$(echo "$parsedData" | grep "youtube:" | awk -F "youtube: " '{print $2}' | tr -d '",')

		if [ $i -ne "$machinesQuantity" ]; then

			echo $(echo "{\"nombre\": \"$nombre\", \"dificultad\": \"$dificultad\", \"ip\": \"$ip\", \"so\": \"$so\", \"habilidades\": \"$habilidades\", \"certificaciones\": \"$certificaciones\", \"youtube\": \"$youtube\"}," | tee -a newjson.json) > /dev/null

		else

			echo $(echo "{\"nombre\": \"$nombre\", \"dificultad\": \"$dificultad\", \"ip\": \"$ip\", \"so\": \"$so\", \"habilidades\": \"$habilidades\", \"certificaciones\": \"$certificaciones\", \"youtube\": \"$youtube\"}" | tee -a newjson.json) >/dev/null
			echo $(echo "]" | tee -a newjson.json) > /dev/null
		fi

	done

}

function updateFile(){

	echo -e "[¡] Actualizando archivos..."
	curl -s "$dataUrl" | js-beautify > data.js
	grep -A $(($(grep -n "var uf" data.js | awk '{print $1}' | tr -d ':') - $(grep -n "lf =" data.js | awk '{print $1}' | tr -d ':') - 1)) "lf =" data.js | sed 's/}(),//g' > parsedData.txt
	createJson
}

while getopts "p:h" arg; do
	case $arg in
		p) machineName=$OPTARG; let parameter_counter+=1;;
		h) helpPanel;;
		\?) echo -e "\n\n[x] La opción que seleccionaste no es valida.\n\nEcha un vistazo al modo de uso:"; helpPanel;;
	esac
done

fileExists=$(find . -name data.js -type f)

if [ -z "$fileExists" ]; then

	updateFile
else

	filebeautify=$(curl -s https://htbmachines.github.io/bundle.js | js-beautify)
	md5newfile=$(echo -n "$filebeautify" | md5sum | awk '{print $1}')
	md5currentfile=$(md5sum data.js | awk '{print $1}')
	if [ "$md5newfile" != "$md5currentfile" ]; then
		echo -e "[+] Nueva actualización disponible...\n"
		echo -e "[¡] Actualizando archivos...\n"
		echo -n "$filebeautify" > data.js
		grep -A $(($(grep -n "var uf" data.js | awk '{print $1}' | tr -d ':') - $(grep -n "lf =" data.js | awk '{print $1}' | tr -d ':') - 1)) "lf =" data.js  | sed 's/}(),//g' > parsedData.txt
		createJson
		echo -e "[¡]Archivos actualizados...\n"
	fi

fi

if [ "$parameter_counter" -eq 1 ]; then

	searchMachine $machineName

else

	echo -e "\n\n[x] La opción que seleccionaste no es valida.\n\nEcha un vistazo al modo de uso:\n"
	helpPanel

fi

echo -e "\n\n[+] Fin del script [+] \n\n"
