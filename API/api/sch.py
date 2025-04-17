import strawberry
from typing import Optional, List
from api.db import get_session  # Make sure this returns a Neo4j session object


@strawberry.type
class endpoint:
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
class Query:

    @strawberry.field
    def all_devices(self) -> List[endpoint]:
        query = """
            match (d:endpoint) 
            return d.name as name, d.ipAddress as ipAddress, d.macAddress as macAddress
        """
        session = get_session()
        result = session.run(query)
        return [
            endpoint(
                name=record["name"],
                ipAddress=record.get("ipAddress"),
                macAddress=record.get("macAddress")
            ) for record in result
        ]

    @strawberry.field
    def indirect_risks(self) -> List[RiskPath]:
        query = """
    MATCH (a)-[r1]->(b)<-[r2]-(c)
    WHERE ANY(x IN [a,b,c] WHERE x.suspected = true)
      AND NOT (a)--(c)
    RETURN 
      a.name AS source,
      type(r1) AS rel1_type,
      b.name AS mediator, 
      type(r2) AS rel2_type,
      c.name AS target,
      CASE
        WHEN a.suspected OR c.suspected THEN 'Direct risk'
        WHEN b.suspected THEN 'Mediator risk'
      END AS risk_type
    """
        session = get_session()
        result = session.run(query)
        return [
        RiskPath(
            source=record["source"],
            rel1_type=record["rel1_type"],
            mediator=record["mediator"],
            rel2_type=record["rel2_type"],
            target=record["target"],
            risk_type=record["risk_type"]
        )
        for record in result
    ]

    @strawberry.field
    def all_switches(self) -> List[Switch]:
        query = """
            match (s:Switch) 
            return s.name as name, s.mac as mac
        """
        session = get_session()
        result = session.run(query)
        return [
            Switch(
                name=record["name"],
                mac=record.get("mac")
            ) for record in result
        ]

    @strawberry.field
    def all_servers(self) -> List[Server]:
        query = """
            match (s:Server) 
            return s.name as name
        """
        session = get_session()
        result = session.run(query)
        return [Server(name=record["name"]) for record in result]

    @strawberry.field
    def devices_by_switch(self, switch_name: str) -> List[endpoint]:
        query = """
            match (s:Switch {name: $switch_name})-[:CONNECTED_TO]->(d:endpoint) 
            return d.name as name, d.ipAddress as ipAddress, d.macAddress as macAddress
        """
        session = get_session()
        result = session.run(query, switch_name=switch_name)
        return [
            endpoint(
                name=record["name"],
                ipAddress=record.get("ipAddress"),
                macAddress=record.get("macAddress")
            ) for record in result
        ]


# Create schema with the Query class
schema = strawberry.Schema(query=Query)
