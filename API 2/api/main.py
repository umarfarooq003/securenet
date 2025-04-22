from flask import Flask, jsonify, request
from flask_cors import CORS  # 👈 Import CORS
from neo4j import GraphDatabase

app = Flask(__name__)
CORS(app)  # 👈 Enable CORS for all origins (Allow from anywhere)

# Neo4j Aura connection details
NEO4J_URI = "*"
NEO4J_USER = "*"
NEO4J_PASSWORD = "*"  # ⚠️ Replace with your actual password

driver = GraphDatabase.driver(NEO4J_URI, auth=(NEO4J_USER, NEO4J_PASSWORD))

# Function to fetch graph data from Neo4j
def fetch_graph_data():
    query = "MATCH (n)-[r]->(m) RETURN n, r, m"
    records_data = []

    with driver.session() as session:
        result = session.run(query)
        for record in result:
            n = record["n"]._properties
            r = record["r"].type
            m = record["m"]._properties
            records_data.append({
                "n": n,
                "r": r,
                "m": m
            })

    return records_data

@app.route("/graph", methods=["GET", "POST"])
def handle_graph_data():
    if request.method == "GET":
        # GET request: Fetch and return the graph data
        records_data = fetch_graph_data()
        return jsonify(records_data)

    elif request.method == "POST":
        # POST request: Accept and process the data from the request
        data = request.get_json()
        
        if not data:
            return jsonify({"error": "No data provided"}), 400
        
        # Use custom query if provided, otherwise default
        query = data.get("query", "MATCH (n)-[r]->(m) RETURN n, r, m")

        records_data = []
        with driver.session() as session:
            result = session.run(query)
            for record in result:
                n = record["n"]._properties
                r = record["r"].type
                m = record["m"]._properties
                records_data.append({
                    "n": n,
                    "r": r,
                    "m": m
                })

        return jsonify(records_data)

if __name__ == "_main_":
    app.run(debug=True)