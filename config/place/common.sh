export SPRING_DATASOURCE_URL=jdbc:mysql://mysql:3306/app
export SPRING_DATASOURCE_USERNAME=root
export SPRING_DATASOURCE_PASSWORD=root

export SPRING_RABBITMQ_HOST=rabbitmq
export SPRING_RABBITMQ_PORT=5672
export SPRING_RABBITMQ_USERNAME=root
export SPRING_RABBITMQ_PASSWORD=root

export SENDER_TOPIC_EXCHANGE_NAME="drz-place"
export SENDER_QUEUE_NAME="drz-place"
export SENDER_TOPIC_NAME="place.place.save"
export SENDER_TOPIC_DELETE_NAME="place.place.delete"