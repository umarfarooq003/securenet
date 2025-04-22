from flask import Flask
from strawberry.flask.views import GraphQLView
from flask_cors import CORS
from api.sch import schema  # adjust path as needed

app = Flask(__name__)

# Enable CORS for all domains, methods, and headers
CORS(app, resources={r"/*": {"origins": "*"}}, supports_credentials=True)

# GraphQL endpoint
app.add_url_rule(
    "/graphql",
    view_func=GraphQLView.as_view("graphql_view", schema=schema, graphiql=True),
)

if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0", port=8000)
