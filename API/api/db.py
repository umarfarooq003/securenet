from neo4j import GraphDatabase

# Set up your connection parameters here
uri = "neo4j+s://cb470ef4.databases.neo4j.io"  # Change this if you are using a different host or port
username = "neo4j"  # Your Neo4j username
password = "vuY_kLLF7XPaPK3memN6rkulymJht9bFNnUpHWmx97I"  # Your Neo4j password


# Create a Neo4j driver
driver = GraphDatabase.driver(uri, auth=(username, password))

# Function to get a session for querying the database
def get_session():
    return driver.session()
