package com.juyan.barracks.mqtt;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import com.juyan.barracks.dto.FecalSensorMessage;
import com.juyan.barracks.dto.NutritionSensorMessage;
import com.juyan.barracks.service.SensorDataService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.integration.annotation.ServiceActivator;
import org.springframework.messaging.Message;
import org.springframework.stereotype.Component;

@Slf4j
@Component
@RequiredArgsConstructor
public class MqttMessageHandler {

    private final SensorDataService sensorDataService;
    private final ObjectMapper objectMapper = new ObjectMapper().registerModule(new JavaTimeModule());

    @ServiceActivator(inputChannel = "mqttInputChannel")
    public void handleMessage(Message<String> message) {
        String topic = (String) message.getHeaders().get("mqtt_receivedTopic");
        String payload = message.getPayload();

        log.info("收到MQTT消息 - Topic: {}, Payload: {}", topic, payload);

        try {
            if (topic != null && topic.contains("nutrition")) {
                NutritionSensorMessage nutritionMessage = objectMapper.readValue(payload, NutritionSensorMessage.class);
                sensorDataService.saveNutritionData(nutritionMessage);
                log.info("营养数据已保存: sensorId={}", nutritionMessage.getSensorId());
            } else if (topic != null && topic.contains("fecal")) {
                FecalSensorMessage fecalMessage = objectMapper.readValue(payload, FecalSensorMessage.class);
                sensorDataService.saveFecalData(fecalMessage);
                log.info("粪便隐血数据已保存: sensorId={}, isPositive={}", fecalMessage.getSensorId(), fecalMessage.getIsPositive());
            } else {
                log.warn("未知的MQTT主题: {}", topic);
            }
        } catch (Exception e) {
            log.error("处理MQTT消息失败 - Topic: {}, Error: {}", topic, e.getMessage(), e);
        }
    }
}
