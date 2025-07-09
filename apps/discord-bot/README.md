# Discord Bot

A Discord bot for the D&D Campaign Organizer project.

## Setup

1. **Create a Discord Application and Bot:**
   - Go to [Discord Developer Portal](https://discord.com/developers/applications)
   - Create a new application
   - Go to the "Bot" section and create a bot
   - Copy the bot token

2. **Set Environment Variables:**
   Create a `.env` file in this directory:
   ```
   DISCORD_TOKEN=your_discord_bot_token_here
   ```

3. **Invite Bot to Your Server:**
   - Go to OAuth2 > URL Generator in your Discord app
   - Select "bot" scope
   - Select permissions: Send Messages, Read Message History
   - Use the generated URL to invite the bot

4. **Run the Bot:**
   ```sh
   npm run dev
   ```

## Commands

- `!ping` - Test command that responds with "Pong! 🏓"

## Development

- `npm run dev` - Start with nodemon for development
- `npm start` - Start the bot
