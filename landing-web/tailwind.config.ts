import type { Config } from "tailwindcss";

const config: Config = {
  content: ["./app/**/*.{ts,tsx}"],
  theme: {
    extend: {
      colors: {
        obsidian: "#07080D",
        accentBlue: "#3E7BFF",
        accentCyan: "#00D9F5",
      },
    },
  },
  plugins: [],
};
export default config;
