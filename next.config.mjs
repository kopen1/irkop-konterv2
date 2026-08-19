/** @type {import('next').NextConfig} */
const nextConfig={
  async rewrites(){return [{source:'/api/irkop/:path*',destination:'https://api.irkop.workers.dev/:path*'}]}
};
export default nextConfig;
