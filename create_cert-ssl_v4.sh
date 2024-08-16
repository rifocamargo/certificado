#!/bin/bash

# Funcoes de formatacao de texto.
# Para utilizar coloque a tag entre o texto
#ex:  ${bold}TEXTO PARA FICAR NEGRITO${normal}
bold=$(tput bold)
smul=$(tput smul)
rmul=$(tput rmul)
normal=$(tput sgr0)
red=$(tput setaf 1)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
blink=$(tput blink)

# Variaveis
domain=$1
password=$2
java_home=$3
commonname=$domain

# Dados da Empresa
country=BR
state=Sao\ Paulo
locality=Bauru
organization=Ricardo
organizationalunit=TI
email=noc@ricardo.com.br

if [ -z "$domain" ]
then
	echo -e
    echo "${red}${bold} Argumentos invalidos!${normal}"
    echo "${yellow} Execute o script: $0 seguido do common name desejado [espaço] senha desejada.${normal}"
    echo "${green} Exemplo: $0 ricardo.com.br ricardo181${normal}"
    echo -e
    exit 0
fi

echo -e
echo "${green} Gerando certificado auto-assinado para: $domain${normal}"
echo -e
rm $domain.conf
echo '[req]' >> $domain.conf
echo 'distinguished_name = req_distinguished_name' >> $domain.conf
echo 'x509_extensions = v3_req' >> $domain.conf
echo 'prompt = no' >> $domain.conf
echo '[req_distinguished_name]' >> $domain.conf
echo 'C = '$country >> $domain.conf
echo 'ST = '$state >> $domain.conf
echo 'L = '$locality >> $domain.conf
echo 'O = '$organization >> $domain.conf
echo 'OU = '$organizationalunit >> $domain.conf
echo 'CN = '$commonname >> $domain.conf
echo '[v3_req]' >> $domain.conf
echo 'subjectAltName = @alt_names' >> $domain.conf
echo '[alt_names]' >> $domain.conf
echo 'DNS.1 = '$domain >> $domain.conf
cat $domain.conf

# Criando o arquivo de requisição (CSR) + chave do certificado (KEY)
#openssl req -sha256 -newkey rsa:2048 -nodes -keyout $domain.key -out $domain.csr -passin pass:$password -subj "/C=$country/ST=$state/L=$locality/O=$organization/OU=$organizationalunit/CN=$commonname/emailAddress=$email" -addext "subjectAltName = DNS:$domain"
openssl req -x509 -nodes -days 3650 -newkey rsa:2048 -keyout $domain.key -out $domain.crt -passin pass:$password -config $domain.conf -extensions 'v3_req'

# Removendo a senha da .key. Comente essa linha caso queira manter a senha na key.
# echo "Removendo a senha da key."
# openssl rsa -in $domain.key -passin pass:$password -out $domain.key

# Exemplo criar CSR para multiplos dominios:
# openssl req -new -newkey rsa:2048 -sha256 -nodes -keyout $domain.key -out $domain.csr -subj "/C=$country/ST=$state/L=$locality/O=$organization/OU=$organizationalunit/CN=$commonname/emailAddress=$email/subjectAltName=DNS.1subjectAltName=DNS.1subjectAltName=DNS.1subjectAltName=DNS.1=MEU.DNS.COM.2=MEU.DNS2.COM"

echo -e
echo "${green} Arquivo de certificado CRT gerado para: $domain${normal}"
#openssl req -in $domain.csr -text -noout
openssl x509 -in $domain.crt -noout -text
echo -e

#Criando arquivo com senha
echo $password > password.txt

# Criando certificado (CRT)
openssl x509 -signkey $domain.key -in $domain.csr -req -days 3650 -out $domain.crt -extensions 'v3_req'

# Criando pk12
openssl pkcs12 -export -in $domain.crt -inkey $domain.key -out $domain.pk12 -passout pass:$password

# Criando JKS
keytool -importkeystore -srckeystore $domain.pk12 -srcstorepass $password -srcstoretype pkcs12 -srcalias 1 -destkeystore $domain.jks  -deststoretype jks -deststorepass $password -destalias autosing_ricardo

keytool -delete -alias $domain -keystore $java_home/lib/security/cacerts -storepass changeit -keypass changeit
keytool -import -alias $domain -trustcacerts -file $domain.crt -keystore $java_home/lib/security/cacerts -storepass changeit -keypass changeit

echo -e
echo "${green} Arquivos do certificado criados:"
echo "   $domain.csr"
echo "   $domain.key"
echo "   $domain.crt"
echo "   $domain.pk12"
echo "   $domain.jks"
echo "${yellow}   A senha do certificado é: $password ${normal}"
echo -e

# MELHORIAS: VALIDAR DIR CERTIFICADOS E CRIAR, CASO CRT SEJA *.NAME USAR RENAME PARA MUDAR.
