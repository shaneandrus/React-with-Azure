import { Client, GatewayIntentBits } from "discord.js";
import "dotenv/config";

const client = new Client({ 
  intents: [
    GatewayIntentBits.Guilds,
    GatewayIntentBits.GuildMessages,
    GatewayIntentBits.MessageContent
  ] 
});

const PREFIX = "!";

client.once("ready", () => {
  console.log(`🤖 Logged in as ${client.user?.tag}!`);
  console.log(`📊 Serving ${client.guilds.cache.size} guilds`);
});

client.on("messageCreate", async message => {
  // Ignore messages from bots and messages that don't start with the prefix
  if (message.author.bot || !message.content.startsWith(PREFIX)) return;
  
  // Extract the command and arguments
  const args = message.content.slice(PREFIX.length).trim().split(/ +/);
  const command = args.shift()?.toLowerCase();
  
  if (command === "ping") {
    await message.reply("Pong! 🏓");
  }
});

// Handle errors
client.on("error", error => {
  console.error("Discord client error:", error);
});

// Replace 'YOUR_BOT_TOKEN' with your actual Discord bot token
const token = process.env.DISCORD_TOKEN || "YOUR_BOT_TOKEN";

if (token === "YOUR_BOT_TOKEN") {
  console.error("❌ Please set your DISCORD_TOKEN in the .env file");
  process.exit(1);
}

client.login(token).catch(error => {
  console.error("Failed to login:", error);
  process.exit(1);
}); 