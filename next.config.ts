import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  experimental: {
    serverActions: {
      // Défaut Next.js = 1 Mo. Un enseignant dépose un scan de sujet de devoir
      // ou une photo de page de manuel : 1 Mo est vite dépassé.
      bodySizeLimit: "10mb",
    },
  },
};

export default nextConfig;
