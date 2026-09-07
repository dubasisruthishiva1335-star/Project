import { NextResponse } from "next/server";

export interface InternshipItem {
  id: string;
  title: string;
  company: string;
  logo?: string;
  workMode: "REMOTE" | "HYBRID" | "ONSITE";
  location: string;
  category: string;
  openings: number;
  startDate?: string;
  deadline?: string;
  duration?: string;
  stipend: string;
  isPaid: boolean;
  currency: string;
  description: string;
  responsibilities: string[];
  requirements: string[];
  skills: string[];
  eligibleBranches: string[];
  minCgpa: number;
  eligibleGradYears: number[];
  perks: string[];
  contactPhone?: string;
  contactEmail?: string;
  companyWebsite?: string;
  applyUrl?: string;
  questions: Array<{ id: string; question: string; type: string; required: boolean }>;
  status: "DRAFT" | "PUBLISHED" | "CLOSED";
  postedAt: string;
  applicantCount: number;
}

let mockInternships: InternshipItem[] = [
  {
    id: "int_google_swe",
    title: "Software Engineering Intern",
    company: "Google",
    logo: "https://upload.wikimedia.org/wikipedia/commons/2/2f/Google_2015_logo.svg",
    workMode: "HYBRID",
    location: "Bengaluru, Karnataka",
    category: "Software Development",
    openings: 8,
    duration: "6 Months",
    stipend: "80,000",
    isPaid: true,
    currency: "INR",
    contactPhone: "+91 80 6721 8000",
    contactEmail: "university-recruiting-in@google.com",
    companyWebsite: "https://careers.google.com",
    applyUrl: "https://careers.google.com/jobs/results/?q=intern",
    description: "Join Google core engineering teams to build scalable distributed systems, search features, and AI-driven cloud infrastructure.",
    responsibilities: [
      "Design, develop, test, and deploy robust software solutions in Python, C++, or Go.",
      "Collaborate with senior software engineers, product managers, and UX designers.",
      "Optimize algorithms for low latency and high availability across millions of users."
    ],
    requirements: [
      "Strong foundation in Data Structures, Algorithms, and Object-Oriented Design.",
      "Proficiency in Python, Java, C++, or Go.",
      "Knowledge of databases, SQL, and REST APIs."
    ],
    skills: ["Python", "C++", "Data Structures", "Algorithms", "System Design"],
    eligibleBranches: ["CSE", "ECE", "AI_ML", "EEE"],
    minCgpa: 7.5,
    eligibleGradYears: [2026, 2027],
    perks: ["PPO / Full-time Conversion", "Mentorship", "Certificate", "Free Meals & Transport"],
    questions: [
      { id: "q1", question: "Describe a challenging technical project you built and the key tradeoffs you made.", type: "textarea", required: true },
      { id: "q2", question: "Are you available for a full-time 6-month internship starting next semester?", type: "text", required: true }
    ],
    status: "PUBLISHED",
    postedAt: new Date(Date.now() - 2 * 86400000).toISOString(),
    applicantCount: 142,
  },
  {
    id: "int_msft_ai",
    title: "AI & Machine Learning Engineering Intern",
    company: "Microsoft",
    logo: "https://upload.wikimedia.org/wikipedia/commons/9/96/Microsoft_logo_%282012%29.svg",
    workMode: "HYBRID",
    location: "Hyderabad, Telangana",
    category: "AI & Data Science",
    openings: 5,
    duration: "6 Months",
    stipend: "65,000",
    isPaid: true,
    currency: "INR",
    contactPhone: "+91 40 6694 0000",
    contactEmail: "ur-india@microsoft.com",
    companyWebsite: "https://careers.microsoft.com",
    applyUrl: "https://careers.microsoft.com/students/us/en/ind-internship",
    description: "Work with Microsoft Azure AI & Cognitive Services teams building enterprise LLM workflows, fine-tuning models, and cloud solutions.",
    responsibilities: [
      "Train, fine-tune, and evaluate deep learning and generative AI models on Azure AI Studio.",
      "Build high-throughput inference pipelines using PyTorch, ONNX, and FastAPI.",
      "Write unit tests and benchmark model accuracy, latency, and resource utilization."
    ],
    requirements: [
      "Hands-on experience with PyTorch, TensorFlow, Scikit-Learn, or Hugging Face.",
      "Understanding of Transformer architectures, embeddings, and vector databases.",
      "Solid Python programming and Git workflow skills."
    ],
    skills: ["Python", "PyTorch", "Generative AI", "Azure", "NLP", "Machine Learning"],
    eligibleBranches: ["CSE", "AI_ML", "ECE"],
    minCgpa: 7.0,
    eligibleGradYears: [2025, 2026, 2027],
    perks: ["PPO Opportunity", "Azure Cloud Credits", "Certificate", "Tech Conferences Access"],
    questions: [
      { id: "q1", question: "What AI/ML models or frameworks have you worked with recently?", type: "textarea", required: true }
    ],
    status: "PUBLISHED",
    postedAt: new Date(Date.now() - 4 * 86400000).toISOString(),
    applicantCount: 98,
  },
  {
    id: "int_amazon_sde",
    title: "SDE Cloud Intern (AWS)",
    company: "Amazon Web Services",
    logo: "https://upload.wikimedia.org/wikipedia/commons/9/93/Amazon_Web_Services_Logo.svg",
    workMode: "HYBRID",
    location: "Bengaluru, Karnataka",
    category: "Cloud Infrastructure",
    openings: 6,
    duration: "6 Months",
    stipend: "75,000",
    isPaid: true,
    currency: "INR",
    contactPhone: "+91 80 4151 5000",
    contactEmail: "india-campus-hiring@amazon.com",
    companyWebsite: "https://amazon.jobs",
    applyUrl: "https://amazon.jobs/en/teams/internships-for-students",
    description: "Build robust distributed cloud services powering AWS S3, DynamoDB, and Serverless event brokers with high uptime guarantees.",
    responsibilities: [
      "Architect and implement REST / gRPC microservices in Java or Rust.",
      "Design zero-downtime database migrations and automated scaling policies.",
      "Work with AWS security champions to maintain strict compliance."
    ],
    requirements: [
      "Proficiency in Java, C++, or Go with strong OOP and concurrency principles.",
      "Experience with Docker, Linux CLI, and CI/CD pipelines.",
      "Strong analytical and root-cause debugging skills."
    ],
    skills: ["Java", "AWS", "Distributed Systems", "Docker", "Microservices"],
    eligibleBranches: ["CSE", "ECE", "AI_ML"],
    minCgpa: 7.0,
    eligibleGradYears: [2026, 2027],
    perks: ["PPO Conversion", "Relocation Allowance", "Certificate", "AWS Certifications Voucher"],
    questions: [
      { id: "q1", question: "Describe a project where you solved high concurrency or scale bottlenecks.", type: "textarea", required: true }
    ],
    status: "PUBLISHED",
    postedAt: new Date(Date.now() - 6 * 86400000).toISOString(),
    applicantCount: 115,
  },
  {
    id: "int_adobe_frontend",
    title: "Frontend Engineering Intern",
    company: "Adobe",
    logo: "https://upload.wikimedia.org/wikipedia/commons/5/51/Adobe_Inc._logo.svg",
    workMode: "REMOTE",
    location: "Noida / Remote, India",
    category: "Frontend & UI/UX",
    openings: 4,
    duration: "3-6 Months",
    stipend: "55,000",
    isPaid: true,
    currency: "INR",
    contactPhone: "+91 120 244 4555",
    contactEmail: "india-careers@adobe.com",
    companyWebsite: "https://adobe.com/careers",
    applyUrl: "https://adobe.com/careers/university.html",
    description: "Create pixel-perfect, high-performance web components for Adobe Creative Cloud Web, leveraging React, WebAssembly, and Canvas.",
    responsibilities: [
      "Build modular and accessible React / TypeScript components.",
      "Optimize rendering performance for canvas and WebGL creative tools.",
      "Collaborate closely with design systems teams and product managers."
    ],
    requirements: [
      "Expertise in JavaScript (ES6+), TypeScript, React, and CSS/Tailwind.",
      "Strong aesthetic sense and understanding of modern UI/UX design patterns.",
      "Experience with state management (Zustand/Redux) and unit testing."
    ],
    skills: ["React", "TypeScript", "Tailwind CSS", "Next.js", "Web Performance"],
    eligibleBranches: ["ALL", "CSE", "ECE", "AI_ML", "MECH", "CIVIL"],
    minCgpa: 6.5,
    eligibleGradYears: [2025, 2026, 2027],
    perks: ["100% Remote Work", "Free Adobe Creative Cloud Subscription", "Mentorship", "Certificate"],
    questions: [
      { id: "q1", question: "Share your live portfolio or CodePen/GitHub links.", type: "text", required: true }
    ],
    status: "PUBLISHED",
    postedAt: new Date(Date.now() - 8 * 86400000).toISOString(),
    applicantCount: 89,
  }
];

const BACKEND_URL = process.env.NEXT_PUBLIC_BACKEND_URL || "https://project-9zrh.onrender.com";

export async function GET(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const id = searchParams.get("id");
    const status = searchParams.get("status");

    let dbInternships: InternshipItem[] = [];
    try {
      const res = await fetch(`${BACKEND_URL}/internships`, { cache: "no-store" });
      if (res.ok) {
        const rows = await res.json();
        if (Array.isArray(rows)) {
          dbInternships = rows.map((r: any) => ({
            id: r.id,
            title: r.title,
            company: r.company || "MyVault",
            logo: r.logo || "",
            workMode: r.workMode || (r.work_mode as any) || "HYBRID",
            location: r.location || "Bengaluru, India",
            category: r.category || "Software Development",
            openings: Number(r.openings || r.max_students || 5),
            startDate: r.start_date || r.startDate,
            deadline: r.deadline,
            duration: r.duration || "6 Months",
            stipend: r.stipend || "₹40,000 / month",
            isPaid: true,
            currency: "INR",
            description: r.description || "",
            contactPhone: r.contactPhone || r.contact_phone || "",
            contactEmail: r.contactEmail || r.contact_email || "",
            companyWebsite: r.companyWebsite || r.company_website || "",
            applyUrl: r.applyUrl || r.apply_url || "",
            responsibilities: Array.isArray(r.responsibilities) ? r.responsibilities : (r.responsibilities ? String(r.responsibilities).split("\n") : []),
            requirements: Array.isArray(r.requirements) ? r.requirements : (r.requirements ? String(r.requirements).split("\n") : []),
            skills: Array.isArray(r.skills) ? r.skills : (r.skills ? String(r.skills).split(",") : ["Full Stack", "Problem Solving"]),
            eligibleBranches: Array.isArray(r.eligibleBranches) ? r.eligibleBranches : (r.branch ? [r.branch] : ["ALL"]),
            minCgpa: Number(r.minCgpa || r.min_cgpa || 6.5),
            eligibleGradYears: [2025, 2026, 2027],
            perks: Array.isArray(r.perks) ? r.perks : ["PPO Opportunity", "Mentorship", "Certificate"],
            questions: [],
            status: (r.status as any) || "PUBLISHED",
            postedAt: r.posted_at || r.postedAt || new Date().toISOString(),
            applicantCount: Number(r.applicantCount || r.enrollment_count || 0),
          }));
        }
      }
    } catch (e) {
      console.error("Failed to fetch from backend DB:", e);
    }

    // Merge backend DB rows with mock list, prioritizing DB rows
    const dbIds = new Set(dbInternships.map(i => i.id));
    const combined = [...dbInternships, ...mockInternships.filter(m => !dbIds.has(m.id))];

    if (id) {
      const found = combined.find(i => i.id === id);
      if (!found) return NextResponse.json({ error: "Internship not found" }, { status: 404 });
      return NextResponse.json(found);
    }
    if (status) {
      return NextResponse.json(combined.filter(i => i.status === status));
    }

    return NextResponse.json(combined);
  } catch (error: any) {
    return NextResponse.json({ error: error?.message || "Internal server error" }, { status: 500 });
  }
}

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const newInternship: InternshipItem = {
      id: body.id || "int_" + Date.now() + "_" + Math.random().toString(36).substring(2, 7),
      title: body.title,
      company: body.company || "MyVault Partner",
      logo: body.logo || "",
      workMode: body.workMode || "HYBRID",
      location: body.location || "Bengaluru, Karnataka",
      category: body.category || "Software Development",
      openings: Number(body.openings) || 5,
      startDate: body.startDate,
      deadline: body.deadline,
      duration: body.duration || "6 Months",
      stipend: body.stipend || "40,000",
      isPaid: body.isPaid !== false,
      currency: body.currency || "INR",
      description: body.description || "",
      contactPhone: body.contactPhone || body.contact_phone || "",
      contactEmail: body.contactEmail || body.contact_email || "",
      companyWebsite: body.companyWebsite || body.company_website || "",
      applyUrl: body.applyUrl || body.apply_url || "",
      responsibilities: Array.isArray(body.responsibilities) ? body.responsibilities : (body.responsibilities || "").split("\n").filter(Boolean),
      requirements: Array.isArray(body.requirements) ? body.requirements : (body.requirements || "").split("\n").filter(Boolean),
      skills: Array.isArray(body.skills) ? body.skills : (body.skills || "").split(",").map((s: string) => s.trim()).filter(Boolean),
      eligibleBranches: Array.isArray(body.eligibleBranches) && body.eligibleBranches.length > 0 ? body.eligibleBranches : ["ALL"],
      minCgpa: Number(body.minCgpa) || 6.5,
      eligibleGradYears: Array.isArray(body.eligibleGradYears) ? body.eligibleGradYears : [2026, 2027],
      perks: Array.isArray(body.perks) ? body.perks : ["Certificate", "Mentorship", "PPO Conversion"],
      questions: Array.isArray(body.questions) ? body.questions : [],
      status: body.status || "PUBLISHED",
      postedAt: new Date().toISOString(),
      applicantCount: 0,
    };

    // Save locally
    mockInternships.unshift(newInternship);

    // Sync to PostgreSQL on Render backend
    try {
      await fetch(`${BACKEND_URL}/admin/internships/confirm`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          id: newInternship.id,
          title: newInternship.title,
          company: newInternship.company,
          type: "INTERNSHIP",
          workMode: newInternship.workMode,
          category: newInternship.category,
          branch: newInternship.eligibleBranches.join(", "),
          stipend: newInternship.stipend,
          location: newInternship.location,
          deadline: newInternship.deadline,
          duration: newInternship.duration,
          maxStudents: newInternship.openings,
          description: newInternship.description,
          applyUrl: newInternship.applyUrl,
          contactPhone: newInternship.contactPhone,
          contactEmail: newInternship.contactEmail,
          companyWebsite: newInternship.companyWebsite,
          responsibilities: newInternship.responsibilities,
          requirements: newInternship.requirements,
          skills: newInternship.skills,
          minCgpa: newInternship.minCgpa,
          perks: newInternship.perks,
        }),
      });
    } catch (err) {
      console.error("Failed to forward internship to Render backend:", err);
    }

    return NextResponse.json(newInternship, { status: 201 });
  } catch (error: any) {
    return NextResponse.json({ error: error?.message || "Failed to create internship" }, { status: 500 });
  }
}

export async function PATCH(request: Request) {
  try {
    const body = await request.json();
    const { id, ...updates } = body;
    const index = mockInternships.findIndex(i => i.id === id);
    if (index !== -1) {
      mockInternships[index] = { ...mockInternships[index], ...updates };
    }

    try {
      await fetch(`${BACKEND_URL}/admin/internships/confirm`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ id, ...updates }),
      });
    } catch (_) {}

    return NextResponse.json(mockInternships[index] || { id, ...updates });
  } catch (error: any) {
    return NextResponse.json({ error: error?.message || "Failed to update internship" }, { status: 500 });
  }
}

export async function DELETE(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const id = searchParams.get("id");
    if (!id) return NextResponse.json({ error: "ID required" }, { status: 400 });

    mockInternships = mockInternships.filter(i => i.id !== id);

    try {
      await fetch(`${BACKEND_URL}/admin/internships/${id}`, { method: "DELETE" });
    } catch (_) {}

    return NextResponse.json({ success: true, id });
  } catch (error: any) {
    return NextResponse.json({ error: error?.message || "Failed to delete internship" }, { status: 500 });
  }
}
