. (Join-Path (pwd) common.ps1)
cd "C:\Program Files\RabbitMQ Server\rabbitmq_server-$v\sbin"

# the followin line  need to run on all nodes
.\rabbitmq-service restart