from neo4j import GraphDatabase

# Set up your connection parameters here
uri = "*"  # Change this if you are using a different host or port
username = "*"  # Your Neo4j username
password = "*"  # Your Neo4j password


# Create a Neo4j driver
driver = GraphDatabase.driver(uri, auth=(username, password))

# Function to get a session for querying the database
def get_session():
    return driver.session()
