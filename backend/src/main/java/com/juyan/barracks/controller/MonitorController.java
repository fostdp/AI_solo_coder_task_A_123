package com.juyan.barracks.controller;

import com.juyan.barracks.dto.SoldierWithRiskDTO;
import com.juyan.barracks.entity.Barracks;
import com.juyan.barracks.entity.EpidemicAlert;
import com.juyan.barracks.entity.NutritionRisk;
import com.juyan.barracks.entity.Soldier;
import com.juyan.barracks.service.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@Slf4j
@RestController
@RequestMapping("/v1")
@RequiredArgsConstructor
public class MonitorController {

    private final BarracksService barracksService;
    private final SoldierService soldierService;
    private final NutritionPredictionService nutritionPredictionService;
    private final EpidemicDetectionService epidemicDetectionService;
    private final SensorDataService sensorDataService;

    @GetMapping("/barracks")
    public ResponseEntity<List<Barracks>> getAllBarracks() {
        return ResponseEntity.ok(barracksService.findAll());
    }

    @GetMapping("/barracks/{id}")
    public ResponseEntity<Barracks> getBarracksById(@PathVariable Long id) {
        Optional<Barracks> barracks = barracksService.findById(id);
        return barracks.map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/barracks/{id}/soldiers")
    public ResponseEntity<List<Soldier>> getSoldiersByBarracks(@PathVariable Long id) {
        return ResponseEntity.ok(soldierService.findByBarracksId(id));
    }

    @GetMapping("/barracks/{id}/soldiers/with-risk")
    public ResponseEntity<List<SoldierWithRiskDTO>> getSoldiersWithRiskByBarracks(@PathVariable Long id) {
        return ResponseEntity.ok(soldierService.findByBarracksIdWithRisk(id));
    }

    @GetMapping("/barracks/{id}/infection-stats")
    public ResponseEntity<Map<String, Object>> getBarracksInfectionStats(@PathVariable Long id) {
        return ResponseEntity.ok(epidemicDetectionService.getBarracksInfectionStats(id));
    }

    @GetMapping("/soldiers")
    public ResponseEntity<List<Soldier>> getAllSoldiers() {
        return ResponseEntity.ok(soldierService.findAll());
    }

    @GetMapping("/soldiers/with-risk")
    public ResponseEntity<List<SoldierWithRiskDTO>> getAllSoldiersWithRisk() {
        return ResponseEntity.ok(soldierService.findAllWithRisk());
    }

    @GetMapping("/soldiers/{id}")
    public ResponseEntity<Soldier> getSoldierById(@PathVariable Long id) {
        Optional<Soldier> soldier = soldierService.findById(id);
        return soldier.map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/soldiers/{id}/nutrition-risk")
    public ResponseEntity<NutritionRisk> getSoldierNutritionRisk(@PathVariable Long id) {
        Optional<NutritionRisk> risk = nutritionPredictionService.getCurrentRiskForSoldier(id);
        return risk.map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/nutrition-risks")
    public ResponseEntity<List<NutritionRisk>> getAllCurrentNutritionRisks() {
        return ResponseEntity.ok(nutritionPredictionService.getAllCurrentRisks());
    }

    @PostMapping("/nutrition-prediction/run")
    public ResponseEntity<Map<String, Object>> runNutritionPrediction() {
        nutritionPredictionService.runNutritionPrediction();
        Map<String, Object> result = new HashMap<>();
        result.put("status", "success");
        result.put("message", "营养预测任务已执行");
        return ResponseEntity.ok(result);
    }

    @GetMapping("/epidemic-alerts")
    public ResponseEntity<List<EpidemicAlert>> getEpidemicAlerts(
            @RequestParam(required = false) String status) {
        if (status != null && !status.isEmpty()) {
            return ResponseEntity.ok(epidemicDetectionService.getActiveAlerts());
        }
        return ResponseEntity.ok(epidemicDetectionService.getActiveAlerts());
    }

    @GetMapping("/barracks/{id}/epidemic-alerts")
    public ResponseEntity<List<EpidemicAlert>> getEpidemicAlertsByBarracks(@PathVariable Long id) {
        return ResponseEntity.ok(epidemicDetectionService.getAlertsByBarracks(id));
    }

    @PostMapping("/epidemic-scan/run")
    public ResponseEntity<Map<String, Object>> runEpidemicScan() {
        epidemicDetectionService.runEpidemicScan();
        Map<String, Object> result = new HashMap<>();
        result.put("status", "success");
        result.put("message", "疫情扫描任务已执行");
        return ResponseEntity.ok(result);
    }

    @GetMapping("/dashboard/summary")
    public ResponseEntity<Map<String, Object>> getDashboardSummary() {
        Map<String, Object> summary = new HashMap<>();

        List<Barracks> barracksList = barracksService.findAll();
        List<SoldierWithRiskDTO> soldiers = soldierService.findAllWithRisk();
        List<NutritionRisk> highRisks = nutritionPredictionService.getAllCurrentRisks().stream()
                .filter(r -> "HIGH".equals(r.getRiskLevel()) || "CRITICAL".equals(r.getRiskLevel()))
                .toList();
        List<EpidemicAlert> activeAlerts = epidemicDetectionService.getActiveAlerts();

        long lowRisk = soldiers.stream().filter(s -> "LOW".equals(s.getRiskLevel())).count();
        long mediumRisk = soldiers.stream().filter(s -> "MEDIUM".equals(s.getRiskLevel())).count();
        long highRisk = soldiers.stream().filter(s -> "HIGH".equals(s.getRiskLevel())).count();
        long criticalRisk = soldiers.stream().filter(s -> "CRITICAL".equals(s.getRiskLevel())).count();

        summary.put("totalBarracks", barracksList.size());
        summary.put("totalSoldiers", soldiers.size());
        summary.put("nutritionRiskStats", Map.of(
                "LOW", lowRisk,
                "MEDIUM", mediumRisk,
                "HIGH", highRisk,
                "CRITICAL", criticalRisk
        ));
        summary.put("highRiskCount", highRisks.size());
        summary.put("activeEpidemicAlerts", activeAlerts.size());
        summary.put("timestamp", System.currentTimeMillis());

        return ResponseEntity.ok(summary);
    }
}
