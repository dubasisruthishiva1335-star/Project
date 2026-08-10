"use client";

import { useEffect, useRef, useState } from "react";
import Link from "next/link";
import * as THREE from "three";

const SERVICES: Record<string, string[]> = {
  "Software & IT": ["Web development", "Mobile apps", "Custom software", "SaaS", "ERP / CRM / HRMS", "E-commerce", "API development", "System integration", "Software modernization"],
  "AI & Automation": ["AI applications", "AI agents", "Chatbots", "Machine learning", "Computer vision", "OCR", "Document intelligence", "AI search", "Predictive analytics", "Workflow automation"],
  "Cloud & DevOps": ["AWS", "Azure", "Google Cloud", "Cloud migration", "Docker", "Kubernetes", "CI/CD", "Infrastructure", "Monitoring", "Backup & disaster recovery"],
  "Cybersecurity": ["Security audits", "Application security", "Vulnerability assessment", "Authorized penetration testing", "Identity & access management", "Security monitoring", "Data protection"],
  "CAD & Engineering": ["AutoCAD", "2D CAD drafting", "3D CAD modeling", "Architectural drawings", "Civil engineering drawings", "Mechanical design", "Electrical design", "Interior design", "CAD conversion", "CAD outsourcing"],
  "Business Solutions": ["ERP", "CRM", "Inventory", "POS", "Accounting", "HR / payroll", "School management", "Hospital management", "Warehouse management", "Fleet management"],
  "Digital & Design": ["UI/UX", "Product design", "Branding", "Digital transformation", "Data analytics", "Business intelligence", "SEO"],
  "Startup & Product": ["Product strategy", "MVP development", "SaaS development", "Prototypes", "Product scaling", "Dedicated development teams"],
  "Managed Services": ["IT support", "Software maintenance", "QA / testing", "Server monitoring", "Application support", "SLA support"],
};

const PRODUCTS = [
  { name: "Academic Hub", cat: "Education", desc: "Branch & year-wise study materials, notes, lab manuals, and syllabus repository.", tags: ["Notes", "Syllabus", "PDF Viewer"], href: "/academic-hub" },
  { name: "Exam Results Portal", cat: "Education", desc: "Instant marksheet & memo lookup by Hall Ticket and Year with authenticated memos.", tags: ["Marksheets", "Instant Search", "PDF Memo"], href: "/results" },
  { name: "Placement & Job Feed", cat: "Careers", desc: "Curated internships, campus placements, and government job updates.", tags: ["Internships", "Govt Jobs", "Placements"], href: "/jobs" },
  { name: "Aptitude Quiz Practice", cat: "Exam Prep", desc: "Quantitative, logical, and verbal practice quizzes for placement drives.", tags: ["Quantitative", "Logical", "Verbal"], href: "/aptitude" },
  { name: "Business ERP", cat: "Operations", desc: "Unified inventory, procurement, and finance for growing manufacturers and distributors.", tags: ["Multi-branch", "Real-time stock", "GST-ready"], href: "#contact" },
  { name: "CRM Platform", cat: "Sales", desc: "Pipeline, follow-ups, and deal forecasting built for field and inside sales teams.", tags: ["Lead scoring", "Email sync", "Mobile app"], href: "#contact" },
  { name: "HRMS Suite", cat: "People", desc: "Attendance, payroll, and performance reviews in one employee-facing portal.", tags: ["Biometric sync", "Payroll auto-run", "Self-service"], href: "#contact" },
  { name: "AI Support Assistant", cat: "AI", desc: "An LLM-backed helpdesk that resolves student & client tickets 24/7.", tags: ["24/7 coverage", "CRM handoff", "Multilingual"], href: "#contact" },
  { name: "Document Management System", cat: "Operations", desc: "Version-controlled document storage with OCR search and approval workflows.", tags: ["OCR search", "Access control", "Audit trail"], href: "#contact" },
];

const INDUSTRIES = ["Healthcare", "Education", "Finance & Banking", "Retail & E-commerce", "Manufacturing", "Logistics", "Real Estate", "Hospitality & Travel", "Government", "Construction", "Agriculture", "Startups", "Enterprise"];

const TECH: Record<string, string[]> = {
  Frontend: ["React", "Next.js", "Angular", "Vue", "Tailwind CSS"],
  Backend: ["Node.js", "NestJS", "Python", "Java", ".NET"],
  Mobile: ["Flutter", "React Native", "Android (APK)", "iOS"],
  Database: ["PostgreSQL", "Prisma", "MySQL", "MongoDB", "Redis"],
  "Cloud & DevOps": ["AWS S3", "Azure", "Google Cloud", "Docker", "Kubernetes"],
  AI: ["Python ML", "LLM APIs", "RAG pipelines", "Computer vision"],
};

const PROCESS = [
  ["01", "Discover", "Understand the business, users, and constraints before proposing a single line of scope."],
  ["02", "Strategy", "Define architecture, technology choices, and a phased delivery roadmap."],
  ["03", "Design", "UX flows, UI systems, and clickable prototypes signed off before development starts."],
  ["04", "Develop", "Build in short, demoable sprints using modern, maintainable stacks."],
  ["05", "Test", "Functional, security, and performance testing before anything ships."],
  ["06", "Deploy", "Launch to cloud, on-prem, or app stores with a documented rollback plan."],
  ["07", "Support", "Monitoring, SLA-backed maintenance, and a direct line to the team that built it."],
];

const QUOTES = [
  ["“They shipped our Student Portal & S3 academic repository in record time — seamless for all students.”", "Reddy Sai Kumar", "Student Council Lead"],
  ["“The 3D walkthrough caught a layout issue before we broke ground — saved us real money.”", "Vikram Chandra", "Director, Real estate developer"],
  ["“Our support ticket volume dropped 40% after the AI assistant went live.”", "Priya Menon", "Customer Ops Lead, SaaS startup"],
];

export default function LandingPage() {
  const [activeTab, setActiveTab] = useState("Software & IT");
  const heroCanvasRef = useRef<HTMLCanvasElement | null>(null);
  const houseCanvasRef = useRef<HTMLCanvasElement | null>(null);
  const wallMaterialRef = useRef<THREE.MeshStandardMaterial | null>(null);

  // 1. Hero Three.js Floating 3D Shapes
  useEffect(() => {
    const canvas = heroCanvasRef.current;
    if (!canvas) return;
    const container = canvas.parentElement;
    if (!container) return;

    const scene = new THREE.Scene();
    const camera = new THREE.PerspectiveCamera(50, 1, 0.1, 100);
    camera.position.set(0, 0, 9);

    const renderer = new THREE.WebGLRenderer({ canvas, antialias: true, alpha: true });
    renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));

    function resize() {
      if (!container) return;
      const w = container.clientWidth;
      const h = container.clientHeight;
      renderer.setSize(w, h, false);
      camera.aspect = w / h;
      camera.updateProjectionMatrix();
    }
    resize();
    window.addEventListener("resize", resize);

    scene.add(new THREE.AmbientLight(0x8899ff, 0.7));
    const pt = new THREE.PointLight(0x38e4e0, 1.2);
    pt.position.set(5, 6, 8);
    scene.add(pt);

    const shapeDefs = [
      { geo: new THREE.IcosahedronGeometry(1.1, 0), color: 0x4c7cff, pos: [-3.4, 1.4, -1] as [number, number, number] },
      { geo: new THREE.TorusGeometry(0.85, 0.28, 12, 40), color: 0x38e4e0, pos: [3.6, -0.8, -2] as [number, number, number] },
      { geo: new THREE.OctahedronGeometry(0.9, 0), color: 0x8b6bff, pos: [2.4, 2.1, -3] as [number, number, number] },
      { geo: new THREE.TetrahedronGeometry(0.8, 0), color: 0xffb454, pos: [-3, -1.6, -2.5] as [number, number, number] },
    ];

    const meshes = shapeDefs.map((def) => {
      const mat = new THREE.MeshStandardMaterial({ color: def.color, wireframe: true, transparent: true, opacity: 0.55 });
      const mesh = new THREE.Mesh(def.geo, mat);
      mesh.position.set(...def.pos);
      scene.add(mesh);
      return mesh;
    });

    let mouseX = 0;
    let mouseY = 0;
    const handleMouseMove = (e: MouseEvent) => {
      mouseX = e.clientX / window.innerWidth - 0.5;
      mouseY = e.clientY / window.innerHeight - 0.5;
    };
    window.addEventListener("mousemove", handleMouseMove);

    let animationFrameId: number;
    let t = 0;
    function animate() {
      animationFrameId = requestAnimationFrame(animate);
      t += 0.006;
      meshes.forEach((m, i) => {
        m.rotation.x += 0.0022 + i * 0.0004;
        m.rotation.y += 0.003 + i * 0.0003;
        m.position.y += Math.sin(t + i) * 0.0025;
      });
      camera.position.x += (mouseX * 1.4 - camera.position.x) * 0.03;
      camera.position.y += (-mouseY * 1.0 - camera.position.y) * 0.03;
      camera.lookAt(0, 0, 0);
      renderer.render(scene, camera);
    }
    animate();

    return () => {
      window.removeEventListener("resize", resize);
      window.removeEventListener("mousemove", handleMouseMove);
      cancelAnimationFrame(animationFrameId);
      renderer.dispose();
    };
  }, []);

  // 2. Interactive CAD 3D House Viewer
  useEffect(() => {
    const canvas = houseCanvasRef.current;
    if (!canvas) return;
    const viewer = canvas.parentElement;
    if (!viewer) return;

    const scene = new THREE.Scene();
    const camera = new THREE.PerspectiveCamera(40, 1, 0.1, 100);
    camera.position.set(6.5, 4.5, 7);
    camera.lookAt(0, 1, 0);

    const renderer = new THREE.WebGLRenderer({ canvas, antialias: true, alpha: true });
    renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));

    function resize() {
      if (!viewer) return;
      const s = viewer.clientWidth;
      renderer.setSize(s, s, false);
      camera.aspect = 1;
      camera.updateProjectionMatrix();
    }
    resize();
    window.addEventListener("resize", resize);

    scene.add(new THREE.AmbientLight(0x8899bb, 0.55));
    const sun = new THREE.DirectionalLight(0xfff2df, 1.15);
    sun.position.set(6, 9, 4);
    scene.add(sun);
    const fill = new THREE.DirectionalLight(0x4d6bff, 0.35);
    fill.position.set(-6, 3, -4);
    scene.add(fill);

    const ground = new THREE.Mesh(
      new THREE.CircleGeometry(9, 48),
      new THREE.MeshStandardMaterial({ color: 0x1b2030, roughness: 1 })
    );
    ground.rotation.x = -Math.PI / 2;
    scene.add(ground);

    const grid = new THREE.GridHelper(14, 14, 0x333a4d, 0x1e2333);
    grid.position.y = 0.01;
    scene.add(grid);

    const house = new THREE.Group();
    const wallMat = new THREE.MeshStandardMaterial({ color: 0xc94f3d, roughness: 0.85 });
    wallMaterialRef.current = wallMat;

    const base = new THREE.Mesh(new THREE.BoxGeometry(3.4, 1.9, 2.6), wallMat);
    base.position.y = 0.95;
    house.add(base);

    const roofMat = new THREE.MeshStandardMaterial({ color: 0x2b2e3a, roughness: 0.6 });
    const roof = new THREE.Mesh(new THREE.ConeGeometry(2.65, 1.3, 4), roofMat);
    roof.rotation.y = Math.PI / 4;
    roof.position.y = 1.9 + 0.65;
    house.add(roof);

    const chimney = new THREE.Mesh(new THREE.BoxGeometry(0.28, 0.9, 0.28), new THREE.MeshStandardMaterial({ color: 0x555b6e }));
    chimney.position.set(0.9, 2.6, 0.4);
    house.add(chimney);

    const door = new THREE.Mesh(new THREE.BoxGeometry(0.55, 1.15, 0.06), new THREE.MeshStandardMaterial({ color: 0x3b2a22 }));
    door.position.set(0, 0.58, 1.31);
    house.add(door);

    const winMat = new THREE.MeshStandardMaterial({ color: 0x9fd3e8, roughness: 0.25, metalness: 0.15 });
    const winGeo = new THREE.BoxGeometry(0.5, 0.5, 0.05);
    [
      [-1.05, 1.15, 1.31],
      [1.05, 1.15, 1.31],
      [-1.72, 1.15, -0.3],
      [-1.72, 1.15, 0.55],
    ].forEach(([x, y, z], i) => {
      const w = new THREE.Mesh(winGeo, winMat);
      w.position.set(x, y, z);
      if (i >= 2) w.rotation.y = Math.PI / 2;
      house.add(w);
    });

    const step = new THREE.Mesh(new THREE.BoxGeometry(1.1, 0.12, 0.4), new THREE.MeshStandardMaterial({ color: 0x8b8f9c }));
    step.position.set(0, 0.06, 1.55);
    house.add(step);

    scene.add(house);

    let dragging = false;
    let lastX = 0;
    let lastY = 0;
    let theta = 0.7;
    let phi = 1.05;
    let radius = 9.5;
    let autoRotate = true;

    function updateCamera() {
      camera.position.x = radius * Math.sin(phi) * Math.sin(theta);
      camera.position.z = radius * Math.sin(phi) * Math.cos(theta);
      camera.position.y = radius * Math.cos(phi);
      camera.lookAt(0, 1, 0);
    }
    updateCamera();

    const handlePointerDown = (e: PointerEvent) => {
      dragging = true;
      autoRotate = false;
      lastX = e.clientX;
      lastY = e.clientY;
    };
    const handlePointerUp = () => {
      dragging = false;
    };
    const handlePointerMove = (e: PointerEvent) => {
      if (!dragging) return;
      theta -= (e.clientX - lastX) * 0.007;
      phi -= (e.clientY - lastY) * 0.007;
      phi = Math.max(0.35, Math.min(1.45, phi));
      lastX = e.clientX;
      lastY = e.clientY;
      updateCamera();
    };
    const handleWheel = (e: WheelEvent) => {
      e.preventDefault();
      radius += e.deltaY * 0.01;
      radius = Math.max(5, Math.min(15, radius));
      updateCamera();
    };

    canvas.addEventListener("pointerdown", handlePointerDown);
    window.addEventListener("pointerup", handlePointerUp);
    window.addEventListener("pointermove", handlePointerMove);
    canvas.addEventListener("wheel", handleWheel, { passive: false });

    let animationFrameId: number;
    function animate() {
      animationFrameId = requestAnimationFrame(animate);
      if (autoRotate) {
        theta += 0.0025;
        updateCamera();
      }
      renderer.render(scene, camera);
    }
    animate();

    return () => {
      window.removeEventListener("pointerup", handlePointerUp);
      window.removeEventListener("pointermove", handlePointerMove);
      canvas.removeEventListener("pointerdown", handlePointerDown);
      canvas.removeEventListener("wheel", handleWheel);
      cancelAnimationFrame(animationFrameId);
      renderer.dispose();
    };
  }, []);

  const changeWallColor = (hex: string) => {
    if (wallMaterialRef.current) {
      wallMaterialRef.current.color.set(hex);
    }
  };

  return (
    <div className="bg-[#08090D] text-[#F4F5F7] antialiased">
      {/* HERO SECTION */}
      <section className="relative overflow-hidden px-6 pt-16 pb-24 text-center">
        <canvas ref={heroCanvasRef} className="absolute inset-0 h-full w-full pointer-events-none z-0" />
        <div className="relative z-10 mx-auto max-w-4xl">
          <div className="mb-6 inline-flex items-center gap-2 rounded-full border border-[#38E4E0]/30 bg-[#38E4E0]/10 px-4 py-1.5 text-xs font-semibold uppercase tracking-widest text-[#38E4E0]">
            <span className="h-2 w-2 rounded-full bg-[#38E4E0] shadow-[0_0_10px_#38E4E0] animate-pulse"></span>
            Digital Products • IT Solutions • AI • Engineering
          </div>

          <h1 className="text-4xl font-extrabold leading-tight tracking-tight sm:text-6xl">
            Transform ideas into powerful{" "}
            <span className="bg-gradient-to-r from-[#4C7CFF] via-[#8B6BFF] to-[#38E4E0] bg-clip-text text-transparent">
              digital &amp; engineering
            </span>{" "}
            solutions
          </h1>

          <p className="mx-auto mt-6 max-w-2xl text-base sm:text-lg text-[#9295A3]">
            MyVault Technologies helps businesses, students, startups, and enterprises turn ideas into software, AI solutions, cloud platforms, secure systems, and professional CAD &amp; engineering designs.
          </p>

          <div className="mt-8 flex flex-wrap justify-center gap-4">
            <Link
              href="/academic-hub"
              className="rounded-full bg-gradient-to-r from-[#4C7CFF] via-[#8B6BFF] to-[#38E4E0] px-7 py-3.5 text-sm font-bold text-[#06070A] shadow-lg shadow-[#4C7CFF]/30 transition-transform hover:-translate-y-0.5"
            >
              Explore Academic Hub →
            </Link>
            <a
              href="http://localhost:3001/login"
              target="_blank"
              rel="noreferrer"
              className="rounded-full border border-white/20 bg-white/5 px-7 py-3.5 text-sm font-semibold text-white transition-colors hover:bg-white/10"
            >
              Admin Web Console ↗
            </a>
            <Link
              href="/myvault-app.apk"
              className="rounded-full border border-[#38E4E0]/40 bg-[#38E4E0]/10 px-7 py-3.5 text-sm font-semibold text-[#38E4E0] hover:bg-[#38E4E0]/20"
            >
              📲 Download Android APK
            </Link>
          </div>

          <div className="mt-16 flex flex-wrap justify-center gap-10 border-t border-white/10 pt-8">
            <div className="text-center"><p className="text-3xl font-extrabold text-white">120+</p><p className="mt-1 text-xs uppercase tracking-wider text-[#5C5F6E]">Projects delivered</p></div>
            <div className="text-center"><p className="text-3xl font-extrabold text-white">38</p><p className="mt-1 text-xs uppercase tracking-wider text-[#5C5F6E]">Industry clients</p></div>
            <div className="text-center"><p className="text-3xl font-extrabold text-white">9</p><p className="mt-1 text-xs uppercase tracking-wider text-[#5C5F6E]">In-house products</p></div>
            <div className="text-center"><p className="text-3xl font-extrabold text-[#38E4E0]">99.9%</p><p className="mt-1 text-xs uppercase tracking-wider text-[#5C5F6E]">Uptime SLA</p></div>
          </div>
        </div>
      </section>

      {/* DUAL PATH SECTION */}
      <section className="mx-auto max-w-6xl px-6 py-16">
        <div className="mb-10 text-center sm:text-left">
          <p className="text-xs font-semibold uppercase tracking-widest text-[#38E4E0]">Two ways to work with us</p>
          <h2 className="mt-2 text-3xl font-bold text-white">Buy the product, or commission the build</h2>
          <p className="mt-2 text-sm text-[#9295A3]">Some clients want a system we already built. Others need custom architecture. We run both models under one roof.</p>
        </div>

        <div className="grid gap-6 sm:grid-cols-2">
          <div className="rounded-2xl border border-white/10 bg-[#12141C] p-8 shadow-xl backdrop-blur-xl">
            <div className="mb-4 flex h-12 w-12 items-center justify-center rounded-xl bg-[#4C7CFF]/20 text-xl font-bold text-[#9FB6FF]">▣</div>
            <h3 className="text-xl font-bold text-white">Product-based</h3>
            <p className="mt-2 text-sm text-[#9295A3]">Subscribe to a proven system — deployed in days, priced per seat, updated continuously.</p>
            <ul className="mt-4 space-y-2 text-xs text-[#9295A3]">
              <li className="flex items-center gap-2"><span className="text-[#38E4E0] font-bold">→</span> Fixed pricing, transparent plans</li>
              <li className="flex items-center gap-2"><span className="text-[#38E4E0] font-bold">→</span> Live in days, not months</li>
              <li className="flex items-center gap-2"><span className="text-[#38E4E0] font-bold">→</span> Continuous updates &amp; support included</li>
            </ul>
            <Link href="#products" className="mt-6 inline-flex items-center gap-1.5 text-xs font-semibold text-[#38E4E0] hover:underline">Browse the catalog →</Link>
          </div>

          <div className="rounded-2xl border border-white/10 bg-[#12141C] p-8 shadow-xl backdrop-blur-xl">
            <div className="mb-4 flex h-12 w-12 items-center justify-center rounded-xl bg-[#8B6BFF]/20 text-xl font-bold text-[#C4B4FF]">◈</div>
            <h3 className="text-xl font-bold text-white">Service-based</h3>
            <p className="mt-2 text-sm text-[#9295A3]">A dedicated team scopes, designs, and builds something that doesn't exist off the shelf.</p>
            <ul className="mt-4 space-y-2 text-xs text-[#9295A3]">
              <li className="flex items-center gap-2"><span className="text-[#38E4E0] font-bold">→</span> Custom architecture &amp; roadmap</li>
              <li className="flex items-center gap-2"><span className="text-[#38E4E0] font-bold">→</span> Dedicated project &amp; engineering team</li>
              <li className="flex items-center gap-2"><span className="text-[#38E4E0] font-bold">→</span> Full IP ownership on delivery</li>
            </ul>
            <Link href="#services" className="mt-6 inline-flex items-center gap-1.5 text-xs font-semibold text-[#38E4E0] hover:underline">See our services →</Link>
          </div>
        </div>
      </section>

      {/* SERVICES TABS */}
      <section id="services" className="mx-auto max-w-6xl px-6 py-16">
        <div className="mb-8">
          <p className="text-xs font-semibold uppercase tracking-widest text-[#38E4E0]">Services</p>
          <h2 className="mt-2 text-3xl font-bold text-white">End-to-end technology delivery</h2>
          <p className="mt-2 text-sm text-[#9295A3]">Nine practice areas, one accountable team — from first sketch to production monitoring.</p>
        </div>

        <div className="mb-6 flex flex-wrap gap-2">
          {Object.keys(SERVICES).map((cat) => (
            <button
              key={cat}
              onClick={() => setActiveTab(cat)}
              className={`rounded-full px-4 py-2 text-xs font-semibold transition-all ${
                activeTab === cat
                  ? "bg-gradient-to-r from-[#4C7CFF] to-[#38E4E0] text-[#06070A]"
                  : "border border-white/10 bg-transparent text-[#9295A3] hover:border-white/20 hover:text-white"
              }`}
            >
              {cat}
            </button>
          ))}
        </div>

        <div className="grid gap-3 sm:grid-cols-3">
          {SERVICES[activeTab]?.map((item) => (
            <div key={item} className="rounded-xl border border-white/10 bg-[#12141C] p-4 text-xs font-medium text-white shadow-sm">
              ✨ {item}
            </div>
          ))}
        </div>
      </section>

      {/* PRODUCTS CATALOG */}
      <section id="products" className="mx-auto max-w-6xl px-6 py-16">
        <div className="mb-8">
          <p className="text-xs font-semibold uppercase tracking-widest text-[#38E4E0]">Products Catalog</p>
          <h2 className="mt-2 text-3xl font-bold text-white">Ready-to-deploy business &amp; academic systems</h2>
        </div>

        <div className="grid gap-6 sm:grid-cols-3">
          {PRODUCTS.map((p) => (
            <div key={p.name} className="flex flex-col justify-between rounded-2xl border border-white/10 bg-[#12141C] p-6 shadow-xl backdrop-blur-xl">
              <div>
                <div className="mb-3">
                  <span className="rounded-full border border-[#4C7CFF]/30 bg-[#4C7CFF]/10 px-3 py-1 text-[10px] font-semibold text-[#9FB6FF]">
                    {p.cat}
                  </span>
                </div>
                <h3 className="text-lg font-bold text-white">{p.name}</h3>
                <p className="mt-2 text-xs leading-relaxed text-[#9295A3]">{p.desc}</p>
                <div className="mt-4 flex flex-wrap gap-1.5">
                  {p.tags.map((t) => (
                    <span key={t} className="rounded-full bg-white/5 px-2.5 py-0.5 text-[10px] text-[#5C5F6E]">
                      {t}
                    </span>
                  ))}
                </div>
              </div>

              <div className="mt-6 border-t border-white/10 pt-4">
                <Link href={p.href} className="inline-flex items-center gap-1 text-xs font-semibold text-[#38E4E0] hover:underline">
                  Open System →
                </Link>
              </div>
            </div>
          ))}
        </div>
      </section>

      {/* 3D CAD & ENGINEERING SECTION */}
      <section id="engineering" className="border-y border-white/10 bg-[#0E1017] py-16">
        <div className="mx-auto max-w-6xl px-6 grid gap-10 lg:grid-cols-2 items-center">
          <div>
            <p className="text-xs font-semibold uppercase tracking-widest text-[#38E4E0]">CAD &amp; Engineering</p>
            <h2 className="mt-2 text-3xl font-bold text-white">CAD drafting and 3D visualization, grounded in engineering practice</h2>
            <p className="mt-4 text-sm text-[#9295A3]">
              The same precision we apply to software goes into physical structures — CAD-accurate floor plans, structural drawings, and walkable 3D models clients can review before a foundation is poured.
            </p>

            <ul className="mt-6 space-y-3 text-xs text-[#9295A3]">
              <li><b className="text-white">2D &amp; 3D CAD modeling</b> — AutoCAD drafting for architectural, mechanical, and electrical design</li>
              <li><b className="text-white">Civil engineering drawings</b> — site grading, road, and drainage documentation</li>
              <li><b className="text-white">Interior design</b> — room layouts, furniture, and material studies</li>
              <li><b className="text-white">CAD conversion &amp; outsourcing</b> — legacy drawings digitized and standardized</li>
            </ul>

            <div className="mt-8 flex items-center gap-6">
              <div><p className="text-xs text-[#5C5F6E]">Drag</p><p className="text-sm font-bold text-white">To Rotate 3D</p></div>
              <div><p className="text-xs text-[#5C5F6E]">Scroll</p><p className="text-sm font-bold text-white">To Zoom</p></div>
              <div><p className="text-xs text-[#5C5F6E]">Swatches</p><p className="text-sm font-bold text-white">To Re-skin</p></div>
            </div>
          </div>

          <div className="relative aspect-square overflow-hidden rounded-2xl border border-white/20 bg-gradient-to-br from-[#1a1e2c] to-[#0a0b10]">
            <canvas ref={houseCanvasRef} className="h-full w-full cursor-grab active:cursor-grabbing" />
            <div className="absolute bottom-4 left-4 right-4 flex items-center gap-2 rounded-xl bg-black/40 p-2.5 backdrop-blur-md">
              <button onClick={() => changeWallColor("#C94F3D")} className="h-7 w-7 rounded-full border-2 border-white/40 bg-[#C94F3D] hover:scale-110" title="Terracotta" />
              <button onClick={() => changeWallColor("#E8E1D3")} className="h-7 w-7 rounded-full border-2 border-white/40 bg-[#E8E1D3] hover:scale-110" title="Sandstone" />
              <button onClick={() => changeWallColor("#4C5C74")} className="h-7 w-7 rounded-full border-2 border-white/40 bg-[#4C5C74] hover:scale-110" title="Slate Blue" />
              <button onClick={() => changeWallColor("#EDEDED")} className="h-7 w-7 rounded-full border-2 border-white/40 bg-[#EDEDED] hover:scale-110" title="Alpine White" />
              <span className="ml-auto rounded-full bg-black/60 px-3 py-1 text-[10px] text-[#5C5F6E]">
                3D CAD Model — Live Render
              </span>
            </div>
          </div>
        </div>
      </section>

      {/* INDUSTRIES & TECH STACK */}
      <section className="mx-auto max-w-6xl px-6 py-16">
        <div className="mb-10">
          <p className="text-xs font-semibold uppercase tracking-widest text-[#38E4E0]">Industries &amp; Technology Stack</p>
          <h2 className="mt-2 text-3xl font-bold text-white">Built on industry standards that scale</h2>
        </div>

        <div className="mb-12">
          <p className="mb-4 text-xs font-bold uppercase tracking-wider text-[#5C5F6E]">Target Industries</p>
          <div className="flex flex-wrap gap-2">
            {INDUSTRIES.map((ind) => (
              <span key={ind} className="rounded-full border border-white/10 bg-[#12141C] px-4 py-2 text-xs font-medium text-[#9295A3]">
                {ind}
              </span>
            ))}
          </div>
        </div>

        <div className="grid gap-6 sm:grid-cols-2">
          {Object.keys(TECH).map((group) => (
            <div key={group} className="rounded-2xl border border-white/10 bg-[#12141C] p-6">
              <h4 className="mb-3 text-xs font-bold uppercase tracking-wider text-[#5C5F6E]">{group}</h4>
              <div className="flex flex-wrap gap-2">
                {TECH[group].map((t) => (
                  <span key={t} className="rounded-full border border-white/10 bg-white/5 px-3 py-1 text-xs text-white">
                    {t}
                  </span>
                ))}
              </div>
            </div>
          ))}
        </div>
      </section>

      {/* 7-STEP DELIVERY PROCESS */}
      <section className="mx-auto max-w-6xl px-6 py-16">
        <div className="mb-10">
          <p className="text-xs font-semibold uppercase tracking-widest text-[#38E4E0]">How We Work</p>
          <h2 className="mt-2 text-3xl font-bold text-white">A seven-step delivery process</h2>
        </div>

        <div className="divide-y divide-white/10 border-y border-white/10">
          {PROCESS.map(([num, title, desc]) => (
            <div key={num} className="flex gap-6 py-6 items-start">
              <span className="text-2xl font-extrabold text-[#5C5F6E]">{num}</span>
              <div>
                <h4 className="text-base font-bold text-white">{title}</h4>
                <p className="mt-1 text-xs text-[#9295A3]">{desc}</p>
              </div>
            </div>
          ))}
        </div>
      </section>

      {/* CLIENT TESTIMONIALS */}
      <section className="mx-auto max-w-6xl px-6 py-16">
        <div className="mb-10">
          <p className="text-xs font-semibold uppercase tracking-widest text-[#38E4E0]">Client Feedback</p>
          <h2 className="mt-2 text-3xl font-bold text-white">What partners say</h2>
        </div>

        <div className="grid gap-6 sm:grid-cols-3">
          {QUOTES.map(([q, name, role]) => (
            <div key={name} className="flex flex-col justify-between rounded-2xl border border-white/10 bg-[#12141C] p-6 shadow-xl">
              <p className="text-xs italic leading-relaxed text-[#9295A3]">{q}</p>
              <div className="mt-6 flex items-center gap-3">
                <div className="h-9 w-9 rounded-full bg-gradient-to-tr from-[#4C7CFF] to-[#38E4E0]" />
                <div>
                  <p className="text-xs font-bold text-white">{name}</p>
                  <p className="text-[10px] text-[#5C5F6E]">{role}</p>
                </div>
              </div>
            </div>
          ))}
        </div>
      </section>

      {/* CALL TO ACTION BANNER */}
      <section className="mx-auto max-w-6xl px-6 py-16">
        <div className="rounded-3xl border border-white/20 bg-gradient-to-br from-[#4C7CFF]/20 via-[#8B6BFF]/10 to-transparent p-12 text-center shadow-2xl backdrop-blur-xl">
          <h2 className="text-3xl font-bold text-white">Have a project in mind?</h2>
          <p className="mx-auto mt-3 max-w-md text-xs text-[#9295A3]">
            Tell us what you're building — software, academic portal, product subscription, or physical design — and we'll route it within one business day.
          </p>
          <div className="mt-8 flex justify-center gap-4">
            <Link href="/register" className="rounded-full bg-gradient-to-r from-[#4C7CFF] to-[#38E4E0] px-8 py-3.5 text-xs font-bold text-[#06070A] shadow-lg">
              Get Started →
            </Link>
            <a href="http://localhost:3001/login" target="_blank" rel="noreferrer" className="rounded-full border border-white/20 bg-white/5 px-8 py-3.5 text-xs font-semibold text-white hover:bg-white/10">
              Admin Web Console ↗
            </a>
          </div>
        </div>
      </section>
    </div>
  );
}
