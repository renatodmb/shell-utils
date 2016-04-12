#!/bin/bash

#################################
##### VARIAVEIS DE AMBIENTE #####
#################################

# Nome da pasta a fazer o pull da aplicacao
APP_PATH='Portal'

# URL de checagem do ambiente stage
URL_STAGE='personare-portal-stage.elasticbeanstalk.com'

# Nome do Ambiente A
ENVIROMENT_A='personare-portal-a'

# Nome do Ambiente A
ENVIROMENT_B='personare-portal-b'

###########################################################################
#### SCRIPT A SER EXECUTADO, EDITAR APENAS COM CERTEZA DO QUE DESEJA ######
###########################################################################

# Definindo status Ready
STATUS_READY="Ready"

# Definindo status Green
STATUS_GREEN="Green"

# Contruindo caminho da aplicacao
APP_PATH="$HOME/$APP_PATH"

# Checando existencia da pasta da Aplicacao
echo "Script esta checando a existencia da pasta da Aplicacao"
if [ -d $APP_PATH ] ;
then  

# Acessando Pasta de Aplicacao
cd $APP_PATH

# Checando existencia de configuracao de GIT.
echo "Script esta checando a existencia de configuracao de GIT"

# Contador de configuracao do GIT
COUNTER_GIT=`(ls -la .git | wc -l 2> /dev/null)`

# Reportando existencia de agendamentos
if [ $COUNTER_GIT -lt 2 ];
then
echo "Nao existe configuracao de GIT, necessario configurar e executar novamente."
exit
else
echo "Existe configuracao do GIT."
fi

# Checando existencia de configuracao de ElasticBeanstalk.
echo "Script esta checando a existencia de configuracao de ElastickBeanstalk"

# Contador da configuracao do beanstalk
COUNTER_EBT=`(ls -la .elasticbeanstalk | wc -l 2> /dev/null)`

# Reportando existencia de conf de elasticbeanstalk
if [ $COUNTER_EBT -lt 2 ];
then
echo "Nao existe configuracao de EBT, necessario configurar e executar novamente."
exit
else
echo "Existe configuracao do EBT."
fi

# Buscando o ambiente de stage
URL_PORTAL_A=`(eb status $ENVIROMENT_A | grep CNAME | cut -d " " -f4)`
URL_PORTAL_B=`(eb status $ENVIROMENT_B | grep CNAME | cut -d " " -f4)`

# Checando se o ambiente stage esta no ambiente a
if [ $URL_PORTAL_A == $URL_STAGE ] ;
then 
ENV_STAGE=$ENVIROMENT_A
ENV_PROD=$ENVIROMENT_B
fi

# Checando se o ambiente stage esta no ambiente b
if [ $URL_PORTAL_B == $URL_STAGE ] ;
then 
ENV_STAGE=$ENVIROMENT_B
ENV_PROD=$ENVIROMENT_A
fi

# Checando status dos Ambientes.
echo "Script esta checando STATUS dos ambientes Stage = $ENV_STAGE e Prod = $ENV_PROD"

# Obtendo status dos Ambientes.
STATUS_ENV_STAGE=`(eb status $ENV_STAGE | grep Status | cut -d " " -f4)`
STATUS_ENV_PROD=`(eb status $ENV_PROD | grep Status | cut -d " " -f4)`

# Checando se STATUS dos ambientes estao como READY, Caso nao estajam script sera paralizado.
if [[ $STATUS_ENV_STAGE != $STATUS_READY || $STATUS_ENV_PROD != $STATUS_READY ]] ;
then
echo "Ambientes nao estao em estado $STATUS_READY. Execute novamente quando ambos estiverem com Status: $STATUS_READY."
exit
else 
echo "Ambientes estao em estado $STATUS_READY"
fi

# Checando health dos Ambientes.
echo "Script esta checando HEALTH do ambiente Stage = $ENV_STAGE"

# Obtendo healt dos Ambientes.
HEALTH_ENV_STAGE=`(eb status $ENV_STAGE | grep Health | cut -d " " -f4)`
HEALTH_ENV_PROD=`(eb status $ENV_PROD | grep Health | cut -d " " -f4)`

# Checando se HEALTH dos ambientes STAGE estao como GREEN, Caso nao estajam script sera paralizado.
if [[ $HEALTH_ENV_STAGE != "$STATUS_GREEN" ]] ;
then
echo "Ambiente $ENV_STAGE nao esta em estado $STATUS_GREEN. Execute novamente quando o Health estiver: $STATUS_GREEN."
exit
else 
echo "Ambiente $ENV_STAGE esta em health $STATUS_GREEN"
fi

# Apresentando ambiente em Stage para usuarios e confirmando atualizacao
echo 'Stage atualmente esta no ambiente '$ENV_STAGE'! Para iniciar o processo geracao da nova configuracao de STAGE em STAGE responda a questao abaixo!' | tee /var/log/deploy.log

while true; do
    read -p 'Voce tem certeza que deseja salvar esta configuracao de STAGE em STAGE?' yn
    case $yn in
        [Yy]* ) echo 'Gerando a nova configuracao STAGE em '$ENV_STAGE'!' | tee /var/log/deploy.log; break;;
        [Nn]* ) exit;;
        * ) echo "Por favor, responda yes ou no.";;
    esac
done

# Obtendo a data da salvacao do template
DATA=`date +%Y-%m-%d-%H-%M`
echo 'Data de que template esta sendo salvo: ' 
echo $DATA

# Realizando a gravacao da nova configuracao de STAGE em STAGE
echo 'Salvando a configuracao nova de STAGE em '$ENV_STAGE'!' | tee /var/log/deploy.log 
eb config save $ENV_STAGE --cfg "portal-stage-$DATA"
echo 'Nova configuracao do Ambiente de STAGE efetuado com Sucesso!' | tee /var/log/deploy.log

else

echo "$APP_PATH pasta nao existe. Favor configurar Aplicacao antes de executar o Script."
exit

fi
