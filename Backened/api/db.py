from neo4j import GraphDatabase

# Set up your connection parameters here
uri = "neo4j+s://d915b217.databases.neo4j.io"  # Change this if you are using a different host or port
username = "neo4j"  # Your Neo4j username
password = "J6dPkFM0tIYOvuQFZmtDkUCRnjj26wMLT6uDES5hRqg"  # Your Neo4j password


# Create a Neo4j driver
driver = GraphDatabase.driver(uri, auth=(username, password))

# Function to get a session for querying the database
def get_session():
    return driver.session()
