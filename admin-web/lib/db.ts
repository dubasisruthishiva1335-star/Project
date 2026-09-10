import { MongoClient, Db } from "mongodb";

const uri = process.env.MONGODB_URI || process.env.DATABASE_URL || "";
let client: MongoClient | null = null;
let db: Db | null = null;

export async function connectDB(): Promise<Db | null> {
  if (!uri || !uri.startsWith("mongodb")) {
    return null;
  }
  try {
    if (!client) {
      client = new MongoClient(uri, {
        serverSelectionTimeoutMS: 5000,
      });
      await client.connect();
    }
    db = client.db("myvault");
    return db;
  } catch (err) {
    console.warn("MongoDB connection notice (will use persistent fallback):", err);
    return null;
  }
}
