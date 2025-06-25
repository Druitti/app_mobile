package com.logistics.tracking.config;

import org.springframework.amqp.core.*;
import org.springframework.amqp.rabbit.connection.ConnectionFactory;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.amqp.support.converter.Jackson2JsonMessageConverter;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class RabbitConfig {
    
    @Bean
    public TopicExchange trackingExchange() {
        return new TopicExchange("tracking.exchange");
    }
    
    @Bean
    public Queue locationUpdatedQueue() {
        return QueueBuilder.durable("location.updated.queue").build();
    }
    
    @Bean
    public Queue deliveryCompletedQueue() {
        return QueueBuilder.durable("delivery.completed.queue").build();
    }
    
    @Bean
    public Binding locationUpdatedBinding() {
        return BindingBuilder
                .bind(locationUpdatedQueue())
                .to(trackingExchange())
                .with("location.updated");
    }
    
    @Bean
    public Binding deliveryCompletedBinding() {
        return BindingBuilder
                .bind(deliveryCompletedQueue())
                .to(trackingExchange())
                .with("delivery.completed");
    }
    
    @Bean
    public Jackson2JsonMessageConverter messageConverter() {
        return new Jackson2JsonMessageConverter();
    }
    
    @Bean
    public RabbitTemplate rabbitTemplate(ConnectionFactory connectionFactory) {
        RabbitTemplate template = new RabbitTemplate(connectionFactory);
        template.setMessageConverter(messageConverter());
        return template;
    }
}