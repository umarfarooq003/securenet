import mesa
import pandas as pd
import numpy as np

import networkx as nx
from enum import Enum
import time
import threading
import os
import ast
import json

class DeviceType(Enum):
    ENDPOINT = "Endpoint"
    ACCESS_POINT = "AccessPoint"
    ROUTER = "Router"
    SWITCH = "Switch"
    AGGREGATION_SWITCH = "AggregationSwitch"
    FIREWALL = "Firewall"
    SERVER = "Server"
    ISP = "ISP"

class NetworkDevice(mesa.Agent):
    def __init__(self, unique_id, model, device_type, name, ip, security_level=0.5):
        # Mesa 3.x: Agent.__init__ only takes the model; unique_id is set separately
        try:
            super().__init__(unique_id, model)  # Mesa 2.x
        except TypeError:
            super().__init__(model)             # Mesa 3.x
            self.unique_id = unique_id
        self.device_type = device_type
        self.name = name
        self.ip = ip
        self.infected = False
        self.security_level = security_level
        self.connections = []
        self.infection_time = None
        self.newly_infected = False
        self.recovery_attempts = 0
        self.max_recovery_attempts = 3
        self.has_resistance = False  # Track if device gained resistance
        
    def step(self):
        self.newly_infected = False
        
        # If device is infected, try to spread virus and potentially recover
        if self.infected:
            self.spread_infection()
            self.attempt_recovery()
            
        # Apply virus check frequency (chance to detect and block infection attempts)
        if not self.infected and self.random.random() < self.model.virus_check_frequency:
            self.attempt_virus_detection()
            
        # Chance to gain resistance after recovering or resisting infection
        if not self.has_resistance and self.random.random() < self.model.gain_resistance_chance:
            self.gain_resistance()
    
    def spread_infection(self):
        """Spread infection to connected devices based on virus-spread-chance"""
        for connected_device in self.connections:
            if not connected_device.infected:
                base_infection_prob = {
                    DeviceType.ENDPOINT: 0.7,
                    DeviceType.ACCESS_POINT: 0.6,
                    DeviceType.SWITCH: 0.5,
                    DeviceType.AGGREGATION_SWITCH: 0.4,
                    DeviceType.ROUTER: 0.5,
                    DeviceType.SERVER: 0.8,
                    DeviceType.FIREWALL: 0.3,
                    DeviceType.ISP: 0.2
                }.get(self.device_type, 0.5)
                
                target_resistance = connected_device.security_level
                
                # Apply resistance boost if device has gained resistance
                if connected_device.has_resistance:
                    target_resistance *= 2.0  # Double the resistance effectiveness
                
                if connected_device.device_type in [DeviceType.FIREWALL, DeviceType.AGGREGATION_SWITCH]:
                    target_resistance *= 1.8
                elif connected_device.device_type == DeviceType.ROUTER:
                    target_resistance *= 1.4
                
                # Apply virus-spread-chance parameter (0% to 100%)
                infection_prob = base_infection_prob * (1 - min(target_resistance, 0.95)) * self.model.virus_spread_chance
                
                # Reduce infection probability if target recently performed virus check
                if self.model.virus_check_frequency > 0:
                    recent_check_boost = connected_device.model.virus_check_frequency * 0.5
                    infection_prob *= (1 - recent_check_boost)
                
                if self.random.random() < infection_prob:
                    connected_device.infected = True
                    connected_device.infection_time = self.model.schedule.time
                    connected_device.newly_infected = True
                    self.model.new_infections_this_step.append((self.unique_id, connected_device.unique_id))
    
    def attempt_recovery(self):
        """Attempt to recover from infection based on recovery-chance (0% to 100%)"""
        if self.infected and self.infection_time is not None:
            # Devices can only start recovery attempts after being infected for at least 2 steps
            if self.model.schedule.time - self.infection_time >= 2:
                recovery_prob = self.model.recovery_chance
                
                # Adjust recovery probability based on device type
                recovery_multiplier = {
                    DeviceType.ENDPOINT: 0.8,
                    DeviceType.ACCESS_POINT: 0.9,
                    DeviceType.SWITCH: 1.0,
                    DeviceType.AGGREGATION_SWITCH: 1.2,
                    DeviceType.ROUTER: 1.1,
                    DeviceType.SERVER: 0.7,
                    DeviceType.FIREWALL: 1.5,
                    DeviceType.ISP: 1.3
                }.get(self.device_type, 1.0)
                
                recovery_prob *= recovery_multiplier
                
                # Increase recovery chance with each attempt (up to 2x boost)
                recovery_prob *= (1 + min(self.recovery_attempts * 0.2, 1.0))
                
                # Ensure probability doesn't exceed 100%
                recovery_prob = min(recovery_prob, 1.0)
                
                if self.random.random() < recovery_prob:
                    self.infected = False
                    self.infection_time = None
                    self.recovery_attempts = 0
                    self.model.recovered_devices_this_step.append(self.unique_id)
                    print(f"✅ {self.name} recovered from infection!")
                else:
                    self.recovery_attempts += 1
    
    def attempt_virus_detection(self):
        """Attempt to detect and block virus based on virus check frequency"""
        if not self.infected:
            # Higher security devices are better at detection
            detection_prob = self.security_level * 0.3  # Base detection capability
            
            # Device type modifiers for detection
            detection_multiplier = {
                DeviceType.FIREWALL: 2.0,
                DeviceType.ISP: 1.5,
                DeviceType.AGGREGATION_SWITCH: 1.3,
                DeviceType.ROUTER: 1.2,
                DeviceType.SERVER: 1.1,
                DeviceType.SWITCH: 1.0,
                DeviceType.ACCESS_POINT: 0.8,
                DeviceType.ENDPOINT: 0.6
            }.get(self.device_type, 1.0)
            
            detection_prob *= detection_multiplier
            
            if self.random.random() < detection_prob:
                # Successful detection - temporarily boost security
                self.security_level = min(self.security_level * 1.2, 0.95)
                self.model.successful_detections_this_step.append(self.unique_id)
    
    def gain_resistance(self):
        """Gain permanent resistance to future infections"""
        if not self.has_resistance:
            # Devices that recovered from infection have higher chance
            recovery_boost = 2.0 if self.infection_time is not None and not self.infected else 1.0
            
            # Security level also affects resistance gain
            security_boost = 1.0 + (self.security_level * 0.5)
            
            resistance_prob = self.model.gain_resistance_chance * recovery_boost * security_boost
            
            if self.random.random() < resistance_prob:
                self.has_resistance = True
                self.security_level = min(self.security_level * 1.5, 0.98)  # Permanent security boost
                self.model.new_resistance_this_step.append(self.unique_id)
                print(f"🛡️ {self.name} gained resistance to infections!")
    
    def add_connection(self, device):
        if device not in self.connections:
            self.connections.append(device)


# ── Mesa 3.x compatibility shim ───────────────────────────────────────────────
# Mesa 3.x removed time.RandomActivation. This shim gives the same interface.
class _Mesa3Scheduler:
    """Minimal RandomActivation replacement for Mesa 3.x."""
    def __init__(self, model):
        self._model = model
        self._agents = []
        self.time = 0

    def add(self, agent):
        self._agents.append(agent)

    def step(self):
        import random
        agents = self._agents[:]
        random.shuffle(agents)
        for agent in agents:
            agent.step()
        self.time += 1


class NetworkInfectionModel(mesa.Model):
    def __init__(self, simulation_speed=1.0, infection_probability=0.7, recovery_chance=0.1,
                 virus_spread_chance=1.0, initial_outbreak_size=1, virus_check_frequency=0.05,
                 gain_resistance_chance=0.5):
        super().__init__()
        self.simulation_speed = simulation_speed
        self.infection_probability = infection_probability
        self.recovery_chance = recovery_chance
        self.virus_spread_chance = virus_spread_chance
        self.initial_outbreak_size = initial_outbreak_size
        self.virus_check_frequency = virus_check_frequency
        self.gain_resistance_chance = gain_resistance_chance
        # Mesa 3.x uses AgentSet; Mesa 2.x uses RandomActivation
        try:
            self.schedule = mesa.time.RandomActivation(self)
        except AttributeError:
            self.schedule = _Mesa3Scheduler(self)  # shim defined below
        self.devices = []
        self.new_infections_this_step = []
        self.recovered_devices_this_step = []
        self.successful_detections_this_step = []
        self.new_resistance_this_step = []
        self.running = False
        self.paused = False
        self.step_data = []

        self.network_graph = nx.Graph()
        self.load_network_from_files()
        self.build_network_graph()
        
    def parse_properties(self, properties_str):
        """Parse properties string from CSV"""
        try:
            # Clean the string and parse as JSON
            cleaned = properties_str.replace("'", '"').replace('since:', '"since":').replace('link:', '"link":').replace('purpose:', '"purpose":').replace('provider:', '"provider":').replace('bandwidth:', '"bandwidth":').replace('model:', '"model":').replace('status:', '"status":').replace('role:', '"role":').replace('vendor:', '"vendor":').replace('os:', '"os":').replace('name:', '"name":').replace('AP:', '"AP":').replace('ip:', '"ip":')
            return json.loads(cleaned)
        except:
            # Fallback for simple cases
            return {}

    def load_network_from_files(self):
        """Load network topology from CSV files.

        Actual file contents (confirmed by inspection):
          nodes.csv  → node list   (columns: nodeId, labels, properties)
          edges.csv  → connections (columns: source, target, relType, properties)
        """
        try:
            # Always resolve paths relative to THIS file (messa.py)
            # so it works both locally and on Vercel serverless
            BASE_DIR = os.path.dirname(os.path.abspath(__file__))
            nodes_path = os.path.join(BASE_DIR, 'nodes.csv')
            edges_path = os.path.join(BASE_DIR, 'edges.csv')

            if not os.path.exists(nodes_path):
                raise FileNotFoundError(f"nodes.csv not found at {nodes_path}")
            if not os.path.exists(edges_path):
                raise FileNotFoundError(f"edges.csv not found at {edges_path}")

            devices_df = pd.read_csv(nodes_path)
            connections_df = pd.read_csv(edges_path)
            print(f"Loaded {len(devices_df)} devices from nodes.csv")
            print(f"Loaded {len(connections_df)} connections from edges.csv")

            self.create_network_from_data(devices_df, connections_df)

        except Exception as e:
            print(f"Error loading network files: {e}")
            self.create_fallback_network()
    
    def create_network_from_data(self, devices_df, connections_df):
        """Create network devices and connections from CSV data"""
        # Security levels for different device types
        security_levels = {
            "Endpoint": 0.3,
            "AccessPoint": 0.5,
            "Switch": 0.6,
            "AggregationSwitch": 0.8,
            "Router": 0.7,
            "Firewall": 0.9,
            "Server": 0.4,
            "ISP": 0.8
        }
        
        # Map labels to DeviceType enum
        label_to_device_type = {
            "Endpoint": DeviceType.ENDPOINT,
            "AccessPoint": DeviceType.ACCESS_POINT,
            "Switch": DeviceType.SWITCH,
            "AggregationSwitch": DeviceType.AGGREGATION_SWITCH,
            "Router": DeviceType.ROUTER,
            "Firewall": DeviceType.FIREWALL,
            "Server": DeviceType.SERVER,
            "ISP": DeviceType.ISP
        }
        
        # Create device lookup dictionary
        device_lookup = {}
        
        print("Creating devices from edges.csv:")
        # Create all devices first from edges.csv
        for _, row in devices_df.iterrows():
            node_id = row['nodeId']
            # Parse labels — Neo4j exports them as strings like "[Endpoint]"
            raw_labels = row['labels']
            if isinstance(raw_labels, str):
                try:
                    labels = ast.literal_eval(raw_labels)
                except Exception:
                    import re
                    labels = re.findall(r"[\w]+", raw_labels)
            else:
                labels = list(raw_labels) if raw_labels else []
            properties = self.parse_properties(row['properties'])

            # Determine device type from labels
            device_type_str = labels[0] if labels else "Endpoint"
            device_type = label_to_device_type.get(device_type_str, DeviceType.ENDPOINT)

            
            # Extract device properties
            name = properties.get('name', f"{device_type_str}{node_id}")
            ip = properties.get('ip', f"192.168.1.{node_id}")
            
            # Create device
            device = NetworkDevice(
                unique_id=node_id,
                model=self,
                device_type=device_type,
                name=name,
                ip=ip,
                security_level=security_levels.get(device_type_str, 0.5)
            )
            
            self.schedule.add(device)
            self.devices.append(device)
            device_lookup[node_id] = device
            
            print(f"  - {name} (ID: {node_id}, Type: {device_type.value}, IP: {ip})")
        
        print(f"\nCreated {len(self.devices)} devices total")
        
        # Count devices by type
        device_counts = {}
        for device in self.devices:
            dev_type = device.device_type.value
            device_counts[dev_type] = device_counts.get(dev_type, 0) + 1
        
        print("\nDevice Counts:")
        for dev_type, count in device_counts.items():
            print(f"  - {dev_type}: {count}")
        
        # Create connections from nodes.csv
        connection_count = 0
        print(f"\nCreating connections from nodes.csv:")
        for _, row in connections_df.iterrows():
            source_id = row['source']
            target_id = row['target']
            rel_type = row['relType']
            
            if source_id in device_lookup and target_id in device_lookup:
                source_device = device_lookup[source_id]
                target_device = device_lookup[target_id]
                
                source_device.add_connection(target_device)
                target_device.add_connection(source_device)
                connection_count += 1
                
                print(f"  - {source_device.name} ({source_id}) --{rel_type}--> {target_device.name} ({target_id})")
            else:
                print(f"  - WARNING: Connection {source_id} -> {target_id} has missing devices")
        
        print(f"\nCreated {connection_count} connections between devices")
        
        # Verify all devices have connections
        isolated_devices = [d for d in self.devices if len(d.connections) == 0]
        if isolated_devices:
            print(f"\nWarning: {len(isolated_devices)} devices have no connections:")
            for device in isolated_devices:
                print(f"  - {device.name} (ID: {device.unique_id})")
    
    def create_fallback_network(self):
        """Create a fallback network if CSV files are not available"""
        print("Creating fallback network...")
        
        # Create devices based on your exact counts
        devices_to_create = [
            (DeviceType.ENDPOINT, "Endpoint", "192.168.10.{}", 0.3, 100),
            (DeviceType.ACCESS_POINT, "AP", "10.0.1.{}", 0.5, 10),
            (DeviceType.SWITCH, "Switch", "10.0.10.{}", 0.6, 4),
            (DeviceType.AGGREGATION_SWITCH, "AggSwitch", "10.0.20.{}", 0.8, 2),
            (DeviceType.ROUTER, "Router", "10.0.0.{}", 0.7, 2),
            (DeviceType.FIREWALL, "Firewall", "10.0.40.{}", 0.9, 1),
            (DeviceType.SERVER, "Server", "172.16.0.{}", 0.4, 5),
            (DeviceType.ISP, "ISP", "203.0.113.{}", 0.8, 1),
            (DeviceType.SWITCH, "ServerSwitch", "10.0.30.{}", 0.6, 1)  # ServerSwitch1
        ]
        
        device_id = 0
        for device_type, name_prefix, ip_template, security, count in devices_to_create:
            for i in range(count):
                device = NetworkDevice(
                    unique_id=device_id,
                    model=self,
                    device_type=device_type,
                    name=f"{name_prefix}{i+1}",
                    ip=ip_template.format(device_id+1),
                    security_level=security
                )
                self.schedule.add(device)
                self.devices.append(device)
                device_id += 1
        
        # Create basic connections similar to your CSV structure
        device_lookup = {device.unique_id: device for device in self.devices}
        
        # Connect endpoints to access points (10 endpoints per AP)
        endpoints = [d for d in self.devices if d.device_type == DeviceType.ENDPOINT]
        aps = [d for d in self.devices if d.device_type == DeviceType.ACCESS_POINT]
        
        for i, endpoint in enumerate(endpoints):
            ap_index = i // 10  # 10 endpoints per AP
            if ap_index < len(aps):
                ap = aps[ap_index]
                endpoint.add_connection(ap)
                ap.add_connection(endpoint)
        
        # Connect APs to switches
        switches = [d for d in self.devices if d.device_type == DeviceType.SWITCH and "Server" not in d.name]
        for i, ap in enumerate(aps):
            switch_index = i // 3  # Rough grouping
            if switch_index < len(switches):
                switch = switches[switch_index]
                ap.add_connection(switch)
                switch.add_connection(ap)
        
        # Connect switches to aggregation switches
        agg_switches = [d for d in self.devices if d.device_type == DeviceType.AGGREGATION_SWITCH]
        for switch in switches:
            for agg_switch in agg_switches:
                switch.add_connection(agg_switch)
                agg_switch.add_connection(switch)
        
        # Connect aggregation switches to routers and firewall
        routers = [d for d in self.devices if d.device_type == DeviceType.ROUTER]
        firewalls = [d for d in self.devices if d.device_type == DeviceType.FIREWALL]
        
        for agg_switch in agg_switches:
            for router in routers:
                agg_switch.add_connection(router)
                router.add_connection(agg_switch)
            for firewall in firewalls:
                agg_switch.add_connection(firewall)
                firewall.add_connection(agg_switch)
        
        # Connect firewall to server switch
        server_switches = [d for d in self.devices if d.device_type == DeviceType.SWITCH and "Server" in d.name]
        servers = [d for d in self.devices if d.device_type == DeviceType.SERVER]
        
        for firewall in firewalls:
            for server_switch in server_switches:
                firewall.add_connection(server_switch)
                server_switch.add_connection(firewall)
        
        # Connect server switch to servers
        for server_switch in server_switches:
            for server in servers:
                server_switch.add_connection(server)
                server.add_connection(server_switch)
        
        # Connect routers to ISP
        isps = [d for d in self.devices if d.device_type == DeviceType.ISP]
        for router in routers:
            for isp in isps:
                router.add_connection(isp)
                isp.add_connection(router)
    
    def build_network_graph(self):
        """Build NetworkX graph for visualization"""
        # Clear existing graph
        self.network_graph.clear()
        
        # Add nodes
        for device in self.devices:
            self.network_graph.add_node(
                device.unique_id,
                device_type=device.device_type,
                name=device.name,
                infected=device.infected,
                newly_infected=device.newly_infected,
                has_resistance=device.has_resistance
            )
        
        # Add edges
        for device in self.devices:
            for connected_device in device.connections:
                self.network_graph.add_edge(device.unique_id, connected_device.unique_id)
    
    def infect_initial_device(self):
        """Infect multiple random devices to start the simulation based on initial_outbreak_size"""
        endpoints = [d for d in self.devices if d.device_type == DeviceType.ENDPOINT]
        if endpoints:
            # Select multiple random endpoints based on initial_outbreak_size
            num_to_infect = min(self.initial_outbreak_size, len(endpoints))
            initial_infected = self.random.sample(endpoints, num_to_infect)
            
            for device in initial_infected:
                device.infected = True
                device.infection_time = 0
                device.newly_infected = True
                print(f"Initially infected: {device.name} (ID: {device.unique_id})")
            
            print(f"Initial outbreak: {num_to_infect} devices infected")
    
    def count_infected_devices(self):
        return sum(1 for device in self.devices if device.infected)
    
    def count_healthy_devices(self):
        return sum(1 for device in self.devices if not device.infected)
    
    def count_recovered_devices(self):
        return len([d for d in self.devices if not d.infected and d.infection_time is not None])
    
    def count_resistant_devices(self):
        return sum(1 for device in self.devices if device.has_resistance)
    
    def step(self):
        if self.running and not self.paused:
            self.new_infections_this_step = []
            self.recovered_devices_this_step = []
            self.successful_detections_this_step = []
            self.new_resistance_this_step = []
            self.schedule.step()
            self.build_network_graph()  # Update graph after each step
            
            step_info = {
                'step': self.schedule.time,  # FIXED: Changed from self.model.schedule.time to self.schedule.time
                'infected_count': self.count_infected_devices(),
                'recovered_count': self.count_recovered_devices(),
                'resistant_count': self.count_resistant_devices(),
                'new_infections': self.new_infections_this_step.copy(),
                'recovered_devices': self.recovered_devices_this_step.copy(),
                'successful_detections': self.successful_detections_this_step.copy(),
                'new_resistance': self.new_resistance_this_step.copy(),
                'infected_devices': [d.unique_id for d in self.devices if d.infected],
                'newly_infected': [d.unique_id for d in self.devices if d.newly_infected]
            }
            self.step_data.append(step_info)