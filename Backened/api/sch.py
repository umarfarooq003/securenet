import strawberry
from typing import Optional, List
from api.db import get_session


# =========================
# TYPES
# =========================

@strawberry.type
class Node:
    nodeId: int
    nodeType: str
    name: Optional[str]
    ipAddress: Optional[str]
    status: Optional[str]
    allProperties: str


@strawberry.type
class NodeRisk:
    nodeType: str
    name: Optional[str]
    riskLevel: str
    riskScore: int


@strawberry.type
class Endpoint:
    name: str
    ipAddress: Optional[str]
    macAddress: Optional[str]


@strawberry.type
class RiskPath:
    source: str
    rel1_type: str
    mediator: str
    rel2_type: str
    target: str
    risk_type: str


@strawberry.type
class Switch:
    name: str
    mac: Optional[str]


@strawberry.type
class Server:
    name: str


@strawberry.type
class LoadBalancer:
    name: str


@strawberry.type
class GraphRelationship:
    source_name: str
    source_type: str
    rel_type: str
    target_name: str
    target_type: str


# =========================
# QUERY CLASS
# =========================

@strawberry.type
class Query:

    # ----------------------------------
    # 1️⃣ Get ALL Nodes (No Risk Logic)
    # ----------------------------------
    @strawberry.field
    def all_nodes(self) -> List[Node]:
        query = """
        MATCH (n)
        RETURN 
            id(n) AS nodeId,
            labels(n)[0] AS nodeType,
            n.name AS name,
            n.ip AS ipAddress,
            n.status AS status,
            properties(n) AS allProperties
        """

        session = get_session()
        result = session.run(query)

        return [
            Node(
                nodeId=record["nodeId"],
                nodeType=record["nodeType"],
                name=record.get("name"),
                ipAddress=record.get("ipAddress"),
                status=record.get("status"),
                allProperties=str(record["allProperties"])
            )
            for record in result
        ]


    # ----------------------------------
    # 2️⃣ Risk Per Node (Separate Query)
    # ----------------------------------
    @strawberry.field
    def node_risks(self) -> List[NodeRisk]:
        query = """
        MATCH (n)
        OPTIONAL MATCH (n)--(m)
        WITH n,
             COUNT(CASE WHEN m.suspected = true THEN 1 END) AS indirectRiskCount
        RETURN 
            labels(n)[0] AS nodeType,
            n.name AS name,
            n.suspected AS directRisk,
            indirectRiskCount
        """

        session = get_session()
        result = session.run(query)

        risks = []

        for record in result:
            direct_risk = record.get("directRisk")
            indirect_count = record.get("indirectRiskCount", 0)

            if direct_risk:
                risk_level = "Direct Risk"
                risk_score = 2
            elif indirect_count > 0:
                risk_level = "Indirect Risk"
                risk_score = 1
            else:
                risk_level = "Safe"
                risk_score = 0

            risks.append(
                NodeRisk(
                    nodeType=record["nodeType"],
                    name=record.get("name"),
                    riskLevel=risk_level,
                    riskScore=risk_score
                )
            )

        return risks


    # ----------------------------------
    # 3️⃣ Risk Paths (Indirect Risk)
    # ----------------------------------
    @strawberry.field
    def indirect_risks(self) -> List[RiskPath]:
        query = """
        MATCH (a)-[r1]->(b)<-[r2]-(c)
        WHERE (a.suspected = true OR b.suspected = true OR c.suspected = true)
        AND NOT (a)--(c)
        RETURN DISTINCT
            labels(a)[0] AS source_type,
            a.name AS source,
            type(r1) AS rel1_type,
            labels(b)[0] AS mediator_type,
            b.name AS mediator,
            type(r2) AS rel2_type,
            labels(c)[0] AS target_type,
            c.name AS target,
            CASE
                WHEN a.suspected = true OR c.suspected = true THEN 'Direct Risk'
                WHEN b.suspected = true THEN 'Mediator Risk'
                ELSE 'Indirect Risk'
            END AS risk_type
        ORDER BY risk_type DESC
        """

        session = get_session()
        result = session.run(query)

        return [
            RiskPath(
                source=f"{record['source']} ({record['source_type']})",
                rel1_type=record["rel1_type"],
                mediator=f"{record['mediator']} ({record['mediator_type']})",
                rel2_type=record["rel2_type"],
                target=f"{record['target']} ({record['target_type']})",
                risk_type=record["risk_type"]
            )
            for record in result
        ]


    # ----------------------------------
    # 4️⃣ All Switches
    # ----------------------------------
    @strawberry.field
    def all_switches(self) -> List[Switch]:
        query = """
        MATCH (s:Switch)
        RETURN s.name AS name, s.mac AS mac
        """

        session = get_session()
        result = session.run(query)

        return [
            Switch(
                name=record["name"],
                mac=record.get("mac")
            )
            for record in result
        ]


    # ----------------------------------
    # 5️⃣ All Servers
    # ----------------------------------
    @strawberry.field
    def all_servers(self) -> List[Server]:
        query = """
        MATCH (s:Server)
        RETURN s.name AS name
        """

        session = get_session()
        result = session.run(query)

        return [Server(name=record["name"]) for record in result]


    # ----------------------------------
    # 6b️⃣ All Load Balancers
    # ----------------------------------
    @strawberry.field
    def all_load_balancers(self) -> List[LoadBalancer]:
        query = """
        MATCH (lb:LoadBalancer)
        RETURN lb.name AS name
        """

        session = get_session()
        result = session.run(query)

        return [LoadBalancer(name=record["name"]) for record in result]


    # ----------------------------------
    # 7️⃣ All Relationships (for graph)
    # ----------------------------------
    @strawberry.field
    def all_relationships(self) -> List[GraphRelationship]:
        query = """
        MATCH (a)-[r]->(b)
        WHERE a.name IS NOT NULL AND b.name IS NOT NULL
        RETURN
            a.name AS source_name,
            labels(a)[0] AS source_type,
            type(r) AS rel_type,
            b.name AS target_name,
            labels(b)[0] AS target_type
        LIMIT 500
        """

        session = get_session()
        result = session.run(query)

        return [
            GraphRelationship(
                source_name=record["source_name"],
                source_type=record["source_type"],
                rel_type=record["rel_type"],
                target_name=record["target_name"],
                target_type=record["target_type"]
            )
            for record in result
        ]


    # ----------------------------------
    # 6️⃣ Devices By Switch
    # ----------------------------------
    @strawberry.field
    def devices_by_switch(self, switch_name: str) -> List[Endpoint]:
        query = """
        MATCH (s:Switch {name: $switch_name})-[:CONNECTED_TO]->(d:Endpoint)
        RETURN d.name AS name,
               d.ip AS ipAddress,
               d.macAddress AS macAddress
        """

        session = get_session()
        result = session.run(query, switch_name=switch_name)

        return [
            Endpoint(
                name=record["name"],
                ipAddress=record.get("ipAddress"),
                macAddress=record.get("macAddress")
            )
            for record in result
        ]


# =========================
# SCHEMA
# =========================

schema = strawberry.Schema(query=Query)