"""
古代兵营士兵膳食营养监测与疫病预警系统 - MQTT传感器数据模拟器

模拟设备:
- 营养分析仪: 15台（检测蛋白质、脂肪、维生素C）
- 粪便隐血传感器: 10台（监测肠道感染）

上报频率: 每2小时
"""

import json
import random
import time
import math
from datetime import datetime, timedelta
from typing import Dict, List, Optional

try:
    import paho.mqtt.client as mqtt
except ImportError:
    print("请先安装paho-mqtt: pip install paho-mqtt")
    raise


class BarracksConfig:
    BARRACKS_CODES = [
        "BARRACKS_001",
        "BARRACKS_002",
        "BARRACKS_003",
        "BARRACKS_004",
        "BARRACKS_005",
    ]

    SOLDIER_CODES_PER_BARRACKS = {
        "BARRACKS_001": [f"S001_{str(i).zfill(3)}" for i in range(1, 51)],
        "BARRACKS_002": [f"S002_{str(i).zfill(3)}" for i in range(1, 41)],
        "BARRACKS_003": [f"S003_{str(i).zfill(3)}" for i in range(1, 46)],
        "BARRACKS_004": [f"S004_{str(i).zfill(3)}" for i in range(1, 36)],
        "BARRACKS_005": [f"S005_{str(i).zfill(3)}" for i in range(1, 31)],
    }


class NutritionSensorSimulator:
    def __init__(self, num_sensors: int = 15):
        self.num_sensors = num_sensors
        self.sensor_ids = [f"NUT-S{str(i).zfill(3)}" for i in range(1, num_sensors + 1)]
        self.barracks_distribution = self._distribute_sensors()

    def _distribute_sensors(self) -> Dict[str, List[str]]:
        distribution = {}
        barracks = BarracksConfig.BARRACKS_CODES
        for i, sensor_id in enumerate(self.sensor_ids):
            barracks_code = barracks[i % len(barracks)]
            if barracks_code not in distribution:
                distribution[barracks_code] = []
            distribution[barracks_code].append(sensor_id)
        return distribution

    def generate_reading(self, sensor_id: str, barracks_code: str, simulate_abnormal: bool = False):
        soldier_codes = BarracksConfig.SOLDIER_CODES_PER_BARRACKS.get(barracks_code, [])
        soldier_code = random.choice(soldier_codes) if soldier_codes else None

        if simulate_abnormal:
            protein_g = round(random.uniform(5, 25), 2)
            fat_g = round(random.uniform(3, 15), 2)
            vitamin_c_mg = round(random.uniform(5, 45), 2)
        else:
            protein_g = round(random.uniform(20, 55), 2)
            fat_g = round(random.uniform(15, 45), 2)
            vitamin_c_mg = round(random.uniform(40, 120), 2)

        if barracks_code == "BARRACKS_003" and random.random() < 0.35:
            vitamin_c_mg = round(random.uniform(10, 50), 2)
            protein_g = round(random.uniform(10, 35), 2)

        return {
            "sensorId": sensor_id,
            "barracksCode": barracks_code,
            "soldierCode": soldier_code,
            "proteinG": protein_g,
            "fatG": fat_g,
            "vitaminCMg": vitamin_c_mg,
            "sampleTime": datetime.now().isoformat()
        }

    def generate_all_readings(self, abnormal_barracks: Optional[str] = None):
        readings = []
        for barracks_code, sensors in self.barracks_distribution.items():
            for sensor_id in sensors:
                is_abnormal = (abnormal_barracks is not None and
                               barracks_code == abnormal_barracks and
                               random.random() < 0.7)
                reading = self.generate_reading(sensor_id, barracks_code, is_abnormal)
                readings.append((barracks_code, reading))
        return readings


class FecalSensorSimulator:
    def __init__(self, num_sensors: int = 10):
        self.num_sensors = num_sensors
        self.sensor_ids = [f"FEC-S{str(i).zfill(3)}" for i in range(1, num_sensors + 1)]
        self.barracks_distribution = self._distribute_sensors()

    def _distribute_sensors(self) -> Dict[str, List[str]]:
        distribution = {}
        barracks = BarracksConfig.BARRACKS_CODES
        for i, sensor_id in enumerate(self.sensor_ids):
            barracks_code = barracks[i % len(barracks)]
            if barracks_code not in distribution:
                distribution[barracks_code] = []
            distribution[barracks_code].append(sensor_id)
        return distribution

    def generate_reading(self, sensor_id: str, barracks_code: str, outbreak_mode: bool = False):
        soldier_codes = BarracksConfig.SOLDIER_CODES_PER_BARRACKS.get(barracks_code, [])
        soldier_code = random.choice(soldier_codes) if soldier_codes else None

        if outbreak_mode:
            is_positive = random.random() < 0.55
        else:
            is_positive = random.random() < 0.05

        if barracks_code == "BARRACKS_001":
            is_positive = random.random() < 0.30

        return {
            "sensorId": sensor_id,
            "barracksCode": barracks_code,
            "soldierCode": soldier_code,
            "isPositive": is_positive,
            "sampleTime": datetime.now().isoformat()
        }

    def generate_all_readings(self, outbreak_barracks: Optional[str] = None):
        readings = []
        for barracks_code, sensors in self.barracks_distribution.items():
            for sensor_id in sensors:
                is_outbreak = (outbreak_barracks is not None and
                               barracks_code == outbreak_barracks)
                reading = self.generate_reading(sensor_id, barracks_code, is_outbreak)
                readings.append((barracks_code, reading))
        return readings


class MqttSimulator:
    def __init__(self, broker_host: str = "localhost", broker_port: int = 1883,
                 username: str = "admin", password: str = "public"):
        self.broker_host = broker_host
        self.broker_port = broker_port
        self.username = username
        self.password = password

        self.client = mqtt.Client(
            client_id=f"barracks-simulator-{random.randint(1000, 9999)}",
            clean_session=True
        )
        self.client.username_pw_set(username, password)
        self.client.on_connect = self._on_connect
        self.client.on_disconnect = self._on_disconnect
        self.client.on_publish = self._on_publish

        self.nutrition_sim = NutritionSensorSimulator(num_sensors=15)
        self.fecal_sim = FecalSensorSimulator(num_sensors=10)

        self.message_count = 0
        self.connected = False

    def _on_connect(self, client, userdata, flags, rc):
        if rc == 0:
            self.connected = True
            print(f"✅ 已连接到MQTT Broker: {self.broker_host}:{self.broker_port}")
        else:
            print(f"❌ MQTT连接失败, 返回码: {rc}")

    def _on_disconnect(self, client, userdata, rc):
        self.connected = False
        if rc != 0:
            print(f"⚠️  MQTT连接意外断开, 返回码: {rc}")

    def _on_publish(self, client, userdata, mid):
        self.message_count += 1

    def connect(self):
        try:
            self.client.connect(self.broker_host, self.broker_port, keepalive=60)
            self.client.loop_start()
            time.sleep(1)
            return self.connected
        except Exception as e:
            print(f"连接MQTT Broker失败: {e}")
            return False

    def disconnect(self):
        self.client.loop_stop()
        self.client.disconnect()
        print(f"\n📊 总共发送 {self.message_count} 条消息")

    def publish_nutrition_data(self, abnormal_barracks: Optional[str] = None):
        readings = self.nutrition_sim.generate_all_readings(abnormal_barracks)
        published = 0

        for barracks_code, reading in readings:
            topic = f"barracks/{barracks_code}/nutrition"
            payload = json.dumps(reading, ensure_ascii=False)
            result = self.client.publish(topic, payload, qos=1)
            if result.rc == mqtt.MQTT_ERR_SUCCESS:
                published += 1

        print(f"  🍎 营养数据: {published}/{len(readings)} 条已发布 "
              f"(异常兵营: {abnormal_barracks or '无'})")

    def publish_fecal_data(self, outbreak_barracks: Optional[str] = None):
        readings = self.fecal_sim.generate_all_readings(outbreak_barracks)
        published = 0
        positive_count = 0

        for barracks_code, reading in readings:
            topic = f"barracks/{barracks_code}/fecal"
            payload = json.dumps(reading, ensure_ascii=False)
            result = self.client.publish(topic, payload, qos=1)
            if result.rc == mqtt.MQTT_ERR_SUCCESS:
                published += 1
            if reading.get("isPositive"):
                positive_count += 1

        print(f"  💩 粪便检测: {published}/{len(readings)} 条已发布 "
              f"(阳性: {positive_count}, 暴发兵营: {outbreak_barracks or '无'})")

    def run_cycle(self, cycle_num: int, simulate_events: bool = True):
        print(f"\n━━━ 上报周期 #{cycle_num} | {datetime.now().strftime('%Y-%m-%d %H:%M:%S')} ━━━")

        abnormal_barracks = None
        outbreak_barracks = None

        if simulate_events:
            if cycle_num % 5 == 0:
                abnormal_barracks = "BARRACKS_003"
                print("  ⚠️  模拟事件: 第三兵营营养摄入不足")

            if cycle_num % 4 == 0:
                outbreak_barracks = "BARRACKS_005"
                print("  ⚠️  模拟事件: 第五兵营肠道感染暴发")

        self.publish_nutrition_data(abnormal_barracks)
        self.publish_fecal_data(outbreak_barracks)

        print(f"  📈 累计发送: {self.message_count} 条")


def run_continuous(broker_host: str = "localhost", broker_port: int = 1883,
                   interval_seconds: int = 7200, num_cycles: int = 0):
    """
    持续运行模拟器

    Args:
        broker_host: MQTT Broker地址
        broker_port: MQTT Broker端口
        interval_seconds: 上报间隔（秒），默认7200秒=2小时
        num_cycles: 运行周期数，0表示无限
    """
    print("=" * 60)
    print("🏯 古代兵营士兵膳食营养监测与疫病预警系统")
    print("   MQTT传感器数据模拟器")
    print("=" * 60)
    print(f"  Broker: {broker_host}:{broker_port}")
    print(f"  上报间隔: {interval_seconds}秒 ({interval_seconds / 3600:.1f}小时)")
    print(f"  营养分析仪: 15台")
    print(f"  粪便隐血传感器: 10台")
    print(f"  监测兵营: 5座")
    print("=" * 60)

    simulator = MqttSimulator(broker_host, broker_port)
    if not simulator.connect():
        print("\n❌ 无法连接到MQTT Broker，请确认:")
        print("   1. Mosquitto或其他MQTT Broker已启动")
        print("   2. 地址和端口正确")
        print("   3. 用户名密码正确")
        return

    cycle = 0
    try:
        while True:
            cycle += 1
            simulator.run_cycle(cycle, simulate_events=True)

            if num_cycles > 0 and cycle >= num_cycles:
                print(f"\n✅ 已完成 {num_cycles} 个周期，模拟器退出")
                break

            print(f"\n  ⏳ 等待 {interval_seconds} 秒后进行下一次上报... (Ctrl+C 退出)")
            time.sleep(interval_seconds)

    except KeyboardInterrupt:
        print(f"\n\n⏹️  用户中断，模拟器停止")
    finally:
        simulator.disconnect()


def run_single_shot(broker_host: str = "localhost", broker_port: int = 1883):
    """单次快速测试，发送一批数据"""
    print("🚀 单次快速上报测试模式")
    simulator = MqttSimulator(broker_host, broker_port)
    if not simulator.connect():
        return

    for i in range(1, 4):
        simulator.run_cycle(i, simulate_events=True)
        time.sleep(2)

    simulator.disconnect()
    print("\n✅ 快速测试完成")


def run_historical(broker_host: str = "localhost", broker_port: int = 1883, days: int = 7):
    """
    生成历史数据

    Args:
        days: 生成最近多少天的历史数据
    """
    print(f"📜 生成最近 {days} 天的历史模拟数据...")

    simulator = MqttSimulator(broker_host, broker_port)
    if not simulator.connect():
        return

    original_now = datetime.now()
    total_cycles = days * 12
    print(f"  共需发送 {total_cycles} 个周期（每2小时一次）")

    try:
        for cycle in range(1, total_cycles + 1):
            hours_ago = total_cycles * 2 - cycle * 2
            simulated_time = original_now - timedelta(hours=hours_ago)

            print(f"\n  [{cycle}/{total_cycles}] {simulated_time.strftime('%Y-%m-%d %H:%M')}")

            readings_nutrition = simulator.nutrition_sim.generate_all_readings()
            for barracks_code, reading in readings_nutrition:
                reading["sampleTime"] = simulated_time.isoformat()
                topic = f"barracks/{barracks_code}/nutrition"
                payload = json.dumps(reading, ensure_ascii=False)
                simulator.client.publish(topic, payload, qos=1)

            readings_fecal = simulator.fecal_sim.generate_all_readings()
            for barracks_code, reading in readings_fecal:
                reading["sampleTime"] = simulated_time.isoformat()
                topic = f"barracks/{barracks_code}/fecal"
                payload = json.dumps(reading, ensure_ascii=False)
                simulator.client.publish(topic, payload, qos=1)

            if cycle % 12 == 0:
                print(f"  ✅ 已完成 {cycle // 12}/{days} 天")
            time.sleep(0.3)

    except KeyboardInterrupt:
        print("\n⏹️  已中断")
    finally:
        simulator.disconnect()
        print("\n✅ 历史数据生成完成")


if __name__ == "__main__":
    import sys

    mode = "continuous"
    if len(sys.argv) > 1:
        mode = sys.argv[1]

    host = "localhost"
    port = 1883
    if len(sys.argv) > 2:
        host = sys.argv[2]
    if len(sys.argv) > 3:
        port = int(sys.argv[3])

    if mode == "single":
        run_single_shot(host, port)
    elif mode == "historical":
        days = int(sys.argv[4]) if len(sys.argv) > 4 else 7
        run_historical(host, port, days)
    else:
        interval = 60
        if len(sys.argv) > 4:
            interval = int(sys.argv[4])
        run_continuous(host, port, interval_seconds=interval)
