package com.juyan.barracks.service;

import com.juyan.barracks.dto.FecalSensorMessage;
import com.juyan.barracks.dto.NutritionSensorMessage;
import com.juyan.barracks.entity.Barracks;
import com.juyan.barracks.entity.FecalSensorData;
import com.juyan.barracks.entity.NutritionSensorData;
import com.juyan.barracks.entity.Soldier;
import com.juyan.barracks.repository.BarracksRepository;
import com.juyan.barracks.repository.FecalSensorDataRepository;
import com.juyan.barracks.repository.NutritionSensorDataRepository;
import com.juyan.barracks.repository.SoldierRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Slf4j
@Service
@RequiredArgsConstructor
public class SensorDataService {

    private final NutritionSensorDataRepository nutritionSensorDataRepository;
    private final FecalSensorDataRepository fecalSensorDataRepository;
    private final BarracksRepository barracksRepository;
    private final SoldierRepository soldierRepository;

    public NutritionSensorData saveNutritionData(NutritionSensorMessage message) {
        NutritionSensorData data = new NutritionSensorData();
        data.setSensorId(message.getSensorId());

        Optional<Barracks> barracks = barracksRepository.findByCode(message.getBarracksCode());
        barracks.ifPresent(b -> data.setBarracksId(b.getId()));

        if (message.getSoldierCode() != null) {
            Optional<Soldier> soldier = soldierRepository.findBySoldierCode(message.getSoldierCode());
            soldier.ifPresent(s -> data.setSoldierId(s.getId()));
        }

        data.setProteinG(message.getProteinG());
        data.setFatG(message.getFatG());
        data.setVitaminCMg(message.getVitaminCMg());
        data.setSampleTime(message.getSampleTime() != null ? message.getSampleTime() : LocalDateTime.now());

        log.debug("保存营养传感器数据: sensorId={}, protein={}, fat={}, vitaminC={}",
                message.getSensorId(), message.getProteinG(), message.getFatG(), message.getVitaminCMg());

        return nutritionSensorDataRepository.save(data);
    }

    public FecalSensorData saveFecalData(FecalSensorMessage message) {
        FecalSensorData data = new FecalSensorData();
        data.setSensorId(message.getSensorId());

        Optional<Barracks> barracks = barracksRepository.findByCode(message.getBarracksCode());
        barracks.ifPresent(b -> data.setBarracksId(b.getId()));

        if (message.getSoldierCode() != null) {
            Optional<Soldier> soldier = soldierRepository.findBySoldierCode(message.getSoldierCode());
            soldier.ifPresent(s -> data.setSoldierId(s.getId()));
        }

        data.setIsPositive(message.getIsPositive());
        data.setSampleTime(message.getSampleTime() != null ? message.getSampleTime() : LocalDateTime.now());

        log.debug("保存粪便隐血传感器数据: sensorId={}, isPositive={}",
                message.getSensorId(), message.getIsPositive());

        return fecalSensorDataRepository.save(data);
    }

    public List<NutritionSensorData> findNutritionByBarracksAndTime(Long barracksId, LocalDateTime startTime, LocalDateTime endTime) {
        return nutritionSensorDataRepository.findByBarracksIdAndSampleTimeBetween(barracksId, startTime, endTime);
    }

    public List<FecalSensorData> findFecalByBarracksAndTime(Long barracksId, LocalDateTime startTime, LocalDateTime endTime) {
        return fecalSensorDataRepository.findByBarracksIdAndSampleTimeBetween(barracksId, startTime, endTime);
    }

    public Long countFecalByBarracksAndTime(Long barracksId, LocalDateTime startTime, LocalDateTime endTime) {
        return fecalSensorDataRepository.countByBarracksIdAndSampleTimeBetween(barracksId, startTime, endTime);
    }

    public Long countPositiveFecalByBarracksAndTime(Long barracksId, LocalDateTime startTime, LocalDateTime endTime) {
        return fecalSensorDataRepository.countPositiveByBarracksIdAndSampleTimeBetween(barracksId, startTime, endTime);
    }
}
