/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  swcMinify: true,
  images: {
    domains: ['mfipo.infura-ipfs.io'],
  },
};

module.exports = nextConfig;
