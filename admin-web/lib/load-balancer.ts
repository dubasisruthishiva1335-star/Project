export interface WebApiNode {
  id: string;
  name: string;
  url: string;
  latency: number;
  healthy: boolean;
}

class WebLoadBalancer {
  private nodes: WebApiNode[] = [
    {
      id: "node-vercel",
      name: "Vercel Edge Gateway (Primary)",
      url: process.env.NEXT_PUBLIC_API_URL || "https://project-chi-six-62.vercel.app",
      latency: 35,
      healthy: true,
    },
    {
      id: "node-render",
      name: "Render Dedicated Node (Secondary)",
      url: "https://project-9zrh.onrender.com",
      latency: 80,
      healthy: true,
    },
  ];

  public getActiveUrl(): string {
    const healthy = this.nodes.filter((n) => n.healthy);
    if (healthy.length === 0) return this.nodes[0].url;
    healthy.sort((a, b) => a.latency - b.latency);
    return healthy[0].url;
  }

  public reportFailure(url: string) {
    const node = this.nodes.find((n) => url.startsWith(n.url));
    if (node) {
      node.healthy = false;
      setTimeout(() => {
        node.healthy = true;
      }, 30000); // 30s recovery
    }
  }

  public reportSuccess(url: string, latency: number) {
    const node = this.nodes.find((n) => url.startsWith(n.url));
    if (node) {
      node.healthy = true;
      node.latency = latency;
    }
  }

  public getNodes(): WebApiNode[] {
    return [...this.nodes];
  }
}

export const webLoadBalancer = new WebLoadBalancer();
