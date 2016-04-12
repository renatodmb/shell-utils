#!/bin/bash

#################################
##### VARIAVEIS DE AMBIENTE #####
#################################

# Pasta de Aplicacao
APP_PATH='Portal'

# URL de checagem do ambiente stage
URL_STAGE='personare-portal-stage.elasticbeanstalk.com'

# Nome do Ambiente A
ENVIROMENT_A='personare-portal-a'

# Nome do Ambiente A
ENVIROMENT_B='personare-portal-b'

# Configuracao do ambiente Stage
STAGE_CONFIG='portal-stage-2016-04-12-01-35'

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
echo 'Stage atualmente esta no ambiente '$ENV_STAGE'! Para iniciar o processo de atualizacao resposta a questao abaixo!' | tee /var/log/deploy.log

# Confirmando Aumento de ambiente.
while true; do
    read -p 'Voce tem certeza que deseja efetuar a atualizacao do ambiente STAGE para STAGE?' yn
    case $yn in
        [Yy]* ) echo 'Realizando deploy em '$ENV_STAGE'!' | tee /var/log/deploy.log; break;;
        [Nn]* ) exit;;
        * ) echo "Por favor, responda yes ou no.";;
    esac
done

# Checando necessidade de aumento de ambiente

# Obtendo informacoes de variaveis de STAGE ou PROD, desta forma identificamos a configuracao de STAGE se esta tamanho de prod.
echo "Obtendo informacoes de variaveis de STAGE ou PROD, desta forma identificamos a configuracao de STAGE se esta tamanho de prod."
CONFIG_STAGE=`(eb printenv $ENV_STAGE | grep stage | wc -l)`

# IF para execucao de aumento de ambiente em caso de necessidade.
if [ $CONFIG_STAGE -gt 0 ];
then
echo "Configracao de ambiente STAGE, ja esta no tamanho de STAGE."
else
echo "Existe a necessidade de UPDATE de tamanho de Ambiente de STAGE para STAGE."
# Realizando a troca de tamanho do servidor. 
echo 'Realizando a troca do tamanho do servidor do Ambiente '$ENV_STAGE' para a configuracao '$STAGE_CONFIG'!' | tee /var/log/deploy.log 
eb config $ENV_STAGE --cfg $STAGE_CONFIG --timeout 15
# Realizando o Restart dos servidor web para atualizacao das variaveis de ambiente. 
echo 'Realizando restart do servidor primario para atualizacao das variaveis de ambiente no Ambiente '$ENV_STAGE'.' | tee /var/log/deploy.log 
aws elasticbeanstalk restart-app-server --environment-name $ENV_STAGE

# Tempo para atualizacao de Health do ambiente
sleep 10

# Checando health do Ambiente Stage.
echo "Script esta checando STATUS do ambiente Stage = $ENV_STAGE"

# Contador do health
COUNTER=0

# Variavel de controle de SWAP
READY_TO_SWAP=false

# Aguardando ambiente mover para Green
while [[ $READY_TO_SWAP == false && $COUNTER -lt 5 ]]; do
	echo "Obtendo Status de Stage"
	STATUS_ENV_STAGE=`(eb status $ENV_STAGE | grep Status | cut -d " " -f4)`
	if [ $STATUS_ENV_STAGE == $STATUS_READY ];
		then
		READY_TO_SWAP=true
		else
		sleep 30
		COUNTER=$[$COUNTER+1]
	fi
done

if [ $READY_TO_SWAP != "true" ] ;
then 
echo "Ambiente nao esta em Status $STATUS_READY"
exit
else
echo "Ambiente esta em Status $STATUS_READY" 
fi

echo 'Resize do Ambiente '$ENV_STAGE' para a configuracao '$STAGE_CONFIG' efetuado com Sucesso!' | tee /var/log/deploy.log
fi

else

echo "$APP_PATH pasta nao existe. Favor configurar Aplicacao antes de executar o Script."
exit

fi
