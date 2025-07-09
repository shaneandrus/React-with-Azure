import express from "express";
import { ApolloServer } from "@apollo/server";
import { expressMiddleware } from "@apollo/server/express4";
import { gql } from "graphql-tag";
import playground from "graphql-playground-middleware-express";

// Example GraphQL schema
const typeDefs = gql`
  type Query {
    hello: String
  }
`;

// Example resolver
const resolvers = {
  Query: {
    hello: () => "Hello world!",
  },
};

async function startServer() {
  const app = express();

  // Add a test endpoint to verify JSON middleware
  app.post("/test", express.json(), (req, res) => {
    res.json({ received: req.body });
  });

  // This must come before Apollo middleware!
  app.use(express.json());

  const server = new ApolloServer({
    typeDefs,
    resolvers,
  });
  await server.start();

  app.use(
    "/graphql",
    expressMiddleware(server, {
      context: async ({ req }) => ({ token: req.headers.token }),
    })
  );

  // Add playground route
  app.get("/playground", playground({ endpoint: "/graphql" }));

  const PORT = process.env.PORT || 4000;
  app.listen(PORT, () => {
    console.log(`🚀 Server ready at http://localhost:${PORT}/graphql`);
    console.log(`🔗 Playground at http://localhost:${PORT}/playground`);
  });
}

startServer();