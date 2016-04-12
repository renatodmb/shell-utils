#!/bin/bash

#################################
##### VARIAVEIS DE AMBIENTE #####
#################################

# Nome da pasta a fazer o pull da aplicacao
APP_PATH='Portal-cron'

# Branch da aplicacao no GIT
APP_BRANCH='crontab'

# URL de checagem do ambiente stage
URL_CRON='personare-portal-cron.elasticbeanstalk.com'

# Nome do Ambiente CRON
ENV_CRON='personare-portal-cron'

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

# Checando status do Ambiente.
echo "Script esta checando STATUS dos ambientes Cron = $ENV_CRON"

# Obtendo status dos Ambientes.
STATUS_ENV_CRON=`(eb status $ENV_CRON | grep Status | cut -d " " -f4)`

# Checando se STATUS dos ambientes estao como READY, Caso nao estajam script sera paralizado.
if [ $STATUS_ENV_CRON != $STATUS_READY ] ;
then
echo "Ambiente $ENV_CRON nao esta em estado $STATUS_READY. Execute novamente quando $ENV_CRON estivere com Status: $STATUS_READY."
exit
else 
echo "Ambiente $ENV_CRON esta em estado $STATUS_READY"
fi

# Checando health dos Ambientes.
echo "Script esta checando HEALTH do ambiente Cron = $ENV_CRON"

# Obtendo healt dos Ambientes.
HEALTH_ENV_CRON=`(eb status $ENV_CRON | grep Health | cut -d " " -f4)`

# Checando se HEALTH dos ambientes CRON estao como GREEN, Caso nao estajam script sera paralizado.
if [[ $HEALTH_ENV_CRON != "$STATUS_GREEN" ]] ;
then
echo "Ambiente $ENV_CRON nao esta em estado $STATUS_GREEN. Execute novamente quando o Health estiver: $STATUS_GREEN."
exit
else 
echo "Ambiente $ENV_CRON esta em health $STATUS_GREEN"
fi

# Efetuando atualização do código através do repositório
git pull origin $APP_BRANCH

while true; do
    read -p 'Voce tem certeza que deseja atualizar o ambiente Cron?' yn
    case $yn in
        [Yy]* ) echo 'Realizando deploy em Cron!' | tee /var/log/deploy.log; aws cloudwatch put-metric-data --metric-name Deploy --namespace DeployServer --statistic-values Sum=1,Minimum=0,Maximum=1,SampleCount=1 --unit Count; eb deploy $ENV_CRON; break;;
        [Nn]* ) exit;;
        * ) echo "Por favor, responda yes ou no.";;
    esac
done

# Entregando URL de CRON.
echo 'Ambiente atualizado com sucesso! Para testar acesse: http://'$URL_CRON | tee /var/log/deploy.log

else

echo "$APP_PATH pasta nao existe. Favor configurar Aplicacao antes de executar o Script."
exit

fi
