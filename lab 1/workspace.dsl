workspace {
    name "Delivery Service"
    description "Сервис доставки посылок (C4 модель)"
    !identifiers hierarchical

    model {
        paymentSystem = softwareSystem "Платежная система"
        smsService = softwareSystem "SMS сервис"
        emailService = softwareSystem "Email сервис"

        sender = person "Отправитель"
        recipient = person "Получатель"
        admin = person "Администратор"

        deliverySystem = softwareSystem "Сервис доставки" {

            database = container "Relational Database" {
                technology "PostgreSQL, JDBC"
            }

            notificationService = container "Notification Service" {
                technology "Java, Spring Boot"
                -> smsService "Отправляет SMS" "HTTPS/REST"
                -> emailService "Отправляет email" "SMTP"
            }

            paymentService = container "Payment Service" {
                technology "Java, Spring Boot"
                -> paymentSystem "Вызывает API платежной системы" "HTTPS/REST"
                -> database "Читает и пишет данные о платежах" "JDBC"
            }

            userService = container "User Service" {
                technology "Java, Spring Boot"
                -> database "Читает и пишет данные пользователей" "JDBC"
                -> notificationService "Уведомления при регистрации" "HTTP/REST"
            }

            parcelService = container "Parcel Service" {
                technology "Java, Spring Boot"
                -> database "Данные о посылках" "JDBC"
                -> userService "Проверка владельца" "HTTP/REST"
            }

            deliveryService = container "Delivery Service" {
                technology "Java, Spring Boot"
                -> database "Данные о доставках" "JDBC"
                -> userService "Проверка отправителя и получателя" "HTTP/REST"
                -> parcelService "Привязка посылок" "HTTP/REST"
                -> notificationService "Уведомление получателя" "HTTP/REST"
                -> paymentService "Оплата доставки" "HTTP/REST"
            }

            apiGateway = container "API Gateway" {
                technology "Java, Spring Boot, REST API"
                -> userService "Пользователи (регистрация, поиск)" "HTTP/REST"
                -> parcelService "Посылки" "HTTP/REST"
                -> deliveryService "Доставки" "HTTP/REST"
            }

            clientWeb = container "Client Web App" {
                technology "React SPA, TypeScript, HTML/CSS"
            }

            adminWeb = container "Admin Web App" {
                technology "React SPA, TypeScript, HTML/CSS"
            }
        }

        sender -> deliverySystem "Посылки и доставки" "HTTPS/REST"
        recipient -> deliverySystem "Входящие доставки" "HTTPS/REST"
        admin -> deliverySystem "Управление и мониторинг" "HTTPS/REST"
        deliverySystem -> paymentSystem "Оплата доставок" "HTTPS/REST"
        deliverySystem -> smsService "SMS-уведомления" "HTTPS/REST"
        deliverySystem -> emailService "Email-уведомления" "SMTP"

        sender -> deliverySystem.clientWeb "Клиентское приложение" "HTTP/HTTPS"
        recipient -> deliverySystem.clientWeb "Клиентское приложение" "HTTP/HTTPS"
        admin -> deliverySystem.adminWeb "Админ-интерфейс" "HTTPS"
        deliverySystem.clientWeb -> deliverySystem.apiGateway "REST API" "HTTPS/REST"
        deliverySystem.adminWeb -> deliverySystem.apiGateway "REST API" "HTTPS/REST"
    }

    views {
        themes default

        systemContext deliverySystem "system_context" {
            include *
            autoLayout
        }

        container deliverySystem "containers" {
            include *
            autoLayout lr
        }

        dynamic deliverySystem "create_delivery" "От отправителя к получателю" {
            autoLayout lr
            sender -> deliverySystem.clientWeb "Создаёт доставку"
            deliverySystem.clientWeb -> deliverySystem.apiGateway "POST /deliveries"
            deliverySystem.apiGateway -> deliverySystem.deliveryService "Создать доставку"
            deliverySystem.deliveryService -> deliverySystem.userService "Проверить отправителя и получателя"
            deliverySystem.deliveryService -> deliverySystem.parcelService "Привязать посылки"
            deliverySystem.deliveryService -> deliverySystem.paymentService "Оплата"
            deliverySystem.paymentService -> paymentSystem "API платежей"
            paymentSystem -> deliverySystem.paymentService "Результат"
            deliverySystem.paymentService -> deliverySystem.deliveryService "Подтверждение"
            deliverySystem.deliveryService -> deliverySystem.database "Сохранить доставку"
            deliverySystem.deliveryService -> deliverySystem.notificationService "Уведомить получателя"
            deliverySystem.notificationService -> emailService "Email"
            deliverySystem.deliveryService -> deliverySystem.apiGateway "Ответ"
            deliverySystem.apiGateway -> deliverySystem.clientWeb "201 Created"
        }
    }
}
